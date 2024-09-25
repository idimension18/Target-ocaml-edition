open Tsdl
open Tsdl_image
open Tools

module Asteroide = struct
	class asteroide render screen_w new_y new_size new_type new_angle new_rotation_direction = object
		(* ---- Variables ---- *)
		(* Game logic  *)
		val mutable x = (float_of_int screen_w) val mutable angle = new_angle val mutable to_destroy = false
		val y = new_y val size = new_size val speed_ratio = 60

		val rotation_speed = let speed_ratio = 60.
			and radius = ( Float.sqrt (2. *. ((float_of_int new_size)**2.)) ) /. 2. in
			(speed_ratio /. radius) *. (float_of_int new_rotation_direction)

		(* Game graphics *)
		val texture = let cut_rect = 
			match new_type with
			| n when n=0 -> Sdl.Rect.create ~x:0 ~y:0 ~w:128 ~h:128
			| n when n=1 -> Sdl.Rect.create ~x:128 ~y:0 ~w:128 ~h:128
			| n when n=2 -> Sdl.Rect.create ~x:0 ~y:128 ~w:128 ~h:128
			| n when n=3 -> Sdl.Rect.create ~x:128 ~y:128 ~w:128 ~h:128
			| _ -> Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0
			in load_image render "../data/images/asteroide.png" cut_rect new_size

		(* ---- Getter ---- *)
		(* Logical data *)
		method get_int_x = (int_of_float x) method get_int_y = (int_of_float y) 
		method get_center_x = x +. ((float_of_int size) /. 2.)  
		method get_center_y = y +. ((float_of_int size) /. 2.)
		method get_angle = angle 
		method get_radius = (float_of_int size) /. 2.
		method get_to_destroy = to_destroy
		
		(* Graphics *)
		method get_texture = texture
		
		(* ---- Other method ---- *)
		method update main_speed =
		(
			to_destroy <- x < (-. (float_of_int size) );
			angle <- angle +. rotation_speed;
			angle <- angle_projection angle;
			x <- x -. main_speed;
		)
	end
end
		
