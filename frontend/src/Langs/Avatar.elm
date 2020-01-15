module Langs.Avatar exposing (encode, decode)


import Bitwise
import Char

import Utils.Funcs
import Utils.Types

import Math.Vector3


{-

  avatar        := <header> <cmds> <footer>

                    author.language.project.feature.version
  header        := "dptole.elm.blog.avatar.0"

                    one or more commands
  cmds          := [ <square> ] +

                    4 bits
                    b0001 = draw square flag
  square        := b0001 <cmd_flag> <coord_x> <coord_y> <color> <color_filler>

                    4 bits
                    x y sign bits
                    bxx00 = positive coord_x / positive coord_y
                    bxx01 = positive coord_x / negative coord_y
                    bxx10 = negative coord_x / positive coord_y
                    bxx11 = negative coord_x / negative coord_y

                    quadrant bits
                    b00xx = quadrant 1
                    b01xx = quadrant 2
                    b10xx = quadrant 3
                    b11xx = quadrant 4

                    bit ranging from b0000 to b1111
  cmd_flag      := b0000-b1111

                    4 bits
                    b0000 = 0
                    b0001 = 1
                    b0010 = 2
                    b0011 = 3
                    b0100 = 4
                    b0101 = 5
                    b0110 = 6
                    b0111 = 7
                    b1000 = 8
                    b1001 = 9
                    b1010 = 10

                    bits between b1010 and b1111 are invalid
  coord_x       := b0000-b1001
  coord_y       := b0000-b1001

                    5 bits
                    b00000 = rgb(170, 170, 170) | aaaaaa
                    b00001 = rgb(51, 51, 51)    | 333333
                    b00010 = rgb(255, 102, 102) | ff6666
                    b00011 = rgb(255, 201, 102) | ffc966
                    b00100 = rgb(252, 244, 130) | fcf482
                    b00101 = rgb(164, 232, 125) | a4e87d
                    b00110 = rgb(131, 163, 252) | 83a3fc
                    b00111 = rgb(168, 147, 210) | a893d2
                    b01000 = rgb(248, 210, 249) | f8d2f9
                    b01001 = rgb(255, 0, 0)     | ff0000
                    b01010 = rgb(255, 165, 0)   | ffa500
                    b01011 = rgb(255, 255, 0)   | ffff00
                    b01100 = rgb(0, 128, 0)     | 008000
                    b01101 = rgb(0, 0, 255)     | 0000ff
                    b01110 = rgb(75, 0, 130)    | 4b0082
                    b01111 = rgb(238, 130, 238) | ee82ee
                    b10000 = rgb(153, 0, 0)     | 990000
                    b10001 = rgb(150, 86, 3)    | 965603
                    b10010 = rgb(153, 153, 0)   | 999900
                    b10011 = rgb(41, 87, 15)    | 29570f
                    b10100 = rgb(4, 43, 149)    | 042b95
                    b10101 = rgb(44, 30, 72)    | 2c1e48
                    b10110 = rgb(177, 24, 180)  | b118b4
  color         := b00000-b10110

  color_filler  := b000

  footer        := "end"

-}


