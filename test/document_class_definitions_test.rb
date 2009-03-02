require File.join(File.dirname(__FILE__), 'test_helper.rb')

class Foo < Exegesis::Document; end
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
        
        expect { @obj.castees.class.will == Array }
        expect { @obj.castees[0].class.will == Foo }
        expect { @obj.castees[0]['foo'].will == 'foo' }
        expect { @obj.castees[1].class.will == Bar }
        expect { @obj.castees[1]['foo'].will == 'bar' }
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
