/*
 *  ant_ext.c - Ruby binding for ANT communications
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "ant_ext.h"

VALUE rant_mAnt;

static ID response_callback_ivar;


/* --------------------------------------------------------------
 * Logging Functions
 * -------------------------------------------------------------- */

/*
 * Log a message to the given +context+ object's logger.
 */
void
#ifdef HAVE_STDARG_PROTOTYPES
rant_log_obj( VALUE context, const char *level, const char *fmt, ... )
#else
rant_log_obj( VALUE context, const char *level, const char *fmt, va_dcl )
#endif
{
	char buf[BUFSIZ];
	va_list	args;
	VALUE logger = Qnil;
	VALUE message = Qnil;

	va_init_list( args, fmt );
	vsnprintf( buf, BUFSIZ, fmt, args );
	message = rb_str_new2( buf );

	logger = rb_funcall( context, rb_intern("log"), 0 );
	rb_funcall( logger, rb_intern(level), 1, message );

	va_end( args );
}


/*
 * Log a message to the global logger.
 */
void
#ifdef HAVE_STDARG_PROTOTYPES
rant_log( const char *level, const char *fmt, ... )
#else
rant_log( const char *level, const char *fmt, va_dcl )
#endif
{
	char buf[BUFSIZ];
	va_list	args;
	VALUE logger = Qnil;
	VALUE message = Qnil;

	va_init_list( args, fmt );
	vsnprintf( buf, BUFSIZ, fmt, args );
	message = rb_str_new2( buf );

	logger = rb_funcall( rant_mAnt, rb_intern("logger"), 0 );
	rb_funcall( logger, rb_intern(level), 1, message );

	va_end( args );
}


/* --------------------------------------------------------------
 * Utility functions
 * -------------------------------------------------------------- */



/* --------------------------------------------------------------
 * Module methods
 * -------------------------------------------------------------- */

/*
 * call-seq:
 *    Ant.lib_version   -> int
 *
 * Return the version of the underlying libant.
 *
 */
static VALUE
rant_s_lib_version( VALUE _module )
{
	const char *version = ANT_LibVersion();

	return rb_str_new_cstr( version );
}


/*
 * call-seq:
 *    Ant.device_usb_info( device_num )   -> [ product_string, serial_string ]
 *
 * Get the product and serial info of the USB device +device_num+.
 *
 */
static VALUE
rant_s_device_usb_info( VALUE _module, VALUE device_num )
{
	const unsigned short deviceNum = NUM2SHORT( device_num );
	unsigned char product_string[256];
	unsigned char serial_string[256];
	VALUE rval = rb_ary_new2( 2 );

	if ( !ANT_GetDeviceUSBInfo( (unsigned char)deviceNum, product_string, serial_string ) ) {
		return Qnil;
	}

	rant_log_obj( _module, "debug", "Got product string = %s, serial string = %s", product_string, serial_string );
	rb_ary_push( rval, rb_str_new_cstr((const char *)product_string) );
	rb_ary_push( rval, rb_str_new_cstr((const char *)serial_string) );

	return rval;
}


static VALUE
rant_s_device_usb_pid( VALUE _module )
{
	// EXPORT BOOL ANT_GetDeviceUSBPID(USHORT* pusPID_);
	unsigned short pid;

	if ( !ANT_GetDeviceUSBPID(&pid) ) {
		rb_sys_fail( "Fetching the USB PID." );
	}

	return INT2FIX( pid );
}


static VALUE
rant_s_device_usb_vid( VALUE _module )
{
	// EXPORT BOOL ANT_GetDeviceUSBVID(USHORT* pusVID_);
	unsigned short vid;

	if ( !ANT_GetDeviceUSBVID(&vid) ) {
		rb_sys_fail( "Fetching the USB VID." );
	}

	return INT2FIX( vid );
}


static VALUE
rant_s_device_serial_number( VALUE _module )
{
	// EXPORT ULONG ANT_GetDeviceSerialNumber();
#ifdef HAVE_ANT_GETDEVICESERIALNUMBER
	const unsigned long serial = ANT_GetDeviceSerialNumber();
	return LONG2FIX( serial );
#else
	rb_notimplement();
#endif
}



