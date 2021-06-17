# -*- ruby -*-
# frozen_string_literal: true

require 'simplecov' if ENV['COVERAGE']

require 'rspec'

require 'ant'
require 'loggability/spechelpers'


### Mock with RSpec
RSpec.configure do |config|
	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	begin
		Ant.close
		Ant.init
		Ant.close
	rescue => err
		config.filter_run_excluding( :hardware )
	end

	config.disable_monkey_patching!
	config.example_status_persistence_file_path = "spec/.status"
	config.filter_run :focus
	config.filter_run_when_matching :focus
	config.order = :random
	config.profile_examples = 5
	config.run_all_when_everything_filtered = true
	config.shared_context_metadata_behavior = :apply_to_host_groups
	# config.warnings = true
end


