#ifndef ANT_EXT_H_4CFF48F9
#define ANT_EXT_H_4CFF48F9

#include "extconf.h"

#include <stdbool.h>
#include <pthread.h>

#include <ruby.h>
#include <ruby/intern.h>
#include <ruby/thread.h>
#include <ruby/encoding.h>
#include <ruby/version.h>

#include "ant.h"

#ifndef TRUE
# define TRUE    1
#endif

#ifndef FALSE
# define FALSE   0
#endif

/* --------------------------------------------------------------
 * Datatypes
 * -------------------------------------------------------------- */

typedef struct callback_t callback_t;
struct callback_t {
	void *data;
	VALUE (*fn)( VALUE );
	bool rval;

	pthread_mutex_t mutex;
	pthread_cond_t  cond;

	bool handled;
	callback_t *next;
};


/* --------------------------------------------------------------
 * Defines
 * -------------------------------------------------------------- */

#define DEFAULT_BAUDRATE  57600

#ifdef HAVE_STDARG_PROTOTYPES
#include <stdarg.h>
#define va_init_list(a,b) va_start(a,b)
void rant_log_obj( VALUE, const char *, const char *, ... );
void rant_log( const char *, const char *, ... );
#else
#include <varargs.h>
#define va_init_list(a,b) va_start(a)
void rant_log_obj( VALUE, const char *, const char *, va_dcl );
void rant_log( const char *, const char *, va_dcl );
#endif


/* -------------------------------------------------------
 * Globals
 * ------------------------------------------------------- */

extern VALUE rant_mAnt;

extern VALUE rant_cAntChannel;
extern VALUE rant_cAntEvent;
extern VALUE rant_cAntMessage;


/* -------------------------------------------------------
 * Initializer functions
 * ------------------------------------------------------- */
extern void Init_ant_ext _(( void ));

extern void init_ant_channel _(( void ));
extern void init_ant_event _(( void ));
extern void init_ant_message _(( void ));

extern void rant_start_callback_thread _(( void ));
extern bool rant_callback _(( callback_t * ));

#endif /* end of include guard: ANT_EXT_H_4CFF48F9 */
