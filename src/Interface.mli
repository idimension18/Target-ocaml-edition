open Tsdl
open Tsdl_image
open Tsdl_ttf
open Tools 


module Interface : sig
	class infos : Sdl.renderer -> object
	  val color : Sdl.color
	  val font : Ttf.font
	  val mutable life : int
	  val life_texture : Sdl.texture
	  val mutable score_value : int
	  method add_score : int -> unit
	  method get_life : int
	  method get_life_texture : Sdl.texture
	  method get_score_texture : Sdl.texture
	  method lost_life : unit
	  method reset : unit
	end
	
  class score_info : Sdl.renderer -> float -> float -> int -> object
	   val texture : Sdl.texture
	   val mutable timer : int
	   val timer_limit : int
	   val mutable to_destroy : bool
	   val mutable velocity_y : float
	   val x : float
	   val mutable y : float
	   method get_int_x : int
	   method get_int_y : int
	   method get_texture : Sdl.texture
	   method get_to_destroy : bool
	   method update : unit -> unit
	end
end
