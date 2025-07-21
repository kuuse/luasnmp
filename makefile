include config

.PHONY: all clean depend uclean
all:
	cd src && $(MAKE) $@

clean depend:
	cd src && $(MAKE) $@

uclean: clean
	rm -f `find . -name "*~"`

.PHONY: install uninstall install-doc uninstall-doc 

install: all
	mkdir -p $(INSTALL_SHARE) $(INSTALL_LIB)/$(INSTALL_LIBSUBDIR)
	$(INSTALL_DATA) snmp.lua $(INSTALL_SHARENAME)
	$(INSTALL_DATA) trapd.lua $(INSTALL_SHARENAMETRAPD)
	cd src && $(INSTALL_COPY) $(LUASNMP_SO) $(INSTALL_LIB)/$(INSTALL_LIBSUBDIR)/$(INSTALL_LIBFILENAME)

uninstall:
	rm -rf $(INSTALL_SHARENAME)
	rm -rf $(INSTALL_SHARENAME)
	rm -rf $(INSTALL_LIB)/$(INSTALL_LIBSUBDIR)

install-doc:
	mkdir -p $(INSTALL_DOC)/html
	cd doc && $(INSTALL_COPY) * $(INSTALL_DOC)/html

uninstall-doc:
	rm -rf $(INSTALL_DOC)

.PHONY: rock

rock::
	luarocks --lua-version=$(LV) pack $(ROCKSPEC)

.PHONY: test testd testtrap testtrapd testtraponly testtraponlyd
test:
	$(LUABIN) test.lua

testd:
	$(LUABIN) test.lua debug

testtrap:
	$(LUABIN) -e "trapyes, informyes = true, true" test_trap.lua

testtrapd:
	$(LUABIN) -e "trapyes, informyes = true, true" test_trap.lua debug


.PHONY: tag tag-git tag-cvs tag-svn
tag:
	git tag -F latest

.PHONY: dist dist-git dist-cvs dist-svn
dist:
	mkdir -p $(EXPORTDIR)
	git archive --format=tar --prefix=$(DISTNAME)/ HEAD | gzip >$(EXPORTDIR)/$(DISTARCH)

