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




void
init_ant_channel()
{

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rant_mAnt = rb_define_module( "Ant" );
#endif


	rant_cAntChannel = rb_define_class_under( rant_mAnt, "Channel", rb_cObject );

	rb_require( "ant/channel" );
}


