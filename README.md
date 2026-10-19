# Foobara::ResqueSchedulerConnector

`foobara-resque-scheduler-connector` adds delayed and recurring scheduling for Foobara commands via the `resque-scheduler`.

## Installation

Add `gem "foobara-resque-scheduler-connector"` to your Gemfile or .gemspec file and `bundle install`. Or even just `gem install foobara-resque-scheduler-connector` if just playing with it directly in the scripts.

## Usage

### Create a `commands.rb` file

This file registers your Foobara command, as well as two other connectors namely the Resque Connector and the Resque Scheduler Connector.

```ruby
require "foobara/resque_scheduler_connector"

Resque.redis = Redis.new(url: ENV.fetch("REDIS_URL"))

class DoSomething < Foobara::Command
  inputs do
    foo :integer
    bar :string
  end

  def execute
    "success! #{foo} #{bar}"
  end
end

resque = Foobara::CommandConnectors::ResqueConnector.new
resque.connect(DoSomething, queue: :general)

scheduler = Foobara::CommandConnectors::ResqueSchedulerConnector.new(
  resque_connector: resque
)
scheduler.connect(DoSomething)
```

### Create a `Rakefile`

A `Rakefile` tells `rake` which tasks are available. This one loads your `commands.rb` file  and adds the tasks for starting the worker and the scheduler.

```ruby
require_relative "commands"
require "resque/tasks"
require "resque/scheduler/tasks"
```

### Running a command later (Delayed jobs)

Connecting exposes `DoSomethingAsyncAt`, which accepts either a delay in seconds (`in:`) or a scheduled `Time` (`at:`). Command inputs go inside the `inputs:` block.

To run the `DoSomething` command in 60 seconds:

```ruby
DoSomethingAsyncAt.run!(
  in: 60,
  inputs: { foo: 1, bar: "bar" }
)
```

To run the command at a specific time instead, use `at:` with a Ruby `Time`:

```ruby
DoSomethingAsyncAt.run!(
  at: Time.now + 3600,
  inputs: { foo: 1, bar: "bar" }
)
```

To run the command in the terminal, use a one-liner like this:

```sh
REDIS_URL=redis://localhost:6379 bundle exec ruby -r ./commands -e 'DoSomethingAsyncAt.run!(in: 60, inputs: { foo: 1, bar: "bar" })'
```

#### What happens next

The call makes the job eligible in 60 seconds, which means it is parked somewhere in the waiting area until then. When the time comes, the scheduler moves it onto the `general` queue, and the worker runs your `DoSomething` command.

### Running a command on repeat(cron jobs)

A recurring job repeats on a schedule. You describe the schedule with a cron expression, then register it with `scheduler.cron`. Each entry is a list in this order: **cron expression, command class, inputs(optional), description(optional)**.

```ruby
scheduler.cron([
  ["0 * * * *", DoSomething, { foo: 1, bar: "bar" }, "Hourly task"]
])
```

The above code runs the `DoSomething` command with `foo: 1, bar: "bar"` as inputs at the start of every hour.

The scheduler process needs to run this code, so the simplest place to put this code is in the `commands.rb` file.

**NOTE**:

Every command has a single entry. This means that registering the same command again replaces its earlier entry. You can't have two schedules for one command.

### Starting a scheduler and a worker

Open two seperate terminals in your project folder. In the first terminal, start the scheduler by running the command below.

```sh
REDIS_URL=redis://localhost:6379 bundle exec rake resque:scheduler
```

In the second terminal, start a worker by running the command below:

```sh
REDIS_URL=redis://localhost:6379 QUEUE=general bundle exec rake resque:work
```

#### What you should see (Example output)

The sample output below comes from a different command, `IncrementAge`, from the [Foobara examples](https://github.com/foobara/examples/blob/main/v1_foobara_101/chapter_5_command_connectors/part_6_scheduler_command_connector.out.txt), so the names and inputs will differ for yours, plus timestamps and process details will vary:

```sh
resque-scheduler: [INFO] 2024-12-12T14:47:41-08:00: Starting
resque-scheduler: [INFO] 2024-12-12T14:47:45-08:00: queueing Foobara::CommandConnectors::ResqueConnector::CommandJob (IncrementAge)
*** got: (Job{general} | Foobara::CommandConnectors::ResqueConnector::CommandJob | [{"command_name"=>"IncrementAge", "inputs"=>{"capybara"=>1}}])
*** done: (Job{general} | Foobara::CommandConnectors::ResqueConnector::CommandJob | [{"command_name"=>"IncrementAge", "inputs"=>{"capybara"=>1}}])
```

### Advanced: Choosing the Resque connector

You can skip this until you have more than one Resque connector.

If you leave out `resque_connector:` when creating the scheduler connector, it uses the **unnamed** Resque connector, the one you created without a `name:`. If you've created named connectors, pass the one you want to use when running a given command by using `resque_connector:`. See the `foobara-resque-connector` documentation to learn more about how named connectors work.

## Contributing

Contributions in the form of bug reports, issues or Pull Requests are always welcome at [foobara/resque-scheduler-connector](https://github.com/foobara/resque-scheduler-connector).

To work on an existing issue or submit a Pull Request:

1. Fork the repository and clone it to your local machine
2. Run `bundle install` to install dependencies
3. Start a Redis server and then run `rake` to ensure that everything works as expected before making any changes
4. Implement your changes
5. Restart the server and re-run `rake` to make sure that all tests and Rubocop pass
6. Commit your changes, push to GitHub and open a Pull Request for review

## License

This project is licensed under the MPL-2.0 license. Please see [LICENSE.txt](LICENSE.txt) for more information.
