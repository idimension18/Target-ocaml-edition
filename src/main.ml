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


(* check result and crash if error *)
let check_result rsl = match rsl with
	| Error(`Msg e) -> Sdl.log "Error:%s" e; exit 1
	| Ok rtn -> rtn

(* check result and ignore if error *)
let check_result_ignore rsl = match rsl with
	| Error(`Msg e) -> (Sdl.log "Error:%s" e); None
	| Ok rtn -> Some(rtn)


(* A function to calculate circular collision  *)
let circular_colision = () 

(* update component scaling value *)
let update_scale window = 
	let (new_w, new_h) = Sdl.get_window_size window in
	begin
		scale_x := (float_of_int new_w) /. (float_of_int screenWidth);
		scale_y := (float_of_int new_h) /. (float_of_int screenHeight)
	end

(* --------- utilities --------- *)
(* Re-size-ing components *)
let scale_rect rect  = (Sdl.Rect.create
	~x:(int_of_float ((float_of_int (Sdl.Rect.x rect)) *. !scale_x))
	~y:(int_of_float ((float_of_int (Sdl.Rect.y rect)) *. !scale_y))
	~w:(int_of_float ((float_of_int (Sdl.Rect.w rect)) *. !scale_x))
	~h:(int_of_float ((float_of_int (Sdl.Rect.h rect)) *. !scale_y)))

(* update renderer *)
let draw render texture x y : unit = 
	let (_, _, (w, h)) = check_result(Sdl.query_texture texture) in
	let dst_rect = Sdl.Rect.create ~x:x ~y:y ~w:w ~h:h in
	(check_result (Sdl.render_copy 
		~src:(Sdl.Rect.create ~x:0 ~y:0 ~w:w ~h:h) ~dst:(scale_rect dst_rect) 
		render texture))

(* update renderer ex (with an angle) *)
let draw_ex render texture x y angle : unit = 
	let (_, _, (w, h)) = check_result(Sdl.query_texture texture) in
	let dst_rect = Sdl.Rect.create ~x:x ~y:y ~w:w ~h:h in
	(check_result (Sdl.render_copy_ex 
		~src:(Sdl.Rect.create ~x:0 ~y:0 ~w:w ~h:h) ~dst:(scale_rect dst_rect) 
		render texture angle None Sdl.Flip.(none)))
(* --------------------------------*)


(* A function to calculate circular collision  *)
let circular_colision = () 

(* update component scaling value *)
let update_scale window = 
	let (new_w, new_h) = Sdl.get_window_size window in
	begin
		scale_x := (float_of_int new_w) /. (float_of_int screenWidth);
		scale_y := (float_of_int new_h) /. (float_of_int screenHeight)
	end

(* log controller info *)
let log_controller_info controller_option =
	Sdl.log "\n";
	Sdl.log "Controller data : \n";
	match controller_option with 
	| None -> ()
	| Some(controller) -> Sdl.log "%s \n\n" (check_result (Sdl.game_controller_mapping controller))

(* -------- main code ------ *)
let () = 
	(* ---- SDL and accompagned lib init --- *)
	(* SDL init *)
	let _ = check_result (Sdl.init Sdl.Init.(video + joystick)) in

	(* SDL_image init  *)
	let _ = Image.init Image.Init.(png) in

	(* SDL_ttf init *)
	let _ = Ttf.init() in

	(* SDL_mixer init *)
	let _ = check_result (Mixer.open_audio 44100 Mixer.default_format Mixer.default_channels 1024) in
	(* ------------------------------------- *)
	
	(* Loading controller  *)
	let controller_option = check_result_ignore (Sdl.game_controller_open 0) in
	
	(* just printing values *)
	let _ = log_controller_info controller_option in
	
	(* m5x7 font *)
	let m5x7 = check_result (Ttf.open_font "../data/fonts/m5x7.ttf" 50) in

	(* Windows creation *)
	let window = check_result (Sdl.create_window "Target ocaml edition" 
		~x:Sdl.Window.pos_centered ~y:Sdl.Window.pos_centered ~w:screenWidth ~h:screenHeight 
		Sdl.Window.(windowed + resizable)) in 
	
	(* Renderer creation *)
	let render = check_result (Sdl.create_renderer window) in
	

	(* ---------- Graphics and UI ------------ *)
	(* Background *)
	let background_surface = check_result (Image.load "../data/images/background.png") in

	let background = check_result (Sdl.create_texture_from_surface render background_surface) in 

	(* Score *)
	
	(* ----------------------------------------- *)

	(* ------ Soundtracks and sound effetcs ------- *)
	(* Channels allocation *)
	let _ = Mixer.allocate_channels 10 in

	(* Soundtrack *)
	let target_soundtrack = check_result (Mixer.load_mus "../data/music/TargetSong.wav") in
	
	(* ---------------------------------------------- *)
	(* Objects declarations *)
	let ship = new Ship.ship render in

	
	(* play the soundtrack *)
	let _ = check_result (Mixer.play_music target_soundtrack (-1)) in

	
	(* ---------- main loop ------------ *)
	let game_is_running = ref true in
	let rec main_loop () = 
		(* ---------- SDL EVENTS  ------------*)
		let evt = Sdl.Event.create() in
		while Sdl.poll_event (Some evt) do
			match Sdl.Event.(enum @@ get evt typ) with
			(* --------- Window events-------- *)
			| `Quit -> game_is_running := false (* check if the game is about to close *)
			| `Window_event -> 
				begin
					match Sdl.Event.(window_event_enum @@ get evt window_event_id) with
					| `Resized -> update_scale window
					| _ -> ()
				end
			(* -------- Controller events ----- *)
			| `Controller_button_down -> 
				begin
					Sdl.log "yo";
					match controller_option with 
					| None -> ()
					| Some(controller) -> 
					begin
						Sdl.log "%d" (Sdl.game_controller_get_button controller Sdl.Controller.(button_a));
						if (Sdl.game_controller_get_button controller Sdl.Controller.(button_a)) == 1 then
							 ship#set_fire_on true
					end
				end
			(* --------------------------------- *)
			| _ -> ()
		done;

		(* ------ Game logic --------- *)
		ship#update (screenWidth, screenHeight);
		
		(* --------- RENDERING ------------- *)
		(* Background  *)
		draw render background 0 0;

		(* Ship *)
		if ship#get_visible then 
		begin 
				draw_ex render ship#get_body (int_of_float ship#get_x) (int_of_float ship#get_y) ship#get_angle;
				if ship#get_fire_on then draw_ex render ship#get_fire (int_of_float ship#get_x) (int_of_float ship#get_y) ship#get_angle
		end;
		
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
