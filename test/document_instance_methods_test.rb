require File.join(File.dirname(__FILE__), 'test_helper.rb')

class DocInstance < Exegesis::Document
  expose :foo
end

class ExegesisDocumentInstanceMethodsTest < Test::Unit::TestCase
  
  context "update_attributes" do
    before do
      reset_db
    end
    
    context "an existing doc" do
      before do
        @doc = DocInstance.new({'foo' => 'bar'})
        @doc.database = @db
        @doc.save
        @old_rev = @doc.rev
      end
      
      context "without a matching rev" do
        expect { lambda {@doc.update_attributes({'foo' => 'bee'})}.will raise_error(ArgumentError) }
        expect { lambda {@doc.update_attributes({'foo' => 'bee', '_rev' => 'z'})}.will raise_error(ArgumentError) }
      end
      
      context "with a matching rev" do
        before do
          @doc.update_attributes({'_rev' => @doc.rev, 'foo' => 'bee', 'bar' => 'boo'})
        end
        
        expect { @doc['foo'].will == 'bee' }
        expect { @doc['bar'].will be(nil) }
        expect { @doc.rev.wont == @old_rev }
      end
    end
    
  end
  
end