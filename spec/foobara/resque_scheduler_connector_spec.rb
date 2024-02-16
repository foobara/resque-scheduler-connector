RSpec.describe Foobara::ResqueSchedulerConnector do
  let(:command_class) do
    stub_module "SomeOrg" do
      foobara_organization!
    end
    stub_module "SomeOrg::SomeDomain" do
      foobara_domain!
    end
    stub_class "SomeOrg::SomeDomain::DoSomething", Foobara::Command do
      description "do something!"

      inputs do
        foo :integer
        bar :string
      end
    end
  end
  let(:sub_command_class) do
    stub_class "DoSomethingElse", command_class do
      description "do something else"
    end
  end
  let(:resque_command_connector) { Foobara::CommandConnectors::ResqueConnector.new }
  let(:resque_scheduler_command_connector) { Foobara::CommandConnectors::ResqueSchedulerConnector.new }

  before do
    stub_const "SPEC_RESULTS", {}

    command_class
    resque_command_connector.connect(SomeOrg)
    resque_scheduler_command_connector.connect(SomeOrg)
    # Forcing it to be transformed to test more code paths
    resque_command_connector.connect(sub_command_class)
    resque_scheduler_command_connector.connect(sub_command_class)
  end

  after do
    Foobara.reset_alls
    described_class.reset_all
  end

  it "connects commands" do
    expect(resque_command_connector.command_registry.all_transformed_command_classes.map(&:full_command_name)).to eq(
      [
        "SomeOrg::SomeDomain::DoSomething",
        "DoSomethingElse"
      ]
    )
    expect(
      resque_scheduler_command_connector.command_registry.all_transformed_command_classes.map(&:full_command_name)
    ).to eq(
      [
        "SomeOrg::SomeDomain::DoSomething",
        "DoSomethingElse"
      ]
    )
  end

  describe ".cron" do
    context "when scheduling a recurring command job" do
      let(:crontab) do
        [
          #    Minute (0-59)
          #    | Hour (0-23)
          #    | | Day-of-Month (1-31)
          #    | | | Month (1-12)
          #    | | | | Day-of-Week (0-6)
          #    | | | | | Timezone
          #    | | | | | |   Command, Inputs
          ["*/25 * * * *  ", SomeOrg::SomeDomain::DoSomething, { foo: 1, bar: "bar" }],
          [" */5 * * * *  ", DoSomethingElse, { foo: 2, bar: "baz" }]
        ]
      end

      # Flexing more paths through the code for coverage by giving a connector name.
      let(:resque_command_connector) { Foobara::CommandConnectors::ResqueConnector.new(name: "foo") }
      let(:resque_scheduler_command_connector) do
        Foobara::CommandConnectors::ResqueSchedulerConnector.new(resque_connector: resque_command_connector)
      end

      before do
        resque_scheduler_command_connector.cron(crontab)
      end

      it "schedules the expected jobs" do
        expect(Resque.schedule).to eq(
          "SomeOrg::SomeDomain::DoSomething": {
            "cron" => "*/25 * * * *  ",
            "class" => "Foobara::CommandConnectors::ResqueConnector::CommandJob",
            "queue" => "general",
            "args" => {
              "command_name" => "SomeOrg::SomeDomain::DoSomething",
              "connector_name" => "foo",
              "inputs" => {
                "foo" => 1, "bar" => "bar"
              }
            },
            "description" => "do something!"
          },
          DoSomethingElse: {
            "cron" => " */5 * * * *  ",
            "class" => "Foobara::CommandConnectors::ResqueConnector::CommandJob",
            "queue" => "general",
            "args" => {
              "command_name" => "DoSomethingElse",
              "connector_name" => "foo",
              "inputs" => {
                "foo" => 2, "bar" => "baz"
              }
            },
            "description" => "do something else"
          }
        )
      end
    end
  end
end
