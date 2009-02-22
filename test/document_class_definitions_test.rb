require File.join(File.dirname(__FILE__), 'test_helper.rb')

class Foo < Exegesis::Document; end
class Bar < Exegesis::Document; end

class Caster < Exegesis::Document
  cast 'castee'
  cast 'castees'
  cast 'time', :as => Time
  cast 'regex', :as => Regexp
  cast 'regexen', :as => Regexp
end
class WithDefault < Exegesis::Document
  default :foo => 'bar'
end
class Exposer < Exegesis::Document
  expose :foo, :bar
  show :baz
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
  
  context "casting keys into classes" do
    before do
      @caster = Caster.new({
        'castee' => {'foo' => 'bar', '.kind' => 'Foo'},
        'castees' => [{'foo' => 'bar', '.kind' => 'Foo'}, {'foo' => 'baz', '.kind' => 'Bar'}],
        'time' => Time.now.to_json,
        'regex' => 'foo', 
        'regexen' => ['foo', 'bar']
      })
    end
    
    expect { @caster['castee'].will be_kind_of(Foo) }
    expect { @caster['castee']['foo'].will == 'bar' }
    
    expect { @caster['regex'].will be_kind_of(Regexp) }
    expect { @caster['regex'].will == /foo/ }

    expect { @caster['time'].will be_kind_of(Time) }

    expect { @caster['castees'].will be_kind_of(Array) }
    expect { @caster['castees'].first.will be_kind_of(Foo) }
    expect { @caster['castees'].first['foo'].will == 'bar' }
    expect { @caster['castees'].last.will be_kind_of(Bar) }
    expect { @caster['castees'].last['foo'].will == 'baz' }
    
    expect { @caster['regexen'].will be_kind_of(Array) }
    expect { @caster['regexen'].first.will be_kind_of(Regexp) }
    expect { @caster['regexen'].last.will be_kind_of(Regexp) }
    expect { @caster['regexen'].first.will == /foo/ }
    expect { @caster['regexen'].last.will == /bar/ }
    
    context "with bad syntax" do
      expect { lambda{Caster.class_eval {cast :foo, Time} }.will raise_error(ArgumentError) }
    end
  end
  
  context "default objects" do
    expect { WithDefault.new['foo'].will == 'bar' }
    expect { WithDefault.new({'foo' => 'baz'})['foo'].will == 'baz' }
  end
  
  context "exposing keys as methods" do
    before do
      @obj = Exposer.new(:foo => 'bar', :bar => 'foo', :baz => 'bee')
    end
    
    expect { @obj.will respond_to(:foo) }
    expect { @obj.foo.will == 'bar' }
    expect { @obj.will respond_to(:bar) }
    expect { @obj.bar.will == 'foo' }
    expect { @obj.will respond_to(:baz) }
    expect { @obj.baz.will == 'bee' }
    
    expect { @obj.will respond_to(:foo=) }
    expect { @obj.will respond_to(:bar=) }
    expect { @obj.wont respond_to(:baz=) }
    
    describe "writing methods" do
      before do
        @obj.foo = "foo"
      end
      
      expect { @obj.foo.will == "foo" }
    end
  end
  
  context "with timestamps" do
    before do
      reset_db
      @obj = Timestamper.new
      @obj.database = @db
      # stub(Time).now { Time.utc(2009,1,15) }
      @obj.save
      @obj = Timestamper.new(@db.get(@obj.id))
    end
    
    context "initial save" do
      expect { @obj['created_at'].to_i.will == Time.now.to_i }
      expect { @obj['updated_at'].to_i.will == Time.now.to_i }
    end
    
    context "when created_at already exists" do
      before do
        @obj.database = @db
        @obj['created_at'] = Time.now
        @obj.save
        @obj = Timestamper.new(@db.get(@obj.id))
      end
      
      expect { @obj['created_at'].to_i.will == Time.now.to_i }
      expect { @obj['updated_at'].to_i.will == Time.now.to_i }
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
  
  context "interacting with rails/merb assumptions" do
    context "to_param for routes" do
      before { @doc = Foo.new({'_id' => 'foo'})}
      expect { @doc.to_param.will == "foo" }
    end
  end
  
end