encode : List Utils.Types.AvatarDrawingCmd -> String
encode cmds =
  let
    iter : List Utils.Types.AvatarDrawingCmd -> List String
    iter all_cmds =
      case all_cmds of
        head_cmd :: tail_cmds ->
          case head_cmd of
            Utils.Types.LineDrawingCmd v ->
              iter tail_cmds

            Utils.Types.SquareDrawingCmd vertexes ->
              case vertexes of
                vertex1 :: vertex2 :: vertex3 :: vertex4 :: _ ->
                  let
                    avatar_color = vec32AvatarColor vertex1.color

                    xs =
                      [ Math.Vector3.getX vertex1.position
                      , Math.Vector3.getX vertex2.position
                      , Math.Vector3.getX vertex3.position
                      , Math.Vector3.getX vertex4.position
                      ]

                    ys =
                      [ Math.Vector3.getY vertex1.position
                      , Math.Vector3.getY vertex2.position
                      , Math.Vector3.getY vertex3.position
                      , Math.Vector3.getY vertex4.position
                      ]

                    l_min_x = Utils.Funcs.minimum xs
                    l_min_y = Utils.Funcs.minimum ys

                    l_max_x = Utils.Funcs.maximum xs
                    l_max_y = Utils.Funcs.maximum ys

                  in
                    case Utils.Funcs.head4 l_min_x l_max_x l_min_y l_max_y of
                      Nothing ->
                        iter tail_cmds

                      Just { a, b, c, d } ->
                        let
                          min_x = a
                          max_x = b
                          min_y = c
                          max_y = d

                          (q, x, y) =
                            if max_y == 1.0 && min_x == -1.0 then
                              ( 3 -- 3 bits = 11 = quadrant 4
                              , min_x
                              , max_y
                              )

                            else if
                              max_y == 1.0 && min_x /= -1 ||
                              max_x == 1 && min_y /= -1
                            then
                              ( 2 -- 2 bits = 10 = quadrant 3
                              , max_x
                              , max_y
                              )

                            else if min_y == -1 && max_x == 1 then
                              ( 1 -- 1 bit = 01 = quadrant 2
                              , max_x
                              , min_y
                              )

                            else
                              ( 0 -- 0 bits = 00 = quadrant 1
                              , min_x
                              , min_y
                              )

                          sign =
                            if x >= 0 && y >= 0 then
                              0

                            else if x >= 0 && y < 0 then
                              1

                            else if x < 0 && y >= 0 then
                              2

                            else
                              3

                          first_byte =
                            Bitwise.shiftLeftBy 2 q
                              |> Bitwise.or sign
                              |> Bitwise.or 16

                          second_byte =
                            Bitwise.shiftLeftBy 4 ( abs x |> (*) 10 |> round )
                              |> Bitwise.or ( abs y |> (*) 10 |> round )

                          third_byte =
                            Bitwise.shiftLeftBy 3 avatar_color

                        in
                          ( Char.fromCode first_byte |> String.fromChar ) ::
                          ( Char.fromCode second_byte |> String.fromChar ) ::
                          ( Char.fromCode third_byte |> String.fromChar ) ::
                          iter tail_cmds

                _ ->
                  iter tail_cmds

        _ ->
          []

  in
    header ++
    ( iter cmds |> String.join "" ) ++
    footer


decode : String -> Result String ( List Utils.Types.AvatarDrawingCmd )
decode avatar =
  let
    iter : String -> List Utils.Types.AvatarDrawingCmd -> Result String ( List Utils.Types.AvatarDrawingCmd )
    iter av c =
      case String.toList av of
        first_byte :: second_byte :: third_byte :: av_tail ->
          case char2AvatarDrawingCmd first_byte of
            Ok drawing_cmd ->
              case parseAvatarCmd first_byte second_byte third_byte of
                Ok cmd ->
                  iter
                    ( String.fromList av_tail )
                    ( List.append c [ cmd ] )

                Err e ->
                  Err e

            Err e ->
              Err e

        _ ->
          Ok c

    header_length = String.length header
    footer_length = String.length footer
    avatar_length = String.length avatar

    avatar_footer = String.slice -footer_length avatar_length avatar
    avatar_header = String.slice 0 header_length avatar
    avatar_body = String.slice header_length -footer_length avatar

  in
    if header /= avatar_header then
      Err "Invalid header."

    else if footer /= avatar_footer then
      Err "Invalid footer."

    else
      iter avatar_body []



-- MISC


-- MISC CONVERTERS


