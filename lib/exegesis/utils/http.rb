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
    
    def get url, headers={}
      JSON.parse(RestClient.get(url, headers), :max_nesting => false)
    end
    
    def post url, body='', headers={}
      JSON.parse(RestClient.post(url, body, headers))
    end
    
    def put url, body='', headers={}
      JSON.parse(RestClient.put(url, body, headers))
    end
    
    def delete url, headers={}
      JSON.parse(RestClient.delete(url, headers))
    end
    
  end
end