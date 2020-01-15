module Utils.Graphs.Bars exposing (..)

import Utils.Funcs
import Utils.Types

import Html
import Html.Attributes
import Math.Vector3
import Math.Matrix4
import WebGL



type alias Uniforms =
  {}


default : List Float -> List String -> Html.Html msg
default data periods =
  WebGL.toHtmlWith
    [ WebGL.alpha True, WebGL.depth 1 ]
    [ Html.Attributes.width 300
    , Html.Attributes.height 300
    , Html.Attributes.class "webgl-graphs-bars"
    ]
    [ WebGL.entity vertexShader fragmentShader ( defaultMesh data periods ) Uniforms ]



-- MESHES


defaultMesh : List Float -> List String -> WebGL.Mesh Utils.Types.Vertex
defaultMesh data periods =
  let
    y_axis_data = yAxis data periods
    x_axis_data = xAxis data periods

  in
    List.concat
      [ y_axis_data
      , x_axis_data
      ]
      |> WebGL.triangles



-- SHADERS


vertexShader : WebGL.Shader Utils.Types.Vertex Uniforms { vcolor : Math.Vector3.Vec3 }
vertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec3 color;
        varying vec3 vcolor;

        void main () {
            gl_Position = vec4(position, 1.0);
            vcolor = color;
        }
    |]


fragmentShader : WebGL.Shader {} Uniforms { vcolor : Math.Vector3.Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;
        varying vec3 vcolor;

        void main () {
            gl_FragColor = vec4(vcolor, 1.0);
        }
    |]



-- MISC


-- TRANSFORMERS


transformVertexes : Math.Matrix4.Mat4 -> List ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex ) -> List ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex )
transformVertexes translate vertexes =
  List.map ( transformVertex translate ) vertexes


transformVertex : Math.Matrix4.Mat4 -> ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex ) -> ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex )
transformVertex translate ( p1, p2, p3 ) =
  ( Utils.Types.Vertex ( Math.Matrix4.transform translate p1.position ) p1.color
  , Utils.Types.Vertex ( Math.Matrix4.transform translate p2.position ) p2.color
  , Utils.Types.Vertex ( Math.Matrix4.transform translate p3.position ) p3.color
  )
  


-- AXIS


xAxisHeight : Float
xAxisHeight = 0.01


xAxisWidth : Float
xAxisWidth = 1.9


xAxisLeft : Float
xAxisLeft = 0.05


xAxisTop : Float
xAxisTop = 1.9


