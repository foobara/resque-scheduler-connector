# Foobara::ResqueSchedulerConnector

`foobara-resque-scheduler-connector` adds delayed and recurring scheduling for Foobara commands via the
`resque-scheduler` gem.

## Installation

Add `gem "foobara-resque-scheduler-connector"` to your Gemfile or .gemspec file and run `bundle install`.

Or run `gem install foobara-resque-scheduler-connector` if playing with it directly in the scripts.

## Usage

To set this up automatically in an existing Foobara project, run:

```sh
foob g resque-scheduler-connector
```

For a complete working example, including instructions for running it, see the
[scheduler connector example](https://github.com/foobara/examples/blob/main/v1_foobara_101/chapter_5_command_connectors/part_6_scheduler_command_connector.rb).

### Advanced: Using Multiple Resque Connectors

If you use multiple Resque connectors, specify which one the scheduler should use with `resque_connector:`:

```ruby
scheduler = Foobara::CommandConnectors::ResqueSchedulerConnector.new(
  resque_connector: resque_connector
)
```

Here, `resque_connector` is an existing Resque connector in your project.

If you omit this option, the scheduler uses the unnamed Resque connector, the one you created without a `name:`.

For more information about named connectors, refer to the `foobara-resque-connector` documentation.

## Contributing

Contributions are welcome on Github at [foobara/resque-scheduler-connector](https://github.com/foobara/resque-scheduler-connector)

To work on an existing issue or submit a Pull Request:

1. Fork the repository and clone it to your local machine
2. Run `bundle install` to install dependencies
3. Start a Redis server and then run `rake` to ensure that everything works as expected before making any changes
4. Implement your changes
5. Restart the server and re-run `rake` to make sure that all tests and RuboCop pass
6. Commit your changes, push to GitHub and open a Pull Request for review

## License

This project is licensed under the MPL-2.0 license. Please see [LICENSE.txt](LICENSE.txt) for more information.