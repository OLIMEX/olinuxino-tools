prefix = /usr

all:

install:
	install -d -m 755 $(DESTDIR)$(prefix)/lib/olinuxino
	install -D -m 755 src/usr/lib/olinuxino/* $(DESTDIR)$(prefix)/lib/olinuxino/
