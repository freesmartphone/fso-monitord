AC_INIT([fso-monitord], [0.2.0], [mlauer@vanille-media.de], [fso-monitord])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
#AC_DISABLE_STATIC
AC_PROG_LIBTOOL


AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.12.0
DBUS_REQUIRED=0.76
VALA_REQUIRED=0.5.9

PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

PKG_CHECK_MODULES(DEPS,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  dbus-glib-1 >= $DBUS_REQUIRED)
AC_SUBST(DEPS_CFLAGS)
AC_SUBST(DEPS_LIBS)

AC_CONFIG_FILES([
	Makefile
	data/Makefile])

AC_OUTPUT