/*
 * call-seq:
 *    Ant.init( device_num=0, baud_rate=57600 )   -> true
 *
 * Initialize the ANT library and connect to the ANT module. The +device_num+ is
 * the USB device number of the module to connect to, defaulting to 0. Modules
 * connected to a PC will be assigned USB device numbers starting from 0. N is
 * the number of USB ANT devices that are connected. The +baud_rate+ is the
 * asynchronous baud rate used to connect to the ANT controller. See specific
 * ANT controllers for allowable baud rates.
 *
 */
static VALUE
rant_s_init( int argc, VALUE *argv, VALUE _module )
{
	VALUE device_num = Qnil, baud_rate = Qnil;
	unsigned char ucUSBDeviceNum;
	unsigned int ulBaudrate;

	rb_scan_args( argc, argv, "02", &device_num, &baud_rate );

	if ( RTEST(device_num) ) {
		ucUSBDeviceNum = NUM2USHORT( device_num );
	} else {
		ucUSBDeviceNum = 0;
	}

	if ( RTEST(baud_rate) ) {
		ulBaudrate = NUM2UINT( baud_rate );
	} else {
		ulBaudrate = DEFAULT_BAUDRATE;
	}

	rant_log_obj( rant_mAnt, "info", "Initializing ANT device %d at %d baud", ucUSBDeviceNum, ulBaudrate );
	if ( !ANT_Init(ucUSBDeviceNum, ulBaudrate) ) {
		rb_raise( rb_eRuntimeError, "Initializing the ANT library (no ANT device present?)." );
	}

	return Qtrue;
}



static VALUE
rant_s_close( VALUE _module )
{
	ANT_Close();

	return Qtrue;
}


/*
 * call-seq:
 *    Ant.assign_channel( channel, channel_type, network_number=0, extended_options=0x0, timeout=0 )   -> channel
 *
 * Assign a channel and return an Ant::Channel object for it. Channel assignment
 * reserves a channel number and assigns the type and network number to the
 * channel. The optional extended assignment byte allows for the following
 * features to be enabled:
 * 
 * +EXT_PARAM_FREQUENCY_AGILITY+:: enable frequency agility
 * +EXT_PARAM_BACKGROUND_SCANNING+:: enable background scanning
 * +EXT_PARAM_FAST_CHANNEL_INIT+:: enable fast channel initiation
 * +EXT_PARAM_ASYNC_TRANSMIT+:: enable asynchronous transmission
 *
 *    chan = Ant.assign_channel( 0, Ant::PARAMTER_RX_NOT_TX, 0, EXT_PARAM_FREQUENCY_AGILITY )
 */
static VALUE
rant_s_assign_channel( int argc, VALUE *argv, VALUE _module )
{
	unsigned char ucChannel,
		ucChannelType,
		ucNetworkNumber = 0,
		ucExtend = 0,
		ulResponseTime = 0;
	VALUE channel,
		channel_type,
		network_number,
		extended_options,
		timeout;
	VALUE args[4];

	rb_scan_args( argc, argv, "23", &channel, &channel_type, &network_number, &extended_options, &timeout );

	ucChannel = NUM2UINT( channel );
	ucChannelType = NUM2UINT( channel_type );

	if ( RTEST(network_number) ) {
		ucNetworkNumber = NUM2UINT( network_number );
	}
	if ( RTEST(extended_options) ) {
		ucExtend = NUM2UINT( extended_options );
	}
	if ( RTEST(timeout) ) {
		ulResponseTime = NUM2UINT( timeout );
	}

	if ( !ANT_AssignChannelExt_RTO(ucChannel, ucChannelType, ucNetworkNumber, ucExtend, ulResponseTime) ) {
		rb_raise( rb_eRuntimeError, "Couldn't assign channel %d", ucChannel );
	}

	rant_log( "info", "Assigned channel %d (0x%02x) to network %d {0x%02x}.",
		ucChannel, ucChannelType, ucNetworkNumber, ucExtend );

	args[0] = channel;
	args[1] = channel_type;
	args[2] = network_number;
	args[3] = extended_options;

	return rb_class_new_instance( 4, args, rant_cAntChannel );
}


// Buffer for response data.
// static UCHAR pucResponseBuffer[ MESG_RESPONSE_EVENT_SIZE ];
static UCHAR pucResponseBuffer[ MESG_MAX_SIZE_VALUE ];

