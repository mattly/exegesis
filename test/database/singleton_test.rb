require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

Exegesis::Http.delete("#{@server.uri}/exegesis-singleton-test") rescue nil

module SingletonDbTest
  extend self
  
  COUCH = 'http://localhost:5984'
  DB    = 'exegesis-singleton-test'
  URI   = "#{COUCH}/#{DB}"
  
  extend Exegesis::Database::Singleton
  uri DB
  
  design :design_doc
  document :named_doc
end

describe Exegesis::Database::Singleton do
  
  describe "database setup" do
    expect { SingletonDbTest.uri.must_equal SingletonDbTest::URI }
    expect { Exegesis::Http.get(SingletonDbTest::URI)["db_name"].must_equal SingletonDbTest::DB }
    expect { lambda{SingletonDbTest.uri('foo.db')}.must_raise ArgumentError }
  end
  
  describe "database REST methods" do
    before do
      Exegesis::Http.delete(SingletonDbTest::URI) rescue nil
      Exegesis::Http.put(SingletonDbTest::URI)
      @test_doc = {"_id" => "test", "foo" => "bar"}
      response = Exegesis::Http.put("#{SingletonDbTest::URI}/test", @test_doc.to_json)
      @test_doc['_rev'] = response['rev']
    end
    expect { SingletonDbTest.get("test")['foo'].must_equal @test_doc['foo'] }
    expect { SingletonDbTest.post({"foo" => "bar"})["id"].must_match /[0-9a-f]{32}/ }
    expect { SingletonDbTest.put("foo", {"_id" => "foo"})["id"].must_equal "foo" }
    expect { SingletonDbTest.delete(@test_doc)["ok"].must_equal true }
  end
  
  describe "database class methods" do
    expect { SingletonDbTest.design_doc.must_be_kind_of Exegesis::Design }
    expect { SingletonDbTest.named_doc.must_be_kind_of Exegesis::GenericDocument }
  end
end