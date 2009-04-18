require 'rubygems'
require 'minitest/spec'
MiniTest::Unit.autorun

unless RUBY_VERSION =~ /^1\.9/
  begin
    require 'ruby-debug'
    Debugger.start
  rescue
    puts "protip: `(sudo) gem install ruby-debug` for superhuman debugging powers"
  end
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/exegesis'

class TestingDatabase
  include Exegesis::Database
end

class MiniTest::Spec
  # beacuse test names are really just comments, and therefore a code smell
  def self.expect(desc=nil, &block)
    @counter ||= 0; @counter += 1
    desc ||= "[#{@counter}]"
    name = ["test_", description_stack.join(' '), desc].join(' ')
    define_method name, &block
  end
end

class MiniTest::Unit::TestCase
  
  def fixtures_path fixtures
    File.join(File.dirname(__FILE__), 'fixtures', fixtures)
  end
  
  def db_server
    @db_server ||= Exegesis::Server.new('http://localhost:5984')
  end
  
  # todo: extract to some helper methods to include ala RR, etc
  def reset_db(name=nil, klass=TestingDatabase)
    RestClient.delete "http://localhost:5984/#{db(name)}" rescue nil
    db_server.create_database(db(name))
    @db = klass.new(db_server, db(name))
  end
  
  def db(name)
    "exegesis-test#{name.nil? ? '' : "-#{name}"}"
  end
  
end