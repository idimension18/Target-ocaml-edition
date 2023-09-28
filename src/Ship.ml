open Tsdl
open Tsdl_image

open Tsdl_tools

let ship_size = 64

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

module Ship = struct
	class ship render = 
		object
			(* --------- Variable --------- *)
			(* Logical data  *)
			val mutable x = 500. val mutable y = 250. 
			val mutable angle = 0. val mutable new_angle = 0.
			val mutable velocity_x = 0. val mutable velocity_y = 0.
			val speed_max = 5. val rotation_speed = 7. val jet_power = 0.1
			val mutable is_blowing_up = false val mutable is_damaged = false
			val mutable visible = true val mutable fire_on = false
			

			(* Graphical data  *)
			val body = Tools.load_image render "../data/images/sprites.png"  
				(Sdl.Rect.create ~x:2048 ~y:0 ~w:256 ~h:256) ship_size

			val fire = Tools.load_image render  "../data/images/sprites.png"
				(Sdl.Rect.create ~x:2048 ~y:256 ~w:256 ~h:256) ship_size

			(* ----- Getter -------  *)
			(* Logical data  *)
			method get_x = x method get_y = y method get_angle = angle
			method get_center_x = x +. ((float_of_int ship_size) /. 2.)
			method get_center_y = y +. ((float_of_int ship_size) /. 2.)
			method get_radius = ( Float.sqrt (2. *. (float_of_int ship_size)**2.) ) /. 2.
			method get_visible = visible method get_fire_on = fire_on

			(* Graphical data  *)
			method get_body = body method get_fire = fire 

			(* ---- Setter -------- *)
			method set_fire_on value = fire_on <- value
			method set_new_angle a = new_angle <- a
		
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
					| (a, _) when a > screen_w - ship_size -> begin velocity_x <- 0.; x <- float_of_int (screen_w - ship_size) end
					| (_, b) when b < 0 -> begin velocity_y <- 0.; y <- 0. end
					| (_, b) when b > screen_h - ship_size -> begin velocity_y <- 0.; y <- float_of_int (screen_h - ship_size) end
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
				(* -------------------- *)
				
				in (* start update function  *)
				begin
					go;
					velocity;
					screen_border; 
					slerp_rotate;
				end

			
	end
end
