require File.join(File.dirname(__FILE__), 'test_helper.rb')

class Foo < Exegesis::Document
  expose :ref, :as => :reference
end
class Bar < Exegesis::Document; end

class WithDefault < Exegesis::Document
  default :foo => 'bar'
end

class Exposer < Exegesis::Document
  expose :foo, :bar
  expose :read_only, :writer => false
  expose :custom_writer, :writer => lambda {|val| {'value' => val} }
  expose :castee, :castees, :as => :given
  expose :time, :times, :as => Time
  expose :regex, :regexen, :as => Regexp
  expose :other_doc, :other_docs, :as => :reference
end

class Timestamper < Exegesis::Document
  timestamps!
end

class UniqueSnowflake < Exegesis::Document
  unique_id :set_id
  def set_id
    @unique_id_attempt.zero? ? "snowflake" : "snowflake-#{@unique_id_attempt}"
  end
end

class ExegesisDocumentClassDefinitionsTest < Test::Unit::TestCase
  
  context "a bare Exegesis::Document" do
    before do
      reset_db
      @obj = Foo.new
      @obj.database = @db
      @obj.save
    end
    
    expect { @obj['.kind'].will == "Foo" }
    expect { @obj['foo'].will == nil }
    expect { @obj.will_not respond_to(:foo) }
    expect { @obj['created_at'].will == nil }
    expect { @obj['updated_at'].will == nil }
  end
  
  context "instantiating" do
    expect { Exegesis::Document.instantiate({'.kind' => 'Foo'}).will be_kind_of(Foo) }

    context "transitions" do
      before do
        @foo = Foo.new
        @foo['.kind'] = 'Bar'
        @bar = Exegesis::Document.instantiate(@foo)
      end
      
      expect { @bar.will be_kind_of(Bar) }
    end
  end
  
  context "default objects" do
    expect { WithDefault.new['foo'].will == 'bar' }
    expect { WithDefault.new({'foo' => 'baz'})['foo'].will == 'baz' }
  end
  
  context "exposing keys" do
    context "regular declarations" do
      before do 
        @obj = Exposer.new(:foo => 'bar', :bar => 'foo')
        @writing = lambda { @obj.bar = "bee" }
      end
      expect { @obj.foo.will == 'bar' }
      expect { @obj.bar.will == 'foo' }
      expect { @writing.wont raise_error }
      expect { @writing.call; @obj.bar.will == "bee" }
    end
    
    context "with a custom writer" do
      context "when false" do
        before { @obj = Exposer.new(:read_only => 'value') }
        expect { @obj.read_only.will == 'value' }
        expect { lambda{@obj.read_only = "other value"}.will raise_error(NoMethodError) }
      end
      
      context "when lambda" do
        before do
          @obj = Exposer.new(:custom_writer => 'value')
          @obj.custom_writer = 'other value'
          @expected = {'value' => 'other value'}
        end
        expect { @obj.custom_writer.will == @expected }
      end
    end
    
    context "when casting a value" do
      context "when as given" do
        before do
          @obj = Exposer.new({
            :castee => {'foo' => 'foo', '.kind' => 'Foo'},
            :castees => [{'foo' => 'foo', '.kind' => 'Foo'}, {'foo' => 'bar', '.kind' => 'Bar'}]
          })
        end
        
        expect { @obj.castee.class.will == Foo }
        expect { @obj.castee['foo'].will == 'foo' }
        expect { @obj.castee.parent.will == @obj }
        
        expect { @obj.castees.class.will == Array }
        expect { @obj.castees[0].class.will == Foo }
        expect { @obj.castees[0]['foo'].will == 'foo' }
        expect { @obj.castees[0].parent.will == @obj }
        expect { @obj.castees[1].class.will == Bar }
        expect { @obj.castees[1]['foo'].will == 'bar' }
        expect { @obj.castees[1].parent.will == @obj }
      end
      
      context "when as time" do
        before do
          @obj = Exposer.new({:time => Time.now.to_json, :times => [Time.local(2009,3,1).to_json, Time.local(2009,2,1).to_json]})
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
          @obj = Exposer.new({
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
            @obj = Exposer.new(:other_doc => "other_doc", :other_docs => ["other_docs_1", "other_docs_2"])
            @obj.database = @db
          end
          
          context "when the document exists" do
            before do
              @db.bulk_save([
                {'.kind' => 'Foo', '_id' => 'other_doc'},
                {'.kind' => 'Foo', '_id' => 'other_docs_1'}, 
                {'.kind' => 'Foo', '_id' => 'other_docs_2'}
              ])
            end
            
            expect { @obj.other_doc.rev.will == @db.get('other_doc')['_rev'] }
            expect { @obj.other_doc.class.will == Foo }
            expect { @obj.other_docs.class.will == Array }
            expect { @obj.other_docs[0].rev.will == @db.get('other_docs_1')['_rev'] }
            expect { @obj.other_docs[0].class.will == Foo }
            expect { @obj.other_docs[1].rev.will == @db.get('other_docs_2')['_rev'] }
            expect { @obj.other_docs[1].class.will == Foo }
            
            context "caching" do
              before do
                @obj.other_doc
                doc = @db.get('other_doc')
                doc['foo'] = "updated"
                doc.save
              end
              
              expect { @obj.other_doc['foo'].will be(nil) }
              expect { @obj.other_doc(true)['foo'].will == 'updated' }
            end
          end
          
          context "when the document is missing" do
            expect { lambda{@obj.other_doc}.will raise_error(RestClient::ResourceNotFound) }
            expect { lambda{@obj.other_docs}.will raise_error(RestClient::ResourceNotFound) }
          end
          
          context "when the doucment has a parent" do
            before do
              @obj.castee = Foo.new({})
              @obj.castee.ref = 'other_doc'
              @obj.save
              @db.save_doc({'.kind' => 'Foo', '_id' => 'other_doc'})
            end
            
            expect { @obj.castee.ref.rev.will == @db.get('other_doc')['_rev'] }
          end
        end
        
        context "without a database present" do
          before { @obj = Exposer.new(:other_doc => "some_doc_id") }
          expect { lambda{@obj.other_doc}.will raise_error(ArgumentError) }
        end
      end
      
      context "when the value is nil" do
        before do
          @obj = Exposer.new({:castee => nil, :castees => nil, :regexen => ['foo', nil]})
        end
        expect { @obj.castee.will be(nil) }
        expect { @obj.castees.will be(nil) }
        expect { @obj.regexen.will == [/foo/] }
      end
    end
  end
  
  context "with timestamps" do
    before do
      reset_db
      @obj = Timestamper.new
      @obj.database = @db
      @obj.save
      @obj = Timestamper.new(@db.get(@obj.id))
    end
    
    context "initial save" do
      expect { @obj.created_at.to_f.will be_close(Time.now.to_f, 1) }
      expect { @obj.updated_at.to_f.will be_close(Time.now.to_f, 1) }
    end
    
    context "when created_at already exists" do
      before do
        @obj.database = @db
        @obj['created_at'] = Time.now
        @obj.save
        @obj = Timestamper.new(@db.get(@obj.id))
      end
      
      expect { @obj.created_at.to_f.will be_close(Time.now.to_f, 1) }
      expect { @obj.updated_at.to_f.will be_close(Time.now.to_f, 1) }
    end
    
  end
  
  context "with a custom unique_id setter" do
    before do
      reset_db
      @obj = UniqueSnowflake.new
      @obj.database = @db
    end
    
    context "when the id isn't in use yet" do
      before do
        @obj.save
      end
      
      expect { @obj.id.will == "snowflake" }
    end
    
    context "when there is an id in place already" do
      before do
        @obj['_id'] = 'foo'
        @obj.save
      end
      
      expect { @obj.id.will == "foo" }
    end
    
    context "when the desired id is already in use" do
      before do
        @db.save_doc({'_id' => 'snowflake', 'foo' => 'bar'})
        @obj.save
      end
      
      expect { @obj.id.will == 'snowflake-1' }
    end
  end
  
end
