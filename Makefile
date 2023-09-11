EXEC = target_ocaml_edition

CC = ocamlfind ocamlc
SOURCE_DIR = src
BUILD_DIR = build
LDFLAGS = -package tsdl -package tsdl-image -package tsdl-mixer -package tsdl-ttf -thread -linkpkg

SRCS = $(shell find $(SOURCE_DIR) -name '*.ml' -and -not -name 'main.ml')
FILE = $(SRCS:$(SOURCE_DIR)/%=%)
OBJS = $(FILE:.ml=.cmo)

all : dir $(EXEC) clean-ocaml

dir :
	mkdir $(BUILD_DIR)

$(EXEC) : $(OBJS)
	$(CC) -o $(BUILD_DIR)/$@ $(LDFLAGS) $(addprefix $(BUILD_DIR)/,$(OBJS)) src/main.ml
	mv -t build/ src/*.cmi src/*.cmo
	@echo done!	



$(OBJS): %.cmo: $(SOURCE_DIR)/%.ml
	$(CC) -o $(BUILD_DIR)/$@ $(LDFLAGS) -c $<
 
clean:
	rm -r $(BUILD_DIR)
