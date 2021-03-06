# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'ant' unless defined?( Ant )


class Ant::Channel
	extend Loggability


	# The default network number
	DEFAULT_NETWORK_NUMBER = 0

	# The default channel options
	DEFAULT_EXTENDED_OPTIONS = 0x0


	#
	# Autoloads
	#

	require 'ant/channel/event_callbacks'
	include Ant::Channel::EventCallbacks


	# Loggability API -- log to the Ant logger
	log_to :ant

	# Disallow manual instantiation
	private_class_method :new


	##
	# :singleton-method: registry
	# Channel registry, keyed by channel number.
	singleton_class.attr_reader( :registry )


	######
	public
	######

	alias_method :set_channel_rf_frequency, :set_channel_rf_freq


	### Set up the given +mod+ as the handler module for channel events.
	def set_event_handlers( object=self )
		self.on_event( &object.method(:handle_event_callback) )
	end


	### Return the ANT channel ID if one has been assigned.
	def channel_id
		device_number     = self.device_number or return nil
		device_type       = self.device_type & 0x7f
		pairing_bit       = self.device_type & 0x80
		transmission_type = self.transmission_type

		return "%d/%d/%d%s" % [
			device_number,
			device_type,
			transmission_type,
			pairing_bit.nonzero? ? '+' : '',
		]
	end


	### Return a human-readable description of the channel type.
	def channel_type_description
		case self.channel_type
		when Ant::PARAMETER_RX_NOT_TX
			return :slave
		when Ant::PARAMETER_TX_NOT_RX
			return :master
		when Ant::PARAMETER_SHARED_CHANNEL
			return :shared
		when Ant::PARAMETER_NO_TX_GUARD_BAND
			return :no_tx_guard_band
		when Ant::PARAMETER_ALWAYS_RX_WILD_CARD_SEARCH_ID
			return :always_rx_wild_card_search_id
		when Ant::PARAMETER_RX_ONLY
			return :rx_only
		else
			return nil
		end
	end


	### Returns +true+ if the channel is not closed.
	def open?
		return !self.closed?
	end


	### Return a human-readable version of the object suitable for debugging.
	def inspect
		return "#<%p:%#x %s {%s} #%d @%dMHz on network %d%s>" % [
			self.class,
			self.object_id,
			self.channel_type_description,
			self.channel_id || '-',
			self.channel_number,
			self.rf_frequency + 2400,
			self.network_number,
			self.closed? ? " (closed)" : "",
		]
	end

end # class Ant::Channel


