require 'cgi'
module Exegesis
  module Http
    extend self
    
    def format_url url, params={}
      if params && !params.empty?
        query = params.map do |key, value|
          value = value.to_json if [:key, :startkey, :endkey, :keys].include?(key)
          "#{key}=#{CGI.escape(value.to_s)}"
        end.join('&')
        url = "#{url}?#{query}"
      end
      url
    end
    
    def escape_id id
      /^_design\/(.*)/ =~ id ? "_design/#{CGI.escape($1)}" : CGI.escape(id) 
    end
    
    def get url
      JSON.parse(RestClient.get(url), :max_nesting => false)
    end
    
    def post url, body=''
      JSON.parse(RestClient.post(url, (body || '').to_json))
    end
    
    def put url, body=''
      JSON.parse(RestClient.put(url, (body || '').to_json))
    end
    
    def delete url
      JSON.parse(RestClient.delete(url))
    end
    
  end
end