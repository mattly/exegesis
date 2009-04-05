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

class TestingDatabase
  include Exegesis::Database
end

class Test::Unit::TestCase
  
  def fixtures_path fixtures
    File.join(File.dirname(__FILE__), 'fixtures', fixtures)
  end
  
  def db_server
    @db_server ||= Exegesis::Server.new('http://localhost:5984')
  end
  
  # todo: extract to some helper methods to include ala RR, etc
  def reset_db(name=nil)
    RestClient.delete "http://localhost:5984/#{db(name)}" rescue nil
    db_server.create_database(db(name))
    @db = TestingDatabase.new(db_server, db(name))
  end
  
  def db(name)
    "exegesis-test#{name.nil? ? '' : "-#{name}"}"
  end
  
end