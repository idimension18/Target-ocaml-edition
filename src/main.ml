open Tsdl
open Tsdl_image
open Tsdl_ttf

let screenWidth = 1000 and screenHeight = 500

let () = 
	(* SDL init *)
	match Sdl.init Sdl.Init.(video + joystick) with
	| Error(`Msg e) -> Sdl.log "Init error: %s" e; exit 1
	| Ok()  -> 

	let _ = Image.init  Image.Init.(png) in
	let _ = Ttf.init in
	
	(* Windows creation *)
	match Sdl.create_window "target_ocaml_edition" 
	~x:Sdl.Window.pos_centered ~y:Sdl.Window.pos_centered ~w:screenWidth ~h:screenHeight 
	Sdl.Window.(windowed) with
	| Error(`Msg e) -> Sdl.log "Create window error: %s" e; exit 1
	| Ok window ->

	print_string "lol";
	print_newline();
	
	(* Clean up and quit *)
	Sdl.destroy_window window;
	Sdl.quit(); 
	exit 0
