$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'github_repo'
require 'rspec'
require 'rspec/autorun'

Rspec.configure do |c|
  # c.mock_with :rspec
end

