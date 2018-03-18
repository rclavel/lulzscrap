# Lulzscrap

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'tor_manager', github: 'rclavel/tor-manager'
gem 'lulzscrap', github: 'rclavel/lulzscrap'
```

And then execute:

    $ bundle

## Usage

Create the tables:
```ruby
create_table :queued_requests do |t|
  t.string :code
  t.string :status
  t.integer :results
  t.text :errors_by_ip, default: '{}'
  t.timestamps
end

create_table :scraped_data do |t|
  # All your specific data to scrap
  # t.string :external_id
  # t.string :name
  t.timestamps
end
```

You can extend the `ScrapedData` model with your specific code:
```ruby
# app/models/scraped_data.rb
class ScrapedData < Lulzscrap::ScrapedData
  # ...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/lulzscrap. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lulzscrap project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/lulzscrap/blob/master/CODE_OF_CONDUCT.md).
