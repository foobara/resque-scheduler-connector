module Foobara
  module CommandConnectors
    class ResqueSchedulerConnector < CommandConnector
      module Commands
        class RunCommandAsyncAt < Command
          class << self
            attr_reader :target_command_class
            attr_accessor :resque_scheduler_connector

            def target_command_class=(target_command_class)
              @target_command_class = target_command_class

              # Not using attributes DSL because in is a reserved word but too obvious an attribute name to not use here
              # TODO: should be able to pass the inputs_type here not only the declaration_data
              inputs inputs: target_command_class.inputs_type.declaration_data,
                     # Do we really need to support both at and in?
                     at: :datetime,
                     # unsure if we want some kind of timespan object here or a numeric
                     in: :duck
            end
          end

          # TODO: set result type to job
          def execute
            build_command_job_data
            determine_queue
            enqueue_command

            resque_scheduled_job
          end

          attr_accessor :resque_scheduled_job, :job_data, :queue

          def validate
            if at
              if self.in
                # TODO: add runtime error instead
                raise "can't set both at and in"
              end
            elsif !self.in
              # TODO: add runtime error instead
              raise "must provide either in or at"
            end
          end

          def enqueue_command
            self.resque_scheduled_job = if at
                                          Resque.enqueue_at_with_queue(queue, at, ResqueConnector::CommandJob, job_data)
                                        else
                                          Resque.enqueue_in_with_queue(queue, self.in, ResqueConnector::CommandJob,
                                                                       job_data)
                                        end
          end

          def build_command_job_data
            connector_name = resque_connector.name

            job = { command_name: }
            job[:inputs] = inputs[:inputs] if inputs[:inputs] && !inputs[:inputs].empty?
            job[:connector_name] = connector_name if connector_name

            self.job_data = job
          end

          def resque_connector
            @resque_connector ||= resque_scheduler_connector.resque_connector
          end

          def determine_queue
            self.queue = resque_connector.command_name_to_queue[command_name]
          end

          def target_command_class
            self.class.target_command_class
          end

          def command_name
            target_command_class.full_command_name
          end

          def resque_scheduler_connector
            self.class.resque_scheduler_connector
          end
        end
      end
    end
  end
end
