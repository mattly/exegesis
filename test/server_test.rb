require File.join(File.dirname(__FILE__), 'test_helper.rb')

describe Exegesis::Server do

  before do
    @db = 'http://localhost:5984/exegesis-test'
    RestClient.delete @db rescue nil
    RestClient.delete "#{@db}-2" rescue nil
    RestClient.put @db, ''
    
    @server = Exegesis::Server.new('http://localhost:5984')
  end
  
  describe "listing databases" do
    expect { @server.databases.must_include('exegesis-test') }
  end
  
  describe "creating a database" do
    before do
      @response = @server.create_database('exegesis-test-2')
    end
    
    expect { assert @response['ok'] }
  end
  
end