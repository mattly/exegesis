require File.join(File.dirname(__FILE__), '..','test_helper.rb')

class FooDesign < Exegesis::Design; end

class PushingDesignDocTest < Test::Unit::TestCase
  
  before do
    Exegesis.designs_directory = fixtures_path('designs')
    reset_db
  end
  
  context "pushing design doc when it doesn't exist yet" do
    before do
      foo = FooDesign.new(@db)
      foo.push_design!
      @get_design = lambda { @db.get('_design/foos') }
      @design = @get_design.call rescue nil
    end
    
    expect { @get_design.wont raise_error }
    expect { @design['_rev'].will =~ /^[0-9]+$/ }
    expect { @design['language'].will == 'javascript' }
    expect { @design['views'].has_key?('by_bar').will be(true) }
  end
  
  context "reading the existing design document" do
    before do
      @db.save_doc(FooDesign.design_doc)
      @foo = FooDesign.new(@db)
    end
    
    expect { lambda {@foo.design_doc}.wont raise_error }
    expect { @foo.design_doc['_rev'].will =~ /^[0-9]+$/ }
    expect { @foo.design_doc['views'].will == FooDesign.design_doc['views'] }
  end
  
  context "updating an existing doc" do
    
    context "when it hasn't changed" do
      before do
        @db.save_doc(FooDesign.design_doc)
        @rev = @db.get('_design/foos')['_rev']
        @foo = FooDesign.new(@db)
        @foo.push_design!
      end
      
      expect { @db.get('_design/foos')['_rev'].will == @rev }
    end
    
    context "when it has chagned" do
      before do
        @db.save_doc({'_id' => '_design/foos', 
          'views' => {'a' => {'map' => 'function(doc) { emit(true, null)}'}}
        })
        @rev = @db.get('_design/foos')['_rev']
        
        @foo = FooDesign.new(@db)
        @foo.push_design!
      end
      
      expect { @db.get('_design/foos')['_rev'].wont == @rev }
      expect { @foo.design_doc_hash.will == FooDesign.design_doc_hash }
    end
  end
  
end