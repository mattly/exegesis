require File.join(File.dirname(__FILE__), 'test_helper.rb')

class DatabaseTest
  include Exegesis::Database
end
class CustomDesignDirDatabaseTest
  include Exegesis::Database
  designs_directory 'app/designs'
end
class DatabaseTestDocument
  include Exegesis::Document
end

class ExegesisDatabaseTest < Test::Unit::TestCase
  before(:all) do
    @server = Exegesis::Server.new('http://localhost:5984')
    RestClient.delete("#{@server.uri}/exegesis-test") rescue nil
    RestClient.delete("#{@server.uri}/exegesis-test-nonexistent") rescue nil
    RestClient.put("#{@server.uri}/exegesis-test", '')
  end
  
  context "initializing" do
    context "with server and name arguments" do
      before do
        @db =DatabaseTest.new(@server, 'exegesis-test')
      end

      expect { @db.is_a?(DatabaseTest).will == true }
      expect { @db.uri.will == "#{@server.uri}/exegesis-test"}

      context "when the database does not exist" do
        before do
          @action = lambda { DatabaseTest.new(@server, 'exegesis-test-nonexistent') }
        end
      
        expect { @action.will raise_error(RestClient::ResourceNotFound) }
      end
    end
    
    context "with a url argument" do
      before do
        @db = DatabaseTest.new('http://localhost:5984/exegesis-test')
      end
      
      expect { @db.is_a?(DatabaseTest).will == true }
      expect { @db.uri.will == 'http://localhost:5984/exegesis-test' }
    end
    
    context "with a name argument" do
      before do
        @db = DatabaseTest.new('exegesis-test')
      end
      
      expect { @db.is_a?(DatabaseTest).will == true }
      expect { @db.uri.will == "http://localhost:5984/exegesis-test" }
    end
  end
  
  context "retrieving documents by id" do
    before do
      @db = DatabaseTest.new @server, 'exegesis-test'
      RestClient.put "#{@db.uri}/test-document", {'key'=>'value', 'class'=>'DatabaseTestDocument'}.to_json rescue nil
      @doc = @db.get('test-document')
    end
    
    after do
      RestClient.delete("#{@db.uri}/test-document?rev=#{@doc['_rev']}") rescue nil
    end
    
    expect { @doc.is_a?(DatabaseTestDocument).will == true }
    expect { @doc.id.will == 'test-document' }
    expect { @doc['key'].will == 'value' }
    
    context "retrieving the raw document" do
      before do
        @doc = @db.raw_get('test-document')
      end
      
      expect { @doc.is_a?(Hash).will == true }
      expect { @doc['_id'].will == 'test-document' }
      expect { @doc['key'].will == 'value' }
      expect { @doc['class'].will == 'DatabaseTestDocument' }
    end
  end
  
  context "saving docs" do
    before do
      reset_db
      @db = DatabaseTest.new('exegesis-test')
    end
    
    context "a single doc" do
      before { @doc = {'foo' => 'bar'} }

      context "without an id" do
        before do
          @db.save(@doc)
          @rdoc = @db.get(@doc['_id'])
        end
        expect { @doc['_rev'].will == @rdoc['_rev'] }
        expect { @rdoc['foo'].will == @doc['foo'] }
      end
      
      context "with an id" do
        before { @doc['_id'] = 'test-document' }
        
        context "when the document doesn't exist yet" do
          before do
            @db.save(@doc)
            @rdoc = @db.get('test-document')
          end
          expect { @doc['_rev'].will == @rdoc['_rev'] }
          expect { @rdoc['foo'].will == @doc['foo'] }
        end
        
        context "when the document exists already" do
          before do 
            response = @db.post(@doc)
            @doc['_id'] = response['id']
            @doc['_rev'] = response['rev']
            @doc['foo'] = 'bee'
          end

          expect { lambda { @db.save(@doc) }.wont raise_error }
          
          context "without a valid rev" do
            before { @doc.delete('_rev') }
            expect { lambda { @db.save(@doc) }.will raise_error }
          end
        end
      end
    end
    
    context "multiple docs" do
      before do
        @updated = @db.post({'_id' => 'updated', 'key' => 'original'})
        @deleted = @db.post({'_id' => 'deleted', 'key' => 'original'})
        @saving = lambda {
          @db.save([
            {'_id' => 'new', 'key' => 'new'},
            {'_id' => 'updated', 'key' => 'new', '_rev' => @updated['rev']},
            {'_id' => 'deleted', '_rev' => @deleted['rev'], '_deleted' => true }
          ])
        }
      end
        
      context "without conflicts" do
        before { @saving.call }
        expect { @db.get('new')['key'].will == 'new' }
        expect { @db.get('updated')['key'].will == 'new' }
        expect { lambda {@db.get('deleted')}.will raise_error(RestClient::ResourceNotFound) }
      end
    end
  end
  
  context "setting the designs directory" do
    expect { DatabaseTest.designs_directory.will == Pathname.new('designs') }
    expect { CustomDesignDirDatabaseTest.designs_directory.will == Pathname.new('app/designs') }
  end
  
end