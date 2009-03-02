require 'rubygems'
require 'test/unit'

require 'context'   # with github: gem install jeremymcanally-context
require 'matchy'    # best bet for now: clone from github and build yourself; when jeremy fixes matchy, jeremymcanally-matchy
require 'zebra'     # until jeremy updates matchy, download and build yourself, after that, with github: gem install giraffesoft-zebra

begin
  require 'ruby-debug'
  Debugger.start
rescue
  puts "no ruby-debug installed? REAlLY? ok, if that's how you roll..."
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/exegesis'

class Test::Unit::TestCase
  
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
  
end