module Exegesis
  module Document
    class Attachment
      
      attr_reader :name, :metadata, :document
      
      def initialize(name, thing, doc)
        @document = doc
        @metadata = thing
        @name = name
      end
      
      def content_type
        @metadata['content_type']
      end
      
      def length
        @metadata['length'] || -1
      end
      
      def stub?
        @metadata['stub'] || false
      end
      
      def file
        RestClient.get("#{document.database.uri}/#{document.id}/#{name}")
      end
      
      def to_json
        if @metadata['data']
          {'content_type' => @metadata['content_type'], 'data' => @metadata['data']}.to_json
        else
          @metadata.to_json
        end
      end
      
      def inspect
        "Attachment:#{@metadata.inspect}"
      end
      
    end
  end
end