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

module DocumentSingletonDatabaseTest
  extend self
  extend Exegesis::Database::Singleton
end
class SingletonDatabaseDocument
  include Exegesis::Document
  database DocumentSingletonDatabaseTest
end

describe Exegesis::Document do
  
  describe "class definitions" do
    describe "with database declarations" do
      before do
        @doc = SingletonDatabaseDocument.new
      end
      
      expect { SingletonDatabaseDocument.database.must_equal DocumentSingletonDatabaseTest }
      expect { @doc.database.must_equal DocumentSingletonDatabaseTest }
      
      expect { lambda{SingletonDatabaseDocument.database("foo")}.must_raise(ArgumentError) }
    end
    
    describe "with timestamps" do
      before do
        reset_db
        @obj = TimestampTestDocument.new({}, @db)
        @obj.save
        @obj = @db.get(@obj.id)
      end
    
      describe "initial save" do
        expect { @obj.created_at.to_f.must_be_close_to Time.now.to_f, 2 }
        expect { @obj.updated_at.to_f.must_be_close_to Time.now.to_f, 2 }
      end
    
      describe "when created_at already exists" do
        before do
          @obj['created_at'] = Time.now - 3600
          @obj.save
          @obj = @db.get(@obj.id)
        end
      
        expect { @obj.created_at.to_f.must_be_close_to((Time.now - 3600).to_f, 2) }
        expect { @obj.updated_at.to_f.must_be_close_to Time.now.to_f, 2 }
      end
    
    end
  
    describe "with a custom unique_id setter" do
      describe "as a method" do
        before do
          reset_db
          @obj = UniqueIdTestDocument.new({}, @db)
        end
    
        describe "when the id isn't in place yet" do
          before do
            @obj.save
          end
      
          expect { @obj.id.must_equal "snowflake" }
        end
    
        describe "when there is an id in place already" do
          before do
            @obj['_id'] = 'foo'
            @obj.save
          end
      
          expect { @obj.id.must_equal "foo" }
        end
    
        describe "when the desired id is already in use" do
          before do
            @db.put('snowflake', {'_id' => 'snowflake', 'foo' => 'bar'})
            @obj.save
          end
      
          expect { @obj.id.must_equal 'snowflake-1' }
        end
      end
      
      describe "as a block" do
        before do
          reset_db
          @obj = UniqueIdBlockTestDocument.new({'pk'=>'bar'}, @db)
        end
        
        describe "when the id doesn't yet exist and no id in place" do
          before { @obj.save }
          expect { @obj.id.must_equal @obj['pk'] }
        end
        
        describe "when the document has an id in place already" do
          before do
            @obj['_id'] = 'foo'
            @obj.save
          end
          expect { @obj.id.must_equal 'foo' }
        end
        
        describe "when the desired id is already in use" do
          before do
            @db.put('bar', {'_id' => 'bar', 'pk' => 'bar'})
            @obj.save
          end
          expect { @obj.id.must_equal 'bar-1'}
        end
      end
    end
  end
  
  describe "instance methods" do
    before do
      reset_db
    end

    describe "updating attributes" do
      
      describe "an existing doc" do
        before do
          @doc = TestDocument.new({'foo' => 'bar'}, @db)
          @doc.save
          @old_rev = @doc.rev
        end
      
        describe "without a matching rev" do
          expect { lambda{@doc.update_attributes({'foo' => 'bee'})}.must_raise ArgumentError }
          expect { lambda{@doc.update_attributes({'foo' => 'bee', '_rev' => 'z'})}.must_raise ArgumentError }
        end
      
        describe "with a matching rev" do
          before do
            @doc.update_attributes({'_rev' => @doc.rev, 'foo' => 'bee'})
          end
        
          expect { @doc['foo'].must_equal 'bee' }
          expect { @doc.rev.wont_equal @old_rev }
        end
        
        describe "when given keys without writers" do
          before do
            @action = lambda {@doc.update_attributes({'_rev' => @doc.rev, 'bar' => 'boo'})}
          end
          
          expect { @action.must_raise NoMethodError }
        end
      end
      
      describe "a new doc" do
        before { @doc = TestDocument.new({'foo' => 'bar'}, @db) }
        
        describe "without a rev" do
          before { @doc.update_attributes({'foo' => 'baz'}) }
          expect { @doc['foo'].must_equal 'baz' }
        end

        describe "with a blank rev" do
          before { @doc.update_attributes({'foo' => 'baz', '_rev' => ''}) }
          expect { @doc['foo'].must_equal 'baz' }
        end
        describe "with a non blank rev" do
          before { @action = lambda{@doc.update_attributes({'foo'=>'baz', '_rev'=>'1-3034523523'})} }
          expect { @action.must_raise ArgumentError }
        end
      end
      
      describe "with attachments" do
        before do
          @doc = TestDocument.new({}, @db)
          @doc.update_attributes({'_attachments' => 
            {'file.txt' => {'content_type' => 'text/plain', 'stub' => true}}
          })
        end
        
        expect {@doc.attachments['file.txt'].must_be_instance_of(Exegesis::Document::Attachment) }
      end
      
    end
  end
  
end
