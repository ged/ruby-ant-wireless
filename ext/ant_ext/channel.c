/*
 *  channel.c - Ant::Channel class
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "ant_ext.h"

#define DEFAULT_ADV_PACKETS 3
#define ADVANCED_BURST_TIMEOUT 5

VALUE rant_cAntChannel;

VALUE rant_mAntDataUtilities;

static void rant_channel_free( void * );
static void rant_channel_mark( void * );


static const rb_data_type_t rant_channel_datatype_t = {
	.wrap_struct_name = "Ant::Channel",
	.function = {
		.dmark = rant_channel_mark,
		.dfree = rant_channel_free,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};



/*
 * Free function
 */
static void
rant_channel_free( void *ptr )
{
	if ( ptr ) {
		rant_channel_t *channel = (rant_channel_t *)ptr;
		ANT_AssignChannelEventFunction( channel->channel_num, NULL, NULL );
		ANT_UnAssignChannel( channel->channel_num );

		channel->callback = Qnil;

		xfree( ptr );
		ptr = NULL;
	}
}


/*
 * Mark function
 */
static void
rant_channel_mark( void *ptr )
{
	rant_channel_t *channel = (rant_channel_t *)ptr;
	rb_gc_mark( channel->callback );
}


/*
 * Alloc function
 */
static VALUE
rant_channel_alloc( VALUE klass )
{
	rant_channel_t *ptr;

	VALUE rval = TypedData_Make_Struct( klass, rant_channel_t, &rant_channel_datatype_t, ptr );
	ptr->callback = Qnil;

	return rval;
}



/*
 * Fetch the data pointer and check it for sanity.
 */
rant_channel_t *
rant_get_channel( VALUE self )
{
	rant_channel_t *ptr;

	if ( !IsChannel(self) ) {
		rb_raise( rb_eTypeError, "wrong argument type %s (expected Ant::Channel)",
			rb_class2name(CLASS_OF( self )) );
	}

	ptr = DATA_PTR( self );
	assert( ptr );

	return ptr;
}


/*
 * Clear the registry after channel have been reset.
 */
void
rant_channel_clear_registry()
{
	VALUE registry = rb_iv_get( rant_cAntChannel, "@registry" );
	rb_hash_clear( registry );
}



/*
 * call-seq:
 *    channel.initialize
 *
 * Set up the channel.
 *
 */
static VALUE
rant_channel_init( VALUE self, VALUE channel_number, VALUE channel_type, VALUE network_number,
	VALUE extended_options )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE registry = rb_iv_get( rant_cAntChannel, "@registry" );

	ptr->channel_num = NUM2USHORT( channel_number );
	MEMZERO( ptr->buffer, unsigned char, MESG_MAX_SIZE );

	rb_iv_set( self, "@channel_type", channel_type );
	rb_iv_set( self, "@network_number", network_number );
	rb_iv_set( self, "@extended_options", extended_options );

	rb_iv_set( self, "@device_type", Qnil );
	rb_iv_set( self, "@device_number", Qnil );
	rb_iv_set( self, "@transmission_type", Qnil );
	rb_iv_set( self, "@rf_frequency", Qnil );
	rb_iv_set( self, "@agility_frequencies", Qnil );

	rb_hash_aset( registry, channel_number, self );

	return self;
}


/*
 * call-seq:
 *    channel.channel_number   -> integer
 *
 * Return the channel number assigned to the Channel.
 *
 */
static VALUE
rant_channel_channel_number( VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );

	return INT2FIX( ptr->channel_num );
}


/*
 * call-seq:
 *    channel.set_channel_id( device_number, device_type, transmission_type, timeout=0 )
 *
 * Set the channel ID using the combination of the +device_number+,
 * +device_type+, and +transmission_type+. If the assignment hasn't been set in
 * +timeout+ seconds, aborts and returns +nil+.
 *
 */
