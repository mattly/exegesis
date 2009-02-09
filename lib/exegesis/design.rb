$:.unshift File.dirname(__FILE__)
require 'design/syncronization'

module Exegesis
  class Design
    
    def self.designs_directory= dir
      @designs_directory = Pathname.new(dir)
    end

    def self.designs_directory
      @designs_directory ||= Pathname.new(ENV["PWD"])
      @designs_directory
    end

    def self.design_file name
      File.read(designs_directory + name)
    end
    
    include Exegesis::Design::Syncronization
    
    attr_accessor :database
    
    def initialize(db)
      @database = db
    end
    
    def self.design_doc
      ActiveSupport::Inflector.pluralize(name.to_s.sub(/(Design)$/,'').downcase)
    end
    
    def design_doc
      self.class.design_doc
    end
    
    def get(id)
      doc = Exegesis::Document.instantiate database.get(id)
      doc.database = self.database
      doc
    end
    
    def parse_opts(opts={})
      if opts[:key]
        case opts[:key]
        when Range
          range = opts.delete(:key)
          opts.update({:startkey => range.first, :endkey => range.last})
        when Array
          if opts[:key].any?{|v| v.kind_of?(Range) }
            key = opts.delete(:key)
            opts[:startkey] = key.map {|v| v.kind_of?(Range) ? v.first : v }
            opts[:endkey]   = key.map {|v| v.kind_of?(Range) ? v.last : v }
          end
        end
      end

      opts
    end
    
    def view view_name, opts={}
      opts = parse_opts opts
      database.view "#{design_doc}/#{view_name}", opts
    end
    
    def docs_for view_name, opts={}
      response = view view_name, opts.update({:include_docs => true})
      response['rows'].map {|doc| Exegesis::Document.instantiate doc['doc'] }
    end
    
    def values_for view_name, opts={}
      response = view view_name, opts
      response['rows'].map {|row| row['value'] }
    end
    
    def keys_for view_name, opts={}
      response = view view_name, opts
      response['rows'].map {|row| row['key'] }
    end
    
    def ids_for view_name, opts={}
      response = view view_name, opts
      response['rows'].map {|row| row['id'] }
    end
    
  end
end