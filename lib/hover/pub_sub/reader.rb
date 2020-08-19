# frozen_string_literal: true

require 'google/cloud/pubsub'
require 'json'

module Hover
  module PubSub
    class Reader
      def self.parse_message(message)
        json = message.data
        JSON.parse(json)
      end

      def initialize(project_id:, subscription_names:, ack_deadline:)
        @project_id = project_id
        @subscription_names = subscription_names
        @ack_deadline = ack_deadline
      end

      def read
        for_each_new_message do |subscription_name, message|
          parsed_message = self.class.parse_message(message)
          processed_successfully = yield(subscription_name, parsed_message).eql?(true)

          delete message if processed_successfully
        end
      end

      private

      def for_each_new_message
        threads = subscriptions.map do |subscription_name, subscription|
          Thread.new do
            subscription.pull(immediate: false).each do |message|
              yield(subscription_name, message)
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
        @subscription_names.map.with_object({}) do |name, hash|
          hash[name] = project.subscription(name, skip_lookup: true).tap do |subscription|
            subscription.deadline = @ack_deadline
          end
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
