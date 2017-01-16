require 'spec_helper'

class MyCoolWorker
  include Sidekiq::Worker
  include Workers::Common

  sidekiq_options queue: :foo
end

# The jid (job id) is always nil during tests, for some reason.
describe Workers::Common do

  describe "#perform" do

    let(:worker) { MyCoolWorker.new }
    let(:job)    {{ some: :thing }}
    let(:log)    {{ job: job }}

    it 'marshals the job' do
      marshaled = Marshal.dump(job)
      expect(Marshal).to receive(:dump).with(job).and_return(marshaled)
      expect(worker).to receive(:run).with(job, log)
      worker.perform(job)
    end

    it "logs 'received' and calls run" do
      expect(worker).to receive(:log).with("received", log)
      expect(worker).to receive(:run).with(job, log)
      worker.perform(job)
    end

    context 'when original_job is nil' do
      let(:job) { nil }
      let(:log) {{ job: {} }}
      it "logs _received and calls run" do
        expect(worker).to receive(:log).with("received", log)
        expect(worker).to receive(:run).with({}, log)
        worker.perform(job)
      end
    end

    context 'on error' do
      let(:worker) { MyCoolWorker.new }

      errors = [StandardError, EOFError, SystemCallError, SocketError]
      errors.each do |error|
        it "for #{error}, logs useful information and reraises error to let sidekiq manage the retries" do
          my_error = error.new("testing plumbing")
          expect(worker).to receive(:run).and_raise(my_error)

          log = {
            event: "received",
            worker: worker.class.to_s,
            jid: nil,
            data: {
              job: job
            }
          }
          expect(Rails.logger).to receive(:info).with(log)

          log_w_exception = {
            event: "error",
            worker: worker.class.to_s,
            jid: nil,
            exception: error.as_json,
            data: {}
          }
          expect(Rails.logger).to receive(:error).with(log_w_exception)

          expect do
            worker.perform(job)
          end.to raise_error(my_error)
        end
      end
    end
  end

  describe "#run" do
    let(:worker) { MyCoolWorker.new }
    it "raises a descriptive error" do
      expect { worker.run }.to raise_error(RuntimeError)
    end
  end

  describe "#log" do
    let(:worker) { MyCoolWorker.new }
    let(:data)   {{ some: :thing }}
    let(:log) {{
      event: "foo",
      worker: worker.class.to_s,
      jid: nil,
      data: data
    }}

    context "only event is passed" do
      let(:data)   {{}}
      it "logs basic stuff" do
        expect(Rails.logger).to receive(:send).with(:info, log)
        worker.log('foo')
      end
    end

    context "when only event and data are provided" do

      it "defaults to level 'info'" do
        expect(Rails.logger).to receive(:send).with(:info, log)
        worker.log('foo', data)
      end
    end

    context "when log level is customized" do
      it "passes them along" do
        expect(Rails.logger).to receive(:send).with(:error, log)
        worker.log('foo', data, :error)
      end
    end

    context "when log level is customized and exception is passed" do
      let(:exception) { StandardError.new("omg!") }

      it "passes them along" do
        expect(Rails.logger).to receive(:send).with(:error, log.merge({exception: exception.as_json}))
        worker.log('foo', data, :error, exception)
      end
    end
  end
end
