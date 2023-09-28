open Tsdl
open Tsdl_image


(* check result and crash if error *)
let check_result rsl = match rsl with 
	| Error(`Msg e) -> Sdl.log "Error:%s" e; exit 1
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

(* Hold angle between 0 and 359 *)
let angle_projection angle = match angle with
	| a when a < 0. -> (a +. 360.)
	| a when a >= 360. -> (a -. 360.)
	| _ -> angle


module Asteroide = struct
	class asteroide render screen_w new_y new_size new_type new_angle new_rotation_direction = 
		object
			(* ---- Variables ---- *)
			(* Game logic  *)
			val mutable x = screen_w val mutable angle = new_angle val mutable to_destroy = false
			val y = new_y val size = new_size val speed_ratio = 60

			val rotation_speed = let speed_ratio = 60. 
				and radius = ( Float.sqrt (2. *. ((float_of_int new_size)**2.)) ) /. 2. in
				(speed_ratio /. radius) *. (float_of_int new_rotation_direction)

			(* Game graphics *)
			val texture = let cut_rect = 
				match new_type with
				| n when n=0 -> Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0
				| n when n=1 -> Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0
				| n when n=2 -> Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0
				| n when n=3 -> Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0
				| _ -> Sdl.Rect.create ~x:0 ~y:0 ~w:0 ~h:0
				in load_image render "../data/images/asteroide.png" cut_rect new_size

			(* ---- Getter ---- *)
			(* Logical data *)
			method get_int_x = (int_of_float x) method get_int_y = (int_of_float y) 
			method get_center_x = x +. ((float_of_int size) /. 2.)  
			method get_center_y = y +. ((float_of_int size) /. 2.)
			method get_angle = angle 
			method get_radius = ( Float.sqrt (2. *. (float_of_int size)**2.) ) /. 2.
			method get_to_destroy = to_destroy
			
			(* Graphics *)
			method get_texture = texture
			
			(* ---- Other method ---- *)
			method update main_speed =
				begin
					to_destroy <- x < (-. (float_of_int size) );
					angle <- angle +. rotation_speed;
					angle <- angle_projection angle;
					x <- x +. main_speed;
				end
		end
end
		
