require File.join(File.dirname(__FILE__), 'test_helper.rb')

class TestDocument
  include Exegesis::Document
  expose :foo
end

class TimestampTestDocument
  include Exegesis::Document
  timestamps!
end

class UniqueIdTestDocument
  include Exegesis::Document
  unique_id :set_id
  def set_id attempt
    attempt.zero? ? "snowflake" : "snowflake-#{attempt}"
  end
end

class UniqueIdBlockTestDocument
  include Exegesis::Document
  unique_id {|doc, attempt| attempt.zero? ? doc['pk'] : "#{doc['pk']}-#{attempt}" }
end

class ExegesisDocumentClassDefinitionsTest < Test::Unit::TestCase
  
  context "class definitions" do
    context "with timestamps" do
      before do
        reset_db
        @obj = TimestampTestDocument.new({}, @db)
        @obj.save
        @obj = @db.get(@obj.id)
      end
    
      context "initial save" do
        expect { @obj.created_at.to_f.will be_close(Time.now.to_f, 2) }
        expect { @obj.updated_at.to_f.will be_close(Time.now.to_f, 2) }
      end
    
      context "when created_at already exists" do
        before do
          @obj['created_at'] = Time.now - 3600
          @obj.save
          @obj = @db.get(@obj.id)
        end
      
        expect { @obj.created_at.to_f.will be_close((Time.now - 3600).to_f, 2) }
        expect { @obj.updated_at.to_f.will be_close(Time.now.to_f, 2) }
      end
    
    end
  
    context "with a custom unique_id setter" do
      context "as a method" do
        before do
          reset_db
          @obj = UniqueIdTestDocument.new({}, @db)
        end
    
        context "when the id isn't in place yet" do
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
            @db.put('snowflake', {'_id' => 'snowflake', 'foo' => 'bar'})
            @obj.save
          end
      
          expect { @obj.id.will == 'snowflake-1' }
        end
      end
      
      context "as a block" do
        before do
          reset_db
          @obj = UniqueIdBlockTestDocument.new({'pk'=>'bar'}, @db)
        end
        
        context "when the id doesn't yet exist and no id in place" do
          before { @obj.save }
          expect { @obj.id.will == @obj['pk'] }
        end
        
        context "when the document has an id in place already" do
          before do
            @obj['_id'] = 'foo'
            @obj.save
          end
          expect { @obj.id.will == 'foo' }
        end
        
        context "when the desired id is already in use" do
          before do
            @db.put('bar', {'_id' => 'bar', 'pk' => 'bar'})
            @obj.save
          end
          expect { @obj.id.will == 'bar-1'}
        end
      end
    end
  end
  
  context "instance methods" do
    before do
      reset_db
    end

    context "updating attributes" do
    
      context "an existing doc" do
        before do
          @doc = TestDocument.new({'foo' => 'bar'}, @db)
          @doc.save
          @old_rev = @doc.rev
        end
      
        context "without a matching rev" do
          expect { lambda {@doc.update_attributes({'foo' => 'bee'})}.will raise_error(ArgumentError) }
          expect { lambda {@doc.update_attributes({'foo' => 'bee', '_rev' => 'z'})}.will raise_error(ArgumentError) }
        end
      
        context "with a matching rev" do
          before do
            @doc.update_attributes({'_rev' => @doc.rev, 'foo' => 'bee'})
          end
        
          expect { @doc['foo'].will == 'bee' }
          expect { @doc.rev.wont == @old_rev }
        end
        
        context "when given keys without writers" do
          before do
            @action = lambda {@doc.update_attributes({'_rev' => @doc.rev, 'bar' => 'boo'})}
          end
          
          expect { @action.will raise_error(NoMethodError) }
        end
      end
      
      context "a new doc" do
        before { @doc = TestDocument.new({'foo' => 'bar'}, @db) }
        
        context "without a rev" do
          before { @doc.update_attributes({'foo' => 'baz'}) }
          expect { @doc['foo'].will == 'baz' }
        end

        context "with a blank rev" do
          before { @doc.update_attributes({'foo' => 'baz', '_rev' => ''}) }
          expect { @doc['foo'].will == 'baz' }
        end
        context "with a non blank rev" do
          before { @action = lambda{@doc.update_attributes({'foo'=>'baz', '_rev'=>'1-3034523523'})} }
          expect { @action.will raise_error(ArgumentError)}
        end
      end
      
      
    end
  end
  
end
