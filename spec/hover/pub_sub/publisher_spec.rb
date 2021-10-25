# frozen_string_literal: true

require_relative '../dummy_pb.rb'

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

    context 'message is a hash' do
      it 'sends and returns message as JSON' do
        expect(published_message).to be_a Google::Cloud::PubSub::Message

        json = published_message.data
        sent_message = JSON.parse(json)

        expect(sent_message).to eq(message)
      end
    end

    context 'message is a protobuf object' do
      let(:message) do
        Dummy.new(foo: 'bar')
      end

      it 'sends and returns message as protobuf object' do
        expect(published_message).to be_a Google::Cloud::PubSub::Message

        send_message = Dummy.decode(published_message.data)
        expect(send_message).to eq(message)
      end
    end

    context 'message is a string' do
      let(:message) { 'foo ' }

      it 'raises an exception' do
        expect {
          published_message
        }.to raise_error(/message must be hash or protobuf/)
      end
    end
  end

  describe '#publish' do
    subject(:published_message) { instance.publish(message) }

    let(:instance) do
      described_class.new(project_id: @pubsub_project_id, topic_name: topic_name)
    end

    context 'message is a hash' do
      it 'sends and returns message as JSON' do
        expect(published_message).to be_a Google::Cloud::PubSub::Message

        json = published_message.data
        sent_message = JSON.parse(json)

        expect(sent_message).to eq(message)
      end
    end

    context 'message is a protobuf object' do
      let(:message) do
        Dummy.new(foo: 'bar')
      end

      it 'sends and returns message as protobuf object' do
        expect(published_message).to be_a Google::Cloud::PubSub::Message

        send_message = Dummy.decode(published_message.data)
        expect(send_message).to eq(message)
      end
    end

    context 'message is a string' do
      let(:message) { 'foo ' }

      it 'raises an exception' do
        expect {
          published_message
        }.to raise_error(/message must be hash or protobuf/)
      end
    end
  end
end
