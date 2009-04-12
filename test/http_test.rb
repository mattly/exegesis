require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'restclient'
require 'json'

class HttpTest < Test::Unit::TestCase
  
  context "url formatting" do
    context "with no params" do
      before do
        @url = "/some_url"
        @action = lambda {|params| Exegesis::Http.format_url(@url, params) }
      end
      
      expect { @action.call(nil).will == "/some_url" }
      expect { @action.call({}).will == "/some_url" }
    end
    
    context "with normal params" do
      before do
        @url = "/some_url"
        @params = {
          :one => 1,
          :two => 2
        }
        @expected = ["/some_url?one=1&two=2", "/some_url?two=2&one=1"]
      end
      
      expect { @expected.will include(Exegesis::Http.format_url(@url, @params)) }
    end
  end
  
  context "making requests" do
    before(:all) do
      @db = 'http://localhost:5984/exegesis-test'
      RestClient.delete(@db) rescue nil
      RestClient.put(@db, '')
    end
    
    after(:all) do
      RestClient.delete(@db) rescue nil
    end
    
    context "get requests" do
      before do
        @response = Exegesis::Http.get(@db)
      end
      
      expect { @response['db_name'].will == 'exegesis-test' }
    end
    
    context "post requests" do
      before do
        @response = Exegesis::Http.post(@db, {'test' => 'value'}.to_json)
      end
      
      expect { @response['ok'].will == true }
    end
    
    context "put requests" do
      before do
        @response = Exegesis::Http.put("#{@db}/test-document", {'test' => 'value'}.to_json)
      end
      
      expect { @response['ok'].will == true }

      after { RestClient.delete("#{@db}/test-document?rev=#{@response['rev']}") }
    end
    
    context "delete requests" do
      before do
        @doc = JSON.parse RestClient.put("#{@db}/test-document", {'test' => 'value'}.to_json)
        @response = RestClient.delete("#{@db}/test-document?rev=#{@doc['rev']}")
      end
      
      expect { @response['ok'].will == 'ok' }
    end
  end
  
end