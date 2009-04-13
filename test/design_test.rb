require File.join(File.dirname(__FILE__), 'test_helper.rb')

class DesignTestDoc
  include Exegesis::Document
  
end

class DesignTestDatabase
  include Exegesis::Database
  
  designs_directory "test/fixtures/designs"
  
  design :things do
    view :by_name
    docs :by_tag
    hash :count, :view => :by_tag
  end
  
  design :stuff, :name => 'things', :directory => 'app/designs/stuff' do
    
  end
end

class ExegesisDesignTest < Test::Unit::TestCase
  
  def setup_db(with_doc=true)
    reset_db
    @db = DesignTestDatabase.new('exegesis-test')
    if with_doc
      @db.save({
        '_id' => '_design/things',
        'views' => {
          'by_tag' => { 
            'map' => 'function(doc) { for (var tag in doc.tags) { emit(doc.tags[tag], 1); } }',
            'reduce' => 'function(keys, values, rereduce) { return sum(values); }' 
        }}
      })
    end
  end
  
  context "design instances" do
    before { setup_db }
    expect { @db.things.database.will == @db }
  end
  
  context "design declarations" do
    before { setup_db }
    expect { @db.things.class.will == DesignTestDatabase::ThingsDesign }
    expect { @db.things.is_a?(Exegesis::Design).will == true }
    expect { @db.things.design_name.will == 'things' }
  end
  
  context "view declarations" do
    before do
      setup_db
      @docs = [
        {'class' => 'DesignTestDoc', 'path' => 'a', 'date' => '2009/04/10', 'tags' => %w(foo bar bee)},
        {'class' => 'DesignTestDoc', 'path' => 'b', 'date' => '2009/04/11', 'tags' => %w(foo bar baz)},
        {'class' => 'DesignTestDoc', 'path' => 'c', 'date' => '2009/04/12', 'tags' => %w(foo bee ruby)}
      ]
      @db.save(@docs)
    end
    
    context "declared docs" do
      describe "with default key" do
        before { @response = @db.things.by_tag('foo') }
        expect { @response.kind_of?(Array).will == true }
        expect { @response.size.will == @docs.select{|d| d['tags'].include?('foo')}.size }
        expect { @response.all? {|d| d.kind_of?(DesignTestDoc) }.will == true }
        expect { @response.all? {|d| d['tags'].include?('foo') }.will == true }
      end
      
      describe "with multiple keys" do
        before { @response = @db.things.by_tag :keys => %w(bar bee) }
        expect { @response.kind_of?(Array).will == true }
        expect { @response.size.will == 3 }
        # expect { @response.size.will == @docs.select{|d| (d['tags'] & %w(bar bee)).size > 0}.size }
        expect { @response.all? {|d| d.kind_of?(DesignTestDoc) }.will == true }
      end
      
    end
    
    context "declared hashes" do
      before do
        @counts = Hash.new(0)
        @docs.each do |doc|
          tags = doc['tags'].sort 
          tags.each_with_index do |tag, index| 
            @counts[tag] += 1
            (tags.length - index).times do |second|
              next if second.zero?
              @counts[tags.slice(index, second+1)] += 1
            end
          end
        end
      end
      expect { @db.things.count.should == @counts }
      expect { @db.things.count('foo').should == @counts['foo'] }
      
      context "invalid options" do
        expect { lambda{@db.things.count(:group=>false)}.will raise_error(ArgumentError) }
        expect { lambda{@db.things.count(:include_docs=>true)}.will raise_error(ArgumentError) }
      end
      
      context "for views without reduce" do
        before { @klass = DesignTestDatabase::StuffDesign }
        expect { lambda{@klass.class_eval{hash(:name_count, :view=>:by_name)}}.will raise_error }
      end
    end
  end
  
  context "parsing query options" do
    before { setup_db }
    
    context "with a key as an initial arguemnt" do
      expect { @db.things.parse_opts('foo').will == {:key => 'foo'} }
      expect { @db.things.parse_opts('foo', :include_docs => true).will == {:key => 'foo', :include_docs => true} }
      expect { @db.things.parse_opts('foo', {:stale => 'ok'}, {:include_docs => true}).will == {:key => 'foo', :stale => 'ok', :include_docs => true }}
    end
    
    context "without an implied key" do
      expect { @db.things.parse_opts(:key => 'foo').will == {:key => 'foo'} }
      expect { @db.things.parse_opts({:key => 'foo'}, nil, {:stale => 'ok'}).will == {:key => 'foo', :stale => 'ok'} }
    end
    
    context "when a keys option is empty" do
      expect { @db.things.parse_opts(:keys => []).will == {} }
    end
    
    context "for ranges" do
      context "when the key _is_ a range" do
        before { @opts = @db.things.parse_opts(:key => 'bar'..'baz') }
        expect { @opts.has_key?(:key).will == false }
        expect { @opts[:startkey].will == 'bar' }
        expect { @opts[:endkey].will == 'baz'}
      end
      
      context "when the key is an array that includes a range" do
        before { @opts = @db.things.parse_opts(:key => ['published', '2009'..'2009/04']) }
        expect { @opts.has_key?(:key).will == false }
        expect { @opts[:startkey].will == ['published', '2009'] }
        expect { @opts[:endkey].will == ['published', '2009/04'] }
      end
      
      context "for non inclusive ranges" do
      end
      context "when descending:true is an option" do
        context "and first value is greater than the end value" do
        end
      end
      context "when the first value is greater than the end value" do
      end
      
      context "invalid option configurations" do
        expect { lambda {@db.things.parse_opts(:startkey => 'foo')}.will raise_error(ArgumentError) }
      end
    end
    
    context "reducing" do
      before { @parsing = lambda{|opts| @db.things.parse_opts(opts) } }
      expect { @parsing.call(:group => 3).will == {:group_level => 3}}
      expect { lambda{@parsing.call(:group => true, :reduce => false)}.will raise_error(ArgumentError) }
      expect { lambda{@parsing.call(:group => true, :include_docs => true)}.will raise_error(ArgumentError) }
      expect { lambda{@parsing.call(:group => 1, :reduce => false)}.will raise_error(ArgumentError) }
      expect { lambda{@parsing.call(:group => 1, :include_docs => true)}.will raise_error(ArgumentError) }
    end
  end
  
  context "design doc meta declarations" do
    expect { DesignTestDatabase::StuffDesign.design_name.will == "things" }
    expect { DesignTestDatabase::StuffDesign.design_directory.will == Pathname.new("app/designs/stuff") }
  end
  
  context "the design document" do
    before do
      @canonical = DesignTestDatabase::ThingsDesign.canonical_design
    end
    
    context "composing the canonical version" do
      context "from files" do
        expect { @canonical['views']['by_tag']['map'].will == File.read(fixtures_path('designs/things/views/by_tag/map.js')) }
        expect { @canonical['views']['by_tag']['reduce'].will == File.read(fixtures_path('designs/things/views/by_tag/reduce.js')) }
      end
      
      context "from class declarations" do
        # tk
      end
    end
    
    context "syncronizing" do
      context "when the design_doc doesn't exist in the db yet" do
        before do 
          setup_db(false)
          @db.things
        end
        expect { lambda{@db.get('_design/things')}.wont raise_error }
        expect { @db.things['views'].will == @canonical['views'] }
        expect { @db.things.rev.will =~ /\d-\d{6,12}/ }
      end
      
      context "when the design_doc exists but is not canonical" do
        before do
          # there are no line breaks in the version that setup_db posts
          setup_db
          @old = @db.get('_design/things')
          @db.things
        end
        
        expect { @db.things.rev.wont == @old['_rev'] }
      end
      
      context "when the design_doc exists and is canonical" do
        before do
          setup_db(false)
          @db.put('_design/things', DesignTestDatabase::ThingsDesign.canonical_design)
          @old = @db.get('_design/things')
          @db.things
        end
        
        expect { @db.things.rev.will == @old['_rev'] }
      end
    end
    
    context "knowing the views" do
      before do
        @klass = DesignTestDatabase::ThingsDesign
      end
      
      expect { @klass.views.will == @canonical['views'].keys }
      expect { @klass.reduceable?('by_tag').will be(true) }
      expect { @klass.reduceable?('by_name').will be(false) }
    end
  end
  
end