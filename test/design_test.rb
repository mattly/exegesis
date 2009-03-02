require File.join(File.dirname(__FILE__), 'test_helper.rb')

class FooDesign < Exegesis::Design; end
class BarDesign < Exegesis::Design
  use_design_doc_name :something_else
end

class TestForDesign < Exegesis::Document; end

class ExegesisDesignTest < Test::Unit::TestCase
  
  before do
    reset_db
    @doc = FooDesign.new(@db)
  end
  
  expect { @doc.database.will == @db }
  expect { @doc.design_doc_name.will == "foos" }

  expect { FooDesign.design_doc_name.will == "foos" }
  expect { BarDesign.design_doc_name.will == "something_else" }
  
  context "retrieving documents with #get" do
    before do
      @db.save_doc '_id' => 'foo', 'foo' => 'bar', '.kind' => 'TestForDesign'
      @obj = @doc.get('foo')
    end
    
    expect { @obj.will be_kind_of(TestForDesign) }
    expect { @obj['foo'].will == 'bar' }
  end
  
  context "retreiving views" do
    before do
      @raw_docs = [
        {'_id' => 'bar', 'foo' => 'bar', 'bar' => 'bar', '.kind' => 'TestForDesign'},
        {'_id' => 'baz', 'foo' => 'baz', 'bar' => 'baz', '.kind' => 'TestForDesign'},
        {'_id' => 'foo', 'foo' => 'foo', 'bar' => 'foo', '.kind' => 'TestForDesign'}
      ]
      @db.bulk_save @raw_docs
      @db.save_doc({
        '_id' => '_design/foos',
        'views' => {
          'test' => { 'map'=>'function(doc) {emit(doc.foo, doc.bar);}' },
        }
      })
    end
    
    context "parsing options" do
      context "when the key is a range" do
        before { @opts = @doc.parse_opts(:key => 'bar'..'baz') }
        
        expect { @opts[:key].will == nil }
        expect { @opts[:startkey].will == 'bar' }
        expect { @opts[:endkey].will == 'baz' }
      end
      
      context "when the key is an array with a range in it" do
        before { @opts = @doc.parse_opts(:key => ['published', '2008'..'2008/13']) }
        
        expect { @opts[:key].will be(nil) }
        expect { @opts[:startkey].will == ['published', '2008'] }
        expect { @opts[:endkey].will == ['published', '2008/13'] }
      end
      
      context "when a keys option is empty" do
        before { @opts = @doc.parse_opts(:keys => []) }
        
        expect { @opts[:keys].will be(nil) }
      end
    end
    
    context "when no key, keys, startkey or all option is present" do
      before { @response = @doc.view :test }
      
      expect { @response.will == [] }
    end

    context "with an all key" do
      before { @response = @doc.view :test, :all => true }
      
      expect { @response.will == @raw_docs.map{|d| {'id' => d['_id'], 'key' => d['foo'], 'value' => d['bar']} } }
    end

    context "with docs" do
      before { @response = @doc.docs_for :test, :key => 'foo' }
    
      expect { @response.will be_kind_of(Array) }
      expect { @response.size.will == 1 }
      expect { @response.first.will be_kind_of(TestForDesign) }
      expect { @response.first['foo'].will == 'foo' }
    end
    
    context "for the view's data" do
      before { @response = @doc.values_for :test, :all => true }
      
      expect { @response.will == %w(bar baz foo) }
    end
    
    context "for the view's matching keys" do
      before { @response = @doc.keys_for :test, :key => 'bar'..'baz' }
      
      expect { @response.will == %w(bar baz) }
    end
    
    context "for the view's matching ids" do
      before { @response = @doc.ids_for :test, :key => 'bar'..'foo'}
      
      expect { @response.will == %w(bar baz foo) }
    end
  end
  
end