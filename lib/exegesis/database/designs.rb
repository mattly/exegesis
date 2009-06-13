# tests for this module are in test/design_test.rb
module Exegesis
  module Database
    module Designs
      
      # set the directory where the designs will be, relative to ENV['PWD']
      def designs_directory dir=nil
        if dir
          @designs_directory = Pathname.new(dir)
        else
          @designs_directory ||= Pathname.new('designs')
        end
      end
      
      # declare a design document for this database. Creates a new class and yields a given block to the class to
      # configure the design document and declare views; See Class methods for Exegesis::Design
      def design design_name, opts={}, &block
        klass_name = "#{design_name.to_s.capitalize}Design"
        klass = const_set(klass_name, Class.new(Exegesis::Design))
        klass.design_directory = opts[:directory] || self.designs_directory + design_name.to_s
        klass.design_name = opts[:name] || design_name.to_s
        klass.compose_canonical
        klass.class_eval &block if block_given?
        define_method design_name do
          @exegesis_designs ||= {}
          @exegesis_designs[design_name] ||= klass.new(self)
        end
      end
    end
  end
end