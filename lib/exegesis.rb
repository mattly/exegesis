require 'time'
require 'pathname'

require 'couchrest'

$:.unshift File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Exegesis
  autoload :Document,   'exegesis/document'
  autoload :Design,     'exegesis/design'
  
  extend self
  
  def designs_directory= dir
    @designs_directory = Pathname.new(dir)
  end
  
  def designs_directory
    @designs_directory ||= Pathname.new(ENV["PWD"])
    @designs_directory
  end
  
  def design_file name
    File.read(designs_directory + name)
  end
  
  def database_template= template
    @db_template = template
  end
  
  def database_template
    @db_template ||= "http://localhost:5984/%s"
  end
  
  def database_for name
    database_template % name
  end
  
  def document_classes
    @document_classes ||= Hash.new(Exegesis::Document)
  end
  
end