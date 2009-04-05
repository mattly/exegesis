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
  include Exegesis::Model
  attr_accessor :database
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

class ExegesisModelTest < Test::Unit::TestCase
  
  context "class definitions" do
    context "default objects" do
      expect { WithDefaultTestModel.new['foo'].will == 'bar' }
      expect { WithDefaultTestModel.new({'foo' => 'baz'})['foo'].will == 'baz' }
    end
  
    context "exposing keys" do
      context "regular declarations" do
        before do 
          @obj = ExposeTestModel.new(:foo => 'bar', :bar => 'foo')
        end
        context "reading" do
          expect { @obj.foo.will == 'bar' }
          expect { @obj.bar.will == 'foo' }
        end
      
        context "writing" do
          before do
            @obj.bar = "bee"
          end
          expect { @obj.bar.will == "bee" }
        end
      end
    
      context "with a custom writer" do
        context "when false" do
          before { @obj = ExposeTestModel.new(:read_only => 'value') }
          expect { @obj.read_only.will == 'value' }
          expect { lambda{@obj.read_only = "other value"}.will raise_error(NoMethodError) }
        end
      
        context "when lambda" do
          before do
            @obj = ExposeTestModel.new(:custom_writer => 'value')
            @obj.custom_writer = 'other value'
            @expected = {'value' => 'other value'}
          end
          expect { @obj.custom_writer.will == @expected }
        end
      end
    
      context "when casting a value" do
        context "when as given" do
          before do
            @obj = ExposeTestModel.new({
              :castee => {'foo' => 'foo', 'class' => 'FooTestModel'},
              :castees => [
                {'foo' => 'foo', 'class' => 'FooTestModel'}, 
                {'foo' => 'bar', 'class' => 'BarTestModel'}
              ]
            })
          end
        
          expect { @obj.castee.class.will == FooTestModel }
          expect { @obj.castee['foo'].will == 'foo' }
          expect { @obj.castee.parent.will == @obj }
        
          expect { @obj.castees.class.will == Array }
          expect { @obj.castees[0].class.will == FooTestModel }
          expect { @obj.castees[0]['foo'].will == 'foo' }
          expect { @obj.castees[0].parent.will == @obj }
          expect { @obj.castees[1].class.will == BarTestModel }
          expect { @obj.castees[1]['foo'].will == 'bar' }
          expect { @obj.castees[1].parent.will == @obj }
        end
      
        context "when as time" do
          before do
            @obj = ExposeTestModel.new({:time => Time.now.to_json, :times => [Time.local(2009,3,1).to_json, Time.local(2009,2,1).to_json]})
          end
        
          expect { @obj.time.class.will == Time }
          expect { @obj.time.to_f.will be_close(Time.now.to_f, 1) }
        
          expect { @obj.times.class.will == Array }
          expect { @obj.times[0].class.will == Time }
          expect { @obj.times[0].will == Time.local(2009,3,1) }
          expect { @obj.times[1].class.will == Time }
          expect { @obj.times[1].will == Time.local(2009,2,1) }
        end
      
        context "when as non document class" do
          before do
            @obj = ExposeTestModel.new({
              :regex => 'foo',
              :regexen => ['foo', 'bar']
            })
          end
        
          expect { @obj.regex.will == /foo/ }
        
          expect { @obj.regexen.class.will == Array }
          expect { @obj.regexen[0].will == /foo/ }
          expect { @obj.regexen[1].will == /bar/ }
        end
      
        context "when as reference" do
          context "with a database present" do
            before do
              reset_db
              @obj = ExposeTestModel.new(:other_doc => "other_doc", 
                                         :other_docs => ["other_docs_1", "other_docs_2"])
              @doc = ModelTestDocument.new
              @doc.database = @db
              @obj.parent = @doc
            end
          
            context "when the referenced document exists" do
              before do
                [ {'class' => 'ModelTestDocument', '_id' => 'other_doc'},
                  {'class' => 'ModelTestDocument', '_id' => 'other_docs_1'}, 
                  {'class' => 'ModelTestDocument', '_id' => 'other_docs_2'}
                ].each {|doc| @db.put(doc.delete('_id'), doc) }
              end
            
              expect { @obj.other_doc['_rev'].will == @db.get('other_doc')['_rev'] }
              expect { @obj.other_doc.class.will == ModelTestDocument }
              expect { @obj.other_docs.class.will == Array }
              expect { @obj.other_docs[0]['_rev'].will == @db.get('other_docs_1')['_rev'] }
              expect { @obj.other_docs[0].class.will == ModelTestDocument }
              expect { @obj.other_docs[1]['_rev'].will == @db.get('other_docs_2')['_rev'] }
              expect { @obj.other_docs[1].class.will == ModelTestDocument }
            
              context "caching" do
                before do
                  @obj.other_doc # load it
                  doc = @db.get('other_doc')
                  doc.update('foo' => 'updated')
                  @db.put(doc['_id'], doc.attributes)
                end
              
                expect { @obj.other_doc['foo'].will be(nil) }
                expect { @obj.other_doc(true)['foo'].will == 'updated' }
              end
            end
          
            context "when the document is missing" do
              expect { lambda{@obj.other_doc}.will raise_error(RestClient::ResourceNotFound) }
              expect { lambda{@obj.other_docs}.will raise_error(RestClient::ResourceNotFound) }
            end
          
            context "when the model has a parent" do
              before do
                @obj.castee = {'class' => 'FooTestModel', 'ref' => 'other_doc'}
                @db.put('other_doc', {'class' => 'ModelTestDocument', '_id' => 'other_doc'})
              end
            
              expect { @obj.castee.ref['_rev'].will == @db.get('other_doc')['_rev'] }
            end
          end
        
          context "without any database present" do
            before { @obj = ExposeTestModel.new(:other_doc => "some_doc_id") }
            expect { lambda{@obj.other_doc}.will raise_error(ArgumentError) }
          end
        end
      
        context "when the value is nil" do
          before do
            @obj =  ExposeTestModel.new({:castee => nil, :castees => nil, :regexen => ['foo', nil]})
          end
          expect { @obj.castee.will be(nil) }
          expect { @obj.castees.will be(nil) }
          expect { @obj.regexen.will == [/foo/] }
        end
      end
    end
  end
  
  context "instance methods" do
    before do
      @obj = ExposeTestModel.new({:read_only => 'bar'})
    end
    context "update" do
      before do
        @obj.update({:read_only => 'bee'})
      end
      
      expect { @obj.read_only.will == 'bee' } 
    end
    
    context "update" do
      context "with a writer" do
        before do
          @obj.update_attributes(:foo => 'foo')
        end
        
        expect { @obj.foo.will == "foo" }
      end
      
      context "without a writer" do
        expect { lambda{@obj.update_attributes({:read_only => 'bee'})}.will raise_error(NoMethodError) }
      end
    end
  end
  
end