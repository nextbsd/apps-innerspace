AC_PREREQ(2.52)
AC_INIT

if test -z "$GNUSTEP_SYSTEM_ROOT"; then
  AC_MSG_ERROR([You must run the GNUstep initialization script first!])
fi

#--------------------------------------------------------------------
# Use config.guess, config.sub and install-sh provided by gnustep-make
#--------------------------------------------------------------------
AC_CHECK_HEADERS(Xlib.h, have_xlib=yes, have_xlib=no)

if test "$have_xlib" = yes; then
   AC_CHECK_LIB(Xlib,XInternAtom)
   if test "$ac_cv_lib_Xlib_XInternAtom" = yes; then
      AC_CHECK_LIB(Xlib,XChangeProperty)
      if test "$ac_cv_lib_Xlib_XInternAtom" = yes; then
	 HAVE_OMNIPRESENT=YES
      fi
   fi
fi

AC_CONFIG_AUX_DIR([$GNUSTEP_MAKEFILES])

#--------------------------------------------------------------------
# Debug logging
#--------------------------------------------------------------------
#AC_ARG_ENABLE(debug_log,
#  [  --enable-debug-log  		Enable debug logging],,
#      enable_debug_log=no)
#
#if test "$enable_debug_log" = "no"; then
# GW_DEBUG_LOG=0
#else
# GW_DEBUG_LOG=1
#fi
#
#AC_DEFINE_UNQUOTED([GW_DEBUG_LOG], [$GW_DEBUG_LOG], [debug logging])

AC_OUTPUT
