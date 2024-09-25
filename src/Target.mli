open Tsdl
open Tsdl_image
open Tsdl_mixer
open Tools 

module Target : sig
	class target : Sdl.renderer -> int -> float -> int -> int -> object
	  val color_id : int
	  val size : int
	  val sound : Mixer.chunk
	  val texture : Sdl.texture
	  val mutable to_destroy : bool
	  val value : int
	  val mutable x : float
	  val y : float
	  method get_center_x : float
	  method get_center_y : float
	  method get_int_x : int
	  method get_int_y : int
	  method get_radius : float
	  method get_sound : Mixer.chunk
	  method get_texture : Sdl.texture
	  method get_to_destroy : bool
	  method get_value : int
	  method set_to_destroy : unit
	  method update : float -> unit
	end
end
