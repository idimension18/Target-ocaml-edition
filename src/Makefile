TARGET = target_ocaml_edition

CC = ocamlfind ocamlc
LDFLAGS = -package tsdl -package tsdl-image -package tsdl-mixer -package tsdl-ttf -thread -linkpkg


OBJS = Tools.cmo Ship.cmo Asteroide.cmo Target.cmo Laser.cmo Interface.cmo
CMI = Tools.cmi Ship.cmi Asteroide.cmi Target.cmi Laser.cmi Interface.cmi


$(TARGET) : $(CMI) $(OBJS) main.cmo
	$(CC) -o $@ $(OBJS) main.cmo $(LDFLAGS)

%.cmi: %.mli
	$(CC) -c $< -o $@ $(LDFLAGS)


main.cmo: main.ml
	$(CC) -c $< -o $@ $(LDFLAGS)


%.cmo: %.ml
	$(CC) -c $< -o $@ $(LDFLAGS) 
	

.PHONY: $(TARGET)

