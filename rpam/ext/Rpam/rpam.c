/******************************************************************************
 *
 * Rpam Copyright (c) 2008 Andre Osti de Moura
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * 
 * A full copy of the GNU license is provided in the file LICENSE.
 *
*******************************************************************************/
#include "ruby.h"
#include <security/pam_appl.h>

typedef struct {
	char *name, *pw;
} pam_auth_t;
    
static const char
*rpam_servicename = "rpam";

VALUE Rpam;

void Init_rpam();

/*
 * auth_pam_talker: supply authentication information to PAM when asked
 *
 * Assumptions:
 *   A password is asked for by requesting input without echoing
 *   A username is asked for by requesting input _with_ echoing
 *
 */
static
int auth_pam_talker(int num_msg,
				const struct pam_message ** msg,
				struct pam_response ** resp,
				void *appdata_ptr)
{

   	unsigned short i = 0;
	pam_auth_t *userinfo = (pam_auth_t *) appdata_ptr;
	struct pam_response *response = 0;

     /* parameter sanity checking */
	if (!resp || !msg || !userinfo) {
	    return PAM_CONV_ERR;
	}
	
   	/* allocate memory to store response */
	response = malloc(num_msg * sizeof(struct pam_response));
	if (!response) {
		return PAM_CONV_ERR;
	}

	/* copy values */
	for (i = 0; i < num_msg; i++) {
		/* initialize to safe values */
		response[i].resp_retcode = 0;
		response[i].resp = 0;

		/* select response based on requested output style */
		switch (msg[i]->msg_style) {
			case PAM_PROMPT_ECHO_ON:
				/* on memory allocation failure, auth fails */
				response[i].resp = strdup(userinfo->name);
				break;
			case PAM_PROMPT_ECHO_OFF:
				response[i].resp = strdup(userinfo->pw);
				break;
		        case PAM_ERROR_MSG:
			       fprintf(stderr, "`PAM Error: %s'\n", msg[i]->msg);
                               break;				
		        case PAM_TEXT_INFO:
			       fprintf(stderr, "`PAM Message: %s'\n", msg[i]->msg);
                               break;				
			default:
				if (response)
				free(response);
				return PAM_CONV_ERR;
		}
	}
	/* everything okay, set PAM response values */
	*resp = response;
	return PAM_SUCCESS;

}

/* Authenticates a user and returns TRUE on success, FALSE on failure */
VALUE method_authpam(VALUE self, VALUE username, VALUE password) {
    pam_auth_t userinfo = {NULL, NULL};
	struct pam_conv conv_info = {&auth_pam_talker, (void *) &userinfo};
	pam_handle_t *pamh = NULL;
	int result;

   	userinfo.name = StringValuePtr(username);
	userinfo.pw =   StringValuePtr(password);
 
	if ((result = pam_start(rpam_servicename, userinfo.name, &conv_info, &pamh)) 
            != PAM_SUCCESS) {
       
        return Qfalse;
    }
    if ((result = pam_authenticate(pamh, PAM_DISALLOW_NULL_AUTHTOK))
           !=  PAM_SUCCESS) {

        pam_end(pamh, PAM_SUCCESS); 
        return Qfalse;
    }

   if ((result = pam_acct_mgmt(pamh, PAM_DISALLOW_NULL_AUTHTOK)) 
           != PAM_SUCCESS) {
       
        pam_end(pamh, PAM_SUCCESS);
        return Qfalse;
   }

    pam_end(pamh, PAM_SUCCESS);
    return Qtrue;
}

/* initialize */
void Init_rpam() {
	Rpam = rb_define_module("Rpam");
	rb_define_module_function(Rpam, "authpam", method_authpam, 2);	
}
