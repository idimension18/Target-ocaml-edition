open Tsdl
open Tsdl_image
open Tsdl_ttf
open Tsdl_mixer

let screenWidth = 1000 and screenHeight = 500 (* default screen dims *)

let scaleX = 1. and scaleY = 1. (* When the screen is resize *)

let mainSpeed = 3 (* I forgot for this one :/ *)

let maxAxis = 32768. (* for the stick controller *)

(* A function to calculate circular collision  *)
let circular_colision = () 

(* Re-size-ing components  *)
let scaleRect = ()

let () = 
	(* ---- SDL and accompagned lib init --- *)
	(* SDL init *)
	match Sdl.init Sdl.Init.(video + joystick) with
	| Error(`Msg e) -> Sdl.log "Init error: %s" e; exit 1
	| Ok()  -> 

	(* SDL_image init  *)
	let _ = Image.init Image.Init.(png) in

	(* SDL_ttf init *)
	let _ = Ttf.init() in

	(* SDL_mixer init *)
	match Mixer.open_audio 44100 Mixer.default_format Mixer.default_channels 1024 with
	| Error(`Msg e) -> Sdl.log "Mixer error: %s" e; exit 1;
	| Ok() ->
	(* ------------------------------------- *)

	(* Loading controller  *)
	match Sdl.game_controller_open 0 with
	| Error(`Msg e) -> Sdl.log "Controller error: %s" e; exit 1 
	| Ok controller ->
	

	(* just printing values *)
	Sdl.log "\n";
	Sdl.log "Controller data : \n";
	match Sdl.game_controller_mapping controller with 
	| Error(`Msg e) -> Sdl.log "%s" e; exit 1;
	| Ok mapping -> Sdl.log "%s \n\n" mapping;

	 
	(* SDL_image init  *)
	let _ = Image.init  Image.Init.(png) in


	(* SDL_ttf init *)
	let _ = Ttf.init() in

	(* m5x7 font *)
	match Ttf.open_font "../data/fonts/m5x7.ttf" 50 with
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1;
	| Ok m5x7 ->

	(* Windows creation *)
	match Sdl.create_window "target_ocaml_edition" 
		~x:Sdl.Window.pos_centered ~y:Sdl.Window.pos_centered ~w:screenWidth ~h:screenHeight 
		Sdl.Window.(windowed) with
	| Error(`Msg e) -> Sdl.log "Create window error: %s" e; exit 1
	| Ok window ->

	(* Renderer creation *)
	match Sdl.create_renderer window with
	| Error(`Msg e) -> Sdl.log "Can't create renderer : %s" e; exit 1;
	| Ok render ->


	(* ---------- Graphics and UI ------------ *)
	(* Background *)
	match Image.load "../data/images/background.png" with
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1;
	| Ok background_surface -> 

	match Sdl.create_texture_from_surface render background_surface with 
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
	| Ok background ->
	
	(* Score *)
	
	(* ----------------------------------------- *)

	(* ------ Soundtracks and sound effetcs ------- *)
	(* Channels allocation *)
	let _ = Mixer.allocate_channels 10 in

	(* Soundtrack *)
	match Mixer.load_mus "../data/music/TargetSong.wav" with
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1;
	| Ok target_soundtrack ->
	
	(* ---------------------------------------------- *)

	(* play the soundtrack *)
	match Mixer.play_music target_soundtrack (-1) with
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1;
	| Ok _ ->
	
	(* Clean up and quit *)
	Sdl.destroy_renderer render;
	Sdl.free_surface background_surface;
	Sdl.destroy_window window;

	Ttf.quit();
	Image.quit();
	Mixer.close_audio();
	Sdl.quit(); 
	exit 0
