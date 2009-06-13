module Exegesis
  module Database
    module Documents
      
      # creates a one-off document
      def document document_name, opts={}, &block
        klass_name = document_name.to_s.capitalize.gsub(/_(\w)/) { $1.capitalize }
        klass = const_set(klass_name, Class.new(Exegesis::GenericDocument))
        klass.unique_id { document_name.to_s }
        klass.class_eval &block if block_given?
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
  end
end