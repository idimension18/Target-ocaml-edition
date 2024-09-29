open Tsdl
open Tsdl_image
open Tsdl_mixer
open Tools

open Laser

module Ship : sig
	class ship : Sdl.renderer -> object
	  val mutable angle : float
	  val blink_time : int
	  val mutable blink_timer : int
	  val blow : Mixer.chunk
	  val mutable blow_gif : gif
	  val mutable blow_time : int
	  val mutable blow_timer : int
	  val body : Sdl.texture
	  val mutable can_recharge : bool
	  val charge_rate : float
	  val damage_time : int
	  val mutable damage_timer : int
	  val mutable energy : float
	  val fire : Sdl.texture
	  val mutable fire_on : bool
	  val mutable is_blowing_up : bool
	  val mutable is_damaged : bool
	  val mutable is_stunt : bool
	  val mutable is_visible : bool
	  val jet_power : float
	  val max_energy : float
	  val mutable new_angle : float
	  val rotation_speed : float
	  val spark : Mixer.chunk
	  val mutable spark_gif : gif
	  val speed_max : float
	  val mutable velocity_x : float
	  val mutable velocity_y : float
	  val mutable x : float
	  val mutable y : float

	  method get_angle : float
	  method get_blow : Mixer.chunk
	  method get_blow_gif : gif
	  method get_body : Sdl.texture
	  method get_center_x : float
	  method get_center_y : float
	  method get_energy : float
	  method get_fire : Sdl.texture
	  method get_fire_on : bool
	  method get_int_x : int
	  method get_int_y : int
	  method get_is_blowing_up : bool
	  method get_is_damaged : bool
	  method get_is_visible : bool
	  method get_max_energy : float
	  method get_radius : float
	  method get_spark : Mixer.chunk
	  method get_spark_gif : gif
	  method get_x : float
	  method get_y : float

	  method set_can_recharge : bool -> unit
	  method set_fire_on : bool -> unit
	  method set_is_blowing_up : unit
	  method set_is_damaged : unit
	  method set_new_angle : float -> unit
	  method sub_energy : float -> unit

    method fire_laser : Sdl.renderer -> Laser.laser option
	  method update : int * int -> unit
	end
end
