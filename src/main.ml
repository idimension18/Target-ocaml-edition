(* Importing SDL  *)
open Tsdl
open Tsdl_image
open Tsdl_ttf
open Tsdl_mixer

(* Importing game objects  *)
open Tools
open Ship
open Laser
open Target
open Asteroide
open Interface

let screenWidth = 1000 and screenHeight = 500 (* default screen dims *)

let scale_x = ref 1. and scale_y = ref 1. (* When the screen is resize *)

let debri_frequence = 30
let main_speed = 3.


(* Calculate circular collision  *)
let collide obj1 obj2 = 
	( Float.sqrt ((obj1#get_center_x -. obj2#get_center_x)**2. +. (obj1#get_center_y -. obj2#get_center_y)**2.) )
	< obj1#get_radius +. obj2#get_radius

(* Return obj that collide with obj1, None otherwise *)
let collide_with_list obj1 obj_list = 
	List.fold_left
		( fun acc obj -> match acc with 
			| None -> if collide obj1 obj then Some(obj) else None
			| Some(a) -> Some(a) ) 
		None obj_list


(* update component scaling value *)
let update_scale window = 
	let (new_w, new_h) = Sdl.get_window_size window in
	(
		scale_x := (float_of_int new_w) /. (float_of_int screenWidth);
		scale_y := (float_of_int new_h) /. (float_of_int screenHeight)
	)

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

(* log controller info *)
let log_controller_info controller_option =
	Sdl.log "\n";
	Sdl.log "Controller data : \n";
	match controller_option with 
	| None -> ()
  | Some(controller) -> Sdl.log "%s \n\n" (check_result (Sdl.game_controller_mapping controller))


let fire_laser ship lasers_list render =
  match ship#fire_laser render with
  | None -> ()
  | Some(new_laser) -> lasers_list := new_laser::!lasers_list


let on_button_down controller_option ship lasers_list render =
  match controller_option with 
    | None -> ()
    | Some(controller) -> 
    (
      (* A Button create lasers*)
      if (Sdl.game_controller_get_button controller Sdl.Controller.(button_a)) == 1 
      then fire_laser ship lasers_list render
    )

(* axis motions *)
let trigger_motion controller ship =
  if (Sdl.game_controller_get_axis controller Sdl.Controller.(axis_trigger_right)) >= 1 then  
    (
      if ship#get_energy > 0. then (ship#set_can_recharge false; ship#set_fire_on true)
      else (ship#set_fire_on false)
    )
    
  else (ship#set_can_recharge true ; ship#set_fire_on false) 

let pad_motion controller ship = 
  let axis_x = Sdl.game_controller_get_axis controller Sdl.Controller.(axis_left_x)
  and axis_y = Sdl.game_controller_get_axis controller Sdl.Controller.(axis_left_y) in

  if (Int.abs axis_x) >=  200 || (Int.abs axis_y) >= 200   (* dead zone check TO MODIFY !!! *) 
  then
    let hyp = Float.sqrt (((float_of_int axis_x)**2.) +. ((float_of_int axis_y)**2.))
    and ad = float_of_int axis_x in 
    let angle = ((Float.acos (ad /. hyp)) *. (180. /. Float.pi)) in
    ship#set_new_angle (if axis_y > 0 then angle else 360. -. angle)

let on_axis_motion controller_option ship =
  match controller_option with
  | None -> ()
  | Some(controller) ->
  (
    (* ---- trigger button ---- *)
    trigger_motion controller ship;
    
    (* ---- Analog pad ---- *)
    pad_motion controller ship 
  )


let on_window_event evt window = 
  match Sdl.Event.(window_event_enum @@ get evt window_event_id) with
  | `Resized -> update_scale window
  | _ -> ()


let manage_events evt controller_option window ship game_is_running lasers_list render =
  let rec f () =  
    if not (Sdl.poll_event (Some evt)) then () else
    let _ = 
      match Sdl.Event.(enum @@ get evt typ) with
      | `Quit -> game_is_running := false (* check if the game is about to close *)
      | `Window_event -> on_window_event evt window 

      (* Get button down *)
      | `Controller_button_down -> on_button_down controller_option ship lasers_list render
       
      (* Get axis states *)
      | `Controller_axis_motion -> on_axis_motion controller_option ship
      | _ -> () 
    in f () 
  in 
  f ()


let init () =
	(* ---- SDL and accompagned lib init --- *)
	let _ = check_result (Sdl.init Sdl.Init.(video + gamecontroller)) in
	let _ = Image.init Image.Init.(png) in
	let _ = Ttf.init() in
	let _ = check_result (Mixer.open_audio 44100 Mixer.default_format Mixer.default_channels 1024) in
	let _ = Mixer.allocate_channels 10 in
	Random.self_init()


let summon_target target_list render =
  let target_size = (Random.int 100) + 50 in 
  let new_target = new Target.target render screenWidth 
  (Random.float (500. -. (float_of_int target_size)) ) target_size (Random.int 3) in
  target_list := new_target::!target_list

let summon_asteroid asteroides_list render =
  let new_size = (Random.int 100) + 40  in
  let new_asteroide = new Asteroide.asteroide render screenWidth 
    (Random.float (500. -. (float_of_int new_size))) 
    new_size (Random.int 4) (Random.float 359.) (if Random.bool() then 1 else (-1)) in
  asteroides_list := new_asteroide::!asteroides_list


let level_update debri_timer debri_frequence asteroides_list target_list render =
  incr debri_timer;
  if !debri_timer > debri_frequence then 
  (
    debri_timer := 0;
    if (Random.int 10) = 1 then (* Creating targets *)
      summon_target target_list render
    else if (Random.int 10) <= 7 then (* Creating asteroides *)
      summon_asteroid asteroides_list render
  )

(* -------- main code ------ *)
let () = 
  let _ = init () in

  (* Loading controller  *)
	let controller_option = check_result_ignore (Sdl.game_controller_open 0) in
	let _ = log_controller_info controller_option in

	(* Windows and renderer creation *)
	let window = check_result (Sdl.create_window "Target ocaml edition" 
		~x:Sdl.Window.pos_centered ~y:Sdl.Window.pos_centered ~w:screenWidth ~h:screenHeight 
		Sdl.Window.(windowed + resizable)) in 
	let render = check_result (Sdl.create_renderer window) in

	(* Background *)
	let background_surface = check_result (Image.load "../data/images/background.png") in
	let background = check_result (Sdl.create_texture_from_surface render background_surface) in 

	(* Channels allocation *)
	let target_soundtrack = check_result (Mixer.load_mus "../data/music/TargetSong.wav") in
	
	(* Objects declarations *)
	let ship = new Ship.ship render 
	and lasers_list = ref [] 
	and asteroides_list = ref []
	and target_list = ref [] 
	and infos = new Interface.infos render
	and score_infos = ref [] in

	(* useful values declations *)
	let debri_timer = ref 0 
	and game_over = ref false in
	
	(* juste before the game *)
	let _ = check_result (Mixer.play_music target_soundtrack (-1)) in
  let game_is_running = ref true in


	(* ---------- main loop ------------ *)
	let rec main_loop () = 
    let evt = Sdl.Event.create() in
    let _ = manage_events evt controller_option window ship game_is_running lasers_list render in

    (* ---- level Reset -----*) (* if game over ocured *)
		if !game_over && not ship#get_is_blowing_up then 
		(
			game_over := false;
			asteroides_list := [];
			target_list := [];
			score_infos := [];
			let _ = check_result (Mixer.play_music target_soundtrack (-1)) in
			infos#reset;
		);
			
		(* ---- Level update ---- *)
    let _ = level_update debri_timer debri_frequence asteroides_list target_list render in

		(* ------ Objects updates  --------- *)
		(* Ship *)
    let _ = ship#update (screenWidth, screenHeight) in

		(* Lists *)
		let update_list alpha_list args = 
			List.iter (fun alpha -> alpha#update args) alpha_list in
			(
				update_list !lasers_list (screenWidth, screenHeight);
				update_list !asteroides_list main_speed;
				update_list !target_list main_speed;
				update_list !score_infos ();
			);

			
		(* ---- Collisions ---- *)
		(* Ship and Asteroides *)
		if not (ship#get_is_damaged || ship#get_is_blowing_up || !game_over) then
		(
			match collide_with_list ship !asteroides_list with
			| None -> ()
			| _ -> 
			(
				infos#lost_life;
				if infos#get_life >= 1 then 
				(
					let _ = check_result (Mixer.play_channel (-1) ship#get_spark 0) in 
					ship#set_is_damaged; 
				)
				else 
				(
					let _ = check_result (Mixer.halt_music ()) in (); 
					let _ = check_result (Mixer.play_channel (-1) ship#get_blow 0) in 
					ship#set_is_blowing_up; 
					game_over := true
				)
			) 
		);
			
		(* Lasers and Targets *)
		List.iter 
			(
				fun target -> List.iter 
				(
					fun laser -> if collide target laser then 
					(
						let _ = check_result (Mixer.play_channel (-1) target#get_sound 0) in 
						target#set_to_destroy;
						laser#set_to_destroy;
						infos#add_score target#get_value;
						
						let new_score_info = new Interface.score_info 
							render target#get_center_x target#get_center_y target#get_value in
						score_infos := new_score_info::!score_infos;
						
					)
				) 
				!lasers_list
			)
			!target_list;
		
		(* Lasers and Asteroides *)
		List.iter 
			(fun aste -> (List.iter (fun laser -> if collide laser aste then laser#set_to_destroy) !lasers_list)) 
			!asteroides_list;

		
		(* ------  Destroy stuff ------ *)
		let destroy_update alpha_list = List.rev
			(List.fold_left (fun acc x -> if x#get_to_destroy then acc else x::acc) [] alpha_list) in
			(
				lasers_list := destroy_update !lasers_list;
				asteroides_list := destroy_update !asteroides_list;
				target_list := destroy_update !target_list;
				score_infos := destroy_update !score_infos
			);


		(* --------- RENDERING ------------- *)
		(* Background  *)
		draw render background 0 0;

		(* Ship *)
		if ship#get_is_visible then 
		(
			draw_ex render ship#get_body (int_of_float ship#get_x) (int_of_float ship#get_y) ship#get_angle;
			if ship#get_fire_on then 
				draw_ex render ship#get_fire (int_of_float ship#get_x) (int_of_float ship#get_y) ship#get_angle
		);

		(* Lasers *)
		List.iter (fun laser -> draw_ex render laser#get_texture laser#get_int_x laser#get_int_y laser#get_angle)
			!lasers_list;

		(* Targets *)
		List.iter (fun tar -> draw render tar#get_texture tar#get_int_x tar#get_int_y)
			!target_list;

		(* Asteroides *)
		List.iter (fun aste -> draw_ex render aste#get_texture aste#get_int_x aste#get_int_y aste#get_angle)
			!asteroides_list;

		(* ---- Gifs ---- *)
		(* spark *) 
		if ship#get_is_damaged then
		(
			let gif = ship#get_spark_gif in 
				draw render gif.texture_array.(gif.cursor) ship#get_int_x ship#get_int_y
		);

		(* blow *)
		if ship#get_is_blowing_up then
		(
			let gif = ship#get_blow_gif in 
				draw render gif.texture_array.(gif.cursor) 
					( (int_of_float ship#get_center_x) - (gif.fs/2) ) 
					( (int_of_float ship#get_center_y) - (gif.fs/2) )
		);
		
		(* ---- User interface ----*)
		(* Life *)
		for i=0 to (infos#get_life -1) do draw render infos#get_life_texture (i*45) 0 done;

		(* Score *)
		draw render infos#get_score_texture 450 0;

		(* Energy *)
		let _ = Sdl.set_render_draw_color render 255 255 255 0 in
		check_result (Sdl.render_draw_rect render 
			(Some (scale_rect (Sdl.Rect.create ~x:850 ~y:20 ~w:75 ~h:25) )));

		let _ = Sdl.set_render_draw_color render 0 255 0 0 in
		check_result (Sdl.render_fill_rect render (Some (scale_rect (Sdl.Rect.create 
			~x:851 ~y:21 ~w:(int_of_float (73. *. (ship#get_energy /. ship#get_max_energy))) ~h:23))));

		(* Score infos *)
		List.iter (fun sf -> draw render sf#get_texture sf#get_int_x sf#get_int_y) !score_infos;
		
		(* ---------------------------*)
		Sdl.render_present render;
		
		(* Exit main loop and Cap to 60 FPS *)
		if !game_is_running then ( (Sdl.delay (Int32.of_int 16)); main_loop() )
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
