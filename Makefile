prefix = /usr

all:

install:
	install -d -m 755 $(DESTDIR)$(prefix)/lib/olinuxino
	install -D -m 755 src/scripts/* $(DESTDIR)$(prefix)/lib/olinuxino/
	install -d -m 755 $(DESTDIR)$(prefix)/share/olinuxino/default/overlays
	install -D -m 644 src/default-overlays/* $(DESTDIR)$(prefix)/share/olinuxino/default/overlays
	install -d -m 755 $(DESTDIR)$(prefix)/share/X11/xorg.conf.d
	install -D -m 644 src/tweaks/91-olinuxino-sun4i-drm.conf $(DESTDIR)$(prefix)/share/X11/xorg.conf.d
	install -d -m 755 $(DESTDIR)/etc/sysctl.d
	install -D -m 644 src/tweaks/99-olinuxino-sysctl.conf $(DESTDIR)/etc/sysctl.d/99-olinuxino-sysctl.conf
