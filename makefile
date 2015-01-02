define DESCR
Description: Command line internet radio player
 For the Raspberry Pi
endef
export DESCR
SHELL := bash
REL := .release

rpi.fm.1: README
	curl -F page=@README http://mantastic.herokuapp.com > rpi.fm.1
install:
	cp rpi.fm $(DESTDIR)/usr/bin
	cp rpi.fm.1 $(DESTDIR)/usr/share/man/man1/
uninstall:
	rm $(DESTDIR)/usr/bin/rpi.fm
	rm $(DESTDIR)/usr/share/man/man1/rpi.fm.1
clean:
	-rm -rf .release rpi.fm.log log
# Release
tag:
	@git status | grep -q 'nothing to commit' || (echo Worktree dirty; exit 1)
	@echo 'Chose old tag to follow: '; \
	select OLD in `git tag`; do break; done; \
	export TAG; \
	read -p 'Please Enter new tag name: ' TAG; \
	sed -r -e "s/^rpi\.fm [0-9.]+$$/rpi.fm $$TAG/" \
	       -e 's/([0-9]{4}-)[0-9]*/\1'`date +%Y`/ \
	       -i rpi.fm || exit 1; \
	git commit -a -m "version $$TAG"; \
	echo Adding git tag $$TAG; \
	echo "rpi.fm ($$TAG)" > changelog; \
	if [ -n "$$OLD" ]; then \
	  git log --pretty=format:"  * %h %an %s" $$OLD.. >> changelog; \
	  echo >> changelog; \
	else \
	  echo '  * Initial release' >> changelog; \
	fi; \
	echo " -- `git config user.name` <`git config user.email`>  `date -R`" >> changelog; \
	git tag -a -F changelog $$TAG HEAD; \
	rm changelog
utag:
	TAG=`git log --oneline --decorate | head -n1 | sed -rn 's/^.+ version (.+)/\1/p'`; \
	[ "$$TAG" ] && git tag -d $$TAG && git reset --hard HEAD^
tarball: clean
	export TAG=`sed -rn 's/^rpi.fm (.+)$$/\1/p' rpi.fm`; \
	$(MAKE) balls
balls:
	mkdir -p $(REL)/rpi.fm-$(TAG); \
	cp -rt $(REL)/rpi.fm-$(TAG) *; \
	cd $(REL); \
	tar -czf rpi.fm_$(TAG).tar.gz rpi.fm-$(TAG)
deb: tarball
	export TAG=`sed -rn 's/^rpi.fm (.+)$$/\1/p' rpi.fm`; \
	export DEB=$(REL)/rpi.fm-$${TAG}/debian; \
	$(MAKE) debs
debs:
	-rm $(REL)/*.deb
	cp -f $(REL)/rpi.fm_$(TAG).tar.gz $(REL)/rpi.fm_$(TAG).orig.tar.gz
	mkdir -p $(DEB)
	echo 'Source: rpi.fm'                                    >$(DEB)/control
	echo 'Section: video'                                   >>$(DEB)/control
	echo 'Priority: optional'                               >>$(DEB)/control
	sed -nr 's/^C.+ [-0-9]+ (.+)$$/Maintainer: \1/p' rpi.fm >>$(DEB)/control
	echo 'Build-Depends: debhelper             '            >>$(DEB)/control
	echo 'Standards-version: 3.8.4'                         >>$(DEB)/control
	echo                                                    >>$(DEB)/control
	echo 'Package: rpi.fm'                                  >>$(DEB)/control
	echo 'Architecture: all'                                >>$(DEB)/control
	echo 'Depends: $${shlibs:Depends}, $${misc:Depends}, omxd, curl' >>$(DEB)/control
	echo "$$DESCR"                                          >>$(DEB)/control
	grep Copyright rpi.fm                         >$(DEB)/copyright
	echo 'License: GNU GPL v2'                   >>$(DEB)/copyright
	echo ' See /usr/share/common-licenses/GPL-2' >>$(DEB)/copyright
	echo 7 > $(DEB)/compat
	for i in `git tag | sort -rg`; do git show $$i | sed -n '/^rpi.fm/,/^ --/p'; done \
	| sed -r 's/^rpi.fm \((.+)\)$$/rpi.fm (\1-1) UNRELEASED; urgency=low/' \
	| sed -r 's/^(.{,79}).*/\1/' \
	> $(DEB)/changelog
	echo '#!/usr/bin/make -f' > $(DEB)/rules
	echo '%:'                >> $(DEB)/rules
	echo '	dh $$@'          >> $(DEB)/rules
	echo usr/bin               > $(DEB)/rpi.fm.dirs
	echo usr/share/man/man1   >> $(DEB)/rpi.fm.dirs
	echo usr/share/doc/rpi.fm >> $(DEB)/rpi.fm.dirs
	chmod 755 $(DEB)/rules
	mkdir -p $(DEB)/source
	echo '3.0 (quilt)' > $(DEB)/source/format
	@cd $(REL)/rpi.fm-$(TAG) && \
	echo && echo List of PGP keys for signing package: && \
	gpg -K | grep uid && \
	read -ep 'Enter key ID (part of name or alias): ' KEYID; \
	if [ "$$KEYID" ]; then \
	  dpkg-buildpackage -k$$KEYID; \
	else \
	  dpkg-buildpackage -us -uc; \
	fi
	fakeroot alien -kr --scripts $(REL)/*.deb; mv *.rpm $(REL)
release: tag deb
