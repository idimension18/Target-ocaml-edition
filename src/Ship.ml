open Tsdl
open Tsdl_image

let ship_size = 64

let check rsl = match rsl with 
	| Error(`Msg e) -> Sdl.log "Error:%s" e; exit 1
	| Ok rtn -> rtn

module Ship = struct
class ship render = 
	object
		(* Logical data  *)
		val mutable x = 500 val mutable y = 250 val mutable angle = 90
		val mutable velocity_x = 0 val mutable velocity_y = 0
		val speed_max = 5. val rotation_speed = 7;

		(* Graphical data  *)
		val body  = let  cut_rect = Sdl.Rect.create ~x:2048 ~y:0 ~w:256 ~h:256 
			and scale_rect = Sdl.Rect.create ~x:0 ~y:0 ~w:ship_size ~h:ship_size
			and croped_img = check (Sdl.create_rgb_surface ~w:256 ~h:256 ~depth:32 
				(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
				(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000))
			and scaled_img = check (Sdl.create_rgb_surface ~w:64 ~h:64 ~depth:32 
				(Int32.of_int 0x000000FF) (Int32.of_int 0x0000FF00) 
				(Int32.of_int 0x00FF0000) (Int32.of_int 0xFF000000)) in 
				match Image.load "../data/images/sprites.png" with
				| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
				| Ok sheet -> 
				begin 
					match Sdl.blit_surface ~src:sheet (Some cut_rect) ~dst:croped_img None with (* unit result *)
					| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
					| Ok _ -> 
					begin 
						match Sdl.blit_scaled ~src:croped_img None ~dst:scaled_img (Some scale_rect) with
						| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
						| Ok _ -> 
						begin
							match Sdl.create_texture_from_surface render scaled_img with
							| Error(`Msg e) -> Sdl.log "Error: %s" e; exit 1
							| Ok final -> final
						end
					end
				end
		
		
end
end
