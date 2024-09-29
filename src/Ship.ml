open Tsdl
open Tsdl_image
open Tsdl_mixer
open Tools

open Laser

let ship_size = 64

module Ship = struct
	class ship render = object (self)
		(* --------- Variable --------- *)
		(* State data  *)
		val mutable x = 500. val mutable y = 250. 
		val mutable angle = 0. val mutable new_angle = 0.
		val mutable velocity_x = 0. val mutable velocity_y = 0.
		val mutable energy = 30. val mutable can_recharge = true 
		val max_energy = 30. val charge_rate = ( 1. /. 5. )
		
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
    val fire_sound = check_result (Mixer.load_wav "../data/music/lazer.wav")
		
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
		method get_energy = energy method get_max_energy = max_energy

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
    method sub_energy nb = energy <- energy -. nb
		method set_can_recharge b = can_recharge <- b

		(* ----- Other method -------*)
    method fire_laser render =
      if energy >= 5. 
      then
      (
        self#sub_energy 5.;
        Mixer.play_channel (-1) fire_sound 0;
        let new_laser = new Laser.laser render
          (self#get_center_x -. (Laser.width /. 2.))
          (self#get_center_y -. (Laser.height /. 2.))
          angle 
        in
        Some(new_laser)
      )
      else None
     
		(* automaticaly update ship *)
		method update (screen_w, screen_h)  = 
			(* Update functions *)
			let go = 
			if fire_on && energy > 0. then   (* Turn the fire on *)
			(
				velocity_x <- velocity_x +. (Float.cos (angle *. (Float.pi /. 180.))) *. jet_power;
				velocity_y <- velocity_y +. (Float.sin (angle *. (Float.pi /. 180.))) *. jet_power;

				(* ------ speedmax ----- *)
				if (Int.abs (int_of_float velocity_x)) > (int_of_float speed_max) then 
					velocity_x <- if velocity_x > 0. then speed_max else (-.speed_max);

				if (Int.abs (int_of_float velocity_y)) > (int_of_float speed_max) then 
					velocity_y <- if velocity_y > 0. then speed_max else (-.speed_max);
					
				(* ---- Energy ---- *)
				energy <- energy -. charge_rate
			)
		
			and velocity = (* manage space physics *)
			(
				x <- x +. velocity_x;
				y <- y +. velocity_y
			)


			(* the ship stay in the window *)
			and screen_border  = match (int_of_float x, int_of_float y) with
				| (a, _) when a < 0 -> (velocity_x <- 0.; x <- 0.)
				| (a, _) when a > screen_w - ship_size -> 
					(velocity_x <- 0.; x <- float_of_int (screen_w - ship_size))
				| (_, b) when b < 0 -> (velocity_y <- 0.; y <- 0.)
				| (_, b) when b > screen_h - ship_size -> 
					(velocity_y <- 0.; y <- float_of_int (screen_h - ship_size))
				| (_, _) -> ()

			and slerp_rotate = 
				if Float.abs (angle -. new_angle) >= rotation_speed then (* avoiding flickering *)
					let direct = rotation_direction angle new_angle in 
					let amount = rotation_speed *. direct in
					(
						angle <- angle +. amount;
						angle <- angle_projection angle
					)
				else angle <- new_angle
				
			(* over complicated function that damage ship XD *)
			and damaged = 
				if is_damaged then 
				(
					if damage_timer < damage_time then
					(
						damage_timer <- damage_timer + 1;
						blink_timer <- blink_timer + 1;

						(* blink ship *)
						if blink_timer > blink_time then (blink_timer <- 0; is_visible <- not is_visible);

						(* damage action *)
						if damage_timer = 1 then 
						(
							can_recharge <- false;
							is_stunt <- true;
							velocity_x <- (-. velocity_x /. 2.); 
							velocity_y <- (-. velocity_y /. 2.) 
						)
						else if damage_timer < damage_time / 4 then fire_on <- false
						else if damage_timer = damage_time / 4 then 
							(is_stunt <- false; velocity_x <- 0.; velocity_y <- 0.)
					)
					else
					(
						is_damaged <- false;
						is_visible <- true;
						damage_timer <- 0;
						blink_timer <- 0;
						spark_gif <- gif_reset spark_gif;
						can_recharge <- true
					)
				)

			(* just explode the ship *)
			and blow_up =
				if is_blowing_up then
				(
					blow_timer <- blow_timer + 1;
					if blow_timer = 1 then 
					(
						can_recharge <- false;
						blow_timer <- blow_timer + 1;
						is_visible <- false; 
						velocity_x <- velocity_x /. 2.; 
						velocity_y <- velocity_y /. 2. 
					)
					else if blow_timer >= blow_time then 
					(
						is_blowing_up <- false;
						x <- 500.; y <- 250.; angle <- 0.; new_angle <- 0.;
						velocity_x <- 0.; velocity_y <- 0.;
						is_visible <- true;
						blow_timer <- 0;
						blow_gif <- gif_reset blow_gif;
						can_recharge <- true; energy <- max_energy;
					)
				)
			(* start update function  *)
			in
			(
				if not is_stunt then (go; slerp_rotate);
				damaged;
				blow_up;
				velocity;
				screen_border; 
				if can_recharge && energy < max_energy then energy <- energy +. charge_rate;
				
				if is_damaged then spark_gif <- gif_update spark_gif; 
				if is_blowing_up then blow_gif <-  gif_update blow_gif
			)
	end
end
