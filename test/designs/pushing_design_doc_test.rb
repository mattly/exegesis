require File.join(File.dirname(__FILE__), '..','test_helper.rb')

class Foos < Exegesis::Design; end

class PushingDesignDocTest < Test::Unit::TestCase
  
  context "pushing design doc when it doesn't exist yet" do
    before do
      reset_db "design_doc_sync"
      Foos.push_design!(@db)
      @get_design = lambda { @db.get('_design/foos') }
      @design = @get_design.call rescue nil
    end
    
    expect { @get_design.wont raise_error }
    expect { @design.has_key?('_rev').will be(true) }
    expect { @design.has_key?('language').will be(true) }
    expect { @design['language'].will == 'javascript' }
    expect { @design.has_key?('views').will be(true) }
    expect { @design['views'].has_key?('by_bar').will be(true) }
  end
  
end