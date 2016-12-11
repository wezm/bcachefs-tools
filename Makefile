
PREFIX=/usr
INSTALL=install
CFLAGS+=-std=gnu99 -O2 -Wall -g -MMD -D_FILE_OFFSET_BITS=64 -I.
LDFLAGS+=-static

PKGCONFIG_LIBS="blkid uuid"
CFLAGS+=`pkg-config --cflags	${PKGCONFIG_LIBS}`
LDLIBS+=`pkg-config --libs	${PKGCONFIG_LIBS}` -lm

ifeq ($(PREFIX),/usr)
	ROOT_SBINDIR=/sbin
else
	ROOT_SBINDIR=$(PREFIX)/sbin
endif

.PHONY: all
all: bcache

CCANSRCS=$(wildcard ccan/*/*.c)
CCANOBJS=$(patsubst %.c,%.o,$(CCANSRCS))

libccan.a: $(CCANOBJS)
	$(AR) r $@ $(CCANOBJS)

bcache-objs = bcache.o bcache-assemble.o bcache-device.o bcache-format.o\
	bcache-fs.o bcache-run.o libbcache.o util.o

-include $(bcache-objs:.o=.d)

bcache: $(bcache-objs) libccan.a

.PHONY: install
install: bcache
	mkdir -p $(DESTDIR)$(ROOT_SBINDIR)
	mkdir -p $(DESTDIR)$(PREFIX)/share/man/man8/
	$(INSTALL) -m0755 bcache	$(DESTDIR)$(ROOT_SBINDIR)
	$(INSTALL) -m0755 mkfs.bcache	$(DESTDIR)$(ROOT_SBINDIR)
	$(INSTALL) -m0644 bcache.8	$(DESTDIR)$(PREFIX)/share/man/man8/

.PHONY: clean
clean:
	$(RM) bcache *.o *.d *.a

.PHONY: deb
deb: all
	debuild --unsigned-source	\
		--unsigned-changes	\
		--no-pre-clean		\
		--build=binary		\
		--diff-ignore		\
		--tar-ignore
