# frozen_string_literal: true

RSpec.describe Hover::PubSub::Reader, :use_pubsub_emulator do
  let(:topic_name) { 'webhook-send' }
  let(:subscription_name) { "#{topic_name}-subscription" }
  let(:published_message) do
    Hover::PubSub::Publisher.publish(
      project_id: @pubsub_project_id,
      topic_name: topic_name,
      message: sent_message
    )
  end
  let(:sent_message) do
    {
      'event' => 'event-name',
      'record_id' => 123,
      'metadata' => 'value'
    }
  end
  let(:project) { ::Google::Cloud::PubSub.new(project_id: @pubsub_project_id) }

  before do
    project.create_topic(topic_name).create_subscription(subscription_name)

    published_message
  end

  describe '#read' do
    subject(:read) { instance.read(&message_processing_block) }

    let(:instance) do
      described_class.new(
        project_id: @pubsub_project_id,
        topic_names: [topic_name],
        ack_deadline: 1
      )
    end
    let(:messages) { @messages }

    before do
      @messages = []
    end

    context 'when caller successfully processes message' do
      let(:message_processing_block) do
        lambda do |_topic_name, message|
          @messages << message
          true
        end
      end

      it 'acknowledges message' do
        read

        expect(messages.size).to eq(1)
        expect(messages.first).to eq(sent_message)

        instance.read do |topic_name, message|
          raise "No messages expected got #{message.inspect} on topic #{topic_name}"
        end
      end
    end

    context 'when caller fails to process message' do
      let(:message_processing_block) do
        lambda do |_topic_name, message|
          @messages << message
          false
        end
      end

      it 'leaves message on queue' do
        read

        expect(messages.size).to eq(1)
        expect(messages.first).to eq(sent_message)

        instance.read(&message_processing_block)

        expect(messages.size).to eq(2)
        expect(messages.first).to eq(sent_message)
        expect(messages.last).to eq(sent_message)
      end
    end
  end
end