struct on_response_call {
	UCHAR ucChannel;
	UCHAR ucResponseMessageId;
};


/*
 * Handle the response callback -- Ruby side.
 */
static VALUE
rant_call_response_callback( VALUE callPtr )
{
	struct on_response_call *call = (struct on_response_call *)callPtr;
	VALUE rb_callback = rb_ivar_get( rant_mAnt, response_callback_ivar );
	VALUE rval = Qnil;

	if ( RTEST(rb_callback) ) {
		VALUE args[3];

		args[0] = INT2FIX( call->ucChannel );
		args[1] = INT2FIX( call->ucResponseMessageId );
		args[2] = rb_enc_str_new( (char *)pucResponseBuffer, MESG_MAX_SIZE_VALUE, rb_ascii8bit_encoding() );

		rval = rb_funcallv_public( rb_callback, rb_intern("call"), 3, args );
	}

	return rval;
}


/*
 * Response callback -- call the registered Ruby callback, if one is set.
 */
static BOOL
rant_on_response_callback( UCHAR ucChannel, UCHAR ucResponseMesgID )
{
	callback_t callback;
	struct on_response_call call;

	call.ucChannel = ucChannel;
	call.ucResponseMessageId = ucResponseMesgID;

	callback.data = &call;
	callback.fn = rant_call_response_callback;

	return rant_callback( &callback );
}


/*
 * call-seq:
 *    Ant.on_response {|channel, response_msg_id| ... }
 *
 * Sets the response callback. The callback is called whenever a response
 * message is received from ANT.
 *
 *    Ant.on_response do |channel, response_msg_id, data|
 *        
 *    end
 */

static VALUE
rant_s_on_response( int argc, VALUE *argv, VALUE module )
{
	VALUE callback = Qnil;

	rb_scan_args( argc, argv, "0&", &callback );

	if ( !RTEST(callback) ) {
		rb_raise( rb_eLocalJumpError, "block required, but not given" );
	}

	rant_log( "debug", "Callback is: %s", RSTRING_PTR(rb_inspect(callback)) );
	rb_ivar_set( module, response_callback_ivar, callback );

	ANT_AssignResponseFunction( rant_on_response_callback, pucResponseBuffer );

	return Qtrue;
}



/*
 * Ant extension init function
 */
