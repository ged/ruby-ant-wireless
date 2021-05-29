# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'ant' unless defined?( Ant )


# A module that handles response callbacks by logging them.
module Ant::ResponseCallbacks
	extend Loggability

	# Loggability API -- send logs to the Ant logger
	log_to :ant


	# Mapping of response message IDs to handler methods
	HANDLER_METHODS = {
		Ant::Message::MESG_VERSION_ID                   => :on_version,
		Ant::Message::MESG_RESPONSE_EVENT_ID            => :on_response_event,

		Ant::Message::MESG_UNASSIGN_CHANNEL_ID          => :on_unassign_channel,
		Ant::Message::MESG_ASSIGN_CHANNEL_ID            => :on_assign_channel,
		Ant::Message::MESG_CHANNEL_MESG_PERIOD_ID       => :on_channel_mesg_period,
		Ant::Message::MESG_CHANNEL_SEARCH_TIMEOUT_ID    => :on_channel_search_timeout,
		Ant::Message::MESG_CHANNEL_RADIO_FREQ_ID        => :on_channel_radio_freq,
		Ant::Message::MESG_NETWORK_KEY_ID               => :on_network_key,
		Ant::Message::MESG_RADIO_TX_POWER_ID            => :on_radio_tx_power,
		Ant::Message::MESG_RADIO_CW_MODE_ID             => :on_radio_cw_mode,
		Ant::Message::MESG_SYSTEM_RESET_ID              => :on_system_reset,
		Ant::Message::MESG_OPEN_CHANNEL_ID              => :on_open_channel,
		Ant::Message::MESG_CLOSE_CHANNEL_ID             => :on_close_channel,
		Ant::Message::MESG_REQUEST_ID                   => :on_request,

		Ant::Message::MESG_BROADCAST_DATA_ID            => :on_broadcast_data,
		Ant::Message::MESG_ACKNOWLEDGED_DATA_ID         => :on_acknowledged_data,
		Ant::Message::MESG_BURST_DATA_ID                => :on_burst_data,

		Ant::Message::MESG_CHANNEL_ID_ID                => :on_channel_id,
		Ant::Message::MESG_CHANNEL_STATUS_ID            => :on_channel_status,
		Ant::Message::MESG_RADIO_CW_INIT_ID             => :on_radio_cw_init,
		Ant::Message::MESG_CAPABILITIES_ID              => :on_capabilities,

		Ant::Message::MESG_STACKLIMIT_ID                => :on_stacklimit,

		Ant::Message::MESG_SCRIPT_DATA_ID               => :on_script_data,
		Ant::Message::MESG_SCRIPT_CMD_ID                => :on_script_cmd,

		Ant::Message::MESG_ID_LIST_ADD_ID               => :on_id_list_add,
		Ant::Message::MESG_CRYPTO_ID_LIST_ADD_ID        => :on_crypto_id_list_add,
		Ant::Message::MESG_ID_LIST_CONFIG_ID            => :on_id_list_config,
		Ant::Message::MESG_CRYPTO_ID_LIST_CONFIG_ID     => :on_crypto_id_list_config,
		Ant::Message::MESG_OPEN_RX_SCAN_ID              => :on_open_rx_scan,

		Ant::Message::MESG_EXT_CHANNEL_RADIO_FREQ_ID    => :on_ext_channel_radio_freq_id,
		Ant::Message::MESG_EXT_BROADCAST_DATA_ID        => :on_ext_broadcast_data,
		Ant::Message::MESG_EXT_ACKNOWLEDGED_DATA_ID     => :on_ext_acknowledged_data,
		Ant::Message::MESG_EXT_BURST_DATA_ID            => :on_ext_burst_data,

		Ant::Message::MESG_CHANNEL_RADIO_TX_POWER_ID    => :on_channel_radio_tx_power,
		Ant::Message::MESG_GET_SERIAL_NUM_ID            => :on_get_serial_num,
		Ant::Message::MESG_GET_TEMP_CAL_ID              => :on_get_temp_cal,
		Ant::Message::MESG_SET_LP_SEARCH_TIMEOUT_ID     => :on_set_lp_search_timeout,
		Ant::Message::MESG_SET_TX_SEARCH_ON_NEXT_ID     => :on_set_tx_search_on_next,
		Ant::Message::MESG_SERIAL_NUM_SET_CHANNEL_ID_ID => :on_serial_num_set_channel_id,
		Ant::Message::MESG_RX_EXT_MESGS_ENABLE_ID       => :on_rx_ext_mesgs_enable,
		Ant::Message::MESG_RADIO_CONFIG_ALWAYS_ID       => :on_radio_config_always,
		Ant::Message::MESG_ENABLE_LED_FLASH_ID          => :on_enable_led_flash,
		Ant::Message::MESG_XTAL_ENABLE_ID               => :on_xtal_enable,
		Ant::Message::MESG_ANTLIB_CONFIG_ID             => :on_antlib_config,
		Ant::Message::MESG_STARTUP_MESG_ID              => :on_startup_mesg,
		Ant::Message::MESG_AUTO_FREQ_CONFIG_ID          => :on_auto_freq_config,
		Ant::Message::MESG_PROX_SEARCH_CONFIG_ID        => :on_prox_search_config,

		Ant::Message::MESG_ADV_BURST_DATA_ID            => :on_adv_burst_data,
		Ant::Message::MESG_EVENT_BUFFERING_CONFIG_ID    => :on_event_buffering_config,

		Ant::Message::MESG_SET_SEARCH_CH_PRIORITY_ID    => :on_set_search_ch_priority,

		Ant::Message::MESG_HIGH_DUTY_SEARCH_MODE_ID     => :on_high_duty_search_mode,
		Ant::Message::MESG_CONFIG_ADV_BURST_ID          => :on_config_adv_burst,
		Ant::Message::MESG_EVENT_FILTER_CONFIG_ID       => :on_event_filter_config,
		Ant::Message::MESG_SDU_CONFIG_ID                => :on_sdu_config,
		Ant::Message::MESG_SDU_SET_MASK_ID              => :on_sdu_set_mask,
		Ant::Message::MESG_USER_CONFIG_PAGE_ID          => :on_user_config_page,
		Ant::Message::MESG_ENCRYPT_ENABLE_ID            => :on_encrypt_enable,
		Ant::Message::MESG_SET_CRYPTO_KEY_ID            => :on_set_crypto_key,
		Ant::Message::MESG_SET_CRYPTO_INFO_ID           => :on_set_crypto_info,
		Ant::Message::MESG_CUBE_CMD_ID                  => :on_cube_cmd,

		Ant::Message::MESG_ACTIVE_SEARCH_SHARING_ID     => :on_active_search_sharing,
		Ant::Message::MESG_NVM_CRYPTO_KEY_OPS_ID        => :on_nvm_crypto_key_ops,
	}



	### Default callback hook -- handles response callbacks.
	def handle_response_callback( channel_num, message_id, data )
		handler_method = HANDLER_METHODS[ message_id ] or
			raise "Unhandled response message ID %p" % [ message_id ]

		if self.respond_to?( handler_method )
			self.public_send( handler_method, channel_num, data )
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


	### Handle version number response messages.
	def on_version( channel_num, data )
		self.log.info "ANT Version %s" % [ data ]
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


	### Handle event response messages.
	def on_response_event( channel_num, data )
		response_event = data.bytes[ 1 ]
		self.handle_response_callback( channel_num, response_event, data )
	end


	### Handle network key event response messages.
	def on_network_key( channel_num, data )
		self.log_response_event( channel_num, data, "setting network key", "Network key set" )
	end


	### Handle channel assignment event response messages.
	def on_assign_channel( channel_num, data )
		self.log_response_event( channel_num, data, "assigning channel", "Channel assigned." )
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


	### Log a success or an error message for a response event message.
	def log_response_event( channel_num, data, err_desc, log_desc )
		status = data.bytes[ 2 ]
		if status.nonzero?
			self.log.error "Error while %s: %#02x" % [ err_desc, status ]
		else
			self.log.info( log_desc )
		end
	end

end # module Ant::ResponseCallbacks

