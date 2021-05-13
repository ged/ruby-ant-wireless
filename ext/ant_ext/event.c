/*
 *  event.c - Ant::Event class
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "ant_ext.h"

VALUE rant_cAntEvent;




void
init_ant_event()
{

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rant_mAnt = rb_define_module( "Ant" );
#endif


	rant_cAntEvent = rb_define_class_under( rant_mAnt, "Event", rb_cObject );

	rb_require( "ant/event" );
}


