EXEC = target_ocaml_edition

CC = ocamlfind ocamlc
SOURCE_DIR = src
BUILD_DIR = build
LDFLAGS = -package tsdl -package tsdl-image -package tsdl-mixer -package tsdl-ttf -thread -linkpkg

SRCS = $(shell find $(SOURCE_DIR) -name '*.ml' -and -not -name 'main.ml')
FILE = $(SRCS:$(SOURCE_DIR)/%=%)
OBJS = $(FILE:.ml=.cmo)
MLIS = $(FILE:.ml=.mli)

all : dir $(EXEC)

dir :
	mkdir $(BUILD_DIR)

$(EXEC) : $(MLIS) main.ml  $(OBJS)
	$(CC) -o $(BUILD_DIR)/$@ $(addprefix $(SOURCE_DIR)/,$(OBJS)) $(SOURCE_DIR)/main.cmo $(LDFLAGS)
	mv -t $(BUILD_DIR)/ $(SOURCE_DIR)/*.cmi $(SOURCE_DIR)/*.cmo $(SOURCE_DIR)/*.mli
	@echo done!	

$(MLIS): %.mli: $(SOURCE_DIR)/%.ml
	$(CC) -i -c $< > $(<:.ml=.mli) $(LDFLAGS)

main.ml:
	cd src;\
	$(CC) -c $(MLIS) main.ml $(LDFLAGS)

$(OBJS): %.cmo: $(SOURCE_DIR)/%.ml
	cd src;\
	$(CC) -c $(<:src/%=%) $(LDFLAGS)

clean:
	rm -r $(BUILD_DIR)

clean-ocaml:
	cd src;\
	rm *.mli *.cmi *.cmo 
