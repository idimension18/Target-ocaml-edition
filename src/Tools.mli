open Tsdl
open Tsdl_image

val check_result : ('a, [< `Msg of string ]) result -> 'a
val check_result_ignore : ('a, [< `Msg of string ]) result -> 'a option

val load_image :
  Sdl.renderer -> string -> Sdl.rect -> int -> Sdl.texture
  
val load_whole_image : Sdl.renderer -> string -> int -> Sdl.texture

val rotation_direction : float -> float -> float

val angle_projection : float -> float

val gif_frame_time : int

type gif = {
  texture_array : Sdl.texture array;
  fs : int;
  nbf : int;
  mutable cursor : int;
  mutable timer : int;
}

val gif_create : Sdl.renderer -> string -> int -> int -> gif
val gif_update : gif -> gif
val gif_reset : gif -> gif

