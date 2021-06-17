# -*- ruby -*-
# frozen_string_literal: true

require_relative 'spec_helper'

require 'securerandom'
require 'rspec'
require 'ant'



RSpec.describe( Ant ) do

	after( :each ) do
		described_class.close
	end


	it "knows what the version of the underlying library is" do
		expect( described_class.lib_version ).to match( /ALU\d+\.\d+/ )
	end


	it "exposes relevant constants to Ruby" do
		expect( described_class::EVENT_CLK_ERROR ).to eq( 0x36 )
	end


	it "raises when initialized with an invalid serial port", :hardware do
		expect {
			described_class.init( 0xFF )
		}.to raise_error( RuntimeError, /no ant device present/i )
	end


	it "can validate a device number" do
		expect( described_class.validate_device_number(111) ).to eq( 111 )
		expect {
			described_class.validate_device_number( 65540 )
		}.to raise_error( RangeError, /invalid device number/i )
	end


	it "can validate a device type" do
		expect( described_class.validate_device_type(34) ).to eq( 34 )
		expect {
			described_class.validate_device_type( 400 )
		}.to raise_error( RangeError, /invalid device type/i )
	end


	it "can validate a channel period" do
		expect( described_class.validate_channel_period(8192) ).to eq( 8192 )
		expect {
			described_class.validate_channel_period( 70000 )
		}.to raise_error( RangeError, /invalid channel period/i )
	end


	it "can validate an ANT network number" do
		expect( described_class.validate_network_number(0) ).to eq( 0 )
		expect {
			described_class.validate_network_number( 260 )
		}.to raise_error( RangeError, /invalid network number/i )
	end


	it "can validate an ANT network key" do
		valid_key = SecureRandom.bytes( 8 )
		expect( described_class.validate_network_key(valid_key) ).
			to eq( valid_key )

		invalid_key = SecureRandom.bytes( 11 )
		expect {
			described_class.validate_network_key( invalid_key )
		}.to raise_error( RangeError, /invalid network key/i )
	end


	it "can validate an RF frequency value" do
		expect( described_class.validate_rf_frequency(112) ).to eq( 112 )
		expect {
			described_class.validate_rf_frequency( 200 )
		}.to raise_error( RangeError, /invalid rf frequency/i )
	end

end

