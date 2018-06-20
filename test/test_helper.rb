$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'lulzscrap'

require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/setup'
require 'vcr'
require 'database_cleaner'
require 'minitest/around/spec'

Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new], ENV, Minitest.backtrace_filter

VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
  config.ignore_localhost = false
end

DatabaseCleaner.strategy = :deletion

module Minitest::Spec::DSL
  def it(name = 'anonymous', &block)
    block ||= proc { skip '(no tests defined)' }

    test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
    raise "#{test_name} is already defined in #{self.name}" if method_defined?(test_name)

    children_classes_with_current_test = children.reject { |c| c.public_method_defined?(test_name) }

    define_method(test_name, &block)

    # Prevent this test to be defined in children classes
    children_classes_with_current_test.each do |class_without_test_method|
      class_without_test_method.send(:undef_method, test_name)
    end

    test_name
  end
end