parseAvatarCmd : Char -> Char -> Char -> Result String Utils.Types.AvatarDrawingCmd
parseAvatarCmd char1 char2 char3 =
  case char2AvatarDrawingCmd char1 of
    Err err ->
      Err err

    Ok drawing_cmd ->
      case drawing_cmd of
        Utils.Types.LineDrawingCmd _ ->
          Ok
            ( Utils.Types.LineDrawingCmd
              ( Utils.Types.Vertex
                  ( Math.Vector3.vec3 0 0 0 )
                  ( Math.Vector3.vec3 0 0 0 )
              )
            )

        Utils.Types.SquareDrawingCmd _ ->
          let
            ( first_byte, second_byte, third_byte ) =
              ( Char.toCode char1
              , Char.toCode char2
              , Char.toCode char3
              )

            cmd_flag = Bitwise.and 15 first_byte

            q_bits = Bitwise.shiftRightBy 2 cmd_flag

            q =
              if q_bits == 0 then -- 1
                (\x2 y2 ->
                  { p1x = x2
                  , p1y = y2

                  , p2x = x2 + 0.1
                  , p2y = y2

                  , p3x = x2
                  , p3y = y2 + 0.1

                  , p4x = x2 + 0.1
                  , p4y = y2 + 0.1
                  }
                )

              else if q_bits == 1 then -- 2
                (\x2 y2 ->
                  { p1x = x2
                  , p1y = y2

                  , p2x = x2 - 0.1
                  , p2y = y2

                  , p3x = x2
                  , p3y = y2 + 0.1

                  , p4x = x2 - 0.1
                  , p4y = y2 + 0.1
                  }
                )

              else if q_bits == 2 then -- 3
                (\x2 y2 ->
                  { p1x = x2
                  , p1y = y2

                  , p2x = x2 - 0.1
                  , p2y = y2

                  , p3x = x2
                  , p3y = y2 - 0.1

                  , p4x = x2 - 0.1
                  , p4y = y2 - 0.1
                  }
                )

              else -- 4
                (\x2 y2 ->
                  { p1x = x2
                  , p1y = y2

                  , p2x = x2 + 0.1
                  , p2y = y2

                  , p3x = x2
                  , p3y = y2 - 0.1

                  , p4x = x2 + 0.1
                  , p4y = y2 - 0.1
                  }
                )

            x_sign =
              if Bitwise.and 2 cmd_flag == 2 then
                -1.0

              else
                1.0

            y_sign =
              if Bitwise.and 1 cmd_flag == 1 then
                -1.0

              else
                1.0

            x = toFloat ( Bitwise.shiftRightBy 4 second_byte ) * 1.0

            y = toFloat ( Bitwise.and 15 second_byte ) * 1.0

            color = Bitwise.shiftRightBy 3 third_byte |> avatarColor2Vec3

          in
            if x > 10 then
              Err "X cannot be greater than 10."

            else if y > 10 then
              Err "Y cannot be greater than 10."

            else
              case q ( x_sign * x / 10.0 ) ( y_sign * y / 10.0 ) of
                { p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y } ->
                  Ok
                    ( Utils.Types.SquareDrawingCmd
                      [ Utils.Types.Vertex
                          ( Math.Vector3.vec3 p1x p1y 0 )
                          color

                      , Utils.Types.Vertex
                          ( Math.Vector3.vec3 p2x p2y 0 )
                          color

                      , Utils.Types.Vertex
                          ( Math.Vector3.vec3 p3x p3y 0 )
                          color

                      , Utils.Types.Vertex
                          ( Math.Vector3.vec3 p4x p4y 0 )
                          color
                      ]
                    )


char2AvatarDrawingCmd : Char -> Result String Utils.Types.AvatarDrawingCmd
char2AvatarDrawingCmd c =
  let
    code = Char.toCode c
    first_4_bits = Bitwise.shiftRightBy 4 code

  in
    if Bitwise.and 1 first_4_bits == 1 then
      Utils.Types.SquareDrawingCmd []
        |> Ok

    else
      "Invalid avatar drawing command: " ++ ( String.fromInt first_4_bits )
        |> Err


avatarColor2Vec3 : Int -> Math.Vector3.Vec3
avatarColor2Vec3 c =
  if c == 0 then
    color0

  else if c == 2 then
    color2

  else if c == 3 then
    color3

  else if c == 4 then
    color4

  else if c == 5 then
    color5

  else if c == 6 then
    color6

  else if c == 7 then
    color7

  else if c == 8 then
    color8

  else if c == 9 then
    color9

  else if c == 10 then
    color10

  else if c == 11 then
    color11

  else if c == 12 then
    color12

  else if c == 13 then
    color13

  else if c == 14 then
    color14

  else if c == 15 then
    color15

  else if c == 16 then
    color16

  else if c == 17 then
    color17

  else if c == 18 then
    color18

  else if c == 19 then
    color19

  else if c == 20 then
    color20

  else if c == 21 then
    color21

  else if c == 22 then
    color22

  else
    color1


