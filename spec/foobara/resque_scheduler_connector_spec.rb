RSpec.describe Foobara::ResqueSchedulerConnector do
  let(:command_class) do
    stub_module "SomeOrg" do
      foobara_organization!
    end
    stub_module "SomeOrg::SomeDomain" do
      foobara_domain!
    end
    stub_class "SomeOrg::SomeDomain::DoSomething", Foobara::Command do
      inputs do
        foo :integer
        bar :string
      end

      def execute
        SPEC_RESULTS[bar] = foo
      end
    end
  end
  let(:sub_command_class) { stub_class "DoSomethingElse", command_class }
  let(:resque_command_connector) { Foobara::CommandConnectors::ResqueConnector.new }
  let(:resque_scheduler_command_connector) { Foobara::CommandConnectors::ResqueSchedulerConnector.new }

  before do
    stub_const "SPEC_RESULTS", {}
  end

  after do
    described_class.reset_all
  end

  it "has a version number" do
    expect(Foobara::ResqueSchedulerConnector::VERSION).to_not be_nil
  end

  describe ".connect" do
    before do
      resque_command_connector.connect(command_class)
      resque_scheduler_command_connector.connect(command_class)
      resque_command_connector.connect(sub_command_class)
      resque_scheduler_command_connector.connect(sub_command_class)
    end

    let(:schedule1) do
      {
        "SomeOrg::SomeDomain::DoSomething": {
          cron: "*/5 * * * *"
        }
      }
    end

    let(:schedule2) do
      {
        DoSomethingElse: {
          cron: "*/25 * * * *"
        }
      }
    end

    it "gives a working AsyncAt command" do
      inputs = { foo: 1, bar: "bar" }
      command = SomeOrg::SomeDomain::DoSomethingAsyncAt.new(in: 1, inputs:)

      expect {
        command.run!
      }.to change(Resque, :delayed_queue_schedule_size).from(0).to(1)

      expect {
        Resque.enqueue_delayed_selection { true }
      }.to change { Resque.size(:general) }.from(0).to(1)

      job = Resque.peek(:general, 0, 1)

      expect(job["class"]).to eq("Foobara::CommandConnectors::ResqueConnector::CommandJob")

      args = job["args"].first
      command_name = args["command_name"]
      inputs = args["inputs"]

      expect(command_name).to eq("SomeOrg::SomeDomain::DoSomething")
      expect(inputs).to eq("foo" => 1, "bar" => "bar")

      worker = Resque::Worker.new(:general)

      expect {
        expect(worker.work_one_job).to be(true)
      }.to change { SPEC_RESULTS["bar"] }.from(nil).to(1)

      expect(Resque::Failure.count).to be(0)
      expect(Resque.size(:general)).to be(0)
    end
  end
end
