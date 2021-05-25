/*
 *  channel.c - Ant::Channel class
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "ant_ext.h"

VALUE rant_cAntChannel;



static unsigned char
rant_get_channel_number( VALUE channel )
{
	return NUM2USHORT( rb_iv_get( channel, "@channel_number" ) );
}


static VALUE
rant_channel_set_channel_id( int argc, VALUE *argv, VALUE channel )
{
	const unsigned char ucANTChannel = rant_get_channel_number( channel );
	VALUE device_number, device_type, transmission_type, timeout;
	unsigned short usDeviceNumber;
	unsigned char ucDeviceType,
		ucTransmissionType;
	unsigned int ulResponseTime = 0;
	bool result;

	rb_scan_args( argc, argv, "31", &device_number, &device_type, &transmission_type, &timeout );

	usDeviceNumber = NUM2USHORT( device_number );
	ucDeviceType = NUM2USHORT( device_type );
	ucTransmissionType = NUM2USHORT( transmission_type );

	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	result = ANT_SetChannelId_RTO( ucANTChannel, usDeviceNumber, ucDeviceType,
		ucTransmissionType, ulResponseTime );

	if ( !result ) {
		rb_raise( rb_eRuntimeError, "Failed to set the channel id." );
	}

	return Qtrue;
}


// ANT_SetChannelPeriod_RTO(UCHAR ucANTChannel_, USHORT usMesgPeriod_, ULONG ulResponseTime_);
// ANT_SetChannelSearchTimeout_RTO(UCHAR ucANTChannel_, UCHAR ucSearchTimeout_, ULONG ulResponseTime_);
// ANT_SetChannelRFFreq_RTO(UCHAR ucANTChannel_, UCHAR ucRFFreq_, ULONG ulResponseTime_);


static VALUE
rant_channel_open( int argc, VALUE *argv, VALUE channel )
{
	const unsigned char ucANTChannel = rant_get_channel_number( channel );
	VALUE timeout;
	unsigned int ulResponseTime = 0;

	rb_scan_args( argc, argv, "01", &timeout );

	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	if ( !ANT_OpenChannel_RTO( ucANTChannel, ulResponseTime ) ) {
		rb_raise( rb_eRuntimeError, "Failed to open the channel." );
	}


	return Qtrue;
}


static VALUE
rant_channel_close( int argc, VALUE *argv, VALUE channel )
{
	const unsigned char ucANTChannel = rant_get_channel_number( channel );
	VALUE timeout;
	unsigned int ulResponseTime = 0;

	rb_scan_args( argc, argv, "01", &timeout );

	if ( RTEST(timeout) )
		ulResponseTime = NUM2UINT( timeout );

	if ( !ANT_CloseChannel_RTO( ucANTChannel, ulResponseTime ) ) {
		rb_raise( rb_eRuntimeError, "Failed to close the channel." );
	}

	return Qtrue;
}


// BOOL ANT_SendBurstTransfer(UCHAR ucChannel, UCHAR* pucData, USHORT usNumDataPackets);



void
init_ant_channel()
{

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rant_mAnt = rb_define_module( "Ant" );
#endif

	rant_cAntChannel = rb_define_class_under( rant_mAnt, "Channel", rb_cObject );



	rb_define_method( rant_cAntChannel, "set_channel_id", rant_channel_set_channel_id, -1 );
	// rb_define_method( rant_cAntChannel, "set_channel_period",
	// 	rant_channel_set_channel_period, -1 );
	// rb_define_method( rant_cAntChannel, "set_channel_search_timeout",
	// 	rant_channel_set_channel_search_timeout, -1 );
	// rb_define_method( rant_cAntChannel, "set_channel_rf_freq",
	// 	rant_channel_set_channel_rf_freq, -1 );

	rb_define_method( rant_cAntChannel, "open", rant_channel_open, -1 );
	rb_define_method( rant_cAntChannel, "close", rant_channel_close, -1 );

	// rb_define_method( rant_cAntChannel, "send_burst_transfer", rant_channel_send_burst_transfer, -1 );

	rb_require( "ant/channel" );
}


