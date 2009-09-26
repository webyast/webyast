/*
 * polkit.c
 *
 * Minimal Ruby extension to check if a specific action
 * is allowed through PolicyKit
 * 
 */
 
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>

#include <dbus/dbus.h>
#include <polkit-dbus/polkit-dbus.h>

#include <sys/types.h>
#include <pwd.h>


#include <ruby.h>

/* Ruby module */
static VALUE mPolKit = Qnil;


static
VALUE
new_runtime_error(const char *fmt, ...)
{
    va_list args;
    char buf[1000];
    va_start(args, fmt);
    vsnprintf(buf, 1000, fmt, args);
    va_end(args);
    return rb_exc_new2(rb_eRuntimeError, buf);
}

/**
 * checks if user can perform action
 * \param action:string action (dbus-style resource string) which user wants do
 * \param user:string id of user
 * \return symbol
 *         :yes if user has permission
 *         :auth if authorization required
 *         :no if permision denied
 *         raises exception on error
 */
VALUE
method_polkit_check(VALUE self, VALUE act_v, VALUE usr_v)
{
    const char *action_s = StringValuePtr(act_v);
    const char *user_s = StringValuePtr(usr_v);
    const char *error = NULL;
    VALUE exc = Qnil;	/* used when "error" would leak memory */
    VALUE ret = Qnil;

    DBusError dbus_error;
    DBusConnection *bus = NULL;
    PolKitCaller *caller = NULL;
    PolKitAction *action = NULL;
    PolKitContext *context = NULL;
    PolKitError *polkit_error = NULL;
    PolKitResult polkit_result;

    struct passwd *passwd;
    uid_t uid;
  
    /*
     * Connect to PolicyKit via DBus
     */
    dbus_error_init(&dbus_error);
    if (!(bus = dbus_bus_get(DBUS_BUS_SYSTEM, &dbus_error))) {
        error = "DBus connect failed";
        goto finish;
    }
    if (!(caller = polkit_caller_new_from_pid(bus, getpid(), &dbus_error))) {
        error = "PolicyKit connect failed";
        goto finish;
    }

    /*
     * get user id
     */
  
    passwd = getpwnam(user_s);

    if (!passwd) {
        exc = new_runtime_error("PolicyKit user '%s' does not exist", user_s);
	goto finish;
    }

    uid = passwd->pw_uid;
    if (!(polkit_caller_set_uid(caller, uid))) {
        error = "Can't set PolicyKit caller uid";
        goto finish;
    } 

    if (!(action = polkit_action_new())) {
        error = "Can't create PolicyKit action";
        goto finish;
    }

    if (!polkit_action_set_action_id(action, action_s)) {
        error = "Can't set PolicyKit action";
        goto finish;
    }

    if (!(context = polkit_context_new())) {
        error = "Can't create PolicyKit context";
        goto finish;
    }

    if (!polkit_context_init(context, &polkit_error)) {
        error = "Can't initialize PolicyKit context";
        goto finish;
    }

    polkit_result = polkit_context_is_caller_authorized(context, action, caller, FALSE, &polkit_error);

    if (polkit_error_is_set(polkit_error)) {
        uid_t uid;
        polkit_caller_get_uid( caller, &uid );
        struct passwd *passwd = getpwuid(uid);
      
	/* polkit_error will be freed before we raise so we must copy the msg */
      exc = new_runtime_error("User %s (uid %d) is not authorized: %s", passwd?passwd->pw_name:"<unknown>", (int)uid, polkit_error_get_error_message(polkit_error));
	goto finish;
    }
    
    switch (polkit_result)
    {
	case POLKIT_RESULT_ONLY_VIA_ADMIN_AUTH:
	case POLKIT_RESULT_ONLY_VIA_ADMIN_AUTH_KEEP_SESSION:
	case POLKIT_RESULT_ONLY_VIA_ADMIN_AUTH_KEEP_ALWAYS:
	case POLKIT_RESULT_ONLY_VIA_ADMIN_AUTH_ONE_SHOT:
	case POLKIT_RESULT_ONLY_VIA_SELF_AUTH:
	case POLKIT_RESULT_ONLY_VIA_SELF_AUTH_KEEP_SESSION:
	case POLKIT_RESULT_ONLY_VIA_SELF_AUTH_KEEP_ALWAYS:
	case POLKIT_RESULT_ONLY_VIA_SELF_AUTH_ONE_SHOT:
            ret = ID2SYM(rb_intern("auth"));
            break;
	case POLKIT_RESULT_YES:
            ret = ID2SYM(rb_intern("yes"));
    	    break;
	case POLKIT_RESULT_NO:
            ret = ID2SYM(rb_intern("no"));
	    break;
	default:
	    error = "Unhandled PolicyKit value";
	    break;
    }

 finish:

    if (caller)
        polkit_caller_unref(caller);

    if (action)
        polkit_action_unref(action);

    if (context)
        polkit_context_unref(context);

    if (bus)
        dbus_connection_unref(bus);

    dbus_error_free(&dbus_error);

    if (polkit_error)
        polkit_error_free(polkit_error);

    if (error)
	rb_raise(rb_eRuntimeError, error);
    if (exc != Qnil)
	rb_exc_raise(exc);

    return ret;
}


/* The initialization method for this module */
void
Init_polkit()
{
    mPolKit = rb_define_module("PolKit");
    rb_define_module_function(mPolKit, "polkit_check", method_polkit_check, 2);	
}
