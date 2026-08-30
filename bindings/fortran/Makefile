# bindings/fortran/Makefile
#
# Builds and runs the self-contained parity test for the Fortran port.
#
# The port relies on two's-complement wraparound, so -fno-range-check is
# required for gfortran to accept the 64-bit hex constants whose high bit is
# set (see README.md).

# make has a built-in default of FC=f77, so `?=` would never take effect;
# only override the built-in, leaving command-line/environment values alone.
ifeq ($(origin FC),default)
FC := gfortran
endif
FFLAGS ?= -O2 -std=f2008 -fno-range-check
BUILD := build

SRC := src/cromulent.f90
TEST := test/test_cromulent.f90
BIN := $(BUILD)/test_cromulent

.PHONY: all test clean

all: $(BIN)

$(BIN): $(SRC) $(TEST) | $(BUILD)
	$(FC) $(FFLAGS) -J$(BUILD) -o $@ $(SRC) $(TEST)

$(BUILD):
	mkdir -p $(BUILD)

test: $(BIN)
	./$(BIN)

clean:
	rm -rf $(BUILD)
