open Tsdl
open Tsdl_image
open Tsdl_ttf


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
	

module Interface = struct 
	class infos render = object
		(* ---- Variables ---- *)
		(* life  *)
		val mutable life = 3
		val life_texture = load_whole_image render "../data/images/life.png" 45

		(* score *)
		val mutable score_value = 0
		val font = check_result (Ttf.open_font "../data/fonts/m5x7.ttf" 50)
		val color = (Sdl.Color.create ~r:0 ~g:255 ~b:0 ~a:0)

		(* ---- GETTER ----*)
		(* life  *)
		method get_life = life
		method get_life_texture = life_texture

		(* score *)
		method get_score_texture = 
			let surface = check_result (Ttf.render_text_solid font 
			 ("score : " ^ (string_of_int score_value)) color) in
			check_result (Sdl.create_texture_from_surface render surface)

		(* ---- SETTER ---- *)
		method add_score new_score = score_value <- score_value + new_score
		method lost_life = life <- life - 1
		method reset = begin life <- 3; score_value <- 0 end
	end


	
	class score_info render new_x new_y value = object
		(* ---- Variables ---- *)
		(* Logic datas *)
		val x = new_x; val mutable y = new_y val mutable velocity_y = 10.
		val mutable timer = 0 val timer_limit = 120
		val mutable to_destroy = false
		 
		(* Graphics *)
		val texture = 
			let surface = check_result (Ttf.render_text_solid 
				(check_result (Ttf.open_font "../data/fonts/m5x7.ttf" 27)) (string_of_int value)
				(Sdl.Color.create ~r:0 ~g:255 ~b:0 ~a:0)) in
			check_result (Sdl.create_texture_from_surface render surface)

		(* ---- GETTER ---- *)
		(* Logic data *)
		method get_int_x = (int_of_float x)
		method get_int_y = (int_of_float y)
		method get_to_destroy = to_destroy
		
		(* Graphics *)
		method get_texture = texture
		
		(* ---- Other methods ---- *)
		method update () =
			begin
				timer <- timer + 1;
				if timer < timer_limit then begin y <- y -. velocity_y; velocity_y <- velocity_y /. 1.5 end
				else begin to_destroy <- true end
			end
	end
end
