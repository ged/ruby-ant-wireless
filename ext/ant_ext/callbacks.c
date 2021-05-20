/*
 *  callbacks.c - ANT callback handling
 *  $Id$
 *
 *  This contains code adapted from Kim Burge Strand's Library-of-Massive-Fun-And-Overjoy
 *  project, namely the code that calls back into Ruby from ANT callbacks. Used under
 *  the conditions of the WTFPL. For more info on how it works, see the associated article:
 *
 *    https://www.burgestrand.se//articles/asynchronous-callbacks-in-ruby-c-extensions/
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "ant_ext.h"


/*
 * Three globals to allow for Ruby/C-thread communication:
 * - mutex & condition to synchronize access to callback_queue
 * - callback_queue to store actual callback data in
 * Be careful with the functions that manipulate the callback
 * queue; they must do so in the protection of a mutex.
 */
pthread_mutex_t rant_callback_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t rant_callback_cond   = PTHREAD_COND_INITIALIZER;
callback_t *rant_callback_queue     = NULL;

typedef struct callback_waiting_t callback_waiting_t;
struct callback_waiting_t {
	callback_t *callback;
	bool abort;
};


/*
 * Use this function to add a callback node onto the global
 * callback queue.
 * Do note that we are adding items to the front of the linked
 * list, and as such events will always be handled by most recent
 * first. To remedy this, add to the end of the queue instead.
 */
static void
callback_queue_push( callback_t *callback )
{
	callback->next = rant_callback_queue;
	rant_callback_queue = callback;
}


/*
 * Use this function to pop off a callback node from the
 * global callback queue. Returns NULL if queue is empty.
 */
static callback_t *
callback_queue_pop(void)
{
	callback_t *callback = rant_callback_queue;

	if ( callback )
	{
		rant_callback_queue = callback->next;
	}
	return callback;
}


/*
 * Queue a +callback+ for handling by Ruby. Blocks until it's handled.
 */
bool
rant_callback( callback_t *callback )
{
	pthread_mutex_init( &callback->mutex, NULL );
	pthread_cond_init( &callback->cond, NULL );

	callback->handled = false;

	// Put callback data in global callback queue
	pthread_mutex_lock( &rant_callback_mutex );
	callback_queue_push( callback );
	pthread_mutex_unlock( &rant_callback_mutex );

	// Notify waiting Ruby thread that we have callback data
	pthread_cond_signal( &rant_callback_cond );

	// Wait for callback to be handled
	pthread_mutex_lock( &callback->mutex );
	while ( callback->handled == false )
	{
		pthread_cond_wait( &callback->cond, &callback->mutex );
	}
	pthread_mutex_unlock( &callback->mutex );

	// Clean up
	pthread_mutex_destroy( &callback->mutex );
	pthread_cond_destroy( &callback->cond );

	return callback->rval;
}


/*
 * Executed for each callback notification; what we receive
 * are the callback parameters. The job of this method is to:
 * 1. Convert callback parameters into Ruby values
 * 2. Call the appropriate callback with said parameters
 * 3. Convert the Ruby return value into a C value
 * 4. Hand over the C value to the C callback
 */
static VALUE
handle_callback( void *cb )
{
	callback_t *callback = (callback_t *)cb;
	int state = 0;
	VALUE rval;

	// callback->fn( callback->data );
	rval = rb_protect( callback->fn, (VALUE)callback->data, &state );

	// tell the callback that it has been handled, we are done
	pthread_mutex_lock( &callback->mutex );

	callback->handled = true;
	callback->rval = RTEST( rval ) ? true : false;

	pthread_cond_signal( &callback->cond );
	pthread_mutex_unlock( &callback->mutex );

	if ( state ) {
		rb_jump_tag( state );
	}

	return rval;
}


/*
 * Wait for the next callback in the global callback queue.
 */
static void *
wait_for_callback_signal( void *w_ptr )
{
	callback_waiting_t *waiting = (callback_waiting_t*) w_ptr;

	pthread_mutex_lock( &rant_callback_mutex );

	// abort signal is used when ruby wants us to stop waiting
	while ( waiting->abort == false && (waiting->callback = callback_queue_pop()) == NULL )
	{
		pthread_cond_wait( &rant_callback_cond, &rant_callback_mutex );
	}

	pthread_mutex_unlock( &rant_callback_mutex );

	return NULL;
}


/*
 * Unblocking function: tell the callback thread to abort if Ruby says it's
 * shutdown time.
 */
static void
stop_waiting_for_callback_signal( void *w_ptr )
{
	callback_waiting_t *waiting = (callback_waiting_t*) w_ptr;

	pthread_mutex_lock( &rant_callback_mutex );

	waiting->abort = true;

	pthread_cond_signal( &rant_callback_cond );
	pthread_mutex_unlock( &rant_callback_mutex );
}


/*
 * Callback handler thread routine; loops until told to abort. Each loop:
 *
 * - Release the GVL
 * - Wait on a signal on the global condition variable with an unblock function
 *   that tells it to abort.
 * - If there's a callback, create a child thread to run it.
 *
 */
static VALUE
callback_thread( void *unused )
{
	callback_waiting_t waiting = {
		.callback = NULL,
		.abort    = false
	};

	while ( waiting.abort == false )
	{
		// release the GIL while waiting for a callback notification
		rb_thread_call_without_gvl( wait_for_callback_signal, &waiting,
			stop_waiting_for_callback_signal, &waiting );

		// if ruby wants us to abort, this will be NULL
		if ( waiting.callback )
		{
			rant_log( "debug", "Starting a callback thread." );
			rb_thread_create( handle_callback, (void *)waiting.callback );
		}
	}

	return Qnil;
}



/*
 * Start a Thread which will wait for ANT callbacks and dispatch them when they arrive.
 */
void
rant_start_callback_thread()
{
	// ThreadGroup isn't a public symbol, so have to look it up
	VALUE cThGroup = rb_define_class( "ThreadGroup", rb_cObject );
	VALUE thread_group = rb_class_new_instance( 0, NULL, cThGroup );
	VALUE callback_dispatcher = rb_thread_create( callback_thread, (void *)NULL );

	rb_funcallv( thread_group, rb_intern("add"), 1, &callback_dispatcher );
	rb_ivar_set( rant_mAnt, rb_intern("@callback_threads"), thread_group );
	rb_ivar_set( rant_mAnt, rb_intern("@callback_dispatcher"), callback_dispatcher );
	rb_attr( rb_singleton_class(rant_mAnt), rb_intern("callback_threads"), 1, 0, 0 );
	rb_attr( rb_singleton_class(rant_mAnt), rb_intern("callback_dispatcher"), 1, 0, 0 );
}


