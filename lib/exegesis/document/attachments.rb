require 'base64'
module Exegesis
  module Document
    class Attachments < Hash
      
      attr_accessor :document
      
      def initialize doc
        @document = doc
        if @document['_attachments']
          @document['_attachments'].each do |name,meta| 
            update(name => Exegesis::Document::Attachment.new(name, meta, document))
          end
        end
      end
      
      def dirty?
        @dirty || false
      end
      
      def clean!
        each do |name, attachment|
          next if attachment.stub?
          attachment.metadata['stub'] = true
          attachment.metadata.delete('data')
        end
        @dirty = false
      end
      
      # saves the attachment to the database NOW. does not keep the attachment in memory once this is done.
      def put(name, contents, type)
        r = Exegesis::Http.put("#{document.uri}/#{name}?rev=#{document.rev}", contents, {:content_type => type})
        if r['ok']
          document['_rev'] = r['rev']
          update(name => Exegesis::Document::Attachment.new(name, {'content_type' => type, 'stub' => true, 'length' => contents.length}, document))
        end
      end

      def []= name, contents_and_type
        @dirty = true
        content = contents_and_type.shift
        meta = {'data' => Base64.encode64(content).gsub(/\s/,''), 'content_type' => contents_and_type.first, 'length' => content.length}
        update(name => Exegesis::Document::Attachment.new(name, meta, document))
      end
    end
    
  end
end