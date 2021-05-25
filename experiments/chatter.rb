#!/usr/bin/env ruby

BEGIN {
	$LOAD_PATH.unshift 'lib', '../lib'
}

require 'ant'


class Chatter


	# Use the first ANT device in the system
	ANT_DEVICE = 0

	# Which network to use
	ANT_NETWORK_PUBLIC = 0

	# The ANT device number to use
	DEVICE_NUMBER = 7286

	# The device type used by this program
	DEVICE_TYPE = 1


	def self::run( args )
		mode = args.shift or abort "Usage: #$0 [MODE]"
		case mode
		when 'master'
			return new( :master ).run( args )
		when 'slave'
			return new( :slave ).run( args )
		else
			abort "Invalid mode %p" % [ mode ]
		end
	end


	def initialize( mode )
		@mode = mode
		@channel = nil
	end


	def run( args )
		Ant.init
		@channel = self.open_channel( self.mode )

		self.log.debug "Got an open channel."
	end


	def open_channel( mode )
		flags = Ant::EXT_PARAM_FREQUENCY_AGILITY

		case mode
		when :master
			Ant::PARAMETER_RX_NOT_TX
			ch = Ant.assign_channel( ANT_DEVICE, channel_type, ANT_NETWORK_PUBLIC, flags )
			ch.set_channel_id( DEVICE_NUMBER, ANT_ID_DEVICE_TYPE_PAIRING_FLAG|DEVICE_TYPE, 1 )
		when :slave
			Ant::PARAMETER_TX_NOT_RX
			ch = Ant.assign_channel( ANT_DEVICE, channel_type, ANT_NETWORK_PUBLIC, flags )
			ch.set_channel_id( DEVICE_NUMBER, ANT_ID_DEVICE_TYPE_PAIRING_FLAG, 0 )
		end

		ch.open

		return ch
	end

end


if __FILE__ == $0
	Chatter.run( ARGV )
end

