open Tsdl
open Tsdl_image

module Asteroide = struct
	class asteroide render screen_w new_y new_size new_type new_angle new_rotation_direction = 
		object
			(* ---- Variables ---- *)
			(* Game logic  *)
			val mutable x = screen_w val mutable angle = new_angle val mutable to_destroy = false
			val y = new_y val size = new_size val rotation_direction = new_rotation_direction

			(* Game graphics *)
			
		end
end
		
