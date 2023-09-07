EXEC = target_ocaml_edition

CC = ocamlfind ocamlc
SOURCE_DIR = src
BUILD_DIR = build
LDFLAGS = -package tsdl -package tsdl-image -package tsdl-mixer -package tsdl-ttf -thread -linkpkg

SRCS = $(shell find $(SOURCE_DIR) -name '*.ml')

all : dir $(EXEC) clean-ocaml

dir :
	mkdir $(BUILD_DIR)

$(EXEC) :
	$(CC) -o $(BUILD_DIR)/$@ $(LDFLAGS)  $(SRCS)
	mv -t build/ src/*.cmi src/*.cmo
	@echo done!	

clean-ocaml : 

clean:
	rm -r $(BUILD_DIR)
