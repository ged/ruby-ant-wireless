# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'ant' unless defined?( Ant )
require 'ant/bitvector'


# A module that handles response callbacks by logging them.
module Ant::ResponseCallbacks
	extend Loggability

	# Loggability API -- send logs to the Ant logger
	log_to :ant


	# Mapping of response message IDs to handler methods
	HANDLER_METHODS = {
		Ant::Message::MESG_STARTUP_MESG_ID              => :on_startup_mesg,

		Ant::Message::MESG_CAPABILITIES_ID              => :on_capabilities,
		Ant::Message::MESG_CHANNEL_STATUS_ID            => :on_channel_status,
		Ant::Message::MESG_VERSION_ID                   => :on_version,
		Ant::Message::MESG_CHANNEL_ID_ID                => :on_channel_id,
		Ant::Message::MESG_EVENT_BUFFERING_CONFIG_ID    => :on_event_buffering_config,
		Ant::Message::MESG_GET_SERIAL_NUM_ID            => :on_get_serial_num,

		Ant::Message::MESG_RESPONSE_EVENT_ID            => :on_response_event,

		Ant::Message::MESG_NETWORK_KEY_ID               => :on_network_key,
		Ant::Message::MESG_ASSIGN_CHANNEL_ID            => :on_assign_channel,
		Ant::Message::MESG_UNASSIGN_CHANNEL_ID          => :on_unassign_channel,
		Ant::Message::MESG_CHANNEL_RADIO_FREQ_ID        => :on_channel_radio_freq,
		Ant::Message::MESG_OPEN_CHANNEL_ID              => :on_open_channel,

		Ant::Message::MESG_RX_EXT_MESGS_ENABLE_ID       => :on_rx_ext_mesgs_enable,
		Ant::Message::MESG_CLOSE_CHANNEL_ID             => :on_close_channel,
		Ant::Message::MESG_REQUEST_ID                   => :on_request,

		Ant::Message::MESG_BROADCAST_DATA_ID            => :on_broadcast_data,
		Ant::Message::MESG_ACKNOWLEDGED_DATA_ID         => :on_acknowledged_data,
		Ant::Message::MESG_BURST_DATA_ID                => :on_burst_data,
		Ant::Message::MESG_ADV_BURST_DATA_ID            => :on_adv_burst_data,

		Ant::Message::MESG_CHANNEL_MESG_PERIOD_ID       => :on_channel_mesg_period,
		Ant::Message::MESG_CHANNEL_SEARCH_TIMEOUT_ID    => :on_channel_search_timeout,

		Ant::Message::MESG_RADIO_TX_POWER_ID            => :on_radio_tx_power,

		Ant::Message::MESG_AUTO_FREQ_CONFIG_ID          => :on_auto_freq_config,

		# :TODO: There are many other MESG_ constants, but I think most or all of
		# them are for the serial protocol.
	}



	### Default callback hook -- handles response callbacks.
	def self::handle_response_callback( channel_num, message_id, data )
		handler_method = Ant::ResponseCallbacks::HANDLER_METHODS[ message_id ] or
			raise "Unhandled response message ID %p" % [ message_id ]

		if self.respond_to?( handler_method, true )
			self.send( handler_method, channel_num, data )
		else
			Ant::ResponseCallbacks.log_response_callback( channel_num, handler_method, message_id, data )
		end
	end


	### Log the response event by default.
	def self::log_response_callback( channel_num, handler_method, message_id, data )
		self.log.debug "Response for channel %d: %#0x (%s): %s" % [
			channel_num,
			message_id,
			handler_method,
			data.bytes[ 0..3 ].map {|b| "%#02x" % b }.join( ' ' )
		]
	end


	###############
	module_function
	###############

	### Handle version number response messages.
	def on_version( channel_num, data )
		version = data.strip
		self.log.info "ANT Version %s" % [ version ]
		Ant.instance_variable_set( :@hardware_version, version )
	end


	### Handle event response messages.
	def on_response_event( channel_num, data )
		response_event = data.bytes[ 1 ]
		self.handle_response_callback( channel_num, response_event, data )
	end


	### Log a success or an error message for a response event message.
	def log_response_event( channel_num, data, err_desc, log_desc )
		status = data.bytes[ 2 ]
		channel = Ant::Channel.registry[ channel_num ]

		if status.nonzero?
			self.log.error "Error while %s on %p: %#02x" % [ err_desc, channel, status ]
		else
			self.log.info( log_desc )
		end
	end


	### Handle startup response messages.
	def on_startup_mesg( channel_num, data )
		reason = case data.bytes[ 0 ]
			when Ant::RESET_POR
				"RESET_POR"
			when Ant::RESET_SUSPEND
				"RESET_SUSPEND "
			when Ant::RESET_SYNC
				"RESET_SYNC "
			when Ant::RESET_CMD
				"RESET_CMD "
			when Ant::RESET_WDT
				"RESET_WDT "
			when Ant::RESET_RST
				"RESET_RST "
			else
				"UNKNOWN REASON"
			end

		self.log.info "Reset complete: %s" % [ reason ]
	end


	### Handle network key event response messages.
	def on_network_key( channel_num, data )
		self.log_response_event( channel_num, data, "setting network key", "Network key set" )
	end


	### Handle channel assignment event response messages.
	def on_assign_channel( channel_num, data )
		self.log_response_event( channel_num, data, "assigning channel",
			"Channel %d assigned." % [channel_num] )
	end


	### Handle channel unassignment event response messages.
	def on_unassign_channel( channel_num, data )
		self.log_response_event( channel_num, data, "unassigning channel",
			"Channel %d unassigned." % [channel_num] )
	end


	### Handle channel ID event response messages.
	def on_channel_id( channel_num, data )
		self.log_response_event( channel_num, data, "setting channel ID", "Channel ID set." )
	end


	### Handle redio frequency event response messages.
	def on_channel_radio_freq( channel_num, data )
		self.log_response_event( channel_num, data, "setting channel radio frequency",
			"Channel radio frequency set." )
	end


	### Handle channel open event response messages.
	def on_open_channel( channel_num, data )
		self.log_response_event( channel_num, data, "opening channel", "Channel opened." )
	end


	### Handle channel close event response messages.
	def on_close_channel( channel_num, data )
		self.log_response_event( channel_num, data, "closing channel", "Channel closed." )
	end


	### Handle channel_mesg_period response events.
	def on_channel_mesg_period( channel_num, data )
		self.log_response_event( channel_num, data, "setting channel period", "Channel period assigned." )
	end


	### Handle channel_search_timeout response event.
	def on_channel_search_timeout( channel_num, data )
		self.log_response_event( channel_num, data, "setting search timeout", "Search timeout." )
	end


	### Handle radio_tx_power response event.
	def on_radio_tx_power( channel_num, data )
		self.log_response_event( channel_num, data, "setting transmit power", "Transmit power changed." )
	end


	### Handle broadcast_data response event.
	def on_broadcast_data( channel_num, data )
		self.log_response_event( channel_num, data, "sending broadcast data", "Sent broadcast data." )
	end


	### Handle acknowledged_data response event.
	def on_acknowledged_data( channel_num, data )
		self.log_response_event( channel_num, data, "sending acked data", "Acked data sent." )
	end


	### Handle burst_data response event.
	def on_burst_data( channel_num, data )
		self.log_response_event( channel_num, data, "sending burst data", "Burst data sent." )
	end


	### Handle channel_status response event.
	def on_channel_status( channel_num, data )
		self.log_response_event( channel_num, data, "requesting channel status", "Got channel status." )
	end


	### Handle on_rx_ext_mesgs_enable response event.
	def on_rx_ext_mesgs_enable( channel_num, data )
		self.log_response_event( channel_num, data, "enabling extended message: not supported",
			"Enabled extended messages." )
	end


	### Handle on_rx_ext_mesgs_enable response event.
	def on_auto_freq_config( channel_num, data )
		self.log_response_event( channel_num, data, "enabling frequency agility",
			"Enabled frequency agility." )
	end


	### Handle capabilities response event.
	def on_capabilities( channel_num, data )
		std_opts  = Ant::BitVector.new( data.bytes[2] )
        adv_opts  = Ant::BitVector.new( data.bytes[3] )
        adv_opts2 = Ant::BitVector.new( data.bytes[4] )
        adv_opts3 = Ant::BitVector.new( data.bytes[6] )
        adv_opts4 = Ant::BitVector.new( data.bytes[7] )

		caps = {
			max_channels: data.bytes[0],
			max_networks: data.bytes[1],
			max_sensrcore_channels: data.bytes[5],

			rx_channels_enabled: std_opts.off?( Ant::CAPABILITIES_NO_RX_CHANNELS ),
			tx_channels_enabled: std_opts.off?( Ant::CAPABILITIES_NO_TX_CHANNELS ),
			rx_messages_enabled: std_opts.off?( Ant::CAPABILITIES_NO_RX_MESSAGES ),
			tx_messages_enabled: std_opts.off?( Ant::CAPABILITIES_NO_TX_MESSAGES ),
			ackd_messages_enabled: std_opts.off?( Ant::CAPABILITIES_NO_ACKD_MESSAGES ),
			burst_transfer_enabled: std_opts.off?( Ant::CAPABILITIES_NO_BURST_TRANSFER ),

			overun_underrun: adv_opts.on?( Ant::CAPABILITIES_OVERUN_UNDERRUN ),
			network_enabled: adv_opts.on?( Ant::CAPABILITIES_NETWORK_ENABLED ),
			api_version2: adv_opts.on?( Ant::CAPABILITIES_AP1_VERSION_2 ),
			serial_number_enabled: adv_opts.on?( Ant::CAPABILITIES_SERIAL_NUMBER_ENABLED ),
			per_channel_tx_power_enabled: adv_opts.on?( Ant::CAPABILITIES_PER_CHANNEL_TX_POWER_ENABLED ),
			low_priority_search_enabled: adv_opts.on?( Ant::CAPABILITIES_LOW_PRIORITY_SEARCH_ENABLED ),
			script_enabled: adv_opts.on?( Ant::CAPABILITIES_SCRIPT_ENABLED ),
			search_list_enabled: adv_opts.on?( Ant::CAPABILITIES_SEARCH_LIST_ENABLED ),

			led_enabled: adv_opts2.on?( Ant::CAPABILITIES_LED_ENABLED ),
			ext_message_enabled: adv_opts2.on?( Ant::CAPABILITIES_EXT_MESSAGE_ENABLED ),
			scan_mode_enabled: adv_opts2.on?( Ant::CAPABILITIES_SCAN_MODE_ENABLED ),
			prox_search_enabled: adv_opts2.on?( Ant::CAPABILITIES_PROX_SEARCH_ENABLED ),
			ext_assign_enabled: adv_opts2.on?( Ant::CAPABILITIES_EXT_ASSIGN_ENABLED ),
			antfs_enabled: adv_opts2.on?( Ant::CAPABILITIES_FS_ANTFS_ENABLED ),
			fit1_enabled: adv_opts2.on?( Ant::CAPABILITIES_FIT1_ENABLED ),

			advanced_burst_enabled: adv_opts3.on?( Ant::CAPABILITIES_ADVANCED_BURST_ENABLED ),
			event_buffering_enabled: adv_opts3.on?( Ant::CAPABILITIES_EVENT_BUFFERING_ENABLED ),
			event_filtering_enabled: adv_opts3.on?( Ant::CAPABILITIES_EVENT_FILTERING_ENABLED ),
			high_duty_search_mode_enabled: adv_opts3.on?( Ant::CAPABILITIES_HIGH_DUTY_SEARCH_MODE_ENABLED ),
			active_search_sharing_mode_enabled: adv_opts3.on?( Ant::CAPABILITIES_ACTIVE_SEARCH_SHARING_MODE_ENABLED ),
			selective_data_update_enabled: adv_opts3.on?( Ant::CAPABILITIES_SELECTIVE_DATA_UPDATE_ENABLED ),
			encrypted_channel_enabled: adv_opts3.on?( Ant::CAPABILITIES_ENCRYPTED_CHANNEL_ENABLED ),

			rfactive_notification_enabled: adv_opts4.on?( Ant::CAPABILITIES_RFACTIVE_NOTIFICATION_ENABLED ),
		}.freeze

		caplist = caps.keys.select do |cap|
			caps[ cap ]
		end
		self.log.info "ANT Capabilities: %s" % [ caplist.sort.join(' ') ]

		Ant.instance_variable_set( :@capabilities, caps );
	end


	### Handle serial number response event.
	def on_get_serial_num( channel_num, data )
		serial = data.unpack1( 'L<' )

		self.log.debug "ANT device serial number: %d." % [ serial ]
		Ant.instance_variable_set( :@serial_num, serial )
	end


	### Handle request response event.
	def on_request( channel_num, data )
		self.log_response_event( channel_num, data, "requesting an unsupported message", "[n/a]" )
	end

end # module Ant::ResponseCallbacks

