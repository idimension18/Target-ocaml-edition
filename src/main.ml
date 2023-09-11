(* Importing SDL  *)
open Tsdl
open Tsdl_image
open Tsdl_ttf
open Tsdl_mixer

(* Importing game objects  *)
open Ship

let screenWidth = 1000 and screenHeight = 500 (* default screen dims *)

let scale_x = ref 1. and scale_y = ref 1. (* When the screen is resize *)

let mainSpeed = 3 (* I forgot for this one :/ *)

let maxAxis = 32768. (* for the stick controller *)

(* A function to calculate circular collision  *)
let circular_colision = () 

(* update component scaling value *)
let update_scale window = 
	let (new_w, new_h) = Sdl.get_window_size window in
	begin
		scale_x := (float_of_int new_w) /. (float_of_int screenWidth);
		scale_y := (float_of_int new_h) /. (float_of_int screenHeight)
	end

(* Re-size-ing components *)
let scale_rect rect  = (Sdl.Rect.create
	~x:(int_of_float ((float_of_int (Sdl.Rect.x rect)) *. !scale_x))
	~y:(int_of_float ((float_of_int (Sdl.Rect.y rect)) *. !scale_y))
	~w:(int_of_float ((float_of_int (Sdl.Rect.w rect)) *. !scale_x))
	~h:(int_of_float ((float_of_int (Sdl.Rect.h rect)) *. !scale_y)))

(* update renderer *)
let draw render texture x y : unit = 
	match Sdl.query_texture texture with
			| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1;
			| Ok (_, _, (w, h)) -> let dst_rect = Sdl.Rect.create ~x:x ~y:y ~w:w ~h:h in
					match (Sdl.render_copy 
						~src:(Sdl.Rect.create ~x:0 ~y:0 ~w:w ~h:h) ~dst:(scale_rect dst_rect) 
						render texture) with
					| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
					| Ok _ -> ()

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
	match Sdl.create_window "Target ocaml edition" 
		~x:Sdl.Window.pos_centered ~y:Sdl.Window.pos_centered ~w:screenWidth ~h:screenHeight 
		Sdl.Window.(windowed + resizable) with
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
	(* Objects declarations *)
	let ship_obj = new Ship.ship render in

	
	(* play the soundtrack *)
	match Mixer.play_music target_soundtrack (-1) with
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1;
	| Ok _ ->
	

	(* ---------- main loop ------------ *)
	let game_is_running = ref true in
	let rec main_loop () = 
		(* ---------- SDL EVENTS  ------------*)
		let evt = Sdl.Event.create() in
		while Sdl.poll_event (Some evt) do
			match Sdl.Event.(enum @@ get evt typ) with
			| `Quit -> game_is_running := false (* check if the game is about to close *)
			| `Window_event ->
			begin
				match Sdl.Event.(window_event_enum @@ get evt window_event_id) with
				| `Resized -> update_scale window
				| _ -> ()
			end
			| _ -> ()
		done;
		
		(* --------- RENDERING ------------- *)
		(* Background  *)
		draw render background 0 0;
		
		Sdl.render_present render;
		(* ---------------------------*)
		
		(* Exit main loop and Cap to 60 FPS *)
		if !game_is_running then begin (Sdl.delay (Int32.of_int 16)); main_loop() end
	in

	main_loop();
	(* --------------------------------- *)

	
	(* Clean up and quit *)
	Sdl.destroy_renderer render;
	Sdl.free_surface background_surface;
	Sdl.destroy_window window;

	Ttf.quit();
	Image.quit();
	Mixer.close_audio();
	Sdl.quit(); 
	exit 0
