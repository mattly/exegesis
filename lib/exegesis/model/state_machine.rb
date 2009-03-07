module Exegesis
  class Model
    module StateMachine
      
      class StateTransitionError < StandardError; end
      
      def self.included base
        base.extend ClassMethods
      end
      
      module ClassMethods
        def state_machine &definitions
          show :state
          class_eval &definitions
        end
        
        def initial_state name, opts={}
          @initial_state = name
          state name, opts
        end
        
        def states
          @states ||= superclass.respond_to?(:states) ? superclass.states : {}
        end
        
        def state name, opts={}
          states[name.to_s] = opts
        end
        
        def events
          @events ||= superclass.respond_to?(:events) ? superclass.events : {}
        end
        
        def event name, opts={}
          events[name] = opts
          
          define_method "#{name}!" do
            old_state = self.class.states[state]
            current_event = self.class.events[name]
            new_state_name = current_event[:enter]
            new_state = self.class.states[new_state_name.to_s]
            raise StateTransitionError, "attempting to transition to state #{new_state_name} which doesn't exist" if new_state.nil?
            
            if current_event[:exit] && ! current_event[:exit].map{|s| s.to_s}.include?(state)
              raise StateTransitionError, "cannot run event #{name} from state #{state}"
            end
            
            if guard = new_state[:guard]
              result = if guard.is_a?(Proc)
                instance_eval guard
              elsif guard.is_a?(Symbol)
                send guard
              end
              raise StateTransitionError, "cannot enter state #{new_state_name}" unless result
            end
            
            if old_state[:exit]
              send old_state[:exit]
            end
            
            self['state'] = new_state_name
            
            if new_state[:enter]
              send new_state[:enter]
            end
            
            save
          end
        end
      end
      
    end
  end
end