void
Init_ant_ext()
{
	rant_mAnt = rb_define_module( "Ant" );

	response_callback_ivar = rb_intern( "@response_callback" );

	rb_define_singleton_method( rant_mAnt, "lib_version", rant_s_lib_version, 0 );

	rb_define_singleton_method( rant_mAnt, "device_usb_info", rant_s_device_usb_info, 1 );
	rb_define_singleton_method( rant_mAnt, "device_usb_pid", rant_s_device_usb_pid, 0 );
	rb_define_singleton_method( rant_mAnt, "device_usb_vid", rant_s_device_usb_vid, 0 );
	rb_define_singleton_method( rant_mAnt, "device_serial_number", rant_s_device_serial_number, 0 );

	rb_define_singleton_method( rant_mAnt, "init", rant_s_init, -1 );
	// rb_define_singleton_method( rant_mAnt, "init_ext", rant_s_init_ext, 4 );
	rb_define_singleton_method( rant_mAnt, "close", rant_s_close, 0 );

	rb_define_singleton_method( rant_mAnt, "assign_channel", rant_s_assign_channel, -1 );

	rb_define_singleton_method( rant_mAnt, "on_response", rant_s_on_response, -1 );


	// EXPORT void ANT_AssignResponseFunction(RESPONSE_FUNC pfResponse, UCHAR* pucResponseBuffer); // pucResponse buffer should be of size MESG_RESPONSE_EVENT_SIZE
	// EXPORT void ANT_AssignChannelEventFunction(UCHAR ucANTChannel,CHANNEL_EVENT_FUNC pfChannelEvent, UCHAR *pucRxBuffer);
	// EXPORT void ANT_UnassignAllResponseFunctions(); //Unassigns all response functions


	// Constants
#define EXPOSE_CONST( name ) \
	rb_define_const( rant_mAnt, #name, INT2FIX( (name) ) )

	EXPOSE_CONST( PORT_TYPE_USB );
	EXPOSE_CONST( PORT_TYPE_COM );

	EXPOSE_CONST( ANT_STANDARD_DATA_PAYLOAD_SIZE );
	EXPOSE_CONST( ANT_EXT_MESG_DEVICE_ID_FIELD_SIZE );
	EXPOSE_CONST( ANT_EXT_STRING_SIZE );
	EXPOSE_CONST( ANT_EXT_MESG_BITFIELD_DEVICE_ID );
	EXPOSE_CONST( ANT_EXT_MESG_BIFIELD_EXTENSION );
	EXPOSE_CONST( ANT_EXT_MESG_BITFIELD_OVERWRITE_SHARED_ADR );
	EXPOSE_CONST( ANT_EXT_MESG_BITFIELD_TRANSMISSION_TYPE );

	EXPOSE_CONST( ANT_LIB_CONFIG_MASK_ALL );
	EXPOSE_CONST( ANT_LIB_CONFIG_RADIO_CONFIG_ALWAYS );
	EXPOSE_CONST( ANT_LIB_CONFIG_MESG_OUT_INC_TIME_STAMP );
	EXPOSE_CONST( ANT_LIB_CONFIG_MESG_OUT_INC_RSSI );
	EXPOSE_CONST( ANT_LIB_CONFIG_MESG_OUT_INC_DEVICE_ID );

	EXPOSE_CONST( ANT_ID_SIZE );
	EXPOSE_CONST( ANT_ID_TRANS_TYPE_OFFSET );
	EXPOSE_CONST( ANT_ID_DEVICE_TYPE_OFFSET );
	EXPOSE_CONST( ANT_ID_DEVICE_NUMBER_HIGH_OFFSET );
	EXPOSE_CONST( ANT_ID_DEVICE_NUMBER_LOW_OFFSET );
	EXPOSE_CONST( ANT_ID_DEVICE_TYPE_PAIRING_FLAG );

	EXPOSE_CONST( ANT_TRANS_TYPE_SHARED_ADDR_MASK );
	EXPOSE_CONST( ANT_TRANS_TYPE_1_BYTE_SHARED_ADDRESS );
	EXPOSE_CONST( ANT_TRANS_TYPE_2_BYTE_SHARED_ADDRESS );

	EXPOSE_CONST( PARAMETER_RX_NOT_TX );
	EXPOSE_CONST( PARAMETER_TX_NOT_RX );
	EXPOSE_CONST( PARAMETER_SHARED_CHANNEL );
	EXPOSE_CONST( PARAMETER_NO_TX_GUARD_BAND );
	EXPOSE_CONST( PARAMETER_ALWAYS_RX_WILD_CARD_SEARCH_ID );
	EXPOSE_CONST( PARAMETER_RX_ONLY );

	EXPOSE_CONST( EXT_PARAM_ALWAYS_SEARCH );
	EXPOSE_CONST( EXT_PARAM_FREQUENCY_AGILITY );

	// Set up some aliases and values not in ant.h
	rb_define_const( rant_mAnt, "EXT_PARAM_BACKGROUND_SCANNING", INT2FIX(EXT_PARAM_ALWAYS_SEARCH) );
	rb_define_const( rant_mAnt, "EXT_PARAM_FAST_CHANNEL_INIT", INT2FIX(0x10) );
	rb_define_const( rant_mAnt, "EXT_PARAM_ASYNC_TRANSMIT", INT2FIX(0x20) );

	EXPOSE_CONST( RADIO_TX_POWER_LVL_MASK );

	EXPOSE_CONST( RADIO_TX_POWER_LVL_0 );
	EXPOSE_CONST( RADIO_TX_POWER_LVL_1 );
	EXPOSE_CONST( RADIO_TX_POWER_LVL_2 );
	EXPOSE_CONST( RADIO_TX_POWER_LVL_3 );

	EXPOSE_CONST( STATUS_CHANNEL_STATE_MASK );
	EXPOSE_CONST( STATUS_UNASSIGNED_CHANNEL );
	EXPOSE_CONST( STATUS_ASSIGNED_CHANNEL );
	EXPOSE_CONST( STATUS_SEARCHING_CHANNEL );
	EXPOSE_CONST( STATUS_TRACKING_CHANNEL );

	EXPOSE_CONST( CAPABILITIES_NO_RX_CHANNELS );
	EXPOSE_CONST( CAPABILITIES_NO_TX_CHANNELS );
	EXPOSE_CONST( CAPABILITIES_NO_RX_MESSAGES );
	EXPOSE_CONST( CAPABILITIES_NO_TX_MESSAGES );
	EXPOSE_CONST( CAPABILITIES_NO_ACKD_MESSAGES );
	EXPOSE_CONST( CAPABILITIES_NO_BURST_TRANSFER );

	EXPOSE_CONST( CAPABILITIES_OVERUN_UNDERRUN );
	EXPOSE_CONST( CAPABILITIES_NETWORK_ENABLED );
	EXPOSE_CONST( CAPABILITIES_AP1_VERSION_2 );
	EXPOSE_CONST( CAPABILITIES_SERIAL_NUMBER_ENABLED );
	EXPOSE_CONST( CAPABILITIES_PER_CHANNEL_TX_POWER_ENABLED );
	EXPOSE_CONST( CAPABILITIES_LOW_PRIORITY_SEARCH_ENABLED );
	EXPOSE_CONST( CAPABILITIES_SCRIPT_ENABLED );
	EXPOSE_CONST( CAPABILITIES_SEARCH_LIST_ENABLED );

	EXPOSE_CONST( CAPABILITIES_LED_ENABLED );
	EXPOSE_CONST( CAPABILITIES_EXT_MESSAGE_ENABLED );
	EXPOSE_CONST( CAPABILITIES_SCAN_MODE_ENABLED );
	EXPOSE_CONST( CAPABILITIES_RESERVED );
	EXPOSE_CONST( CAPABILITIES_PROX_SEARCH_ENABLED );
	EXPOSE_CONST( CAPABILITIES_EXT_ASSIGN_ENABLED );
	EXPOSE_CONST( CAPABILITIES_FS_ANTFS_ENABLED );
	EXPOSE_CONST( CAPABILITIES_FIT1_ENABLED );

	EXPOSE_CONST( CAPABILITIES_ADVANCED_BURST_ENABLED );
	EXPOSE_CONST( CAPABILITIES_EVENT_BUFFERING_ENABLED );
	EXPOSE_CONST( CAPABILITIES_EVENT_FILTERING_ENABLED );
	EXPOSE_CONST( CAPABILITIES_HIGH_DUTY_SEARCH_MODE_ENABLED );
	EXPOSE_CONST( CAPABILITIES_ACTIVE_SEARCH_SHARING_MODE_ENABLED );
	EXPOSE_CONST( CAPABILITIES_SELECTIVE_DATA_UPDATE_ENABLED );
	EXPOSE_CONST( CAPABILITIES_ENCRYPTED_CHANNEL_ENABLED );

	EXPOSE_CONST( CHANNEL_NUMBER_MASK );
	EXPOSE_CONST( SEQUENCE_NUMBER_MASK );
	EXPOSE_CONST( SEQUENCE_NUMBER_ROLLOVER );
	EXPOSE_CONST( SEQUENCE_FIRST_MESSAGE );
	EXPOSE_CONST( SEQUENCE_LAST_MESSAGE );
	EXPOSE_CONST( SEQUENCE_NUMBER_INC );

	EXPOSE_CONST( ADV_BURST_CONFIG_FREQ_HOP );

	EXPOSE_CONST( MSG_EXT_ID_MASK );

	EXPOSE_CONST( BROADCAST_CONTROL_BYTE );
	EXPOSE_CONST( ACKNOWLEDGED_CONTROL_BYTE );

	EXPOSE_CONST( RESPONSE_NO_ERROR );
	EXPOSE_CONST( NO_EVENT );

	EXPOSE_CONST( EVENT_RX_SEARCH_TIMEOUT );
	EXPOSE_CONST( EVENT_RX_FAIL );
	EXPOSE_CONST( EVENT_TX );
	EXPOSE_CONST( EVENT_TRANSFER_RX_FAILED );
	EXPOSE_CONST( EVENT_TRANSFER_TX_COMPLETED );
	EXPOSE_CONST( EVENT_TRANSFER_TX_FAILED );
	EXPOSE_CONST( EVENT_CHANNEL_CLOSED );
	EXPOSE_CONST( EVENT_RX_FAIL_GO_TO_SEARCH );
	EXPOSE_CONST( EVENT_CHANNEL_COLLISION );
	EXPOSE_CONST( EVENT_TRANSFER_TX_START );

	EXPOSE_CONST( EVENT_CHANNEL_ACTIVE );

	EXPOSE_CONST( EVENT_TRANSFER_TX_NEXT_MESSAGE );

	EXPOSE_CONST( CHANNEL_IN_WRONG_STATE );
	EXPOSE_CONST( CHANNEL_NOT_OPENED );
	EXPOSE_CONST( CHANNEL_ID_NOT_SET );
	EXPOSE_CONST( CLOSE_ALL_CHANNELS );

	EXPOSE_CONST( TRANSFER_IN_PROGRESS );
	EXPOSE_CONST( TRANSFER_SEQUENCE_NUMBER_ERROR );
	EXPOSE_CONST( TRANSFER_IN_ERROR );
	EXPOSE_CONST( TRANSFER_BUSY );

	EXPOSE_CONST( INVALID_MESSAGE_CRC );
	EXPOSE_CONST( MESSAGE_SIZE_EXCEEDS_LIMIT );
	EXPOSE_CONST( INVALID_MESSAGE );
	EXPOSE_CONST( INVALID_NETWORK_NUMBER );
	EXPOSE_CONST( INVALID_LIST_ID );
	EXPOSE_CONST( INVALID_SCAN_TX_CHANNEL );
	EXPOSE_CONST( INVALID_PARAMETER_PROVIDED );

	EXPOSE_CONST( EVENT_SERIAL_QUE_OVERFLOW );
	EXPOSE_CONST( EVENT_QUE_OVERFLOW );

	EXPOSE_CONST( EVENT_CLK_ERROR );
	EXPOSE_CONST( EVENT_STATE_OVERRUN );

	EXPOSE_CONST( EVENT_ENCRYPT_NEGOTIATION_SUCCESS );
	EXPOSE_CONST( EVENT_ENCRYPT_NEGOTIATION_FAIL );

	EXPOSE_CONST( SCRIPT_FULL_ERROR );
	EXPOSE_CONST( SCRIPT_WRITE_ERROR );
	EXPOSE_CONST( SCRIPT_INVALID_PAGE_ERROR );
	EXPOSE_CONST( SCRIPT_LOCKED_ERROR );

	EXPOSE_CONST( NO_RESPONSE_MESSAGE );
	EXPOSE_CONST( RETURN_TO_MFG );

	EXPOSE_CONST( FIT_ACTIVE_SEARCH_TIMEOUT );
	EXPOSE_CONST( FIT_WATCH_PAIR );
	EXPOSE_CONST( FIT_WATCH_UNPAIR );

	EXPOSE_CONST( USB_STRING_WRITE_FAIL );


	EXPOSE_CONST( INTERNAL_ONLY_EVENTS );
	EXPOSE_CONST( EVENT_RX );
	EXPOSE_CONST( EVENT_NEW_CHANNEL );
	EXPOSE_CONST( EVENT_PASS_THRU );

	EXPOSE_CONST( EVENT_BLOCKED );

	EXPOSE_CONST( SCRIPT_CMD_FORMAT );
	EXPOSE_CONST( SCRIPT_CMD_DUMP );
	EXPOSE_CONST( SCRIPT_CMD_SET_DEFAULT_SECTOR );
	EXPOSE_CONST( SCRIPT_CMD_END_SECTOR );
	EXPOSE_CONST( SCRIPT_CMD_END_DUMP );
	EXPOSE_CONST( SCRIPT_CMD_LOCK );

	EXPOSE_CONST( USB_DESCRIPTOR_VID_PID );
	EXPOSE_CONST( USB_DESCRIPTOR_MANUFACTURER_STRING );
	EXPOSE_CONST( USB_DESCRIPTOR_DEVICE_STRING );
	EXPOSE_CONST( USB_DESCRIPTOR_SERIAL_STRING );

	EXPOSE_CONST( RESET_FLAGS_MASK );
	EXPOSE_CONST( RESET_SUSPEND );
	EXPOSE_CONST( RESET_SYNC );
	EXPOSE_CONST( RESET_CMD );
	EXPOSE_CONST( RESET_WDT );
	EXPOSE_CONST( RESET_RST );
	EXPOSE_CONST( RESET_POR );

	EXPOSE_CONST( EVENT_RX_BROADCAST );
	EXPOSE_CONST( EVENT_RX_ACKNOWLEDGED );
	EXPOSE_CONST( EVENT_RX_BURST_PACKET );

	EXPOSE_CONST( EVENT_RX_EXT_BROADCAST );
	EXPOSE_CONST( EVENT_RX_EXT_ACKNOWLEDGED );
	EXPOSE_CONST( EVENT_RX_EXT_BURST_PACKET );

	EXPOSE_CONST( EVENT_RX_RSSI_BROADCAST );
	EXPOSE_CONST( EVENT_RX_RSSI_ACKNOWLEDGED );
	EXPOSE_CONST( EVENT_RX_RSSI_BURST_PACKET );

	EXPOSE_CONST( EVENT_RX_FLAG_BROADCAST );
	EXPOSE_CONST( EVENT_RX_FLAG_ACKNOWLEDGED );
	EXPOSE_CONST( EVENT_RX_FLAG_BURST_PACKET );

	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_PAIR_REQUEST );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_DOWNLOAD_START );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_UPLOAD_START );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_DOWNLOAD_COMPLETE );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_UPLOAD_COMPLETE );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_ERASE_COMPLETE );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_LINK_STATE );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_AUTH_STATE );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_TRANSPORT_STATE );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_CMD_RECEIVED );
	EXPOSE_CONST( MESG_FS_ANTFS_EVENT_CMD_PROCESSED );

	EXPOSE_CONST( FS_NO_ERROR_RESPONSE );
	EXPOSE_CONST( FS_MEMORY_UNFORMATTED_ERROR_RESPONSE );
	EXPOSE_CONST( FS_MEMORY_NO_FREE_SECTORS_ERROR_RESPONSE );
	EXPOSE_CONST( FS_MEMORY_READ_ERROR_RESPONSE );
	EXPOSE_CONST( FS_MEMORY_WRITE_ERROR_RESPONSE );
	EXPOSE_CONST( FS_MEMORY_ERASE_ERROR_RESPONSE );
	EXPOSE_CONST( FS_TOO_MANY_FILES_OPEN_RESPONSE );
	EXPOSE_CONST( FS_FILE_INDEX_INVALID_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FILE_INDEX_EXISTS_ERROR_RESPONSE );
	EXPOSE_CONST( FS_AUTO_INDEX_FAILED_TRY_AGAIN_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FILE_ALREADY_OPEN_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FILE_NOT_OPEN_ERROR_RESPONSE );
	EXPOSE_CONST( FS_DIR_CORRUPTED_ERROR_RESPONSE );
	EXPOSE_CONST( FS_INVALID_OFFSET_ERROR_RESPONSE );
	EXPOSE_CONST( FS_BAD_PERMISSIONS_ERROR_RESPONSE );
	EXPOSE_CONST( FS_EOF_REACHED_ERROR_RESPONSE );
	EXPOSE_CONST( FS_INVALID_FILE_HANDLE_ERROR_RESPONSE );

	EXPOSE_CONST( FS_CRYPTO_OPEN_PERMISSION_ERROR_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_HANDLE_ALREADY_IN_USE_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_USER_KEY_NOT_SPECIFIED_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_USER_KEY_ADD_ERROR_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_USER_KEY_FETCH_ERROR_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_IVNONE_READ_ERROR_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_BLOCK_OFFSET_ERROR_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_BLOCK_SIZE_ERROR_RESPONSE );
	EXPOSE_CONST( FS_CRYPTO_CFG_TYPE_NOT_SUPPORTED_RESPONSE );

	EXPOSE_CONST( FS_FIT_FILE_HEADER_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FIT_FILE_SIZE_INTEGRITY_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FIT_FILE_CRC_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FIT_FILE_CHECK_PERMISSION_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FIT_FILE_CHECK_FILE_TYPE_ERROR_RESPONSE );
	EXPOSE_CONST( FS_FIT_FILE_OP_ABORT_ERROR_RESPONSE );
#undef EXPOSE_CONST

	init_ant_channel();
	init_ant_event();
	init_ant_message();

	rant_start_callback_thread();
}

