#!/usr/bin/env ruby

BEGIN {
	$LOAD_PATH.unshift 'lib', '../lib'
}

require 'ant'


class Chatter

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
		Ant.init

		@channel = self.get_channel( @mode )
	end


	def run( args )
		@channel.configure_some_shit
	end


	def get_channel( mode )
		case mode
		when :master
			return Ant.assign_channel( 0, Ant::PARAMETER_RX_NOT_TX )
		when :slave
			return Ant.assign_channel( 0, Ant::PARAMETER_TX_NOT_RX )
		end
	end

end


if __FILE__ == $0
	Chatter.run( ARGV )
end

