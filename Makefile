TARGET = target_ocaml_edition

BIN = bin
SRC = src


all: dir inside
	mv $(SRC)/$(TARGET) $(BIN)

dir:
	mkdir -p $(BIN)


inside:
	cd $(SRC) && $(MAKE)


clean:
	rm -r $(BIN)
	rm -r $(SRC)/*.cmi $(SRC)/*.cmo 


.PHONY: all clean

