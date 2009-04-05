require File.join(File.dirname(__FILE__), 'test_helper.rb')

class ExegesisServerTest < Test::Unit::TestCase

  before(:all) do
    @db = 'http://localhost:5984/exegesis-test'
    RestClient.delete @db rescue nil
    RestClient.delete "#{@db}-2" rescue nil
    RestClient.put @db, ''
    
    @server = Exegesis::Server.new('http://localhost:5984')
  end
  
  context "listing databases" do
    expect { @server.databases.include?('exegesis-test').will == true }
  end
  
  context "creating a database" do
    before do
      @response = @server.create_database('exegesis-test-2')
    end
    
    expect { @response['ok'].will == true }
  end
  
end