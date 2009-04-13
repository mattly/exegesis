require File.join(File.dirname(__FILE__), 'test_helper.rb')

class DocCollectionTestDoc
  include Exegesis::Document
end

class ExegesisDocumentCollectionTest < Test::Unit::TestCase
  
  context "when dealing with view response rows" do
    before do
      reset_db
      @docs = [{'_id' => 'foo'}, {'_id' => 'bar'}, {'_id' => 'bee'}].map {|d| d.update('class' => 'DocCollectionTestDoc') }
      @db.save(@docs)
      @rows = [['bar',5,'bar'], ['bee',5,'bee'], ['foo',3,'foo'], ['foo',10,'foo']]
      @response_rows = @rows.map {|r| {'key' => r[0], 'value' => r[1], 'id' => r[2]} }
      @collection = Exegesis::DocumentCollection.new(@response_rows, @db)
    end
    
    expect { @collection.size.will == @rows.size }
    expect { @collection.keys.will == @rows.map{|r| r.first}.uniq }
    expect { @collection.values.will == @rows.map{|r| r[1]} }
    expect { @collection.documents.size.will == @rows.map{|r| r[2]}.uniq.size }
    expect { @collection.documents.all? {|id,d| d.kind_of?(DocCollectionTestDoc) }.will == true }
    expect { @collection.documents['foo'].id.will == @docs.first['_id'] }
    
    context "when documents are already in the rows" do
      before do
        # "thing":"foobar" is not in the docs that have been saved to the database
        @docs.each {|d| d.update('thing' => 'foobar') }
        @response_rows = @docs.map {|doc| {'key' => doc['_id'], 'value' => nil, 'id' => doc['_id'], 'doc' => doc } }
        @collection = Exegesis::DocumentCollection.new(@response_rows, @db)
      end
      
      expect { @collection.documents.all?{|id,d| d['thing'] == 'foobar' }.will == true }
    end
    
    context "filtering to a specific key" do
      before do
        @rows = @rows.select {|r| r[0]=="foo" }
        @foos = @collection['foo']
      end
      
      expect { @foos.size.will == @rows.size }
      expect { @foos.values.will == @rows.map{|r| r[1]} }
      expect { @foos.documents.size.will == @rows.map{|r| r[2]}.uniq.size }
      expect { @foos.documents.all? {|id,d| d.kind_of?(DocCollectionTestDoc) }.will == true }
      expect { @foos.documents['foo'].object_id.will == @collection.documents['foo'].object_id }
      
      context "with array keys" do
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

        expect { @collection['foo'].size.will == @rows.select{|r| r[0][0]=='foo'}.size }
        expect { @collection['foo'].values.will == @rows.select{|r| r[0][0]=='foo' }.map{|r| r[1]} }
        expect { @collection['foo']['bar'].size.will == @rows.select{|r| r[0][0]=='foo' && r[0][1]=='bar'}.size }
        expect { @collection['foo']['bar'].values.will == @rows.select{|r| r[0][0]=='foo'&&r[0][1]=='bar'}.map{|r| r[1]} }
      end

    end
    
  end
  
  context "iterating" do
    before do
      reset_db
      @docs = [%w(bar bee), %w(bee foo), %w(foo bar)].map {|k,t| {'_id'=>k, 'thing'=>t, 'class'=>'DocCollectionTestDoc'} }
      @db.save(@docs)
      @rows = @docs.map {|doc| {'key'=>doc['_id'], 'value'=>doc['thing'], 'id'=>doc['_id']} }
      @collection = Exegesis::DocumentCollection.new(@rows, @db)
    end
    
    context "each" do
      before do
        @counter = 0
        @bin = []
        @counting = lambda{ @collection.each{|k,v,d| @counter+=1 }; @counter }
        @keybinning = lambda{ @collection.each{|k,v,d| @bin << k }; @bin }
        @valbinning = lambda{ @collection.each{|k,v,d| @bin << v }; @bin }
        @docbinning = lambda{ @collection.each{|k,v,d| @bin << d.id }; @bin }
      end
      expect { @counting.call.will == 3 }
      expect { @keybinning.call.will == @rows.map{|r| r['key']} }
      expect { @valbinning.call.will == @rows.map{|r| r['value']} }
      expect { @docbinning.call.will == @rows.map{|r| @db.get(r['id']).id} }
    end
  end
end