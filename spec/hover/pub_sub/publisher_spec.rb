# frozen_string_literal: true

RSpec.describe Hover::PubSub::Publisher, :use_pubsub_emulator do
  let(:topic_name) { 'webhook-send' }
  let(:message) do
    { 'event' => 'event-name', 'record_id' => 123, 'metadata' => 'value' }
  end

  before do
    ::Google::Cloud::PubSub.new(project_id: @pubsub_project_id).create_topic(topic_name)
  end

  describe '.publish' do
    subject(:published_message) do
      described_class.publish(
        project_id: @pubsub_project_id,
        topic_name: topic_name,
        message: message
      )
    end

    it 'sends and returns message' do
      expect(published_message).to be_a Google::Cloud::PubSub::Message

      json = published_message.data
      sent_message = JSON.parse(json)

      expect(sent_message).to eq(message)
    end
  end

  describe '#publish' do
    subject(:published_message) { instance.publish(message) }

    let(:instance) do
      described_class.new(project_id: @pubsub_project_id, topic_name: topic_name)
    end

    it 'sends and returns message' do
      expect(published_message).to be_a Google::Cloud::PubSub::Message

      json = published_message.data
      sent_message = JSON.parse(json)

      expect(sent_message).to eq(message)
    end
  end
end