vec32AvatarColor : Math.Vector3.Vec3 -> Int
vec32AvatarColor v =
  let
    red = Math.Vector3.getX v
    green = Math.Vector3.getY v
    blue = Math.Vector3.getZ v

  in
    if red == Math.Vector3.getX color0 && green == Math.Vector3.getY color0 && blue == Math.Vector3.getZ color0 then
      0

    else if red == Math.Vector3.getX color2 && green == Math.Vector3.getY color2 && blue == Math.Vector3.getZ color2 then
      2

    else if red == Math.Vector3.getX color3 && green == Math.Vector3.getY color3 && blue == Math.Vector3.getZ color3 then
      3

    else if red == Math.Vector3.getX color4 && green == Math.Vector3.getY color4 && blue == Math.Vector3.getZ color4 then
      4

    else if red == Math.Vector3.getX color5 && green == Math.Vector3.getY color5 && blue == Math.Vector3.getZ color5 then
      5

    else if red == Math.Vector3.getX color6 && green == Math.Vector3.getY color6 && blue == Math.Vector3.getZ color6 then
      6

    else if red == Math.Vector3.getX color7 && green == Math.Vector3.getY color7 && blue == Math.Vector3.getZ color7 then
      7

    else if red == Math.Vector3.getX color8 && green == Math.Vector3.getY color8 && blue == Math.Vector3.getZ color8 then
      8

    else if red == Math.Vector3.getX color9 && green == Math.Vector3.getY color9 && blue == Math.Vector3.getZ color9 then
      9

    else if red == Math.Vector3.getX color10 && green == Math.Vector3.getY color10 && blue == Math.Vector3.getZ color10 then
      10

    else if red == Math.Vector3.getX color11 && green == Math.Vector3.getY color11 && blue == Math.Vector3.getZ color11 then
      11

    else if red == Math.Vector3.getX color12 && green == Math.Vector3.getY color12 && blue == Math.Vector3.getZ color12 then
      12

    else if red == Math.Vector3.getX color13 && green == Math.Vector3.getY color13 && blue == Math.Vector3.getZ color13 then
      13

    else if red == Math.Vector3.getX color14 && green == Math.Vector3.getY color14 && blue == Math.Vector3.getZ color14 then
      14

    else if red == Math.Vector3.getX color15 && green == Math.Vector3.getY color15 && blue == Math.Vector3.getZ color15 then
      15

    else if red == Math.Vector3.getX color16 && green == Math.Vector3.getY color16 && blue == Math.Vector3.getZ color16 then
      16

    else if red == Math.Vector3.getX color17 && green == Math.Vector3.getY color17 && blue == Math.Vector3.getZ color17 then
      17

    else if red == Math.Vector3.getX color18 && green == Math.Vector3.getY color18 && blue == Math.Vector3.getZ color18 then
      18

    else if red == Math.Vector3.getX color19 && green == Math.Vector3.getY color19 && blue == Math.Vector3.getZ color19 then
      19

    else if red == Math.Vector3.getX color20 && green == Math.Vector3.getY color20 && blue == Math.Vector3.getZ color20 then
      20

    else if red == Math.Vector3.getX color21 && green == Math.Vector3.getY color21 && blue == Math.Vector3.getZ color21 then
      21

    else if red == Math.Vector3.getX color22 && green == Math.Vector3.getY color22 && blue == Math.Vector3.getZ color22 then
      22

    else
      1



-- MISC CONSTANTS


color0 : Math.Vector3.Vec3
color0 =
  Math.Vector3.vec3
    ( 170.0 / 255.0 ) ( 170.0 / 255.0 ) ( 170.0 / 255.0 )


color1 : Math.Vector3.Vec3
color1 =
  Math.Vector3.vec3
    ( 51.0 / 255.0 ) ( 51.0 / 255.0 ) ( 51.0 / 255.0 )


color2 : Math.Vector3.Vec3
color2 =
  Math.Vector3.vec3
    ( 255.0 / 255.0 ) ( 102.0 / 255.0 ) ( 102.0 / 255.0 )


