require 'time'
require 'pathname'

require 'couchrest'
require 'active_support/inflector'

$:.unshift File.dirname(__FILE__)
require 'exegesis/document'
require 'exegesis/design'

module Exegesis
  
  def self.set_designs_directory dir
    @designs_directory = Pathname.new(dir)
  end
  
  def self.designs_directory= dir
    @designs_directory = Pathname.new(dir)
  end
  
  def self.designs_directory
    @designs_directory ||= Pathname.new(ENV["PWD"])
    @designs_directory.to_s
  end
  
  def self.design_file name
    File.read(designs_directory + name)
  end
  
  def self.database_template= template
    @db_template = template
  end
  
  def self.database_template
    @db_template ||= "http://localhost:5984/%s"
  end
  
  def self.database_for name
    database_template % name
  end
  
end