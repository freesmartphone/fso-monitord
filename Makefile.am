NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	data \
	po \
	$(NULL)

INCLUDES = \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/.vala.stamp

sbin_PROGRAMS = fso-monitord

fso_monitord_VALASOURCES = \
	src/obj.vala \
	src/main.vala \
	src/consts.vala \
	$(NULL)

dbus_hlid_SOURCES = \
	$(fso_monitord_VALASOURCES:.vala=.c) \
	$(fso_monitord_VALASOURCES:.vala=.h) \
	$(NULL)

src/.vala.stamp: $(dbus_hlid_VALASOURCES)
	$(VALAC) -c --pkg dbus-glib-1 --save-temps --basedir $(top_srcdir) $^
	touch $@

dbus_hlid_LDADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(dbus_hlid_VALASOURCES) \
	src/.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub \
                       configure depcomp install-sh ltmain.sh     \
                       Makefile.in missing config.h.in            \
                       mkinstalldirs src/*.h src/*.c
