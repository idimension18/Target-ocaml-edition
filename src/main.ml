(* Importing SDL  *)
open Tsdl
open Tsdl_image
open Tsdl_ttf
open Tsdl_mixer

(* Importing game objects  *)
open Ship
open Laser
open Target
open Asteroide

let screenWidth = 1000 and screenHeight = 500 (* default screen dims *)

let scale_x = ref 1. and scale_y = ref 1. (* When the screen is resize *)

let debri_frequence = 30
let main_speed = 3.

(* check result and crash if error *)
let check_result rsl = match rsl with
	| Error(`Msg e) -> Sdl.log "Error:%s" e; exit 1
	| Ok rtn -> rtn

(* check result and ignore if error *)
let check_result_ignore rsl = match rsl with
	| Error(`Msg e) -> (Sdl.log "Error:%s" e); None
	| Ok rtn -> Some(rtn)


(* Calculate circular collision  *)
let collide obj1 obj2 = 
	( Float.sqrt ((obj1#get_center_x -. obj2#get_center_x)**2. +. (obj1#get_center_y -. obj2#get_center_y)**2.) )
	< obj1#get_radius +. obj2#get_radius

(* Return obj that collide with obj1, None otherwise *)
let collide_with_list obj1 obj_list = 
	List.fold_left (fun acc obj -> match acc with 
		| None -> if collide obj1 obj then Some(obj) else None
		| Some(a) -> Some(a) ) 
		None obj_list

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
	let _ = check_result (Sdl.init Sdl.Init.(video + gamecontroller)) in

	(* SDL_image init  *)
	let _ = Image.init Image.Init.(png) in

	(* SDL_ttf init *)
	let _ = Ttf.init() in

	(* SDL_mixer init *)
	let _ = check_result (Mixer.open_audio 44100 Mixer.default_format Mixer.default_channels 1024) in

	let _ = Random.self_init() in
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
	let ship = new Ship.ship render 
	and lasers_list = ref [] 
	and asteroides_list = ref []
	and target_list = ref [] in

	(* useful values declations *)
	let debri_timer = ref 0 
	and game_over = ref false in
	
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
			(* Get button down *)
			| `Controller_button_down -> 
				begin
					match controller_option with 
					| None -> ()
					| Some(controller) -> 
						begin
							(* A Button create lasers*)
							if (Sdl.game_controller_get_button controller Sdl.Controller.(button_a)) == 1 then
								begin 
									let new_laser = new Laser.laser render 
										(ship#get_center_x -. (Laser.width /. 2.)) 
										(ship#get_center_y -. (Laser.height /. 2.)) 
										ship#get_angle in
									let _ = check_result (Mixer.play_channel (-1) new_laser#get_sound 0) in
									lasers_list := new_laser::!lasers_list
								end
						end
				end
			(* Get button up *)
			| `Controller_button_up -> ()
			
			(* Get axis states *)
			| `Controller_axis_motion ->
				begin 
					match controller_option with
					| None -> ()
					| Some(controller) ->
						begin
							if (Sdl.game_controller_get_axis controller Sdl.Controller.(axis_trigger_right)) >= 1
								then ship#set_fire_on true
								else ship#set_fire_on false;
							(* ---- Analog pad ----- *)
							let axis_x = Sdl.game_controller_get_axis controller Sdl.Controller.(axis_left_x)
							and axis_y = Sdl.game_controller_get_axis controller Sdl.Controller.(axis_left_y) in
							if (Int.abs axis_x) >=  200 || (Int.abs axis_y) >= 200   (* dead zone check TO MODIFY !!! *) then
							let hyp = Float.sqrt (((float_of_int axis_x)**2.) +. ((float_of_int axis_y)**2.))
							and ad = float_of_int axis_x in
							ship#set_new_angle 
								(if axis_y > 0 then ((Float.acos (ad /. hyp)) *. (180. /. Float.pi))
								else 360. -. ((Float.acos (ad /. hyp)) *. (180. /. Float.pi)));
						end
				end
			(* --------------------------------- *)
			| _ -> ()
		done;

		
		(* ---- level Reset -----*) (* if game over ocured *)
		if !game_over && not ship#get_is_blowing_up then 
			begin
				game_over := false;
				asteroides_list := [];
				target_list := [];
				let _ = check_result (Mixer.play_music target_soundtrack (-1)) in ()
			end;
			
		(* ---- Level update ---- *)
		incr debri_timer;
		if !debri_timer > debri_frequence then 
			begin
				debri_timer := 0;
				if (Random.int 10) = 1 then (* Creating targets *)
					begin
					let target_size = (Random.int 100) + 50 in 
					let new_target = new Target.target render screenWidth 
					(Random.float (500. -. (float_of_int target_size)) ) target_size (Random.int 3) in
					target_list := new_target::!target_list
					end;
					
				if (Random.int 10) <= 7 then (* Creating asteroides *)
					begin
					let new_size = (Random.int 100) + 40  in
					let new_asteroide = new Asteroide.asteroide render screenWidth 
						(Random.float (500. -. (float_of_int new_size))) 
						new_size (Random.int 4) (Random.float 359.) (if Random.bool() then 1 else (-1)) in
					asteroides_list := new_asteroide::!asteroides_list
					end;
			end;
			
		(* ------ Objects updates  --------- *)
		(* Ship *)
		ship#update (screenWidth, screenHeight);

		(* Lists *)
		let update_list alpha_list args = 
			List.iter (fun alpha -> alpha#update args) alpha_list in
			begin
				update_list !lasers_list (screenWidth, screenHeight);
				update_list !asteroides_list main_speed;
				update_list !target_list main_speed
			end;

			
		(* ---- Collisions ---- *)
		(* Ship and Asteroides *)
		if not (ship#get_is_damaged || ship#get_is_blowing_up || !game_over) then
			begin
				match collide_with_list ship !asteroides_list with
				| None -> ()
				| _ -> 
					begin
						let _ = check_result (Mixer.halt_music ()) in (); 
						let _ = check_result (Mixer.play_channel (-1) ship#get_blow 0) in 
						ship#set_is_blowing_up; 
						game_over := true
					end 
			end;
			
		(* Lasers and Targets *)
		List.iter 
			(fun target -> List.iter (fun laser -> if collide target laser then 
				begin
					let _ = check_result (Mixer.play_channel (-1) target#get_sound 0) in 
					target#set_to_destroy;
					laser#set_to_destroy
				end) !lasers_list)
			!target_list;
		
		(* Lasers and Asteroides *)
		List.iter 
			(fun aste -> (List.iter (fun laser -> if collide laser aste then laser#set_to_destroy) !lasers_list)) 
			!asteroides_list;

		
		(* ------  Destroy stuff ------ *)
		let destroy_update alpha_list = List.rev
			(List.fold_left (fun acc x -> if x#get_to_destroy then acc else x::acc) [] alpha_list) in
			begin
				lasers_list := destroy_update !lasers_list;
				asteroides_list := destroy_update !asteroides_list;
				target_list := destroy_update !target_list
			end;


		(* --------- RENDERING ------------- *)
		(* Background  *)
		draw render background 0 0;

		(* Ship *)
		if ship#get_is_visible then 
			begin 
				draw_ex render ship#get_body (int_of_float ship#get_x) (int_of_float ship#get_y) ship#get_angle;
				if ship#get_fire_on then 
					draw_ex render ship#get_fire (int_of_float ship#get_x) (int_of_float ship#get_y) ship#get_angle
			end;

		(* Lasers *)
		List.iter (fun laser -> draw_ex render laser#get_texture laser#get_int_x laser#get_int_y laser#get_angle)
			!lasers_list;

		(* Targets *)
		List.iter (fun tar -> draw render tar#get_texture tar#get_int_x tar#get_int_y)
			!target_list;

		(* Asteroides *)
		List.iter (fun aste -> draw_ex render aste#get_texture aste#get_int_x aste#get_int_y aste#get_angle)
			!asteroides_list;
		
		
		Sdl.render_present render;
		(* ---------------------------*)
		
		(* Exit main loop and Cap to 60 FPS *)
		if !game_is_running then begin (Sdl.delay (Int32.of_int 16)); main_loop() end
	in

	main_loop();
	(* --------------------------------- *)
	
	(* Clean up and quit *)
	match controller_option with | None -> (); | Some(controller) -> Sdl.game_controller_close controller;
	Sdl.destroy_renderer render;
	Sdl.free_surface background_surface;
	Sdl.destroy_window window;
	
	Ttf.quit();
	Image.quit();
	Mixer.close_audio();
	Sdl.quit(); 
	exit 0
