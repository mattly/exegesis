module Exegesis
  class DocumentCollection
    
    attr_reader :rows, :parent, :index
    
    def initialize docs=[], master=nil, index=0
      @rows = docs
      if master.is_a?(Exegesis::DocumentCollection)
        @parent = master
      else
        @database = master
      end
      @index = index
    end
    
    def database
      @database || @parent.database
    end
    
    def size
      @rows.length
    end
    
    def keys
      @keys ||= rows.map {|r| r['key'] }.uniq
    end
    
    def values
      @values ||= rows.map {|r| r['value'] }
    end
    
    def documents
      @documents ||= load_documents
    end
    
    def [] key
      @keymaps ||= {}
      filtered_rows = rows.select do |row|
        if row['key'].is_a?(Array)
          row['key'][index] == key
        else
          row['key'] == key
        end
      end
      new_index = index + 1
      @keymaps[key] ||= self.class.new(filtered_rows, self, new_index)
    end
    
    def each &block
      rows.each do |row|
        yield row['key'], row['value'], documents[row['id']]
      end
    end
    
    private
    def load_documents
      docmap = {}
      if parent.nil?
        non_doc_rows = rows.select {|r| ! r.has_key?('doc') }
        if non_doc_rows.empty?
          rows.map {|r| docmap[r['id']] = Exegesis.instantiate(r['doc'], database) }
        else
          database.get(non_doc_rows.map{|r| r['id']}.uniq, :include_docs=>true).each {|doc| docmap[doc.id] = doc}
        end
      else
        rows.map {|r| docmap[r['id']] = parent.documents[r['id']] }
      end
      docmap
    end
    
  end
end