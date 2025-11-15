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
        self.resque_connector = resque_connector || ResqueConnector.default_connector

        super(*, **, &)
      end

      # connector.connect(IncrementAge, cron: "*/10 * * * *", with: { capybara: 1 })
      # connector.connect(IncrementAge, "*/10 * * * *", capybara: 1)
      # connector.connect(IncrementAge)

      # This method is used if you want to schedule a command already connected via
      # a ResqueConnector to run on a specific schedule.
      # If args/opts is meant instead for ResqueConnector then connect it to a
      # ResqueConnector manually first instead. This will interpret these options only
      # for this connector.
      def connect(registerable, *args, **opts)
        exposed_commands = super

        Util.array(exposed_commands).each do |exposed_command|
          if !resque_connector.command_connected?(exposed_command.command_class)
            resque_connector.connect(exposed_command.command_class)
          end

          command_name = "#{exposed_command.full_command_name}AsyncAt"

          klass = Util.make_class(command_name, Commands::RunCommandAsyncAt)

          klass.resque_scheduler_connector = self
          klass.target_command_class = exposed_command.transformed_command_class
        end

        exposed_commands
      end

      # This method is used if you want to schedule a command already connected via
      # a ResqueConnector to run on a specific schedule.
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
          # TODO: it would be nice to use a constructed type where all entities are converted to their primary key
          # types so that we could validate inputs before stuffing them into Redis.  But for now we will just
          # stick stuff in there raw because otherwise if we used inputs_type then primary key values would be
          # cast to thunks and that would explode without a transaction.
          serializer_class = CommandConnectors::Serializers::EntitiesToPrimaryKeysSerializer
          serializer = serializer_class.new(detached_to_primary_key: true)
          h[:args][:inputs] = serializer.serialize(inputs)
        end

        connector_name = resque_connector.name

        binding.pry
        if connector_name
          h[:args][:connector_name] = connector_name
        end

        { command_name.to_sym => h }
      end
    end
  end
end
