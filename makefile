rpi.fm.1: README
	curl -F page=@README http://mantastic.herokuapp.com > rpi.fm.1
install:
	cp rpi.fm $(DESTDIR)/usr/bin
	cp rpi.fm.1 $(DESTDIR)/usr/share/man/man1/
uninstall:
	rm $(DESTDIR)/usr/bin/rpi.fm 
	rm $(DESTDIR)/usr/share/man/man1/rpi.fm.1 
