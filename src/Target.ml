open Tsdl
open Tsdl_image
open Tsdl_mixer

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
	

module Target = struct
	class target render screen_w new_y new_size new_color_id =
		object 
			(* ---- Variables ---- *)
			(* Logical data *)
			val mutable x = screen_w  val mutable to_destroy = false
			val y = new_y val size = new_size
			val color_id = new_color_id
			
			(* Sounds *)
			(* val breaks = Mixer.load_chunk *) 
			
			(* Graphics *)
			val texture = ()

			(* ---- Getter ---- *)
			method get_int_x = (int_of_float x)  method get_int_y = (int_of_float y)
			method get_to_destroy = to_destroy
			
			(* ---- Setter ---- *)
			method set_to_destroy = to_destroy <- true
			
			(* ---- Other method ----*)
			(* method target_sound = check_result Mixer. *) 
			
			method update main_speed = 
				begin
					if x < (-. (float_of_int size)) then to_destroy <- true;
					x = x +. main_speed;
				end
		end
end
