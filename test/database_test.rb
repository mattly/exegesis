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

describe Exegesis::Database do
  before do
    @server = Exegesis::Server.new('http://localhost:5984')
    RestClient.delete("#{@server.uri}/exegesis-test") rescue nil
    RestClient.delete("#{@server.uri}/exegesis-test-nonexistent") rescue nil
    RestClient.put("#{@server.uri}/exegesis-test", '')
  end
  
  describe "initializing" do
    describe "with server and name arguments" do
      before do
        @db = DatabaseTest.new(@server, 'exegesis-test')
      end

      expect { @db.must_be_kind_of DatabaseTest }
      expect { @db.uri.must_equal "#{@server.uri}/exegesis-test"}

      describe "when the database does not exist" do
        before do
          @action = lambda { DatabaseTest.new(@server, 'exegesis-test-nonexistent') }
        end
      
        expect { @action.must_raise(RestClient::ResourceNotFound) }
      end
    end
    
    describe "with a url argument" do
      before do
        @db = DatabaseTest.new('http://localhost:5984/exegesis-test')
      end
      
      expect { @db.must_be_kind_of DatabaseTest }
      expect { @db.uri.must_equal 'http://localhost:5984/exegesis-test' }
    end
    
    describe "with a name argument" do
      before do
        @db = DatabaseTest.new('exegesis-test')
      end
      
      expect { @db.must_be_kind_of DatabaseTest }
      expect { @db.uri.must_equal "http://localhost:5984/exegesis-test" }
    end
  end
  
  describe "retrieving documents by id" do
    before do
      @db = DatabaseTest.new @server, 'exegesis-test'
      RestClient.put "#{@db.uri}/test-document", {'key'=>'value', 'class'=>'DatabaseTestDocument'}.to_json rescue nil
      @doc = @db.get('test-document')
    end
    
    after do
      RestClient.delete("#{@db.uri}/test-document?rev=#{@doc['_rev']}") rescue nil
    end
    
    expect { @doc.must_be_kind_of DatabaseTestDocument }
    expect { @doc.id.must_equal 'test-document' }
    expect { @doc['key'].must_equal 'value' }
    
    describe "retrieving the raw document" do
      before do
        @doc = @db.raw_get('test-document')
      end
      
      expect { @doc.must_be_kind_of Hash }
      expect { @doc['_id'].must_equal 'test-document' }
      expect { @doc['key'].must_equal 'value' }
      expect { @doc['class'].must_equal 'DatabaseTestDocument' }
    end
    
    describe "retrieving multiple documents" do
      before do
        docs = [{"_id"=>"a"},{"_id"=>"b"},{"_id"=>"c"}].map{|d| d.update('class' => 'DatabaseTestDocument')}
        RestClient.post("#{@db.uri}/_bulk_docs", {"docs"=>docs}.to_json)
      end
      
      expect { @db.get(%w(a b c)).size.must_equal 3 }
      expect { @db.get(%w(a b c)).each{|doc| doc.must_be_kind_of DatabaseTestDocument} }
    end
  end
  
  describe "saving docs" do
    before do
      reset_db
      @db = DatabaseTest.new('exegesis-test')
    end
    
    describe "a single doc" do
      before { @doc = {'foo' => 'bar'} }

      describe "without an id" do
        before do
          @db.save(@doc)
          @rdoc = @db.get(@doc['_id'])
        end
        expect { @doc['_rev'].must_equal @rdoc['_rev'] }
        expect { @rdoc['foo'].must_equal @doc['foo'] }
      end
      
      describe "with an id" do
        before { @doc['_id'] = 'test-document' }
        
        describe "when the document doesn't exist yet" do
          before do
            @db.save(@doc)
            @rdoc = @db.get('test-document')
          end
          expect { @doc['_rev'].must_equal @rdoc['_rev'] }
          expect { @rdoc['foo'].must_equal @doc['foo'] }
        end
        
        describe "when the document exists already" do
          before do 
            response = @db.post(@doc)
            @doc['_id'] = response['id']
            @doc['_rev'] = response['rev']
            @doc['foo'] = 'bee'
          end

          expect { @db.save(@doc)['_rev'].must_match /2-\d+/ }
          
          describe "without a valid rev" do
            before { @doc.delete('_rev') }
            expect { lambda{ @db.save(@doc) }.must_raise RestClient::RequestFailed }
          end
        end
        
      end
    end
    
    describe "multiple docs" do
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
        
      describe "without conflicts" do
        before { @saving.call }
        expect { @db.get('new')['key'].must_equal 'new' }
        expect { @db.get('updated')['key'].must_equal 'new' }
        expect { lambda {@db.get('deleted')}.must_raise RestClient::ResourceNotFound }
      end
    end
  end
  
  describe "setting the designs directory" do
    expect { DatabaseTest.designs_directory.must_equal Pathname.new('designs') }
    expect { CustomDesignDirDatabaseTest.designs_directory.must_equal Pathname.new('app/designs') }
  end
  
end
