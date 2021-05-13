# -*- ruby -*-
# frozen_string_literal: true

require_relative 'spec_helper'

require 'rspec'
require 'ant'



RSpec.describe( Ant ) do

	it "knows what the version of the underlying library is" do
		expect( described_class.lib_version ).to match( /ALU\d+\.\d+/ )
	end


	it "raises when initialized with an invalid device number" do
		expect {
			Ant.init( 0xFF )
		}.to raise_error( Errno::EINVAL, /initializing the ant library/i )
	end


	it "exposes relevant constants to Ruby" do
		expect( described_class::EVENT_CLK_ERROR ).to eq( 0x36 )
	end

end

