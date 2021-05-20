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

		
	end


	def get_channel( mode )
		flags = Ant::EXT_PARAM_FREQUENCY_AGILITY
		channel_type = case mode
			when :master
				Ant::PARAMETER_RX_NOT_TX
			when :slave
				Ant::PARAMETER_TX_NOT_RX
			end

		ch = Ant.assign_channel( ANT_DEVICE, channel_type, AMT_NETWORK_PUBLIC, flags )
		

	end

end


if __FILE__ == $0
	Chatter.run( ARGV )
end

