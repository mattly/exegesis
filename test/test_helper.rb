require 'rubygems'
require 'test/unit'

require 'rr'
require 'context'
require 'matchy'
require 'zebra'

require 'ruby-debug'
Debugger.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/exegesis'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  
  def fixtures_path fixtures
    File.join(File.dirname(__FILE__), 'fixtures', fixtures)
  end
  
  # todo: extract to some helper methods to include ala RR, etc
  def reset_db(name=nil)
    @db = CouchRest.database db(name) rescue nil
    @db.delete! rescue nil
    @db = CouchRest.database! db(name)
  end
  
  def teardown_db
    @db.delete! rescue nil
  end
  
  def db(name)
    "http://localhost:5984/exegesis-test#{name.nil? ? '' : "-#{name}"}"
  end
  
  # def with_couch(%blk)
  #   test_db_name = method_name.downcase.gsub(/[^-$\w]/,'$$')
  #   
  # end
end