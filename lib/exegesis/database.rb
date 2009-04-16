require 'pathname'
module Exegesis
  module Database
    
    VALID_NAME_PATTERN = '[-a-z0-9_\$\(\)\+\/]+'
    
    def self.included base
      base.send :attr_accessor, :server, :uri
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end
    
    module ClassMethods
      def designs_directory dir=nil
        if dir
          @designs_directory = Pathname.new(dir)
        else
          @designs_directory ||= Pathname.new('designs')
        end
      end
      
      # declare a design document for this database. Creates a new class and yields a given block to the class to
      # configure the design document and declare views; See Class methods for Exegesis::Design
      def design design_name, opts={}, &block
        klass_name = "#{design_name.to_s.capitalize}Design"
        klass = const_set(klass_name, Class.new(Exegesis::Design))
        klass.design_directory = opts[:directory] || self.designs_directory + design_name.to_s
        klass.design_name = opts[:name] || design_name.to_s
        klass.compose_canonical
        klass.class_eval &block
        define_method design_name do
          @exegesis_designs ||= {}
          @exegesis_designs[design_name] ||= klass.new(self)
        end
      end
      
      def named_document document_name, opts={}, &block
        klass_name = document_name.to_s.capitalize.gsub(/_(\w)/) { $1.capitalize }
        klass = const_set(klass_name, Class.new(Exegesis::GenericDocument))
        klass.unique_id { document_name.to_s }
        klass.class_eval &block if block
        define_method document_name do
          @exegesis_named_documents ||= {}
          @exegesis_named_documents[document_name] ||= begin
            get(document_name.to_s)
          rescue RestClient::ResourceNotFound
            doc = klass.new({}, self)
            doc.save
            doc
          end
        end
      end
    end
    
    module InstanceMethods
      # Create a Database adapter for the given server and database name. Will raise 
      # RestClient::ResourceNotFound if the database does not exist.
      def initialize server, database_name=nil
        if database_name.nil?
          if server.match(/\A(https?:\/\/[-0-9a-z\.]+(?::\d+))\/(#{Exegesis::Database::VALID_NAME_PATTERN})\Z/)
            @server = Exegesis::Server.new($1)
            database_name = $2
          elsif server.match(/\A#{Exegesis::Database::VALID_NAME_PATTERN}\Z/)
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
      
      # performs a raw GET request against the database
      def raw_get id, options={}
        keys = options.delete(:keys)
        id = Exegesis::Http.escape_id id
        url = Exegesis::Http.format_url "#{@uri}/#{id}", options
        if id.match(%r{^_design/.*/_view/.*$}) && keys
          Exegesis::Http.post url, {:keys => keys}.to_json
        else
          Exegesis::Http.get url
        end
      end
      
      # GETs a document with the given id from the database
      def get id, opts={}
        if id.kind_of?(Array)
          collection = opts.delete(:collection) # nil or true for yes, false for no
          r = post '_all_docs?include_docs=true', {"keys"=>id}
          r['rows'].map {|d| Exegesis.instantiate d['doc'], self }
        else
          Exegesis.instantiate raw_get(id), self
        end
      end
      
      # saves a document or collection thereof
      def save docs
        if docs.is_a?(Array)
          post "_bulk_docs", { 'docs' => docs }
        else
          result = docs['_id'].nil? ? post(docs) : put(docs['_id'], docs)
          if result['ok']
            docs['_id'] = result['id']
            docs['_rev'] = result['rev']
          end
          docs
        end
      end
      
      # PUTs the body to the given id in the database
      def put id, body, headers={}
        Exegesis::Http.put "#{@uri}/#{id}", (body || '').to_json, headers
      end
      
      # POSTs the body to the database
      def post url, body={}, headers={}
        if body.is_a?(Hash) && body.empty?
          body = url
          url = ''
        end
        Exegesis::Http.post "#{@uri}/#{url}", (body || '').to_json, headers
      end
    end
  end
end