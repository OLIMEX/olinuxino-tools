prefix = /usr

all:

install:
	install -d -m 755 $(DESTDIR)$(prefix)/lib/olinuxino
	install -D -m 755 src/scripts/* $(DESTDIR)$(prefix)/lib/olinuxino/
	install -d -m 755 $(DESTDIR)$(prefix)/share/olinuxino/default/overlays
	install -D -m 755 src/default-overlays/* $(DESTDIR)$(prefix)/share/olinuxino/default/overlays
