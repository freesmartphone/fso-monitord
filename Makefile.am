NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	data \
	$(NULL)

INCLUDES = \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/.vala.stamp

sbin_PROGRAMS = fso-monitord

fso_monitord_VALASOURCES = \
	src/logger.vala \
	src/gsm.vala \
	src/phone.vala \
	src/preferences.vala \
	src/device.vala \
	src/usage.vala \
	src/fso.vala \
	src/monitor.vala \
	$(NULL)

fso_monitord_SOURCES = \
	$(fso_monitord_VALASOURCES:.vala=.c) \
	$(fso_monitord_VALASOURCES:.vala=.h) \
	$(NULL)

src/.vala.stamp: $(fso_monitord_VALASOURCES)
	$(VALAC) -c --pkg  dbus-glib-1 --save-temps --basedir=$(top_srcdir) $^
	touch $@

fso_monitord_LDADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(fso_monitord_VALASOURCES) \
	src/.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub \
                       configure depcomp install-sh ltmain.sh     \
                       Makefile.in missing config.h.in            \
                       mkinstalldirs src/*.h src/*.c .deps
