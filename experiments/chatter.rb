#!/usr/bin/env ruby

BEGIN {
	$LOAD_PATH.unshift 'lib', '../lib'
}

require 'tty-prompt'
require 'loggability'
require 'ant'


class Chatter
	extend Loggability

	log_to :ant


	# Use the first ANT device in the system
	ANT_DEVICE = 0

	# Which network to use
	ANT_NETWORK_PUBLIC = 0

	# The ANT device number to use
	DEVICE_NUMBER = 49

	# The channel frequency to set
	CHANNEL_RF_FREQ = 35

	# The device type used by this program
	DEVICE_TYPE = 1

	# The public network key
	NETWORK_PUBLIC_KEY = "\x00" * 8


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
		@prompt = TTY::Prompt.new
	end

	attr_reader :mode, :channel


	def run( args )
		self.set_signal_handlers
		Ant.set_response_handlers
		Ant.init( ANT_DEVICE )
		self.log.info "Using a %s (%s)" % Ant.device_usb_info( ANT_DEVICE )
		Ant.reset

		Ant.set_network_key( 0, NETWORK_PUBLIC_KEY )
		@channel = self.open_channel( self.mode )
		self.start_read_loop
	ensure
		$stdin.close

		$stderr.puts "Closing ANT down."
		Ant.reset
		Ant.close
		$stderr.puts "ANT closed down."
	end


	def start_read_loop
		until self.channel.closed?
			$stderr.print "> "
			data = $stdin.gets

			$stderr.puts "Got data: %p" % [ data ]

			case data
			when /^Q\b/
				$stderr.puts "Closing the channel."
				begin
					self.channel.close( 10 )
				rescue
					# Channel might have already closed itself
				end
				$stderr.puts "Ok, I think I closed it (%p) %p." % [ Ant::Channel.registry, self.channel ]
			when /^A\b/
				$stderr.puts "Sending acked data."
				self.channel.send_acknowledged_data( "some data" )
			else
				$stderr.puts "Sending burst data."
				self.channel.send_burst_transfer( data.strip ) if data
			end

			$stderr.puts "Channel is not closed." unless self.channel.closed?
		end

		$stderr.puts "Stopping read loop."
	end


	def open_channel( mode )
		flags = 0
		# flags = Ant::EXT_PARAM_FREQUENCY_AGILITY

		case mode
		when :master
			channel_type = Ant::PARAMETER_TX_NOT_RX
			ch = Ant.assign_channel( ANT_DEVICE, channel_type, ANT_NETWORK_PUBLIC, flags )
			# ch.set_channel_id( DEVICE_NUMBER, ANT_ID_DEVICE_TYPE_PAIRING_FLAG|DEVICE_TYPE, 1 )
			ch.set_channel_id( DEVICE_NUMBER, DEVICE_TYPE, 1 )
		when :slave
			channel_type = Ant::PARAMETER_RX_NOT_TX
			ch = Ant.assign_channel( ANT_DEVICE, channel_type, ANT_NETWORK_PUBLIC, flags )
			ch.set_channel_id( 0, 0, 0 )
		end

		ch.set_event_handlers
		ch.set_channel_rf_freq( CHANNEL_RF_FREQ )
		ch.open
		Ant.use_extended_messages = true

		return ch
	end


	def set_signal_handlers
		Signal.trap( :INT ) { }
	end

end


if __FILE__ == $0
	Loggability.level = :debug
	Chatter.run( ARGV )
end

