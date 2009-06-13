require 'pathname'
module Exegesis
  module Database
    autoload :Designs,    'exegesis/database/designs'
    autoload :Documents,  'exegesis/database/documents'
    autoload :Singleton,  'exegesis/database/singleton'
    autoload :Rest,       'exegesis/database/rest'
    
    VALID_NAME_PATTERN = '[-a-z0-9_\$\(\)\+\/]+'
    URI_PATTERN   = /\A(https?:\/\/[-0-9a-z\.]+(?::\d+))\/(#{Exegesis::Database::VALID_NAME_PATTERN})\Z/
    NAME_PATTERN  = /\A#{Exegesis::Database::VALID_NAME_PATTERN}\Z/
    
    def self.included base
      base.send :attr_accessor, :server, :uri
      base.send :include, InstanceMethods
      base.extend Exegesis::Database::Designs
      base.extend Exegesis::Database::Documents
    end
    
    module InstanceMethods
      include Exegesis::Database::Rest
      
      # Create a Database adapter for the given server and database name. Will raise 
      # RestClient::ResourceNotFound if the database does not exist.
      def initialize server, database_name=nil
        if database_name.nil?
          if server.match(URI_PATTERN)
            @server = Exegesis::Server.new($1)
            database_name = $2
          elsif server.match(NAME_PATTERN)
            @server = Exegesis::Server.new #localhost
            database_name = server
          else
            raise "Not a valid database url or name"
          end
        else
          @server = server
        end
        @uri = "#{@server.uri}/#{database_name}"
        @server.get @uri # raise RestClient::ResourceNotFound if the database does not exist
      end
      
      def to_s
        "#<#{self.class.name}(Exegesis::Database):#{self.object_id} uri=#{uri}>"
      end
      alias :inspect :to_s
      
    end
  end
end