require File.join(File.dirname(__FILE__), 'test_helper.rb')

class FooTestModel
  include Exegesis::Model
  expose :ref, :as => :reference
end
class BarTestModel
  include Exegesis::Model
end

class WithDefaultTestModel
  include Exegesis::Model
  default :foo => 'bar'
end

class ModelTestDocument
  include Exegesis::Document
end

class ExposeTestModel
  include Exegesis::Model
  expose :foo, :bar
  expose :read_only, :writer => false
  expose :custom_writer, :writer => lambda {|val| {'value' => val} }
  expose :castee, :castees, :as => :given
  expose :time, :times, :as => Time
  expose :regex, :regexen, :as => Regexp
  expose :other_doc, :other_docs, :as => :reference
end

describe Exegesis::Model do
  
  describe "class definitions" do
    describe "default objects" do
      expect { WithDefaultTestModel.new['foo'].must_equal 'bar' }
      expect { WithDefaultTestModel.new({'foo' => 'baz'})['foo'].must_equal 'baz' }
    end
  
    describe "exposing keys" do
      describe "regular declarations" do
        before do 
          @obj = ExposeTestModel.new(:foo => 'bar', :bar => 'foo')
        end
        describe "reading" do
          expect { @obj.foo.must_equal 'bar' }
          expect { @obj.bar.must_equal 'foo' }
        end
      
        describe "writing" do
          before do
            @obj.bar = "bee"
          end
          expect { @obj.bar.must_equal "bee" }
        end
      end
    
      describe "with a custom writer" do
        describe "when false" do
          before { @obj = ExposeTestModel.new(:read_only => 'value') }
          expect { @obj.read_only.must_equal 'value' }
          expect { lambda{@obj.read_only = "other value"}.must_raise NoMethodError }
        end
      
        describe "when lambda" do
          before do
            @obj = ExposeTestModel.new(:custom_writer => 'value')
            @obj.custom_writer = 'other value'
            @expected = {'value' => 'other value'}
          end
          expect { @obj.custom_writer.must_equal @expected }
        end
      end
    
      describe "when casting a value" do
        describe "when as given" do
          before do
            @obj = ExposeTestModel.new({
              :castee => {'foo' => 'foo', 'class' => 'FooTestModel'},
              :castees => [
                {'foo' => 'foo', 'class' => 'FooTestModel'}, 
                {'foo' => 'bar', 'class' => 'BarTestModel'}
              ]
            })
            @obj.castee
            @obj.castees
          end
        
          expect { @obj.castee.must_be_kind_of FooTestModel }
          expect { @obj.castee['foo'].must_equal 'foo' }
          expect { @obj.castee.parent.must_equal @obj }
        
          expect { @obj.castees.must_be_kind_of Array }
          expect { @obj.castees[0].must_be_kind_of FooTestModel }
          expect { @obj.castees[0]['foo'].must_equal 'foo' }
          expect { @obj.castees[0].parent.must_equal @obj }
          expect { @obj.castees[1].must_be_kind_of BarTestModel }
          expect { @obj.castees[1]['foo'].must_equal 'bar' }
          expect { @obj.castees[1].parent.must_equal @obj }
          
          describe "defining the writer" do
            before do
              @obj = ExposeTestModel.new
              @foo = FooTestModel.new({'foo' => 'bar'})
              @obj.castee = @foo
            end
            expect { @obj.castee.must_equal @foo }
          end
        end
      
        describe "when as time" do
          before do
            @obj = ExposeTestModel.new({:time => Time.now.to_json, :times => [Time.local(2009,3,1).to_json, Time.local(2009,2,1).to_json]})
            @obj.time
            @obj.times
          end
        
          expect { @obj.time.must_be_kind_of Time }
          expect { @obj.time.to_f.must_be_close_to Time.now.to_f, 1 }
        
          expect { @obj.times.must_be_kind_of Array }
          expect { @obj.times[0].must_be_kind_of Time }
          expect { @obj.times[0].must_equal Time.local(2009,3,1) }
          expect { @obj.times[1].must_be_kind_of Time }
          expect { @obj.times[1].must_equal Time.local(2009,2,1) }
          
          describe "writing times" do
            before do
              @obj = ExposeTestModel.new
              @time = Time.local(2009,4,16,20,14,26)
            end
            describe "from a time object" do
              before do
                @obj.time = @time
                @obj.times = [@time, @time]
              end
              expect { @obj.time.must_equal @time }
              expect { @obj.times.must_equal [@time, @time] }
            end
            describe "from a string" do
              before do
                @obj.time = @time.xmlschema
                @obj.times = [@time.rfc2822, @time.getutc.strftime("%a, %d %b %Y %H:%M:%S GMT")]
              end
              expect { @obj.time.must_equal @time }
              expect { @obj.times.map{|time| time.localtime }.must_equal [@time, @time] }
              expect { @obj['time'].must_equal @time }
              expect { @obj['times'].must_equal [@time, @time] }
            end
            describe "from a blank string" do
              before do
                @obj.time = ''
                @obj.times = ['', '']
              end
              expect { @obj.time.must_be_nil }
              expect { @obj.times.map{|t| t }.must_equal [] }
              expect { @obj['time'].must_be_nil }
              expect { @obj['times'].must_equal [nil, nil] }
            end
          end
        end
      
        describe "when as non document class" do
          before do
            @obj = ExposeTestModel.new({
              :regex => 'foo',
              :regexen => ['foo', 'bar']
            })
            @obj.regex
            @obj.regexen
          end
        
          expect { @obj.regex.must_equal /foo/ }
        
          expect { @obj.regexen.must_be_kind_of Array }
          expect { @obj.regexen[0].must_equal /foo/ }
          expect { @obj.regexen[1].must_equal /bar/ }
          
          describe "writing values from the class" do
            before do
              @obj = ExposeTestModel.new
              @regex = /foo/
              @obj.regex = @regex
            end
            expect { @obj.regex.must_equal @regex }
          end
        end
      
        describe "when as reference" do
          describe "with a database present" do
            before do
              reset_db
              @obj = ExposeTestModel.new(:other_doc => "other_doc", 
                                         :other_docs => ["other_docs_1", "other_docs_2"])
              @doc = ModelTestDocument.new({}, @db)
              @obj.parent = @doc
            end
          
            describe "when the referenced document exists" do
              before do
                [ {'class' => 'ModelTestDocument', '_id' => 'other_doc'},
                  {'class' => 'ModelTestDocument', '_id' => 'other_docs_1'}, 
                  {'class' => 'ModelTestDocument', '_id' => 'other_docs_2'}
                ].each {|doc| @db.put(doc.delete('_id'), doc) }
              end
            
              expect { @obj.other_doc['_rev'].must_equal @db.get('other_doc')['_rev'] }
              expect { @obj.other_doc.must_be_kind_of ModelTestDocument }
              expect { @obj.other_docs.must_be_kind_of Array }
              expect { @obj.other_docs[0]['_rev'].must_equal @db.get('other_docs_1')['_rev'] }
              expect { @obj.other_docs[0].must_be_kind_of ModelTestDocument }
              expect { @obj.other_docs[1]['_rev'].must_equal @db.get('other_docs_2')['_rev'] }
              expect { @obj.other_docs[1].must_be_kind_of ModelTestDocument }
            
              describe "caching" do
                before do
                  @obj.other_doc # load it
                  doc = @db.get('other_doc')
                  doc.update('foo' => 'updated')
                  @db.put(doc['_id'], doc.attributes)
                end
              
                expect { @obj.other_doc['foo'].must_be_nil }
                expect { @obj.other_doc(true)['foo'].must_equal 'updated' }
              end
            end
          
            describe "when the document is missing" do
              expect { lambda{@obj.other_doc}.must_raise RestClient::ResourceNotFound }
              expect { lambda{@obj.other_docs}.must_raise RestClient::ResourceNotFound }
            end
          
            describe "when the model has a parent" do
              before do
                @obj.castee = {'class' => 'FooTestModel', 'ref' => 'other_doc'}
                @db.put('other_doc', {'class' => 'ModelTestDocument', '_id' => 'other_doc'})
              end
            
              expect { @obj.castee.ref['_rev'].must_equal @db.get('other_doc')['_rev'] }
            end
          end
        
          describe "without any database present" do
            before { @obj = ExposeTestModel.new(:other_doc => "some_doc_id") }
            expect { lambda{@obj.other_doc}.must_raise ArgumentError }
          end
          
          describe "setting references" do
            before do
              reset_db
              @parent = ModelTestDocument.new({}, @db)
              @obj = ExposeTestModel.new
              @obj.parent = @parent
              @doc = ModelTestDocument.new({}, @db)
              @doc.save
            end
            describe "from a doc that has been saved" do
              before do
                @obj.other_doc = @doc
              end
              expect { @obj['other_doc'].must_equal @doc.id }
              expect { @obj.other_doc.must_equal @doc }
            end
            describe "from an id" do
              before do
                @obj.other_doc = @doc.id
              end
              expect { @obj['other_doc'].must_equal @doc.id }
              expect { @obj.other_doc.must_equal @doc }
            end
          end
        end
      
        describe "when the value is nil" do
          before do
            @obj =  ExposeTestModel.new({:castee => nil, :castees => nil, :regexen => ['foo', nil]})
          end
          expect { @obj.castee.must_be_nil }
          expect { @obj.castees.must_be_nil }
          expect { @obj.regexen.must_equal [/foo/] }
        end
        
      end
    end
  end
  
  describe "instance methods" do
    before do
      @obj = ExposeTestModel.new({:read_only => 'bar'})
    end
    describe "update" do
      before do
        @obj.update({:read_only => 'bee'})
      end
      
      expect { @obj.read_only.must_equal 'bee' } 
    end
    
    describe "update_attributes" do
      describe "with a writer" do
        before do
          @obj.update_attributes(:foo => 'foo')
        end
        
        expect { @obj.foo.must_equal "foo" }
      end
      
      describe "without a writer" do
        expect { lambda{@obj.update_attributes({:read_only => 'bee'})}.must_raise NoMethodError }
      end
      
      describe "filtering reserved keys" do
        before do
          @obj.update_attributes('class' => 'Foo')
        end
        
        expect { @obj['class'].must_equal 'ExposeTestModel' }
      end
    end
  end
  
end