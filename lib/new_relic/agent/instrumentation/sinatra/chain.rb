# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.

require 'new_relic/agent/instrumentation/controller_instrumentation'
require 'new_relic/agent/instrumentation/sinatra/transaction_namer'
require 'new_relic/agent/instrumentation/sinatra/ignorer'
require 'new_relic/agent/parameter_filtering'

module NewRelic::Agent::Instrumentation
  module SinatraInstrumentation
    module Chain 
      def self.instrument!
        ::Sinatra::Base.class_eval do
          include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
          include NewRelic::Agent::Instrumentation::Sinatra

          def dispatch_with_newrelic
            dispatch_with_tracing { dispatch_without_newrelic }
          end
          alias dispatch_without_newrelic dispatch!
          alias dispatch! dispatch_with_newrelic
    
          def process_route_with_newrelic(*args, &block)
            process_route_with_tracing(*args) do 
              process_route_without_newrelic(*args, &block)
            end
          end
          alias process_route_without_newrelic process_route
          alias process_route process_route_with_newrelic
    
          def route_eval_with_newrelic(*args, &block)
            route_eval_with_tracing(*args) do
              route_eval_without_newrelic(*args, &block)
            end
          end
          alias route_eval_without_newrelic route_eval
          alias route_eval route_eval_with_newrelic
    
          register NewRelic::Agent::Instrumentation::Sinatra::Ignorer
        end

        ::Sinatra.module_eval do
          register NewRelic::Agent::Instrumentation::Sinatra::Ignorer
        end

        

      end
    end
  end
end
