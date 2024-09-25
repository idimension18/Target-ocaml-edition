open Tsdl
open Tsdl_image

val check_result : ('a, [< `Msg of string ]) result -> 'a
val load_image :
  Sdl.renderer -> string -> Sdl.rect -> int -> Sdl.texture
val angle_projection : float -> float
module Asteroide :
  sig
    class asteroide :
      Sdl.renderer ->
      int ->
      float ->
      int ->
      int ->
      float ->
      int ->
      object
        val mutable angle : float
        val rotation_speed : float
        val size : int
        val speed_ratio : int
        val texture : Sdl.texture
        val mutable to_destroy : bool
        val mutable x : float
        val y : float
        method get_angle : float
        method get_center_x : float
        method get_center_y : float
        method get_int_x : int
        method get_int_y : int
        method get_radius : float
        method get_texture : Sdl.texture
        method get_to_destroy : bool
        method update : float -> unit
      end
  end
