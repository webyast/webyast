/*
 * polkit1.c
 *
 * Minimal Ruby extension to check if a specific action
 * is allowed through polkit
 * 
 */
 
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#define _POLKIT_COMPILATION
#include <polkit/polkit.h>
#include <polkit/polkitunixprocess.h>

#include <sys/types.h>
#include <ruby.h>

static gboolean
do_cancel (GCancellable *cancellable)
{
  g_cancellable_cancel (cancellable);
  return FALSE;
}


/* Ruby module */
static VALUE mPolKit1 = Qnil;

/**
 * checks if user can perform action
 * \param action:string action (dbus-style resource string) which user wants do
 * \param user:fixnum uid of user
 * \return symbol
 *         :yes if user has permission
 *         :auth if authorization required
 *         :no if permision denied
 *         raises exception on error
 */
VALUE
method_polkit1_check(VALUE self, VALUE act_v, VALUE usr_v)
{
   const char *action_s = StringValuePtr(act_v);
   uid_t uid = NUM2ULONG(usr_v);
   VALUE ret = Qnil;
   VALUE ruby_error = Qnil;
   const char *error_string = NULL;

   pid_t parent_pid;
   PolkitSubject *subject = NULL;
   PolkitAuthority *authority = NULL;
   GCancellable *cancellable = NULL;
   GError *error = NULL;
   PolkitAuthorizationResult *result = NULL;

   g_type_init ();

   /*
   * Note that if the parent was reaped we have to be careful not to
   * check if init(1) is authorized (it always is).
   */
   parent_pid = getppid ();
   subject = polkit_unix_process_new (parent_pid);
   polkit_unix_process_set_uid(subject, uid); 
   cancellable = g_cancellable_new ();

   /* Set up a 10 second timer to cancel the check */
   g_timeout_add (10 * 1000,
                  (GSourceFunc) do_cancel,
                  cancellable);

   error = NULL;
   authority = polkit_authority_get_sync (cancellable,&error);
   result =polkit_authority_check_authorization_sync (authority,
                                        subject,
                                        action_s,
                                        NULL, /* PolkitDetails */
                                        POLKIT_CHECK_AUTHORIZATION_FLAGS_NONE,
                                        cancellable,
				        &error);

   if (error != NULL) 
   {
     VALUE message = rb_str_buf_new2("polkit failed: ");
     rb_str_buf_cat2(message, error->message);
     ruby_error = rb_exc_new3(rb_eRuntimeError, message);
     g_error_free (error);
     goto finish;
   }
   if (polkit_authorization_result_get_is_authorized (result))
   {
     ret = ID2SYM(rb_intern("yes"));
   }
   else if (polkit_authorization_result_get_is_challenge (result))
   {
     ret = ID2SYM(rb_intern("auth"));
   }
   else
   {
     ret = ID2SYM(rb_intern("no"));
   }

 finish:
   if (authority)
     g_object_unref (authority);
   if (subject)
     g_object_unref (subject);
   if (cancellable)
     g_object_unref (cancellable);

   if (!NIL_P(ruby_error))
     rb_exc_raise(ruby_error);

   if (error_string)
     rb_raise(rb_eRuntimeError, error_string);

   return ret;
}


/* The initialization method for this module */
void
Init_polkit1()
{
    mPolKit1 = rb_define_module("PolKit1");
    rb_define_module_function(mPolKit1, "polkit1_check_uid", method_polkit1_check, 2);	
}
