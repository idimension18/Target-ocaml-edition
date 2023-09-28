open Tsdl
open Tsdl_image
open Tsdl_mixer

let check_result rsl = match rsl with
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
	| Ok rtn -> rtn


module Laser = struct
	let height = 13.
	let width = 50.
	class laser render new_x new_y new_angle = 
		object
			(* ------- Variables ------ *)
			(* Logic Data *)
			val mutable x = new_x val mutable y = new_y val mutable to_destroy = false
			val speed = 10. val angle = new_angle
			(* val height = 13. val width = 50.   Never change this X/ *)

			(* Sonor *)
			val sound =  check_result (Mixer.load_wav "../data/music/lazer.wav")
			
			(* Graphics *)
			val texture = let laser_img = check_result (Image.load "../data/images/laser.png") in
				check_result (Sdl.create_texture_from_surface render laser_img)

			(* --------- GETTER -----------*)
			(* Logic Data *)
			method get_x = x method get_y = y method get_angle = angle
			method get_int_x = (int_of_float x) method get_int_y = (int_of_float y)
			method get_center_x =  (* the head x *)
				(x +. width /. 2.) +. (Float.cos (angle *. (Float.pi /. 180. )) ) *. (width /. 2.)
			method get_center_y =  (* the head y *)
				(y +. height /. 2.) +. (Float.sin (angle *. (Float.pi /. 180. )) ) *. (height /. 2.)
			method get_radius = 0.
			method get_to_destroy = to_destroy
			
			(* Sonor *)
			method get_sound = sound

			(* Graphics *)
			method get_texture = texture
			
			(* --------- update ------------*)
			method update (screen_w, screen_h) = 
				let go = 
					x <- x +. (Float.cos (angle *. (Float.pi /. 180.))) *. speed;
					y <- y +. (Float.sin (angle *. (Float.pi /. 180.))) *. speed;
					
				and over_screen =
					if (x > (float_of_int screen_w) || x < 0. || y > (float_of_int screen_h) || y < 0.) 
						then to_destroy <- true
				in 
				begin
					go;
					over_screen
				end

			
		end 
end
