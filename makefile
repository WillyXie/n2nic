ROOT 	:= $(shell pwd)
BUILD	:= $(ROOT)/build
VERB 	?= NONE
ifneq ($(VERB), NONE)
endif
ECHO 	:= @echo
PROC 	?= 8

# GTKWave
GTKSRC := $(ROOT)/ext/gtkwave/gtkwave3-gtk3
GTKBLD := $(ROOT)/build/gtkwave3
GTKPTH := $(ROOT)/tools/gtkwave3
GTKWAV := $(GTKPTH)/bin/gtkwave

# Icarus Verilog
ICVSRC := $(ROOT)/ext/iverilog
ICVBLD := $(ROOT)/build/iverilog
ICVPTH := $(ROOT)/tools/iverilog
ICVCOM := $(ICVPTH)/bin/iverilog
ICVSIM := $(ICVPTH)/bin/vvp

# Simulate target
SRC	?= $(ROOT)/src/hello.sv
TARG	?= $(ROOT)/hello
WAVE	:= $(TARG).vcd

test: $(GTKWAV) $(WAVE)
	$(GTKWAV) $(WAVE) &

$(WAVE): $(ICVSIM) $(TARG)
	$(ICVSIM) $(TARG)

$(TARG): $(ICVCOM)
	$(ICVCOM) -o $@ $(SRC)

$(WPTH)/%:
	@mkdir -p $(GTKPTH); cd $(GTKSRC); ./autogen.sh;\
		mkdir -p $(GTKBLD); cd $(GTKBLD);\
		$(GTKSRC)/configure --enable-gtk3 --prefix=$(GTKPTH) \
		--with-tcl=/usr/lib/tcl8.6 --with-tk=/usr/lib/tk8.6;\
		make -j$(PROC); sudo make install

$(ICVPTH)/%:
	@mkdir -p $(ICVPTH); cd $(ICVSRC); sh autoconf.sh;\
		mkdir -p $(ICVBLD); cd $(ICVBLD);\
		$(ICVSRC)/configure --prefix=$(ICVPTH);\
		make -j$(PROC); make install

clean:
	rm -rf build*/ $(TARG) $(WAVE)
