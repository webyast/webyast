#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <dbus/dbus.h>
#include <polkit-dbus/polkit-dbus.h>

#include <sys/types.h>
#include <pwd.h>

// Include the Ruby headers and goodies
#include "ruby.h"

#define MAXLEN 256

// Defining a space for information and references about the module to be stored internally
VALUE PolKit = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_polKit();

// Prototype for our method 'polkit_check' - methods are prefixed by 'method_' here
VALUE method_polkit_check(VALUE self, VALUE action_id, VALUE user);

// The initialization method for this module
void Init_polKit() {
	PolKit = rb_define_module("PolKit");
	rb_define_method(PolKit, "polkit_check", method_polkit_check, 2);	
}


/**
 * checks if user can provide action
 * \param action action which user want do
 * \return 0 if user have permision, -1 if error occured, -2 if authorization required and -3 if permision denied
 */
VALUE method_polkit_check(VALUE self, VALUE act, VALUE usr) {

    char action_id[MAXLEN];
    char user[MAXLEN];

    action_id[0] = 0;
    user[0] = 0;

    if (RSTRING(act)->len+1 < 256)
    {
	strncpy (action_id, RSTRING(act)->ptr, RSTRING(act)->len);
	action_id[RSTRING(act)->len] = 0;
    }

    if (RSTRING(usr)->len+1 < 256)
    {
	strncpy (user, RSTRING(usr)->ptr, RSTRING(usr)->len);
	user[RSTRING(usr)->len] = 0;
    }

    int ret = -1;
    DBusError dbus_error;
    DBusConnection *bus = NULL;
    PolKitCaller *caller = NULL;
    PolKitAction *action = NULL;
    PolKitContext *context = NULL;
    PolKitError *polkit_error = NULL;
    PolKitSession *session = NULL;
    PolKitResult polkit_result;

    dbus_error_init(&dbus_error);
    if (!(bus = dbus_bus_get(DBUS_BUS_SYSTEM, &dbus_error))) {
        goto finish;
    }

    if (!(caller = polkit_caller_new_from_pid(bus, getpid(), &dbus_error))) {
        goto finish;
    }


    /* This function is called when PulseAudio is called SUID root. We
     * want to authenticate the real user that called us and not the
     * effective user we gained through being SUID root. Hence we
     * overwrite the UID caller data here explicitly, just for
     * paranoia. In fact PolicyKit should fill in the UID here anyway
     * -- an not the EUID or any other user id. */
    struct passwd *passwd = getpwnam(user);

    if (passwd == NULL)
	goto finish;

    uid_t uid = passwd->pw_uid;
    if (!(polkit_caller_set_uid(caller, uid))) {
        goto finish;
    }

    if (!(polkit_caller_get_ck_session(caller, &session)))
    {
        goto finish;
    }

    if (session!=NULL)
    {
    	/* We need to overwrite the UID in both the caller and the session
	 * object */
    	if (!(polkit_session_set_uid(session, getuid()))) {
	    goto finish;
    	}
    }

    if (!(action = polkit_action_new())) {
        goto finish;
    }

    if (!polkit_action_set_action_id(action, action_id)) {
        goto finish;
    }

    if (!(context = polkit_context_new())) {
        goto finish;
    }

    if (!polkit_context_init(context, &polkit_error)) {
        goto finish;
    }

    polkit_result = polkit_context_is_caller_authorized(context, action, caller, FALSE, &polkit_error);

    if (polkit_error_is_set(polkit_error)) {
	goto finish;
    }
    
    printf("Action: %s Result: %s\n", action_id, polkit_result_to_string_representation(polkit_result));

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
            ret = -2;
            break;
	case POLKIT_RESULT_YES:
	    ret = 0;
    	    break;
	case POLKIT_RESULT_NO:
	    ret = -3;
	    break;
	default:
	    ; //handle new value in polkit
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

    return INT2NUM(ret);
}
