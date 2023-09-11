# Target-ocaml-edition
the same Target as usual, but in ocaml this time !

# TODO
I have to improve the makefile even more :
- 1 : Generate all mli file related to modules  `ocamlc -i -c a.ml > a.mli`
- 2 : Generate main.cmo thanks to mli files `ocamlc -c a.mli b.ml`
- 3 : Generate all .cmo files after all mli was processed into main.cmo `ocamlc -c a.ml`
- 4 : Build the game into an executable `ocamlc -o b a.cmo b.cmo`
