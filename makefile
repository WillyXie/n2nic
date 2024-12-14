ROOT 	:= $(shell pwd)
BUILD	:= $(ROOT)/build
VERB 	?= NONE
ifneq ($(VERB), NONE)
endif
ECHO 	:= @echo
PROC 	?= 8

# Icarus
VSRC := $(ROOT)/ext/iverilog
VPTH := $(ROOT)/tools/iverilog
VCOM := $(VPTH)/bin/iverilog
VSIM := $(VPTH)/bin/vvp

# Simulate target
TARG	?= $(ROOT)/hello

hello: $(VSIM) $(TARG)
	$(VSIM) $(TARG)

$(TARG): $(VCOM)
	$(VCOM) -o $@ $(ROOT)/src/hello.sv

$(VPTH)/%: | $(BUILD)
	@mkdir -p $(VPTH); cd $(VSRC); sh autoconf.sh;\
		cd $(BUILD); $(VSRC)/configure --prefix=$(VPTH);\
		make -j$(PROC); make install; rm -rf $(BUILD)/*

$(BUILD):
	$(ECHO) Create directory $@
	@mkdir -p $@

clean:
	rm -rf $(BUILD)/* $(TARG)
