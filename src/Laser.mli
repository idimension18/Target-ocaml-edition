open Tsdl
open Tsdl_image
open Tsdl_mixer
open Tools

module Laser : sig
	val height : float
	val width : float
	
	class laser : Sdl.renderer -> float -> float -> float -> object
	  val angle : float
	  val sound : Mixer.chunk
	  val speed : float
	  val texture : Sdl.texture
	  val mutable to_destroy : bool
	  val mutable x : float
	  val mutable y : float
	  method get_angle : float
	  method get_center_x : float
	  method get_center_y : float
	  method get_int_x : int
	  method get_int_y : int
	  method get_radius : float
	  method get_sound : Mixer.chunk
	  method get_texture : Sdl.texture
	  method get_to_destroy : bool
	  method get_x : float
	  method get_y : float
	  method set_to_destroy : unit
	  method update : int * int -> unit
	end
end
