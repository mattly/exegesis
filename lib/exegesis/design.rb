require 'pathname'
module Exegesis
  class Design
    include Exegesis::Document
    
    def self.design_directory= dir
      @design_directory = Pathname.new(dir)
    end
    
    def self.design_directory
      @design_directory ||= Pathname.new("designs/#{design_name}")
    end
    
    def self.design_name= n
      @design_name = n.to_s
    end
    
    def self.design_name
      @design_name ||= name.scan(/^(?:[A-Za-z0-9\:]+::)([A-Za-z0-9]+)Design$/).first.first.downcase
    end
    
    def self.compose_canonical
      Dir[design_directory + 'views' + '**/*.js'].each do |view_func|
        path = view_func.split('/')
        func = path.pop.sub(/\.js$/,'')
        name = path.pop
        canonical_design['views'][name] ||= {}
        canonical_design['views'][name][func] = File.read(view_func)
      end
    end
    
    def self.canonical_design
      @canonical_design ||= {
        '_id' => "_design/#{design_name}",
        'views' => {}
      }
    end
    
    def self.view name, default_options={}
      define_method name do |key, *opts|
        view name, key, opts.first, default_options
      end
    end
    
    def self.docs name, default_options={}
      default_options = {:include_docs => true, :reduce => false}.merge(default_options)
      define_method name do |*opts|
        key = opts.shift
        options = parse_opts key, opts.first, default_options
        response = call_view name, options
        ids = []
        response.inject([]) do |memo, doc|
          unless ids.include?(doc['id'])
            ids << doc['id']
            memo << Exegesis.instantiate(doc['doc'], database)
          end
          memo
        end
      end
    end
    
    def self.hash name, default_options={}
      default_options = {:group => true}.merge(default_options)
      view_name = default_options.delete(:view) || name
      define_method name do |*opts|
        key = opts.shift
        options = parse_opts key, opts.first, default_options
        options.delete(:group) if options[:key]
        
        response = call_view view_name, options
        if response.size == 1 && response.first['key'].nil?
          response.first['value']
        else
          response.inject({}) do |memo, row|
            if ! memo.has_key?(row['key'])
              memo[row['key']] = row['value']
            end
            memo
          end
        end
      end
    end
    
    
    def initialize db
      begin
        super db.get("_design/#{design_name}"), db
      rescue RestClient::ResourceNotFound
        db.put("_design/#{design_name}", self.class.canonical_design)
        retry
      end
      unless self['views'] == self.class.canonical_design['views']
        self['views'].update(self.class.canonical_design['views'])
        save
      end
    end
    
    def view name, key=nil, opts={}
      call_view name, parse_opts(key, opts)
    end
    
    def call_view name, opts={}
      url = "_design/#{design_name}/_view/#{name}"
      database.raw_get(url, opts)['rows']
    end
    
    def design_name
      self.class.design_name
    end
    
    def parse_opts key, opts={}, defaults={}
      opts = straighten_args key, opts, defaults
      parse_key opts
      parse_keys opts
      parse_range opts
      opts
    end
    
    private
    
    def straighten_args key, opts, defaults
      opts ||= {}
      if key.is_a?(Hash)
        opts = key
      elsif ! key.nil?
        opts[:key] = key
      end
      defaults.merge(opts)
    end
    
    def parse_key opts
      if opts[:key]
        if opts[:key].is_a?(Range)
          range = opts.delete(:key)
          opts.update({:startkey => range.first, :endkey => range.last})
        elsif opts[:key].is_a?(Array) && opts[:key].any?{|v| v.kind_of?(Range) }
          key = opts.delete(:key)
          opts[:startkey] = key.map {|v| v.kind_of?(Range) ? v.first : v }
          opts[:endkey]   = key.map {|v| v.kind_of?(Range) ? v.last : v }
        end
      end
    end
    
    def parse_keys opts
      opts.delete(:keys) if opts[:keys] && opts[:keys].empty?
    end
    
    def parse_range opts
      if opts[:startkey] || opts[:endkey]
        raise ArgumentError, "both a startkey and endkey must be specified if either is" unless opts[:startkey] && opts[:endkey]
      end
    end
    
  end
end