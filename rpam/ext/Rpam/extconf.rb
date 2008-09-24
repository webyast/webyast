require 'mkmf'

$CFLAGS = ""
$LDFLAGS = ""

have_pam_appl_h = have_header("security/pam_appl.h")
have_pam_modules_h = have_header("security/pam_modules.h")

have_pam_lib = have_library("pam","pam_start")

have_func("pam_end")
have_func("pam_open_session")
have_func("pam_close_session")
have_func("pam_authenticate")
have_func("pam_acct_mgmt")
# have_func("pam_fail_delay")
#have_func("pam_setcred")
#have_func("pam_chauthtok")
#have_func("pam_putenv")
#have_func("pam_getenv")

create_makefile("rpam")
