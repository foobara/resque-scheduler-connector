RSpec.describe Foobara::CommandConnectors::ResqueSchedulerConnector::Commands::RunCommandAsyncAt do
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

      def execute
        SPEC_RESULTS[bar] = foo
      end
    end
  end
  let(:resque_command_connector) { Foobara::CommandConnectors::ResqueConnector.new }
  let(:resque_scheduler_command_connector) { Foobara::CommandConnectors::ResqueSchedulerConnector.new }

  before do
    stub_const "SPEC_RESULTS", {}
    resque_command_connector.connect(command_class)
    resque_scheduler_command_connector.connect(command_class, inputs_transformers: proc { |x| x })
  end

  after do
    Foobara.reset_alls
    Foobara::ResqueSchedulerConnector.reset_all
  end

  describe ".run" do
    let(:inputs) { { foo: 1, bar: "bar" } }
    let(:command) do
      async_inputs = { inputs: }
      async_inputs[:in] = self.in if self.in
      async_inputs[:at] = at if at

      SomeOrg::SomeDomain::DoSomethingAsyncAt.new(async_inputs)
    end
    let(:outcome) { command.run }
    let(:in) { nil }
    let(:at) { nil }

    context "when using in" do
      let(:in) { 1 }

      it "gives a working AsyncAt command" do
        expect {
          expect(outcome).to be_success
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
          expect(Resque::Failure.all).to be_nil
        }.to change { SPEC_RESULTS["bar"] }.from(nil).to(1)

        expect(Resque::Failure.count).to be(0)
        expect(Resque.size(:general)).to be(0)
      end
    end

    context "when using at" do
      let(:at) { Time.now + 1 }

      it "gives a working AsyncAt command" do
        expect {
          expect(outcome).to be_success
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
          expect(Resque::Failure.all).to be_nil
        }.to change { SPEC_RESULTS["bar"] }.from(nil).to(1)

        expect(Resque::Failure.count).to be(0)
        expect(Resque.size(:general)).to be(0)
      end
    end

    context "when using both in and at" do
      let(:in) { 1 }
      let(:at) { Time.now + 1 }

      it "is not successful" do
        expect(outcome).to_not be_success

        expect(outcome.errors.size).to be(1)
        error = outcome.errors.first

        expect(error.key).to eq("data.both_in_and_at_provided")
        expect(error.path).to eq([])
        expect(error.message).to eq("cannot specify both in and at")
        expect(error.context).to eq(in:, at:)
      end
    end

    context "when not providing in or at" do
      it "is not successful" do
        expect(outcome).to_not be_success

        expect(outcome.errors.size).to be(1)
        error = outcome.errors.first

        expect(error.key).to eq("data.no_in_or_at_provided")
        expect(error.path).to eq([])
        expect(error.message).to eq("must provide either in or at")
        expect(error.context).to eq({})
      end
    end
  end
end
