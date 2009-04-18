require File.join(File.dirname(__FILE__), 'test_helper.rb')

class DocCollectionTestDoc
  include Exegesis::Document
end

describe Exegesis::DocumentCollection do
  
  describe "when dealing with view response rows" do
    before do
      reset_db
      @docs = [{'_id' => 'foo'}, {'_id' => 'bar'}, {'_id' => 'bee'}].map {|d| d.update('class' => 'DocCollectionTestDoc') }
      @db.save(@docs)
      @rows = [['bar',5,'bar'], ['bee',5,'bee'], ['foo',3,'foo'], ['foo',10,'foo']]
      @response_rows = @rows.map {|r| {'key' => r[0], 'value' => r[1], 'id' => r[2]} }
      @collection = Exegesis::DocumentCollection.new(@response_rows, @db)
    end
    
    expect { @collection.size.must_equal @rows.size }
    expect { @collection.keys.must_equal @rows.map{|r| r.first}.uniq }
    expect { @collection.values.must_equal @rows.map{|r| r[1]} }
    expect { @collection.documents.size.must_equal @rows.map{|r| r[2]}.uniq.size }
    expect { @collection.documents.each {|id,d| d.must_be_kind_of DocCollectionTestDoc } }
    expect { @collection.documents['foo'].id.must_equal @docs.first['_id'] }
    
    describe "when documents are already in the rows" do
      before do
        # "thing":"foobar" is not in the docs that have been saved to the database
        @docs.each {|d| d.update('thing' => 'foobar') }
        @response_rows = @docs.map {|doc| {'key' => doc['_id'], 'value' => nil, 'id' => doc['_id'], 'doc' => doc } }
        @collection = Exegesis::DocumentCollection.new(@response_rows, @db)
      end
      
      expect { @collection.documents.each {|id,d| d['thing'].must_equal 'foobar' } }
    end
    
    describe "filtering to a specific key" do
      before do
        @rows = @rows.select {|r| r[0]=="foo" }
        @foos = @collection['foo']
      end
      
      expect { @foos.size.must_equal @rows.size }
      expect { @foos.values.must_equal @rows.map{|r| r[1]} }
      expect { @foos.documents.size.must_equal @rows.map{|r| r[2]}.uniq.size }
      expect { @foos.documents.each {|id,d| d.must_be_kind_of DocCollectionTestDoc } }
      expect { @foos.documents['foo'].object_id.must_equal @collection.documents['foo'].object_id }
      
      describe "with array keys" do
        before do
          @rows = [ [%w(bar baz), 5, 'bar'], 
                    [%w(bar bee), 5, 'bee'], 
                    [%w(bee bar), 3, 'bee'], 
                    [%w(foo bar), 9, 'foo'], 
                    [%w(foo bar), 2, 'bar'],
                    [%w(foo bee), 1, 'foo'],
                    [%w(foo bee), 8, 'bee']
                  ]
          @response_rows = @rows.map {|r| {'key' => r[0], 'value' => r[1], 'id' => r[2] }}
          @collection = Exegesis::DocumentCollection.new(@response_rows, @db)
        end

        expect { @collection['foo'].size.must_equal @rows.select{|r| r[0][0]=='foo'}.size }
        expect { @collection['foo'].values.must_equal @rows.select{|r| r[0][0]=='foo' }.map{|r| r[1]} }
        expect { @collection['foo']['bar'].size.must_equal @rows.select{|r| r[0][0]=='foo' && r[0][1]=='bar'}.size }
        expect { @collection['foo']['bar'].values.must_equal @rows.select{|r| r[0][0]=='foo'&&r[0][1]=='bar'}.map{|r| r[1]} }
      end

    end
    
  end
  
  describe "iterating" do
    before do
      reset_db
      @docs = [%w(bar bee), %w(bee foo), %w(foo bar)].map {|k,t| {'_id'=>k, 'thing'=>t, 'class'=>'DocCollectionTestDoc'} }
      @db.save(@docs)
      @rows = @docs.map {|doc| {'key'=>doc['_id'], 'value'=>doc['thing'], 'id'=>doc['_id']} }
      @collection = Exegesis::DocumentCollection.new(@rows, @db)
    end
    
    describe "each" do
      before do
        @counter = 0
        @bin = []
        @counting = lambda{ @collection.each{|k,v,d| @counter+=1 }; @counter }
        @keybinning = lambda{ @collection.each{|k,v,d| @bin << k }; @bin }
        @valbinning = lambda{ @collection.each{|k,v,d| @bin << v }; @bin }
        @docbinning = lambda{ @collection.each{|k,v,d| @bin << d.id }; @bin }
      end
      expect { @counting.call.must_equal 3 }
      expect { @keybinning.call.must_equal @rows.map{|r| r['key']} }
      expect { @valbinning.call.must_equal @rows.map{|r| r['value']} }
      expect { @docbinning.call.must_equal @rows.map{|r| @db.get(r['id']).id} }
    end
  end
end