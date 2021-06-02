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


	#
	# Handlers
	#

	### Handle version number response messages.
	def on_version( channel_num, data )
		self.log.info "ANT Version %s" % [ data ]
	end


	### Handle event response messages.
	def on_response_event( channel_num, data )
		response_event = data.bytes[ 1 ]
		self.handle_response_callback( channel_num, response_event, data )
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
		self.log_response_event( channel_num, data, "assigning channel", "Channel assigned." )
	end


	### Handle channel unassignment event response messages.
	def on_unassign_channel
		self.log_response_event( channel_num, data, "unassigning channel", "Channel unassigned." )
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


	### 
	def on_channel_mesg_period( channel_num, data )
		self.log_response_event( channel_num, data, "channel_mesg_period", "Channel assigned." )
	end


	### Handle channel_search_timeout response event.
	def on_channel_search_timeout( channel_num, data )
		self.log_response_event( channel_num, data, "channel_search_timeout", "Channel assigned." )
	end


	### Handle radio_tx_power response event.
	def on_radio_tx_power( channel_num, data )
		self.log_response_event( channel_num, data, "radio_tx_power", "Channel assigned." )
	end


	### Handle radio_cw_mode response event.
	def on_radio_cw_mode( channel_num, data )
		self.log_response_event( channel_num, data, "radio_cw_mode", "Channel assigned." )
	end


	### Handle system_reset response event.
	def on_system_reset( channel_num, data )
		self.log_response_event( channel_num, data, "system_reset", "Channel assigned." )
	end


	### Handle request response event.
	def on_request( channel_num, data )
		self.log_response_event( channel_num, data, "request", "Channel assigned." )
	end


	### Handle broadcast_data response event.
	def on_broadcast_data( channel_num, data )
		self.log_response_event( channel_num, data, "broadcast_data", "Channel assigned." )
	end


	### Handle acknowledged_data response event.
	def on_acknowledged_data( channel_num, data )
		self.log_response_event( channel_num, data, "acknowledged_data", "Channel assigned." )
	end


	### Handle burst_data response event.
	def on_burst_data( channel_num, data )
		self.log_response_event( channel_num, data, "burst_data", "Channel assigned." )
	end


	### Handle channel_status response event.
	def on_channel_status( channel_num, data )
		self.log_response_event( channel_num, data, "channel_status", "Channel assigned." )
	end


	### Handle radio_cw_init response event.
	def on_radio_cw_init( channel_num, data )
		self.log_response_event( channel_num, data, "radio_cw_init", "Channel assigned." )
	end


	### Handle capabilities response event.
	def on_capabilities( channel_num, data )
		self.log_response_event( channel_num, data, "capabilities", "Channel assigned." )
	end


	### Handle stacklimit response event.
	def on_stacklimit( channel_num, data )
		self.log_response_event( channel_num, data, "stacklimit", "Channel assigned." )
	end


	### Handle script_data response event.
	def on_script_data( channel_num, data )
		self.log_response_event( channel_num, data, "script_data", "Channel assigned." )
	end


	### Handle script_cmd response event.
	def on_script_cmd( channel_num, data )
		self.log_response_event( channel_num, data, "script_cmd", "Channel assigned." )
	end


	### Handle id_list_add response event.
	def on_id_list_add( channel_num, data )
		self.log_response_event( channel_num, data, "id_list_add", "Channel assigned." )
	end


	### Handle crypto_id_list_add response event.
	def on_crypto_id_list_add( channel_num, data )
		self.log_response_event( channel_num, data, "crypto_id_list_add", "Channel assigned." )
	end


	### Handle id_list_config response event.
	def on_id_list_config( channel_num, data )
		self.log_response_event( channel_num, data, "id_list_config", "Channel assigned." )
	end


	### Handle crypto_id_list_config response event.
	def on_crypto_id_list_config( channel_num, data )
		self.log_response_event( channel_num, data, "crypto_id_list_config", "Channel assigned." )
	end


	### Handle open_rx_scan response event.
	def on_open_rx_scan( channel_num, data )
		self.log_response_event( channel_num, data, "open_rx_scan", "Channel assigned." )
	end


	### Handle ext_channel_radio_freq_id response event.
	def on_ext_channel_radio_freq_id( channel_num, data )
		self.log_response_event( channel_num, data, "ext_channel_radio_freq_id", "Channel assigned." )
	end


	### Handle ext_broadcast_data response event.
	def on_ext_broadcast_data( channel_num, data )
		self.log_response_event( channel_num, data, "ext_broadcast_data", "Channel assigned." )
	end


	### Handle ext_acknowledged_data response event.
	def on_ext_acknowledged_data( channel_num, data )
		self.log_response_event( channel_num, data, "ext_acknowledged_data", "Channel assigned." )
	end


	### Handle ext_burst_data response event.
	def on_ext_burst_data( channel_num, data )
		self.log_response_event( channel_num, data, "ext_burst_data", "Channel assigned." )
	end


	### Handle channel_radio_tx_power response event.
	def on_channel_radio_tx_power( channel_num, data )
		self.log_response_event( channel_num, data, "channel_radio_tx_power", "Channel assigned." )
	end


	### Handle get_serial_num response event.
	def on_get_serial_num( channel_num, data )
		self.log_response_event( channel_num, data, "get_serial_num", "Channel assigned." )
	end


	### Handle get_temp_cal response event.
	def on_get_temp_cal( channel_num, data )
		self.log_response_event( channel_num, data, "get_temp_cal", "Channel assigned." )
	end


	### Handle set_lp_search_timeout response event.
	def on_set_lp_search_timeout( channel_num, data )
		self.log_response_event( channel_num, data, "set_lp_search_timeout", "Channel assigned." )
	end


	### Handle set_tx_search_on_next response event.
	def on_set_tx_search_on_next( channel_num, data )
		self.log_response_event( channel_num, data, "set_tx_search_on_next", "Channel assigned." )
	end


	### Handle serial_num_set_channel_id response event.
	def on_serial_num_set_channel_id( channel_num, data )
		self.log_response_event( channel_num, data, "serial_num_set_channel_id", "Channel assigned." )
	end


	### Handle rx_ext_mesgs_enable response event.
	def on_rx_ext_mesgs_enable( channel_num, data )
		self.log_response_event( channel_num, data, "rx_ext_mesgs_enable", "Channel assigned." )
	end


	### Handle radio_config_always response event.
	def on_radio_config_always( channel_num, data )
		self.log_response_event( channel_num, data, "radio_config_always", "Channel assigned." )
	end


	### Handle enable_led_flash response event.
	def on_enable_led_flash( channel_num, data )
		self.log_response_event( channel_num, data, "enable_led_flash", "Channel assigned." )
	end


	### Handle xtal_enable response event.
	def on_xtal_enable( channel_num, data )
		self.log_response_event( channel_num, data, "xtal_enable", "Channel assigned." )
	end


	### Handle antlib_config response event.
	def on_antlib_config( channel_num, data )
		self.log_response_event( channel_num, data, "antlib_config", "Channel assigned." )
	end


	### Handle auto_freq_config response event.
	def on_auto_freq_config( channel_num, data )
		self.log_response_event( channel_num, data, "auto_freq_config", "Channel assigned." )
	end


	### Handle prox_search_config response event.
	def on_prox_search_config( channel_num, data )
		self.log_response_event( channel_num, data, "prox_search_config", "Channel assigned." )
	end


	### Handle adv_burst_data response event.
	def on_adv_burst_data( channel_num, data )
		self.log_response_event( channel_num, data, "adv_burst_data", "Channel assigned." )
	end


	### Handle event_buffering_config response event.
	def on_event_buffering_config( channel_num, data )
		self.log_response_event( channel_num, data, "event_buffering_config", "Channel assigned." )
	end


	### Handle set_search_ch_priority response event.
	def on_set_search_ch_priority( channel_num, data )
		self.log_response_event( channel_num, data, "set_search_ch_priority", "Channel assigned." )
	end


	### Handle high_duty_search_mode response event.
	def on_high_duty_search_mode( channel_num, data )
		self.log_response_event( channel_num, data, "high_duty_search_mode", "Channel assigned." )
	end


	### Handle config_adv_burst response event.
	def on_config_adv_burst( channel_num, data )
		self.log_response_event( channel_num, data, "config_adv_burst", "Channel assigned." )
	end


	### Handle event_filter_config response event.
	def on_event_filter_config( channel_num, data )
		self.log_response_event( channel_num, data, "event_filter_config", "Channel assigned." )
	end


	### Handle sdu_config response event.
	def on_sdu_config( channel_num, data )
		self.log_response_event( channel_num, data, "sdu_config", "Channel assigned." )
	end


	### Handle sdu_set_mask response event.
	def on_sdu_set_mask( channel_num, data )
		self.log_response_event( channel_num, data, "sdu_set_mask", "Channel assigned." )
	end


	### Handle user_config_page response event.
	def on_user_config_page( channel_num, data )
		self.log_response_event( channel_num, data, "user_config_page", "Channel assigned." )
	end


	### Handle encrypt_enable response event.
	def on_encrypt_enable( channel_num, data )
		self.log_response_event( channel_num, data, "encrypt_enable", "Channel assigned." )
	end


	### Handle set_crypto_key response event.
	def on_set_crypto_key( channel_num, data )
		self.log_response_event( channel_num, data, "set_crypto_key", "Channel assigned." )
	end


	### Handle set_crypto_info response event.
	def on_set_crypto_info( channel_num, data )
		self.log_response_event( channel_num, data, "set_crypto_info", "Channel assigned." )
	end


	### Handle cube_cmd response event.
	def on_cube_cmd( channel_num, data )
		self.log_response_event( channel_num, data, "cube_cmd", "Channel assigned." )
	end


	### Handle active_search_sharing response event.
	def on_active_search_sharing( channel_num, data )
		self.log_response_event( channel_num, data, "active_search_sharing", "Channel assigned." )
	end


	### Handle nvm_crypto_key_ops response event.
	def on_nvm_crypto_key_ops( channel_num, data )
		self.log_response_event( channel_num, data, "nvm_crypto_key_ops", "Channel assigned." )
	end


end # module Ant::ResponseCallbacks

