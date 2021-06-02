# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'ant/channel' unless defined?( Ant::Channel )


# A module that contains logging event callbacks for an ANT::Channel.
#
# Refs:
# * 9.5.6.1 Channel Response / Event (0x40) [ANT Message Protocol and Usage, Rev 5.1]
module Ant::Channel::EventCallbacks
	extend Loggability


	# Loggability API -- send logs to the Ant logger
	log_to :ant


	# Mapping of response message IDs to handler methods
	HANDLER_METHODS = {
		Ant::EVENT_CHANNEL_CLOSED        => :on_event_channel_closed,
		Ant::EVENT_CHANNEL_COLLISION     => :on_event_channel_collision,
		Ant::EVENT_RX_ACKNOWLEDGED       => :on_event_rx_acknowledged,
		Ant::EVENT_RX_BROADCAST          => :on_event_rx_broadcast,
		Ant::EVENT_RX_BURST_PACKET       => :on_event_rx_burst_packet,
		Ant::EVENT_RX_EXT_ACKNOWLEDGED   => :on_event_rx_ext_acknowledged,
		Ant::EVENT_RX_EXT_BROADCAST      => :on_event_rx_ext_broadcast,
		Ant::EVENT_RX_EXT_BURST_PACKET   => :on_event_rx_ext_burst_packet,
		Ant::EVENT_RX_FAIL               => :on_event_rx_fail,
		Ant::EVENT_RX_FAIL_GO_TO_SEARCH  => :on_event_rx_fail_go_to_search,
		Ant::EVENT_RX_FLAG_ACKNOWLEDGED  => :on_event_rx_flag_acknowledged,
		Ant::EVENT_RX_FLAG_BROADCAST     => :on_event_rx_flag_broadcast,
		Ant::EVENT_RX_FLAG_BURST_PACKET  => :on_event_rx_flag_burst_packet,
		Ant::EVENT_RX_SEARCH_TIMEOUT     => :on_event_rx_search_timeout,
		Ant::EVENT_TRANSFER_RX_FAILED    => :on_event_transfer_rx_failed,
		Ant::EVENT_TRANSFER_TX_COMPLETED => :on_event_transfer_tx_completed,
		Ant::EVENT_TRANSFER_TX_FAILED    => :on_event_transfer_tx_failed,
		Ant::EVENT_TRANSFER_TX_START     => :on_event_transfer_tx_start,
		Ant::EVENT_TX                    => :on_event_tx,
	}

	# The mask of the channel number in buffer data
	CHANNEL_NUMBER_MASK = 0x1F

	# The mask of the sequence number in buffer data
	SEQUENCE_NUMBER_MASK = 0xE0


	### Default callback hook -- handles event callbacks.
	def handle_event_callback( channel_num, event_id, data )
		handler_method = HANDLER_METHODS[ event_id ] or
			raise "Unhandled channel event %p" % [ event_id ]

		if self.respond_to?( handler_method )
			self.public_send( handler_method, channel_num, data )
		else
			Ant::Channel::EventCallbacks.log_event_callback( channel_num, handler_method, event_id, data )
		end
	end


	### Log the channel event by default.
	def self::log_event_callback( channel_num, handler_method, event_id, data )
		self.log.debug "Event on channel %d: %#0x (%s): %s" % [
			channel_num,
			event_id,
			handler_method,
			data.bytes[ 0..3 ].map {|b| "%#02x" % b }.join( ' ' )
		]
	end


	### Handle an TX event.
	def on_event_tx( channel_num, data )
		self.log.info "Broadcast message on channel %d was transmitted." % [ channel_num ]
	end


	### Handle a RX_SEARCH_TIMEOUT event.
	def on_event_rx_search_timeout( channel_num, * )
		self.log.warn "Search timeout on channel %d." % [ channel_num ]
	end


	### Handle a RX_FAIL event.
	def on_event_rx_fail( channel_num, * )
		self.log.warn "Receive failed on channel %d." % [ channel_num ]
	end


	### Handle a TRANSFER_RX_FAILED event.
	def on_event_transfer_rx_failed( channel_num, * )
		self.log.warn "Receive failed on channel %d." % [ channel_num ]
	end


	### Handle a TRANSFER_TX_COMPLETED event.
	def on_event_transfer_tx_completed( channel_num, * )
		self.log.warn "Transfer completed on channel %d." % [ channel_num ]
	end


	### Handle a TRANSFER_TX_FAILED event.
	def on_event_transfer_tx_failed( channel_num, * )
		self.log.warn "Transfer failed on channel %d." % [ channel_num ]
	end


	### Handle a CHANNEL_CLOSED event.
	def on_event_channel_closed( channel_num, * )
		self.log.warn "Channel %d was closed." % [ channel_num ]
	end


	### Handle a RX_FAIL_GO_TO_SEARCH event.
	def on_event_rx_fail_go_to_search( channel_num, * )
		self.log.warn "Channel %d dropped; resume search." % [ channel_num ]
	end


	### Handle a CHANNEL_COLLISION event.
	def on_event_channel_collision( channel_num, * )
		self.log.warn "Channel collision on channel %d." % [ channel_num ]
	end


	### Handle a TRANSFER_TX_START event.
	def on_event_transfer_tx_start( channel_num, * )
		self.log.warn "Burst transfer started on channel %d." % [ channel_num ]
	end


	# def on_event_rx_flag_acknowledged( channel_num, data )
	#
	# end
	# def on_event_rx_flag_burst_packet( channel_num, data )
	#
	# end
	# def on_event_rx_flag_broadcast( channel_num, data )
	#
	# end
	# def on_event_rx_acknowledged( channel_num, data )
	#
	# end
	def on_event_rx_burst_packet( channel_num, data )
		channel = (data.bytes[0] & CHANNEL_NUMBER_MASK) >> 5
		sequence_num = data.bytes[0] & SEQUENCE_NUMBER_MASK

		self.log.info "Burst (0x%02x): Rx: %d [%p]" % [ channel, sequence_num, data[1..9] ]
	end

	def on_event_rx_broadcast( channel_num, data )
		self.log.info "Broadcast: Rx: %d" % [ data.bytes[0] ]
	end
	# def on_event_rx_ext_acknowledged( channel_num, data )
	#
	# end
	# def on_event_rx_ext_burst_packet( channel_num, data )
	#
	# end
	# def on_event_rx_ext_broadcast( channel_num, data )
	#
	# end

end # module Ant::Channel::EventCallbacks
