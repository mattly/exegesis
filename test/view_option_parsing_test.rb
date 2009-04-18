require File.join(File.dirname(__FILE__), 'test_helper.rb')

class ViewOptionsParsingTestDatabase
  include Exegesis::Database
  
  designs_directory "test/fixtures/designs"
  
  design :things do
    view :by_name
    docs :by_tag
    hash :count, :view => :by_tag
  end
end

describe "parsing query options" do
  before { @db = reset_db('', ViewOptionsParsingTestDatabase) }
  
  describe "with a key as an initial arguemnt" do
    expect { @db.things.parse_opts('foo').must_equal({:key => 'foo'}) }
    expect { @db.things.parse_opts('foo', :include_docs => true).must_equal({:key => 'foo', :include_docs => true}) }
    expect { @db.things.parse_opts('foo', {:stale => 'ok'}, {:include_docs => true}).must_equal({:key => 'foo', :stale => 'ok', :include_docs => true })}
  end
  
  describe "without an implied key" do
    expect { @db.things.parse_opts(:key => 'foo').must_equal({:key => 'foo'}) }
    expect { @db.things.parse_opts({:key => 'foo'}, nil, {:stale => 'ok'}).must_equal({:key => 'foo', :stale => 'ok'}) }
  end
  
  describe "when a keys option is empty" do
    expect { @db.things.parse_opts(:keys => []).must_equal({}) }
  end
  
  describe "for ranges" do
    describe "when the key _is_ a range" do
      before { @opts = @db.things.parse_opts(:key => 'bar'..'baz') }
      expect { @opts.has_key?(:key).must_equal false }
      expect { @opts[:startkey].must_equal 'bar' }
      expect { @opts[:endkey].must_equal 'baz'}
    end
    
    describe "when the key is an array that includes a range" do
      before { @opts = @db.things.parse_opts(:key => ['published', '2009'..'2009/04']) }
      expect { @opts.has_key?(:key).must_equal false }
      expect { @opts[:startkey].must_equal ['published', '2009'] }
      expect { @opts[:endkey].must_equal ['published', '2009/04'] }
    end
    
    describe "for non inclusive ranges" do
    end
    describe "when descending:true is an option" do
      describe "and first value is greater than the end value" do
      end
    end
    describe "when the first value is greater than the end value" do
    end
    
    describe "invalid option configurations" do
      expect { lambda {@db.things.parse_opts(:startkey => 'foo')}.must_raise ArgumentError }
    end
  end
  
  describe "reducing" do
    before { @parsing = lambda{|opts| @db.things.parse_opts(opts) } }
    expect { @parsing.call(:group => 3).must_equal({:group_level => 3})}
    expect { lambda{@parsing.call(:group => true, :reduce => false)}.must_raise ArgumentError }
    expect { lambda{@parsing.call(:group => true, :include_docs => true)}.must_raise ArgumentError }
    expect { lambda{@parsing.call(:group => 1, :reduce => false)}.must_raise ArgumentError }
    expect { lambda{@parsing.call(:group => 1, :include_docs => true)}.must_raise ArgumentError }
  end
end
