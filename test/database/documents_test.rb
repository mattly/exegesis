require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class DatabaseDocumentsTest
  include Exegesis::Database
  
  document :settings do
    expose :things
  end
  document :no_block
end

describe Exegesis::Database::Documents do
  
  before do
    reset_db
    @db = DatabaseDocumentsTest.new('exegesis-test')
  end
  
  describe "with named documents" do
    describe "that doesn't exist yet" do
      before do
        @db.settings
      end
      
      expect { @db.settings.must_be_kind_of DatabaseDocumentsTest::Settings }
      expect { @db.settings.rev.must_match /1-\d{7,12}/ }
      expect { @db.settings.must_respond_to :things }
      expect { @db.get('settings').must_be_kind_of DatabaseDocumentsTest::Settings }
    end
    
    describe "that does exist" do
      before do
        @doc = @db.save({'_id' => 'settings', 'things' => %w(foo bar baz), 'class' => 'DatabaseDocumentsTest::Settings'})
      end
      
      expect { @db.settings.rev.must_equal @doc['_rev'] }
      expect { @db.settings.rev.must_match /1-\d{7,12}/ }
      expect { @db.settings.things.must_equal %w(foo bar baz) }
    end
    
    describe "when the declaration does not have a block" do
      expect { @db.no_block.must_be_kind_of DatabaseDocumentsTest::NoBlock }
    end
  end
  
end