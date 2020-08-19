# frozen_string_literal: true

require 'google/cloud/pubsub'
require 'json'

module Hover
  module PubSub
    class Reader
      def self.subscription_name(topic_name)
        "#{topic_name}-subscription"
      end

      def self.parse_message(message)
        json = message.data
        JSON.parse(json)
      end

      def initialize(project_id:, topic_names:, ack_deadline:)
        @project_id = project_id
        @topic_names = topic_names
        @ack_deadline = ack_deadline
      end

      def read
        for_each_new_message do |topic_name, message|
          parsed_message = self.class.parse_message(message)
          processed_successfully = yield(topic_name, parsed_message).eql?(true)

          delete message if processed_successfully
        end
      end

      private

      def for_each_new_message
        threads = subscriptions.map do |topic_name, subscription|
          Thread.new do
            subscription.pull(immediate: false).each do |message|
              yield(topic_name, message)
            end
          end
        end

        threads.each(&:join)
        threads.map(&:value)
      end

      def delete(message)
        message.acknowledge!
      end

      def subscriptions
        @topic_names.map.with_object({}) do |topic_name, hash|
          project.topic(topic_name, skip_lookup: true)

          hash[topic_name] = subscription(topic_name)
        end
      end

      def subscription(topic_name)
        name = self.class.subscription_name(topic_name)

        project.subscription(name, skip_lookup: true).tap do |subscription|
          subscription.deadline = @ack_deadline
        end
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
