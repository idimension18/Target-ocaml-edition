open Tsdl
open Tsdl_image
open Tsdl_mixer

let ship_size = 64

(* check result and crash if error *)
let check_result rsl = match rsl with 
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
	| Ok rtn -> rtn

(* load croped part of an image with a scaled proportion *)
let load_image render link cut_rect scale_rect_value = 
	let scale_rect = (Sdl.Rect.create ~x:0 ~y:0 ~w:scale_rect_value ~h:scale_rect_value) in
	let croped_img = check_result (Sdl.create_rgb_surface ~w:(Sdl.Rect.w cut_rect) ~h:(Sdl.Rect.h cut_rect) ~depth:32
		(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
		(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000)) in
	let scaled_img = check_result (Sdl.create_rgb_surface ~w:scale_rect_value ~h:scale_rect_value ~depth:32
		(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
		(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000)) in
	let sheet = check_result (Image.load link) in
	let _ = check_result (Sdl.blit_surface ~src:sheet (Some cut_rect) ~dst:croped_img None) in
	let _ = check_result (Sdl.blit_scaled ~src:croped_img None ~dst:scaled_img (Some scale_rect)) in
	check_result (Sdl.create_texture_from_surface render scaled_img)

let load_whole_image render link scale_rect_value = 
	let scale_rect = (Sdl.Rect.create ~x:0 ~y:0 ~w:scale_rect_value ~h:scale_rect_value) in
	let scaled_img = check_result (Sdl.create_rgb_surface ~w:scale_rect_value ~h:scale_rect_value ~depth:32
		(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
		(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000)) in
	let sheet = check_result (Image.load link) in
	let _ = Sdl.log "lol" in
	let _ = check_result (Sdl.blit_scaled ~src:sheet None ~dst:scaled_img (Some scale_rect)) in
	check_result (Sdl.create_texture_from_surface render scaled_img)


(* Give the direction for smooth rotation *)
let rotation_direction angle new_angle =
	let delta_angle = angle -. new_angle in
	if delta_angle >= 0. then 
		if delta_angle <= 180. then (-. 1.) else 1.
	else 
		if delta_angle >= (-. 180.) then 1. else (-. 1.)

(* Hold angle between 0 and 359 *)
let angle_projection angle = match angle with
	| a when a < 0. -> (a +. 360.)
	| a when a >= 360. -> (a -. 360.)
	| _ -> angle


(* ---- GIF ---- *)
let gif_frame_time = 3; 
type gif = {texture_array: Sdl.texture array; fs: int ; nbf: int ; mutable cursor : int; mutable timer : int}

let gif_create render gif_folder frame_size nb_frame =
	let image_array = 
		Array.init nb_frame (fun i -> load_whole_image render (gif_folder^(string_of_int i)^".png") frame_size) in
	{texture_array = image_array; fs = frame_size; nbf = nb_frame; cursor = 0; timer = 0}


let gif_update gife : gif = 
	gife.timer <- gife.timer + 1; 
	if (gife.timer >= gif_frame_time) && gife.cursor <> (gife.nbf - 1) then 
		begin
			gife.cursor <- gife.cursor + 1; 
			gife.timer <- 0;
			gife
		end
	else gife


 let gif_reset gife : gif = begin gife.cursor <- 0; gife.timer <- 0; gife end

(* -------------- *)

module Ship = struct
	class ship render = 
		object
			(* --------- Variable --------- *)
			(* State data  *)
			val mutable x = 500. val mutable y = 250. 
			val mutable angle = 0. val mutable new_angle = 0.
			val mutable velocity_x = 0. val mutable velocity_y = 0.

			(* Constants *)
			val speed_max = 5. val rotation_speed = 7. val jet_power = 0.1

			(* damage and game over *)
			val mutable is_blowing_up = false val mutable is_damaged = false
			val mutable is_visible = true val mutable fire_on = false
			val mutable damage_timer = 0 val damage_time = 120
			val mutable blink_timer = 0 val blink_time = 10
			val mutable is_stunt = false
			val mutable blow_timer = 0 val mutable blow_time = 150
			
			(* Sounds *)
			val spark = check_result (Mixer.load_wav "../data/music/spark.wav")
			val blow = check_result (Mixer.load_wav "../data/music/blow.wav")
			
			
			(* Graphical data  *)
			val body = load_image render "../data/images/sprites.png"  
				(Sdl.Rect.create ~x:2048 ~y:0 ~w:256 ~h:256) ship_size

			val fire = load_image render  "../data/images/sprites.png"
				(Sdl.Rect.create ~x:2048 ~y:256 ~w:256 ~h:256) ship_size

			val mutable spark_gif = gif_create render "../data/images/sparkGif/" ship_size 18 
			val mutable blow_gif = gif_create render "../data/images/blowGif/" 350 28

			(* ----- Getter -------  *)
			(* Logical data  *)
			method get_x = x method get_y = y method get_angle = angle
			method get_int_x = (int_of_float x)
			method get_int_y = (int_of_float y)
			method get_center_x = x +. ((float_of_int ship_size) /. 2.)
			method get_center_y = y +. ((float_of_int ship_size) /. 2.)
			method get_radius = (float_of_int ship_size) /. 2.
			method get_is_visible = is_visible method get_fire_on = fire_on
			method get_is_damaged = is_damaged
			method get_is_blowing_up = is_blowing_up

			(* Sounds *)
			method get_spark = spark
			method get_blow = blow

			(* Graphical data  *)
			method get_body = body method get_fire = fire 

			method get_spark_gif = spark_gif
			method get_blow_gif = blow_gif
			
			(* ---- Setter -------- *)
			method set_fire_on value = fire_on <- value
			method set_new_angle a = new_angle <- a
			method set_is_damaged = is_damaged <- true
			method set_is_blowing_up = is_blowing_up <- true
		
			(* ----- Other method -------*)

			(* automaticaly update ship *)
			method update (screen_w, screen_h)  = 
				(* Update functions *)
				let go = if fire_on then   (* Turn the fire on *)
					begin
						velocity_x <- velocity_x +. (Float.cos (angle *. (Float.pi /. 180.))) *. jet_power;
						velocity_y <- velocity_y +. (Float.sin (angle *. (Float.pi /. 180.))) *. jet_power;

						(* ------ speedmax ----- *)
						if (Int.abs (int_of_float velocity_x)) > (int_of_float speed_max) then 
							velocity_x <- if velocity_x > 0. then speed_max else (-.speed_max);

						if (Int.abs (int_of_float velocity_y)) > (int_of_float speed_max) then 
							velocity_y <- if velocity_y > 0. then speed_max else (-.speed_max);
						(* --------------------- *)
					end

			
				and velocity = (* manage space physics *)
					begin
						x <- x +. velocity_x;
						y <- y +. velocity_y
					end


				(* the ship stay in the window *)
				and screen_border  = match (int_of_float x, int_of_float y) with
					| (a, _) when a < 0 -> begin velocity_x <- 0.; x <- 0. end
					| (a, _) when a > screen_w - ship_size -> 
						begin velocity_x <- 0.; x <- float_of_int (screen_w - ship_size) end
					| (_, b) when b < 0 -> begin velocity_y <- 0.; y <- 0. end
					| (_, b) when b > screen_h - ship_size -> 
						begin velocity_y <- 0.; y <- float_of_int (screen_h - ship_size) end
					| (_, _) -> ()

				and slerp_rotate = 
					if Float.abs (angle -. new_angle) >= rotation_speed then (* avoiding flickering *)
						let direct = rotation_direction angle new_angle in 
						let amount = rotation_speed *. direct in
						begin
							angle <- angle +. amount;
							angle <- angle_projection angle
						end
					else angle <- new_angle
					
				(* over complicated function that damage ship XD *)
				and damaged = 
					if is_damaged then 
					begin
						if damage_timer < damage_time then
							begin
								damage_timer <- damage_timer + 1;
								blink_timer <- blink_timer + 1;

								(* blink ship *)
								if blink_timer > blink_time then begin blink_timer <- 0; is_visible <- not is_visible end;

								(* damage action *)
								if damage_timer = 1 then 
									begin 
										is_stunt <- true;
										velocity_x <- (-. velocity_x /. 2.); 
										velocity_y <- (-. velocity_y /. 2.) 
										end
								else if damage_timer < damage_time / 4 then fire_on <- false
								else if damage_timer = damage_time / 4 then 
									begin is_stunt <- false; velocity_x <- 0.; velocity_y <- 0. end
							end
						else
							begin
								is_damaged <- false;
								is_visible <- true;
								damage_timer <- 0;
								blink_timer <- 0;
								spark_gif <- gif_reset spark_gif
							end
					end

				(* just explode the ship *)
				and blow_up =
					if is_blowing_up then
						begin
							blow_timer <- blow_timer + 1;
							if blow_timer = 1 then 
								begin 
									blow_timer <- blow_timer + 1;
									is_visible <- false; 
									velocity_x <- (-. velocity_x /. 2.); 
									velocity_y <- (-. velocity_y /. 2.) 
								end
							else if blow_timer >= blow_time then 
								begin
									is_blowing_up <- false;
									x <- 500.; y <- 250.; angle <- 0.; new_angle <- 0.;
									velocity_x <- 0.; velocity_y <- 0.;
									is_visible <- true;
									blow_timer <- 0;
									blow_gif <- gif_reset blow_gif
								end
						end
				(* start update function  *)
				in
				begin
					if not is_stunt then begin go; slerp_rotate end;
					damaged;
					blow_up;
					velocity;
					screen_border; 

					if is_damaged then spark_gif <- gif_update spark_gif; 
					if is_blowing_up then blow_gif <-  gif_update blow_gif
				end

			
	end
end
