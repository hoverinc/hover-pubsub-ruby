# frozen_string_literal: true

require 'json'
require 'google/cloud/pubsub'

module Hover
  module PubSub
    class Publisher
      def self.publish(project_id:, topic_name:, message:)
        new(project_id: project_id, topic_name: topic_name).publish(message)
      end

      def initialize(project_id:, topic_name:)
        @project_id = project_id
        @topic_name = topic_name
      end

      def publish(message)
        if message.is_a?(Hash)
          payload = JSON.generate(message)
          topic.publish(payload)
        elsif message.class.include?(Google::Protobuf::MessageExts)
          payload = message.class.encode(message)
          topic.publish(payload)
        else
          raise "message must be hash or protobuf: #{message.inspect}"
        end
      end

      private

      def topic
        @topic ||= project.topic(@topic_name, skip_lookup: true)
      end

      def project
        @project ||= ::Google::Cloud::PubSub.new(**project_options)
      end

      def project_options
        options = {}
        options[:project_id] = @project_id if @project_id
        options
      end
    end
  end
end