xAxis : List Float -> List String -> List ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex )
xAxis data periods =
  let
    max_data = Utils.Funcs.maximumFloat data

    translate = Math.Matrix4.makeTranslate ( Math.Vector3.vec3 ( xAxisLeft - 1 ) ( 1 - xAxisTop ) 0 )

    total_periods = List.length periods

    total_periods_float = toFloat total_periods

    bars_gutter = 0.05

    max_bars_width = maxBarsWidth - ( total_periods_float - 1 ) * bars_gutter

    bars_width = max_bars_width / total_periods_float

    indexed_records = Utils.Funcs.listNumberString2IndexedRecords data periods

    max_bars_height = 2 - ( 2 - ( yAxisHeight - yAxisTop ) )

    bars =
      List.concatMap (\{index, a, b} ->
        let
          f = toFloat index

          bars_height = ( max_bars_height / max_data ) * a

          gutter =
            if index > 0 then
              bars_gutter * f
            else
              0

          translate_x = bars_width * f + gutter

        in
          [ ( Utils.Types.Vertex ( Math.Vector3.vec3 barsLeft 0 0 ) ( Math.Vector3.vec3 1 0 0 )
            , Utils.Types.Vertex ( Math.Vector3.vec3 ( barsLeft + bars_width ) 0 0 ) ( Math.Vector3.vec3 0 1 0 )
            , Utils.Types.Vertex ( Math.Vector3.vec3 barsLeft bars_height 0 ) ( Math.Vector3.vec3 0 0 1 )
            )
          , ( Utils.Types.Vertex ( Math.Vector3.vec3 ( barsLeft + bars_width ) 0 0 ) ( Math.Vector3.vec3 0 1 0 )
            , Utils.Types.Vertex ( Math.Vector3.vec3 barsLeft bars_height 0 ) ( Math.Vector3.vec3 0 0 1 )
            , Utils.Types.Vertex ( Math.Vector3.vec3 ( barsLeft + bars_width ) bars_height 0 ) ( Math.Vector3.vec3 1 0 0 )
            )
          ]
          |> transformVertexes ( Math.Matrix4.makeTranslate ( Math.Vector3.vec3 translate_x 0 0 ) )

      ) indexed_records

    axis = 
      [ ( Utils.Types.Vertex ( Math.Vector3.vec3 0 0 0 ) ( Math.Vector3.vec3 0 0 0 )
        , Utils.Types.Vertex ( Math.Vector3.vec3 xAxisWidth 0 0 ) ( Math.Vector3.vec3 0 0 0 )
        , Utils.Types.Vertex ( Math.Vector3.vec3 0 xAxisHeight 0 ) ( Math.Vector3.vec3 0 0 0 )
        )
      , ( Utils.Types.Vertex ( Math.Vector3.vec3 0 xAxisHeight 0 ) ( Math.Vector3.vec3 0 0 0 )
        , Utils.Types.Vertex ( Math.Vector3.vec3 xAxisWidth 0 0 ) ( Math.Vector3.vec3 0 0 0 )
        , Utils.Types.Vertex ( Math.Vector3.vec3 xAxisWidth xAxisHeight 0 ) ( Math.Vector3.vec3 0 0 0 )
        )
      ]

    meshed_triangles =
      List.concat
        [ axis
        , bars
        ]

  in
    transformVertexes translate meshed_triangles


yAxisHeight : Float
yAxisHeight = 1.9


yAxisWidth : Float
yAxisWidth = 0.01


yAxisLeft : Float
yAxisLeft = 0.1


yAxisTop : Float
yAxisTop = 0.05


yAxisPaddingLeft : Float
yAxisPaddingLeft = 0.05


yAxisPaddingRight : Float
yAxisPaddingRight = 0.05


yAxisPaddingLeftRight : Float
yAxisPaddingLeftRight = yAxisPaddingLeft + yAxisPaddingRight


yAxis : List Float -> List String -> List ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex )
yAxis data periods =
  let
    translate =
      Math.Matrix4.makeTranslate ( Math.Vector3.vec3 ( yAxisLeft - 1 ) ( 1 - yAxisTop ) 0 )

  in
    [ ( Utils.Types.Vertex ( Math.Vector3.vec3 0 0 0 ) ( Math.Vector3.vec3 0 0 0 )
      , Utils.Types.Vertex ( Math.Vector3.vec3 yAxisWidth 0 0 ) ( Math.Vector3.vec3 0 0 0 )
      , Utils.Types.Vertex ( Math.Vector3.vec3 0 -yAxisHeight 0 ) ( Math.Vector3.vec3 0 0 0 )
      )
    , ( Utils.Types.Vertex ( Math.Vector3.vec3 0 -yAxisHeight 0 ) ( Math.Vector3.vec3 0 0 0 )
      , Utils.Types.Vertex ( Math.Vector3.vec3 yAxisWidth 0 0 ) ( Math.Vector3.vec3 0 0 0 )
      , Utils.Types.Vertex ( Math.Vector3.vec3 yAxisWidth -yAxisHeight 0 ) ( Math.Vector3.vec3 0 0 0 )
      )
    ]
    |>
    List.map (\( p1, p2, p3 ) ->
      ( Utils.Types.Vertex ( Math.Matrix4.transform translate p1.position ) p1.color
      , Utils.Types.Vertex ( Math.Matrix4.transform translate p2.position ) p2.color
      , Utils.Types.Vertex ( Math.Matrix4.transform translate p3.position ) p3.color
      )
    )


barsLeft : Float
barsLeft = yAxisPaddingLeft + yAxisWidth + yAxisPaddingRight


maxBarsWidth : Float
maxBarsWidth = xAxisWidth - barsLeft - yAxisPaddingRight



