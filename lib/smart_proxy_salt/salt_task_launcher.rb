require 'smart_proxy_dynflow/task_launcher'

module Proxy
  module Salt
    # Implements the TaskLauncher::Batch for Salt
    class SaltTaskLauncher < ::Proxy::Dynflow::TaskLauncher::Batch
      # Implements the Runner::Action for Salt
      class SaltRunnerAction < ::Proxy::Dynflow::Action::Runner
        def initiate_runner
          additional_options = {
            :step_id => run_step_id,
            :uuid => execution_plan_id
          }
          ::Proxy::Salt::SaltRunner.new(
            input.merge(additional_options),
            :suspended_action => suspended_action
          )
        end
      end

      def child_launcher(parent)
        ::Proxy::Dynflow::TaskLauncher::Single.new(world, callback, :parent => parent,
                                                                    :action_class_override => SaltRunnerAction)
      end
    end
  end
end
