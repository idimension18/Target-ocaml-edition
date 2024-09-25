open Tsdl
open Tsdl_image

(* check result and crash if error *)
let check_result rsl = match rsl with 
	| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
	| Ok rtn -> rtn


(* check result and ignore if error *)
let check_result_ignore rsl = match rsl with
	| Error(`Msg e) -> (Sdl.log "Error:%s" e); None
	| Ok rtn -> Some(rtn)


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

let load_whole_image render link scale_rect_value = 
	let scale_rect = (Sdl.Rect.create ~x:0 ~y:0 ~w:scale_rect_value ~h:scale_rect_value) in
	let scaled_img = check_result (Sdl.create_rgb_surface ~w:scale_rect_value ~h:scale_rect_value ~depth:32
		(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
		(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000)) in
	let sheet = check_result (Image.load link) in
	let _ = check_result (Sdl.blit_scaled ~src:sheet None ~dst:scaled_img (Some scale_rect)) in
	check_result (Sdl.create_texture_from_surface render scaled_img)


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


(* ---- GIF ---- *)
let gif_frame_time = 3; 
type gif = {texture_array: Sdl.texture array; fs: int ; nbf: int ; mutable cursor : int; mutable timer : int}

let gif_create render gif_folder frame_size nb_frame =
	let image_array = 
		Array.init nb_frame (fun i -> load_whole_image render (gif_folder^(string_of_int i)^".png") frame_size) in
	{texture_array = image_array; fs = frame_size; nbf = nb_frame; cursor = 0; timer = 0}


let gif_update gife : gif = 
	gife.timer <- gife.timer + 1; 
	if (gife.timer >= gif_frame_time) && gife.cursor <> (gife.nbf - 1) then 
	(
		gife.cursor <- gife.cursor + 1; 
		gife.timer <- 0;
		gife
	)
	else gife


 let gif_reset gife : gif = (gife.cursor <- 0; gife.timer <- 0; gife)

(* -------------- *)
