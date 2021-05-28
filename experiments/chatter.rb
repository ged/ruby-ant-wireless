#!/usr/bin/env ruby

BEGIN {
	$LOAD_PATH.unshift 'lib', '../lib'
}

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
	end

	attr_reader :mode, :channel


	def run( args )
		Ant.on_response( &self.method(:handle_response_message) )
		Ant.init
		Ant.reset

		Ant.set_network_key( 0, NETWORK_PUBLIC_KEY )
		@channel = self.open_channel( self.mode )

		self.log.debug "Got an open channel."
		@channel.on_event do |channel_num, event_type, data|
			case event_type
			when Ant::EVENT_RX_BURST_PACKET
				$stdout.puts "Got burst data: %p" % [ data ]
			else
				self.log.debug "Unknown channel event: 0x%02x : %p" %
					[ event_type, data ]
			end
		end

		self.start_read_loop
	ensure
		$stderr.puts "Closing ANT down."
		Ant.reset
		Ant.close
		$stderr.puts "ANT closed down."
	end


	def handle_response_message( channel_num, message_id, data )
		case message_id
		when Ant::Message::MESG_RESPONSE_EVENT_ID
			self.handle_response_event( channel_num, data )
		else
			self.log.debug "Response for channel %d: %#0x: %p" % [
				channel_num,
				message_id,
				data
			]
		end
	end


	def handle_response_event( channel_num, data )
		event_type = data.bytes[ 1 ]
		error_code = data.bytes[ 2 ]
		error = error_code.nonzero?

		case event_type
		when Ant::Message::MESG_NETWORK_KEY_ID
			return self.log.error "Error configuring network key: 0x%02x" % [ error ] if error
			self.log.info "Network key set on channel %d." % [ channel_num ]
		when Ant::Message::MESG_ASSIGN_CHANNEL_ID
			return self.log.error "Error assigning channel: 0x%02x" % [ error ] if error
			self.log.info "Channel assigned to channel %d." % [ channel_num ]
		when Ant::Message::MESG_CHANNEL_ID_ID
			return self.log.error "Error setting channel ID: 0x%02x" % [ error ] if error
			self.log.info "Channel id set on channel %d." % [ channel_num ]
		when Ant::Message::MESG_CHANNEL_RADIO_FREQ_ID
			return self.log.error "Error setting radio frequency: 0x%02x" % [ error ] if error
			self.log.info "Channel radio frequency set on channel %d." % [ channel_num ]
		when Ant::Message::MESG_OPEN_CHANNEL_ID
			return self.log.error "Error opening channel: 0x%02x" % [ error ] if error
			self.log.info "Opened channel %d." % [ channel_num ]
		when Ant::Message::MESG_RX_EXT_MESGS_ENABLE_ID
			return self.log.error "Error enabling extended messages: 0x%02x" % [ error ] if error
			self.log.info "Enabled extended messages for channel %d." % [ channel_num ]
		when Ant::Message::MESG_UNASSIGN_CHANNEL_ID
			return self.log.error "Error unassigning channel: 0x%02x" % [ error ] if error
			self.log.info "Unassigned channel %d." % [ channel_num ]
		when Ant::Message::MESG_CLOSE_CHANNEL_ID
			return self.log.error "Error closing channel: 0x%02x" % [ error ] if error
			self.log.info "Closed channel %d." % [ channel_num ]
		when Ant::Message::MESG_REQUEST_ID
			return self.log.error "Requested message not supported by this ANT product: 0x%02x" % [ error ] if error
		when Ant::Message::MESG_BROADCAST_DATA_ID
			return self.log.error "Error sending broadcast: 0x%02x" % [ error ] if error
			self.log.info "Sent broadcast transmission on channel %d." % [ channel_num ]
		when Ant::Message::MESG_ACKNOWLEDGED_DATA_ID
			return self.log.error "Error sending acked message: 0x%02x" % [ error ] if error
			self.log.info "Sent acked data transmission on channel %d." % [ channel_num ]
		when Ant::Message::MESG_BURST_DATA_ID
			return self.log.error "Error sending burst data: 0x%02x" % [ error ] if error
			self.log.info "Sent burst data transmission on channel %d." % [ channel_num ]
		else
			self.log.warn "Unknown response event type 0x%02x" % [ event_type ]
		end
	end


	def start_read_loop
		until self.channel.closed?
			$stderr.print "> "
			data = $stdin.gets

			$stderr.puts "Got data: %p" % [ data ]

			case data
			when /^Q\b/
				$stderr.puts "Closing the channel."
				self.channel.close( 10 )
				$stderr.puts "Ok, I think I closed it (%p) %p." % [ Ant::Channel.registry, self.channel ]
			else
				$stderr.puts "Sending burst data."
				self.channel.send_burst_transfer( data.strip )
			end

			$stderr.puts "Channel is not closed." unless self.channel.closed?
		end

		$stderr.puts "Stopping read loop."
	end


	def open_channel( mode )
		flags = Ant::EXT_PARAM_FREQUENCY_AGILITY

		case mode
		when :master
			channel_type = Ant::PARAMETER_RX_NOT_TX
			ch = Ant.assign_channel( ANT_DEVICE, channel_type, ANT_NETWORK_PUBLIC, flags )
			# ch.set_channel_id( DEVICE_NUMBER, ANT_ID_DEVICE_TYPE_PAIRING_FLAG|DEVICE_TYPE, 1 )
			ch.set_channel_id( DEVICE_NUMBER, DEVICE_TYPE, 1 )
		when :slave
			channel_type = Ant::PARAMETER_TX_NOT_RX
			ch = Ant.assign_channel( ANT_DEVICE, channel_type, ANT_NETWORK_PUBLIC, flags )
			ch.set_channel_id( DEVICE_NUMBER, 0, 0 )
		end

		ch.set_channel_rf_freq( CHANNEL_RF_FREQ )
		ch.open

		return ch
	end

end


if __FILE__ == $0
	Loggability.level = :debug
	Chatter.run( ARGV )
end

