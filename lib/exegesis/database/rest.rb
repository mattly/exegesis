module Exegesis
  module Database
    module Rest
      # performs a raw GET request against the database
      def raw_get(id, options={})
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
      def get(id, opts={})
        if id.kind_of?(Array)
          collection = opts.delete(:collection) # nil or true for yes, false for no
          r = post '_all_docs?include_docs=true', {"keys"=>id}
          r['rows'].map {|d| Exegesis.instantiate d['doc'], self }
        else
          Exegesis.instantiate raw_get(id), self
        end
      end
      
      # saves a document or collection thereof
      def save(docs)
        if docs.is_a?(Array)
          post "_bulk_docs", { 'docs' => docs }
        else
          result = docs['_id'] ? put(docs['_id'], docs) : post(docs)
          if result['ok']
            docs['_id'] = result['id']
            docs['_rev'] = result['rev']
          end
          docs
        end
      end
      
      # PUTs the body to the given id in the database
      def put(id, body, headers={})
        Exegesis::Http.put "#{@uri}/#{id}", (body || '').to_json, headers
      end
      
      # POSTs the body to the database
      def post(url, body={}, headers={})
        if body.is_a?(Hash) && body.empty?
          body = url
          url = ''
        end
        Exegesis::Http.post "#{@uri}/#{url}", (body || '').to_json, headers
      end
      
      # DELETE the doc from the database. requires a hash with _id and _rev keys
      def delete(doc={})
        raise ArgumentError, "doc must have both '_id' and '_rev' keys" unless doc['_id'] && doc['_rev']
        Exegesis::Http.delete "#{@uri}/#{doc['_id']}?rev=#{doc['_rev']}"
      end
    end
  end
end