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

describe Exegesis::Design do
  
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
  
  describe "design instances" do
    before { setup_db }
    expect { @db.things.database.must_equal @db }
  end
  
  describe "design declarations" do
    before { setup_db }
    expect { @db.things.class.must_equal DesignTestDatabase::ThingsDesign }
    expect { @db.things.must_be_kind_of Exegesis::Design }
    expect { @db.things.design_name.must_equal 'things' }
  end
  
  describe "view declarations" do
    before do
      setup_db
      @docs = [
        {'class' => 'DesignTestDoc', 'path' => 'a', 'date' => '2009/04/10', 'tags' => %w(foo bar bee)},
        {'class' => 'DesignTestDoc', 'path' => 'b', 'date' => '2009/04/11', 'tags' => %w(foo bar baz)},
        {'class' => 'DesignTestDoc', 'path' => 'c', 'date' => '2009/04/12', 'tags' => %w(foo bee ruby)}
      ]
      @db.save(@docs)
    end
    
    describe "declared docs" do
      describe "with default key" do
        before { @response = @db.things.by_tag('foo') }
        expect { @response.must_be_kind_of Exegesis::DocumentCollection }
        expect { @response.size.must_equal @docs.select{|d| d['tags'].include?('foo')}.size }
        expect { @response.documents.each {|id,d| d.must_be_kind_of DesignTestDoc } }
        expect { @response.documents.each {|id,d| d['tags'].must_include 'foo' } }
      end
      
      describe "with multiple keys" do
        before { @response = @db.things.by_tag :keys => %w(bar bee) }
        expect { @response.must_be_kind_of Exegesis::DocumentCollection }
        expect { @response.size.must_equal @docs.inject(0){|sum,d| sum+=(d['tags'] & %w(bar bee)).size } }
        expect { @response.documents.size.must_equal @docs.select{|d| (d['tags'] & %w(bar bee)).size > 0}.size }
        expect { @response.documents.each {|id,d| d.must_be_kind_of DesignTestDoc } }
      end
      
    end
    
    describe "declared hashes" do
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
      expect { @db.things.count.must_equal @counts }
      expect { @db.things.count('foo').must_equal @counts['foo'] }
      
      describe "invalid options" do
        expect { lambda{@db.things.count(:group=>false)}.must_raise ArgumentError }
        expect { lambda{@db.things.count(:include_docs=>true)}.must_raise ArgumentError }
      end
      
      describe "for views without reduce" do
        before { @klass = DesignTestDatabase::StuffDesign }
        expect { lambda{@klass.class_eval{hash(:name_count, :view=>:by_name)}}.must_raise(ArgumentError) }
      end
    end
  end
  
  describe "design doc meta declarations" do
    expect { DesignTestDatabase::StuffDesign.design_name.must_equal "things" }
    expect { DesignTestDatabase::StuffDesign.design_directory.must_equal Pathname.new("app/designs/stuff") }
  end
  
  describe "the design document" do
    before do
      @canonical = DesignTestDatabase::ThingsDesign.canonical_design
    end
    
    describe "composing the canonical version" do
      describe "from files" do
        expect { @canonical['views']['by_tag']['map'].must_equal File.read(fixtures_path('designs/things/views/by_tag/map.js')) }
        expect { @canonical['views']['by_tag']['reduce'].must_equal File.read(fixtures_path('designs/things/views/by_tag/reduce.js')) }
      end
      
      describe "from class declarations" do
        # tk
      end
    end
    
    describe "syncronizing" do
      describe "when the design_doc doesn't exist in the db yet" do
        before do 
          setup_db(false)
        end
        expect { lambda{@db.get('_design/things')}.must_raise RestClient::ResourceNotFound }
        expect { @db.things['views'].must_equal @canonical['views'] }
        expect { @db.things.rev.must_match /\d-\d{6,12}/ }
      end
      
      describe "when the design_doc exists but is not canonical" do
        before do
          # there are no line breaks in the version that setup_db posts
          setup_db
          @old = @db.get('_design/things')
          @db.things
        end
        
        expect { @db.things.rev.wont_equal @old['_rev'] }
      end
      
      describe "when the design_doc exists and is canonical" do
        before do
          setup_db(false)
          @db.put('_design/things', DesignTestDatabase::ThingsDesign.canonical_design)
          @old = @db.get('_design/things')
          @db.things
        end
        
        expect { @db.things.rev.must_equal @old['_rev'] }
      end
    end
    
    describe "knowing the views" do
      before do
        @klass = DesignTestDatabase::ThingsDesign
      end
      
      expect { @klass.views.must_equal @canonical['views'].keys }
      expect { assert @klass.reduceable?('by_tag') }
      expect { refute @klass.reduceable?('by_name') }
    end
  end
  
end