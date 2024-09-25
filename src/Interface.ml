open Tsdl
open Tsdl_image
open Tsdl_ttf
open Tools


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
		method reset = (life <- 3; score_value <- 0)
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
		(
			timer <- timer + 1;
			if timer < timer_limit then (y <- y -. velocity_y; velocity_y <- velocity_y /. 1.5)
			else (to_destroy <- true)
		)
	end
end