static VALUE
rant_channel_set_channel_id( int argc, VALUE *argv, VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE device_number, device_type, transmission_type, timeout;
	unsigned short usDeviceNumber;
	unsigned char ucDeviceType,
		ucTransmissionType;
	unsigned int ulResponseTime = 0;
	bool result;

	rb_scan_args( argc, argv, "31", &device_number, &device_type, &transmission_type, &timeout );

	usDeviceNumber = NUM2USHORT( device_number );
	ucDeviceType = NUM2CHR( device_type );
	ucTransmissionType = NUM2CHR( transmission_type );

	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	result = ANT_SetChannelId_RTO( ptr->channel_num, usDeviceNumber, ucDeviceType,
		ucTransmissionType, ulResponseTime );

	if ( !result ) {
		rb_raise( rb_eRuntimeError, "Failed to set the channel id." );
	}

	rb_iv_set( self, "@device_type", device_type );
	rb_iv_set( self, "@device_number", device_number );
	rb_iv_set( self, "@transmission_type", transmission_type );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.set_channel_period( period, timeout=0 )
 *
 * This message configures the messaging +period+ of a specific channel where:
 * Messaging period = channel period time +period+ * 32768.
 *
 * E.g.: To send or receive a message at 4Hz, set the channel period to 8192 (32768/4).
 *
 * Note: The minimum acceptable channel period is difficult to specify as it is
 * system dependent and depends on the number of configured channels and their use.
 * Caution should be used to appropriately test the system when high data rates are
 * used, especially in combination with multiple channels.
 *
 */
static VALUE
rant_channel_set_channel_period( int argc, VALUE *argv, VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE period, timeout;
	unsigned int ulResponseTime = 0;
	unsigned short usMesgPeriod;
	bool result;

	rb_scan_args( argc, argv, "11", &period, &timeout );

	usMesgPeriod = NUM2USHORT( period );
	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	result = ANT_SetChannelPeriod_RTO( ptr->channel_num, usMesgPeriod, ulResponseTime );

	if ( !result )
		rb_raise( rb_eRuntimeError, "Failed to set the channel period." );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.set_channel_search_timeout( search_timeout, timeout=0 )
 *
 * Configure the length of time that the receiver will search for a channel
 * before timing out. Note that a value of zero will disable high priority
 * search mode, and a value of 255 sets an infinite search time-out. The
 * exception to this is the AP1 module, which has only a high priority search
 * mode. For AP1 only, a value of 0 is an immediate search timeout, and a value
 * of 255 corresponds to approximately 10.5 minutes.
 *
 */
static VALUE
rant_channel_set_channel_search_timeout( int argc, VALUE *argv, VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE search_timeout, timeout;
	unsigned int ulResponseTime = 0;
	unsigned char ucSearchTimeout;
	bool result;

	rb_scan_args( argc, argv, "11", &search_timeout, &timeout );

	ucSearchTimeout = NUM2CHR( search_timeout );
	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	result = ANT_SetChannelSearchTimeout_RTO( ptr->channel_num, ucSearchTimeout, ulResponseTime );

	if ( !result )
		rb_raise( rb_eRuntimeError, "Failed to set the channel search timeout." );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.set_channel_rf_freq( frequency )
 *
 * Set the ANT RF +frequency+.
 *
 */
static VALUE
rant_channel_set_channel_rf_freq( VALUE self, VALUE frequency )
{
	rant_channel_t *ptr = rant_get_channel( self );
	unsigned short ucRFFreq = NUM2USHORT( frequency );

	if ( ucRFFreq > 124 ) {
		rb_raise( rb_eArgError, "frequency must be between 0 and 124." );
	}

	ANT_SetChannelRFFreq( ptr->channel_num, ucRFFreq );

	rb_iv_set( self, "@rf_frequency", frequency );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.set_frequency_agility( freq1, freq2, freq3 )
 *
 * Set the frequencies to use in frequency agility (integers between 0 and 124). These values
 * use the same convention as the +rf_frequency+ setting; i.e., they're offsets from 2400 MHz.
 *
 */
static VALUE
rant_channel_set_frequency_agility( VALUE self, VALUE freq1, VALUE freq2, VALUE freq3 )
{
	rant_channel_t *ptr = rant_get_channel( self );
	unsigned char ucFreq1 = NUM2CHR( freq1 ),
		ucFreq2 = NUM2CHR( freq2 ),
		ucFreq3 = NUM2CHR( freq3 );
	VALUE frequencies = rb_ary_new_from_args( 3, freq1, freq2, freq3 );

	if ( ucFreq1 > 124 || ucFreq2 > 124 || ucFreq3 > 124 ) {
		rb_raise( rb_eArgError, "frequencies must be between 0 and 124." );
	}

	rant_log_obj( self, "info",
		"Configuring channel %d to use frequency agility on %d, %d, and %d MHz.",
		ptr->channel_num, ucFreq1 + 2400, ucFreq2 + 2400, ucFreq3 + 2400 );
	ANT_ConfigFrequencyAgility( ptr->channel_num, ucFreq1, ucFreq2, ucFreq3 );

	rb_ary_freeze( frequencies );
	rb_iv_set( self, "@agility_frequencies", frequencies );

	return Qtrue;
}




/*
 * call-seq:
 *    channel.open( tineout=0 )
 *
 * Open the channel. If it hasn't completed within +timeout+ seconds, raises a RuntimeError.
 */
static VALUE
rant_channel_open( int argc, VALUE *argv, VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE timeout;
	unsigned int ulResponseTime = 0;

	rb_scan_args( argc, argv, "01", &timeout );

	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	if ( !ANT_OpenChannel_RTO( ptr->channel_num, ulResponseTime ) ) {
		rb_raise( rb_eRuntimeError, "Failed to open the channel." );
	}

	return Qtrue;
}


/*
 * call-seq:
 *    channel.close
 *
 * Close the channel and remove it from the registry.
 *
 */
static VALUE
rant_channel_close( int argc, VALUE *argv, VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE timeout;
	VALUE registry = rb_iv_get( rant_cAntChannel, "@registry" );
	unsigned int ulResponseTime = 0;

	rb_scan_args( argc, argv, "01", &timeout );

	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	rant_log_obj( self, "info", "Closing channel %d (with timeout %d).", ptr->channel_num, ulResponseTime );
	if ( !ANT_CloseChannel_RTO( ptr->channel_num, ulResponseTime ) ) {
		rb_raise( rb_eRuntimeError, "Failed to close the channel." );
	}
	rant_log_obj( self, "info", "Channel %d closed.", ptr->channel_num );

	rb_hash_delete( registry, INT2FIX( ptr->channel_num ) );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.closed?   -> true or false
 *
 * Returns +true+ if the channel has been closed; i.e., if it's not longer the
 * registered channel for its channel number.
 *
 */
static VALUE
rant_channel_closed_p( VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE registry = rb_iv_get( rant_cAntChannel, "@registry" );
	VALUE channel = rb_hash_lookup( registry, INT2FIX( ptr->channel_num ) );

	return self == channel ? Qfalse : Qtrue;
}


/*
 * Event callback functions
 */

struct on_event_call {
	unsigned char ucANTChannel;
	unsigned char ucEvent;
};


/*
 * Handle the event callback -- Ruby side.
 */
static VALUE
rant_channel_call_event_callback( VALUE callPtr )
{
	struct on_event_call *call = (struct on_event_call *)callPtr;
	VALUE registry = rb_iv_get( rant_cAntChannel, "@registry" );
	VALUE channel = rb_hash_fetch( registry, INT2FIX(call->ucANTChannel) );
	rant_channel_t *ptr = rant_get_channel( channel );
	VALUE rb_callback = ptr->callback;
	VALUE rval = Qnil;

	if ( RTEST(rb_callback) ) {
		VALUE args[3];

		args[0] = INT2FIX( call->ucANTChannel );
		args[1] = INT2FIX( call->ucEvent );
		args[2] = rb_enc_str_new( (char *)ptr->buffer, MESG_MAX_SIZE, rb_ascii8bit_encoding() );

		rval = rb_funcallv_public( rb_callback, rb_intern("call"), 3, args );
	}

	MEMZERO( ptr->buffer, unsigned char, MESG_MAX_SIZE );

	return rval;
}


/*
 * Handle the event callback -- C side.
 */
static BOOL
rant_channel_on_event_callback( unsigned char ucANTChannel, unsigned char ucEvent )
{
	rant_callback_t callback;
	struct on_event_call call;

	call.ucANTChannel = ucANTChannel;
	call.ucEvent = ucEvent;

	callback.data = &call;
	callback.fn = rant_channel_call_event_callback;

	return rant_callback( &callback );
}


/*
 * call-seq:
 *    channel.on_event {|channel_num, event_id, data| ... }
 *
 * Set up a callback for events on the receiving channel.
 *
 */
static VALUE
rant_channel_on_event( int argc, VALUE *argv, VALUE self )
{
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE callback = Qnil;

	rb_scan_args( argc, argv, "0&", &callback );

	if ( !RTEST(callback) ) {
		rb_raise( rb_eLocalJumpError, "block required, but not given" );
	}

	rant_log_obj( self, "debug", "Channel event callback is: %s", RSTRING_PTR(rb_inspect(callback)) );
	ptr->callback = callback;

	ANT_AssignChannelEventFunction( ptr->channel_num, rant_channel_on_event_callback, ptr->buffer );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.send_burst_transfer( data )
 *
 * Send the given +data+ as one or more burst packets.
 *
 */
static VALUE
rant_channel_send_burst_transfer( VALUE self, VALUE data )
{
	rant_channel_t *ptr = rant_get_channel( self );
	unsigned char *data_s;
	long data_len = RSTRING_LEN( data );
	unsigned short usNumDataPackets = data_len / 8,
		remainingBytes = data_len % 8;

	data_s = ALLOC_N( unsigned char, data_len );
	strncpy( (char *)data_s, StringValuePtr(data), data_len );

	// Pad it to 8-byte alignment
	if ( remainingBytes ) {
		int pad_bytes = (8 - remainingBytes);
		REALLOC_N( data_s, unsigned char, data_len + pad_bytes );
		memset( data_s + data_len, 0, pad_bytes );

		usNumDataPackets += 1;
	}

	VALUE data_string = rb_enc_str_new( (char *)data_s, usNumDataPackets * 8, rb_ascii8bit_encoding() );
	VALUE hexdump = rb_funcall( rant_mAntDataUtilities, rb_intern("hexdump"), 1, data_string );

	rant_log_obj( self, "debug", "Sending burst packets:\n%s", RSTRING_PTR(hexdump) );
	if ( !ANT_SendBurstTransfer(ptr->channel_num, data_s, usNumDataPackets) ) {
		rb_raise( rb_eRuntimeError, "failed to send burst transfer." );
	}

	return Qtrue;
}


/*
 * call-seq:
 *    channel.send_acknowledged_data( data )
 *
 * Send the given +data+ as an acknowledged transmission. The +data+ cannot be longer
 * than 8 bytes in length.
 *
 */
static VALUE
rant_channel_send_acknowledged_data( VALUE self, VALUE data )
{
	rant_channel_t *ptr = rant_get_channel( self );
	UCHAR aucTempBuffer[] = {0, 0, 0, 0, 0, 0, 0, 0};

	StringValue( data );
	if ( RSTRING_LEN(data) > 8 ) {
		rb_raise( rb_eArgError, "Data can't be longer than 8 bytes." );
	}
	strncpy( (char *)aucTempBuffer, StringValuePtr(data), RSTRING_LEN(data) );

	ANT_SendAcknowledgedData( ptr->channel_num, aucTempBuffer );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.send_broadcast_data( data )
 *
 * Send the given +data+ as a broadcast transmission. The +data+ cannot be longer
 * than 8 bytes in length.
 *
 */
static VALUE
rant_channel_send_broadcast_data( VALUE self, VALUE data )
{
	rant_channel_t *ptr = rant_get_channel( self );
	UCHAR aucTempBuffer[8] = {0, 0, 0, 0, 0, 0, 0, 0,};

	StringValue( data );
	if ( RSTRING_LEN(data) > 8 ) {
		rb_raise( rb_eArgError, "Data can't be longer than 8 bytes." );
	}
	strncpy( (char *)aucTempBuffer, StringValuePtr(data), RSTRING_LEN(data) );

	ANT_SendBroadcastData( ptr->channel_num, aucTempBuffer );

	return Qtrue;
}


/*
 * call-seq:
 *    channel.send_advanced_transfer( data, packets_per_message=3 )
 *
 * Send the given +data+ as one or more advanced burst packets. The +packets_per_message+
 * may be set to a value between 1 and 3 to control how many 8-byte packets are send with
 * each message.
 *
 */
static VALUE
rant_channel_send_advanced_transfer( int argc, VALUE *argv, VALUE self )
{
#ifdef HAVE_ANT_SENDADVANCEDBURST
	rant_channel_t *ptr = rant_get_channel( self );
	VALUE data = Qnil, packets = Qnil;
	unsigned char *data_s;
	long data_len;
	unsigned short usNumDataPackets, remainingBytes;
	unsigned char ucStdPcktsPerSerialMsg = DEFAULT_ADV_PACKETS;

	rb_scan_args( argc, argv, "11", &data, &packets );
	data_len = RSTRING_LEN( data );
	usNumDataPackets = data_len / 8;
	remainingBytes = data_len % 8;
	if ( RTEST(packets) ) {
		ucStdPcktsPerSerialMsg = NUM2CHR(packets);
	}

	data_s = ALLOC_N( unsigned char, data_len );
	strncpy( (char *)data_s, StringValuePtr(data), data_len );

	// Pad it to 8-byte alignment
	if ( remainingBytes ) {
		int pad_bytes = (8 - remainingBytes);
		REALLOC_N( data_s, unsigned char, data_len + pad_bytes );
		memset( data_s + data_len, 0, pad_bytes );

		usNumDataPackets += 1;
	}

	rant_log_obj( self, "warn", "Sending advanced burst packets (%d-byte messages): %s",
		ucStdPcktsPerSerialMsg * 8, data_s );
	if ( !ANT_SendAdvancedBurst_RTO(ptr->channel_num, data_s, usNumDataPackets,
		ucStdPcktsPerSerialMsg, ADVANCED_BURST_TIMEOUT) )
	{
		rant_log_obj( self, "error", "failed to send advanced burst transfer." );
	}

	return Qtrue;
#else
	rb_notimplement();
#endif
}


void
init_ant_channel()
{
#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rant_mAnt = rb_define_module( "Ant" );
#endif

	/*
	 * Document-module: Ant::Channel
	 *
	 * An assigned ANT channel object.
	 *
	 */
	rant_cAntChannel = rb_define_class_under( rant_mAnt, "Channel", rb_cObject );
	rb_iv_set( rant_cAntChannel, "@registry", rb_hash_new() );

	rant_mAntDataUtilities = rb_define_module_under( rant_mAnt, "DataUtilities" );

	rb_define_alloc_func( rant_cAntChannel, rant_channel_alloc );
	rb_define_protected_method( rant_cAntChannel, "initialize", rant_channel_init, 4 );

	rb_define_method( rant_cAntChannel, "channel_number", rant_channel_channel_number, 0 );

	rb_attr( rant_cAntChannel, rb_intern("channel_type"), 1, 0, 0 );
	rb_attr( rant_cAntChannel, rb_intern("network_number"), 1, 0, 0 );
	rb_attr( rant_cAntChannel, rb_intern("extended_options"), 1, 0, 0 );

	rb_attr( rant_cAntChannel, rb_intern("device_number"), 1, 0, 0 );
	rb_attr( rant_cAntChannel, rb_intern("device_type"), 1, 0, 0 );
	rb_attr( rant_cAntChannel, rb_intern("transmission_type"), 1, 0, 0 );
	rb_attr( rant_cAntChannel, rb_intern("rf_frequency"), 1, 0, 0 );
	rb_attr( rant_cAntChannel, rb_intern("agility_frequencies"), 1, 0, 0 );

	rb_define_method( rant_cAntChannel, "set_channel_id", rant_channel_set_channel_id, -1 );
	rb_define_method( rant_cAntChannel, "set_channel_period", rant_channel_set_channel_period, -1 );
	rb_define_method( rant_cAntChannel, "set_channel_search_timeout",
		rant_channel_set_channel_search_timeout, -1 );
	rb_define_method( rant_cAntChannel, "set_channel_rf_freq", rant_channel_set_channel_rf_freq, 1 );
	rb_define_method( rant_cAntChannel, "set_frequency_agility", rant_channel_set_frequency_agility, 3 );

	rb_define_method( rant_cAntChannel, "open", rant_channel_open, -1 );
	rb_define_method( rant_cAntChannel, "close", rant_channel_close, -1 );
	rb_define_method( rant_cAntChannel, "closed?", rant_channel_closed_p, 0 );

	rb_define_method( rant_cAntChannel, "send_burst_transfer", rant_channel_send_burst_transfer, 1 );
	rb_define_method( rant_cAntChannel, "send_acknowledged_data", rant_channel_send_acknowledged_data, 1 );
	rb_define_method( rant_cAntChannel, "send_broadcast_data", rant_channel_send_broadcast_data, 1 );
	rb_define_method( rant_cAntChannel, "send_advanced_transfer", rant_channel_send_advanced_transfer, -1 );

	rb_define_method( rant_cAntChannel, "on_event", rant_channel_on_event, -1 );

	rb_require( "ant/channel" );
}


