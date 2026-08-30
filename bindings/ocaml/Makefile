# bindings/ocaml/Makefile
#
# Builds and runs the self-contained parity test for the OCaml port. Uses only
# the compiler shipped with a stock OCaml install -- no dune, no opam packages.

OCAMLC ?= ocamlc

SRC := src/cromulent.ml
TEST := test/test_cromulent.ml
BIN := test_cromulent

.PHONY: all test clean

all: $(BIN)

$(BIN): $(SRC) $(TEST)
	$(OCAMLC) -I src -o $@ $(SRC) $(TEST)

test: $(BIN)
	./$(BIN)

clean:
	rm -f $(BIN) src/*.cm[iox] src/*.o test/*.cm[iox] test/*.o