color3 : Math.Vector3.Vec3
color3 =
  Math.Vector3.vec3
    ( 255.0 / 255.0 ) ( 201.0 / 255.0 ) ( 102.0 / 255.0 )


color4 : Math.Vector3.Vec3
color4 =
  Math.Vector3.vec3
    ( 252.0 / 255.0 ) ( 244.0 / 255.0 ) ( 130.0 / 255.0 )


color5 : Math.Vector3.Vec3
color5 =
  Math.Vector3.vec3
    ( 164.0 / 255.0 ) ( 232.0 / 255.0 ) ( 125.0 / 255.0 )


color6 : Math.Vector3.Vec3
color6 =
  Math.Vector3.vec3
    ( 131.0 / 255.0 ) ( 163.0 / 255.0 ) ( 252.0 / 255.0 )


color7 : Math.Vector3.Vec3
color7 =
  Math.Vector3.vec3
    ( 168.0 / 255.0 ) ( 147.0 / 255.0 ) ( 210.0 / 255.0 )


color8 : Math.Vector3.Vec3
color8 =
  Math.Vector3.vec3
    ( 248.0 / 255.0 ) ( 210.0 / 255.0 ) ( 249.0 / 255.0 )


color9 : Math.Vector3.Vec3
color9 =
  Math.Vector3.vec3
    ( 255.0 / 255.0 ) ( 0.0 / 255.0 ) ( 0.0 / 255.0 )


color10 : Math.Vector3.Vec3
color10 =
  Math.Vector3.vec3
    ( 255.0 / 255.0 ) ( 165.0 / 255.0 ) ( 0.0 / 255.0 )


color11 : Math.Vector3.Vec3
color11 =
  Math.Vector3.vec3
    ( 255.0 / 255.0 ) ( 255.0 / 255.0 ) ( 0.0 / 255.0 )


color12 : Math.Vector3.Vec3
color12 =
  Math.Vector3.vec3
    ( 0.0 / 255.0 ) ( 128.0 / 255.0 ) ( 0.0 / 255.0 )


color13 : Math.Vector3.Vec3
color13 =
  Math.Vector3.vec3
    ( 0.0 / 255.0 ) ( 0.0 / 255.0 ) ( 255.0 / 255.0 )


color14 : Math.Vector3.Vec3
color14 =
  Math.Vector3.vec3
    ( 75.0 / 255.0 ) ( 0.0 / 255.0 ) ( 130.0 / 255.0 )


color15 : Math.Vector3.Vec3
color15 =
  Math.Vector3.vec3
    ( 238.0 / 255.0 ) ( 130.0 / 255.0 ) ( 238.0 / 255.0 )


color16 : Math.Vector3.Vec3
color16 =
  Math.Vector3.vec3
    ( 153.0 / 255.0 ) ( 0.0 / 255.0 ) ( 0.0 / 255.0 )


color17 : Math.Vector3.Vec3
color17 =
  Math.Vector3.vec3
    ( 150.0 / 255.0 ) ( 86.0 / 255.0 ) ( 3.0 / 255.0 )


color18 : Math.Vector3.Vec3
color18 =
  Math.Vector3.vec3
    ( 153.0 / 255.0 ) ( 153.0 / 255.0 ) ( 0.0 / 255.0 )


color19 : Math.Vector3.Vec3
color19 =
  Math.Vector3.vec3
    ( 41.0 / 255.0 ) ( 87.0 / 255.0 ) ( 15.0 / 255.0 )


color20 : Math.Vector3.Vec3
color20 =
  Math.Vector3.vec3
    ( 4.0 / 255.0 ) ( 43.0 / 255.0 ) ( 149.0 / 255.0 )


color21 : Math.Vector3.Vec3
color21 =
  Math.Vector3.vec3
    ( 44.0 / 255.0 ) ( 30.0 / 255.0 ) ( 72.0 / 255.0 )


color22 : Math.Vector3.Vec3
color22 =
  Math.Vector3.vec3
    ( 177.0 / 255.0 ) ( 24.0 / 255.0 ) ( 180.0 / 255.0 )


header : String
header = "dptole.elm.blog.avatar.WebGL.0"


footer : String
footer = "end"



