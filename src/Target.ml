open Tsdl
open Tsdl_image
open Tsdl_mixer

(* check result and crash if error *)
let check_result rsl = match rsl with 
	| Error(`Msg e) -> Sdl.log "Error:%s" e; exit 1
	| Ok rtn -> rtn


let load_whole_image render link scale_rect_value = 
	let scale_rect = (Sdl.Rect.create ~x:0 ~y:0 ~w:scale_rect_value ~h:scale_rect_value) in
	let scaled_img = check_result (Sdl.create_rgb_surface ~w:scale_rect_value ~h:scale_rect_value ~depth:32
		(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
		(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000)) in
	let sheet = check_result (Image.load link) in
	let _ = check_result (Sdl.blit_scaled ~src:sheet None ~dst:scaled_img (Some scale_rect)) in
	check_result (Sdl.create_texture_from_surface render scaled_img)

module Target = struct
	class target render screen_w new_y new_size new_color_id = object 
		(* ---- Variables ---- *)
		(* Logical data *)
		val mutable x = (float_of_int screen_w)  val mutable to_destroy = false
		val y = new_y val size = new_size
		val color_id = new_color_id
		val value = int_of_float (100. *. ( 1. -. (( (float_of_int new_size) -. 50. ) /. 100.) ))
		
		(* Sounds *)
		val sound = check_result (Mixer.load_wav "../data/music/break.wav")
		
		(* Graphics *)
		val texture = let link =
			match new_color_id with
			| id when id=0 -> "../data/images/redTarget.png" 
			| id when id=1 -> "../data/images/greenTarget.png" 
			| id when id=2 -> "../data/images/yellowTarget.png" 
			| _ -> Sdl.log "Error: wrong value" ; exit 1
			in load_whole_image render link new_size

		(* ---- Getter ---- *)
		(* Logical data *)
		method get_int_x = (int_of_float x)  method get_int_y = (int_of_float y)
		method get_center_x = x +. ((float_of_int size) /. 2.)
		method get_center_y = y +. ((float_of_int size) /. 2.)
		method get_radius = (float_of_int size) /. 2.
		method get_to_destroy = to_destroy
		method get_value = value

		(* Sounds *)
		method get_sound = sound
		
		(* Graphics *)
		method get_texture = texture
		
		(* ---- Setter ---- *)
		method set_to_destroy = to_destroy <- true
		
		(* ---- Other method ----*)
		method update main_speed = 
		(
			if x < (-. (float_of_int size)) then to_destroy <- true;
			x <- x -. main_speed;
		)
	end
end
