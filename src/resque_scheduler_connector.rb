module Foobara
  module CommandConnectors
    class ResqueSchedulerConnector < CommandConnector
      class NoCommandFoundError < StandardError
        attr_accessor :command_class

        def initialize(command_class)
          # :nocov:
          self.command_class = command_class

          super("No command found for #{command_class}")
          # :nocov:
        end
      end

      attr_accessor :resque_connector

      def initialize(*, resque_connector: nil, **, &)
        self.resque_connector = resque_connector || ResqueConnector[nil]

        super(*, **, &)
      end

      # NOTE: inputs transformer in this context is not clear. Is it how we transform for writing the job to redis?
      # Or are we transforming what comes out of redis?  It seems like redis serialize/redis deserialize would make
      # more sense here. It feels like these types of inputs_transformer helpers from connectors like http are not
      # universally meaningful.
      # It also feels like CommandClass.run_async would be a more intuitive interface.
      # This makes run_async feel like an "action" like "run" and "help". So maybe "actions" should be viewed
      # as methods on Org/Domain/Commands/Connector.
      # However, if it made a class, like SomeCommandAsync, then it could be exposed through other connectors
      # and be declared in depends_on calls and have proper possible errors for that operation.
      # But on the downside, it would appear in the domain's list of commands unless coming up with a clear way
      # to express that. A way could be found, though. So probably creating a command class is better.
      # And in this context maybe that should be the transformed command?
      # So TransformedCommand is connector specific? And some connectors might have no TransformedCommand?
      def connect(command_class, ...)
        transformed_command_classes = super(command_class, ...)

        Util.array(transformed_command_classes).each do |transformed_command_class|
          command_class = transformed_command_class.command_class

          if command_class.is_a?(Class) && command_class < Command
            command_name = "#{transformed_command_class.full_command_name}AsyncAt"

            klass = Util.make_class(command_name, Commands::RunCommandAsyncAt)

            klass.resque_scheduler_connector = self
            klass.target_command_class = transformed_command_class
          end
        end

        transformed_command_classes
      end

      def cron(crontab)
        crontab.each do |cron_entry|
          new_schedule_entry = build_resque_schedule_entry(*cron_entry)

          Resque.schedule = Resque.schedule.merge(new_schedule_entry)
        end
      end

      private

      def build_resque_schedule_entry(cron, command_class, inputs = nil, description = command_class.description)
        command_name = command_class.full_command_name

        h = {
          cron:,
          class: ResqueConnector::CommandJob.name,
          queue: resque_connector.command_name_to_queue[command_name],
          args: {
            command_name:
          }
        }

        h[:description] = description if description

        if inputs
          h[:args][:inputs] = command_class.inputs_type.process_value!(inputs)
        end

        connector_name = resque_connector.name

        if connector_name
          h[:args][:connector_name] = connector_name
        end

        { command_name.to_sym => h }
      end
    end
  end
end
