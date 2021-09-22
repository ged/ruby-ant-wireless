# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require_relative 'ant_ext'


#--
# See ext/ant_ext/ant_ext.c
module Ant
	extend Loggability

	# Package version
	VERSION = '0.2.0'

	# A Range for matching valid ANT device numbers
	VALID_DEVICE_NUMBERS = ( 0...65535 ).freeze

	# A Range for matching valid ANT device types (6 least signficant bits)
	VALID_DEVICE_TYPES = ( 0...127 ).freeze

	# The default range of frequencies for the channel period
	VALID_CHANNEL_PERIODS = ( 0...65535 ).freeze

	# The valid offsets for the "RF Frequency" setting; this is an offset from 2400Hz.
	VALID_RF_FREQUENCIES = ( 0...124 ).freeze


	# Loggability API -- set up a logger for the library
	log_as :ant


	autoload :ResponseCallbacks, 'ant/response_callbacks'
	autoload :DataUtilities, 'ant/mixins'


	# Capabilities hash -- set asynchronously by calling Ant.request_capabilities
	@capabilities = nil
	singleton_class.attr_reader( :capabilities )

	# Serial number -- set asynchronously by calling Ant.request_serial_num
	@serial_num = nil
	singleton_class.attr_reader( :serial_num )

	# Version of ANT supported by the hardware -- set asynchronously by calling
	# Ant.request_version
	@hardware_version = nil
	singleton_class.attr_reader( :hardware_version )

	# Add some convenience aliases
	singleton_class.alias_method( :is_initialized?, :initialized? )


	### Set up the given +object+ as the handler for response callbacks. It must
	### respond to :handle_response_callback.
	def self::set_response_handler( object=Ant::ResponseCallbacks )
		self.on_response( &object.method(:handle_response_callback) )
	end


	### Check that specified +number+ is a valid device number and raise an
	### appropriate exception if it isn't. Returns the number as an Integer if it is
	### valid.
	def self::validate_device_number( number )
		number = Integer( number )
		unless VALID_DEVICE_NUMBERS.include?( number )
			raise RangeError, "invalid device number; expected a number between %d and %d, got %p" %
				[ VALID_DEVICE_NUMBERS.begin, VALID_DEVICE_NUMBERS.end, number ]
		end

		return number
	end


	### Check that specified +number+ is a valid device type and raise an
	### appropriate exception if it isn't. Returns the number as an Integer if it is
	### valid.
	def self::validate_device_type( number )
		number = Integer( number )
		unless VALID_DEVICE_TYPES.include?( number )
			raise RangeError, "invalid device type; expected a number between %d and %d, got %p" %
				[ VALID_DEVICE_TYPES.begin, VALID_DEVICE_TYPES.end, number ]
		end

		return number
	end


	### Check that specified +frequency+ is a valid channel period and raise an
	### appropriate exception if it isn't. Returns the frequency as an Integer if it is
	### valid.
	def self::validate_channel_period( frequency )
		frequency = Integer( frequency )
		unless VALID_CHANNEL_PERIODS.include?( frequency )
			raise RangeError, "invalid channel period; expected a frequency between %d and %d, got %p" %
				[ VALID_CHANNEL_PERIODS.begin, VALID_CHANNEL_PERIODS.end, frequency ]
		end

		return frequency
	end


	### Check that specified +number+ is a valid ANT network number and raise an
	### appropriate exception if it isn't. Note that this does not check
	### the local device(s) to ensure they support the given network. Returns the key
	### as an Integer if it is valid.
	def self::validate_network_number( number )
		number = Integer( number )
		unless number >= 0 && number <= 255
			raise RangeError, "invalid network number; expected an eight-bit number, got %p" %
				[ number ]
		end

		return number
	end


	### Check that specified +data+ is a valid ANT network key and raise an
	### appropriate exception if it isn't. Returns the key itself if it is valid.
	def self::validate_network_key( data )
		data = data.to_s
		unless data.bytesize == 8
			raise RangeError, "invalid network key; expected exactly eight bytes, got %d" %
				[ data.bytesize ]
		end

		self.log.debug "Validated network key: %p" % [ data ]
		return data
	end


	### Check that specified +offset+ is a valid "rf frequency" and raise an
	### appropriate exception if it isn't. Returns the offset as an Integer if it is
	### valid.
	def self::validate_rf_frequency( offset )
		offset = Integer( offset )
		unless VALID_RF_FREQUENCIES.include?( offset )
			raise RangeError, "invalid RF Frequency; expected a offset between %d and %d, got %p" %
				[ VALID_RF_FREQUENCIES.begin, VALID_RF_FREQUENCIES.end, offset ]
		end

		return offset
	end

end # module Ant

