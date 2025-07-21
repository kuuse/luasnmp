include ../config

OBJS += nm_snmp.o nm_util.o nm_trap.o nm_mib.o nm_c64.o except.o

all: $(LUASNMP_SO)

$(LUASNMP_SO): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)
	mkdir -p ../$(INSTALL_LIBSUBDIR)
	cp $(LUASNMP_SO) ../$(INSTALL_LIBSUBDIR)/core.$(EXT)

clean:
	rm -f $(OBJS) $(LUASNMP_SO) 
	rm -rf ../$(INSTALL_LIBSUBDIR)
	rm -rf makefile.deps

depend: makefile.deps

makefile.deps: $(OBJS:.o=.c)
	rm -f makefile.deps
	test -z "$(OBJS)" || $(CC) -MM $(CFLAGS) $(OBJS:.o=.c) >> makefile.deps

-include makefile.deps
