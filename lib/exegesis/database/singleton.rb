module Exegesis
  module Database
    module Singleton
      
      include Exegesis::Database::InstanceMethods
      include Exegesis::Database::Designs
      include Exegesis::Database::Documents
      
      def uri(addr=nil)
        if addr
          if addr.match(Exegesis::Database::URI_PATTERN)
            @server   = Exegesis::Server.new($1)
            @uri      = "#{@server.uri}/#{$2}"
          elsif addr.match(Exegesis::Database::NAME_PATTERN)
            @server   = Exegesis::Server.new
            @uri      = "#{@server.uri}/#{addr}"
          else
            raise ArgumentError, "does not match a valid database name/uri pattern"
          end
          begin
            @server.get @uri
          rescue RestClient::ResourceNotFound
            @server.put @uri
          end
        else
          @uri
        end
      end
    
      def server
        @server
      end
    end
  end
end
