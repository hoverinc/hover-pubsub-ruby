# Hover::Pubsub::Ruby

This gem provides a simple wrapper around the [Google Cloud PubSub gem](https://github.com/googleapis/google-cloud-ruby/tree/master/google-cloud-pubsub).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hover-pubsub-ruby', git: 'hoverinc/hover-pubsub-ruby'
```

And then execute:

    $ bundle install

## Usage

### Conventions

- Subscription names follow the format `"#{topic_name}_subscription"`
- Messages are hashes
- Message hashes are encoded to JSON for transport and decoded back to hashes when reading

### Receiving Messages

```ruby
reader = Hover::PubSub::Reader.new(
  project_id: ENV['GCP_PUBSUB_PROJECT_ID'],
  topic_names: ['list', 'of', 'topic', 'names'],
  ack_deadline: 30
)

reader.read |topic_name, message|
  process(message)
end
```

A `Reader` instance has a `#read` instance method that takes a block. The block is responsible for processing each message. If the block returns true, processing is considered successful and the message is acknowledged and deleted. If the block returns false the message goes back to the queue for another reader to attempt processing again. 

When the `#read` method is called a thread is created for each topic. And all topics are read from concurrently. It is safe to have more than one reader reading at the same time. With that you scale up the number of active readers are the number of messages needing to be processed grows.

`#read` does not yield the [received message](https://googleapis.dev/ruby/google-cloud-pubsub/latest/Google/Cloud/PubSub/ReceivedMessage.html) objects to your block. It assumes your messages are JSON strings and decodes them and returns the decoded object. 

`Reader` assumes your subscription names follow the pattern `"#{topic_name}-subscription"`.


### Publishing Messages

```ruby

Hover::PubSub::Publisher.publish(
  project_id: ENV['GCP_PUBSUB_PROJECT_ID'],
  topic_name: 'topic-name',
  message: {event: "sales_opportunity-state-changed", id: 123, state: 'sold'}
)
```

You can call `.publish` or instantiate an instance and call `#publish` for each message. The sent [message](https://googleapis.dev/ruby/google-cloud-pubsub/latest/Google/Cloud/PubSub/Message.html) is returned. 


## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bundle exec bin/console` for an interactive prompt that will allow you to experiment.

To release a new version:

- Update the version number in `version.rb`
- Make a PR with your changes and the version number increment
- After the PR is merged, make the new release https://github.com/hoverinc/hover-pubsub-ruby/releases

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hoverinc/hover-pubsub-ruby.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
