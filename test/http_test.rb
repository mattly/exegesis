require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'restclient'
require 'json'

describe Exegesis::Http do
  
  describe "url formatting" do
    describe "with no params" do
      before do
        @url = "/some_url"
        @action = lambda {|params| Exegesis::Http.format_url(@url, params) }
      end
      
      expect { @action.call(nil).must_equal "/some_url" }
      expect { @action.call({}).must_equal "/some_url" }
    end
    
    describe "with normal params" do
      before do
        @url = "/some_url"
        @params = {
          :one => 1,
          :two => 2
        }
        @expected = ["/some_url?one=1&two=2", "/some_url?two=2&one=1"]
      end
      
      expect { @expected.must_include Exegesis::Http.format_url(@url, @params) }
    end
  end
  
  describe "making requests" do
    before do
      @db = 'http://localhost:5984/exegesis-test'
      RestClient.delete(@db) rescue nil
      RestClient.put(@db, '')
    end
    
    after do
      RestClient.delete(@db) rescue nil
    end
    
    describe "get requests" do
      before do
        @response = Exegesis::Http.get(@db)
      end
      
      expect { @response['db_name'].must_equal 'exegesis-test' }
    end
    
    describe "post requests" do
      before do
        @response = Exegesis::Http.post(@db, {'test' => 'value'}.to_json)
      end
      
      expect { @response['ok'].must_equal true }
    end
    
    describe "put requests" do
      before do
        @response = Exegesis::Http.put("#{@db}/test-document", {'test' => 'value'}.to_json)
      end
      
      expect { @response['ok'].must_equal true }
    end
    
    describe "delete requests" do
      before do
        @doc = JSON.parse RestClient.put("#{@db}/test-document", {'test' => 'value'}.to_json)
        @response = RestClient.delete("#{@db}/test-document?rev=#{@doc['rev']}")
      end
      
      expect { @response['ok'].must_equal 'ok' }
    end
  end
  
end