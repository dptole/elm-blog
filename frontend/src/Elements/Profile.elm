module Elements.Profile exposing (..)

import Langs.Avatar

import Utils.Api
import Utils.Decoders
import Utils.Encoders
import Utils.Funcs
import Utils.Types
import Utils.Work

import Bitwise
import Dict
import Json.Decode
import Html
import Html.Attributes
import Html.Events
import Http
import Math.Vector3
import WebGL



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | NoOp
  | CartesianPlaneCoordsClick Coords
  | AvatarToolSelected AvatarTool
  | ExitingAvatarToolEditing
  | StartEditingAvatar
  | EndEditingAvatar
  | UndoLastCmd
  | UpdateColor String
  | SaveAvatar
  | TypingPassword String
  | UpdatePassword
  | GotUpdatePasswordResponse ( Result Http.Error Utils.Types.AuthUser_ )
  | GotSaveAvatarResponse ( Result Http.Error Utils.Types.AuthUser )
  | FetchAvatar
  | GotFetchAvatarResponse ( Result Http.Error Utils.Types.UserAvatar )



type AvatarTool
  = SelectTool
  | LineTool
  | PencilTool
  | BucketTool
  | SquareTool
  | EllipsisTool



-- MODEL


type alias Model =
  { canvas_width : Int
  , canvas_height : Int
  , range_lines_from : Int
  , range_lines_to : Int
  , vertexes : List Utils.Types.Vertex
  , work : Int
  , drawing_cmds : List Utils.Types.AvatarDrawingCmd
  , active_drawing_cmd : Maybe Utils.Types.AvatarDrawingCmd
  , selected_color : String
  , password : String
  , final_avatar : List Utils.Types.AvatarDrawingCmd
  , dict_errors : Dict.Dict String String
  , http_cmds : Dict.Dict String ( Cmd Msg )
  }


type alias Coords =
  { x : Int
  , y : Int
  }


type alias Clipspace =
  { xr : Float
  , yr : Float
  , xc : Float
  , yc : Float
  , xf : Float
  , yf : Float
  }


type alias Uniforms =
  {}



-- INIT


initModel : Model
initModel =
  Model
    300                         -- canvas_width
    300                         -- canvas_height
    -10                         -- range_lines_from
    10                          -- range_lines_to
    []                          -- vertexes
    Utils.Work.notWorking       -- work
    []                          -- drawing_cmds
    Nothing                     -- active_drawing_cmd
    getColorsPalettColor1       -- selected_color
    ""                          -- password
    []                          -- final_avatar
    Utils.Funcs.emptyDict       -- dict_errors
    Utils.Funcs.emptyDict       -- http_cmds



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    NoOp ->
      ( model, Cmd.none )

    FetchAvatar ->
      let
        http_cmd =
          Utils.Api.getMyAvatar
            GotFetchAvatarResponse
            Utils.Decoders.userAvatar

      in
        ( { model
          | work = Utils.Work.addWork loadingAvatar model.work
          , drawing_cmds = []
          , final_avatar = []
          , http_cmds = Dict.insert "FetchAvatar" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotFetchAvatarResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork loadingAvatar model.work
          , http_cmds = Dict.remove "FetchAvatar" model.http_cmds
          }

      in
        case response of
          Ok av ->
            case Langs.Avatar.decode av.avatar of
              Ok drawing_cmds ->
                ( { model2
                  | drawing_cmds = drawing_cmds
                  , final_avatar = drawing_cmds
                  }
                , Cmd.none
                )

              Err _ ->
                ( model2, Cmd.none )

          Err _ ->
            ( model2, Cmd.none )

    UpdatePassword ->
      let
        http_cmd =
          Utils.Api.updatePassword
            ( Utils.Encoders.updatePassword model.password )
            GotUpdatePasswordResponse
            Utils.Decoders.user_

      in
        ( { model
          | work = Utils.Work.addWork updatingPassword model.work
          , dict_errors = Utils.Funcs.emptyDict
          , http_cmds = Dict.insert "UpdatePassword" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotUpdatePasswordResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork updatingPassword model.work
          , http_cmds = Dict.remove "UpdatePassword" model.http_cmds
          }

      in
        case response of
          Ok json ->
            if List.length json.errors > 0 then
              ( { model2
                | dict_errors = Utils.Funcs.mergeDicts json.errors
                }
              , Cmd.none
              )

            else
              ( { model2 | password = "" }
              , Cmd.none
              )

          Err _ ->
            ( { model2 | password = "" }
            , Cmd.none
            )

    TypingPassword password ->
      ( { model | password = password }, Cmd.none )

    SaveAvatar ->
      let
        avatar = Langs.Avatar.encode model.drawing_cmds
        http_cmd =
          Utils.Api.updateAvatar
            ( Utils.Encoders.updateAvatar avatar )
            GotSaveAvatarResponse
            Utils.Decoders.user

      in
        ( { model
          | work = Utils.Work.addWork savingAvatar model.work
          , http_cmds = Dict.insert "SaveAvatar" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotSaveAvatarResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork savingAvatar model.work
          , http_cmds = Dict.remove "SaveAvatar" model.http_cmds
          }

      in
        case response of
          Ok _ ->
            ( { model2
              | final_avatar = model2.drawing_cmds
              }
            , Cmd.none
            )

          Err _ ->
            ( model2
            , Cmd.none
            )

    UpdateColor color ->
      ( { model
        | selected_color = color
        }
      , Cmd.none
      )

    CartesianPlaneCoordsClick {x, y} ->
      case work2SelectedTool model.work of
        Just SquareTool ->
          ( appendSquareDrawingCmd x y model
          , Cmd.none
          )

        Just LineTool ->
          ( appendLineDrawingCmd x y model
          , Cmd.none
          )

        _ ->
          ( model, Cmd.none )

    UndoLastCmd ->
      ( { model
        | drawing_cmds =
            List.take
              ( List.length model.drawing_cmds - 1 )
              model.drawing_cmds
        }
      , Cmd.none
      )

    ExitingAvatarToolEditing ->
      ( { model
        | work = exitAvatarToolEditing model.work
        , active_drawing_cmd = Nothing
        }
      , Cmd.none
      )

    StartEditingAvatar ->
      ( { model
        | work = Utils.Work.addWork startEditingAvatar model.work
        , drawing_cmds = model.final_avatar
        }
      , Cmd.none
      )

    EndEditingAvatar ->
      ( { model
        | work = removeAvatarToolWork model.work
        , drawing_cmds = []
        , active_drawing_cmd = Nothing
        }
      , Cmd.none
      )

    AvatarToolSelected tool ->
      let
        work_tool = selectedTool2Work tool

      in
        ( { model
          | work = Utils.Work.addWork work_tool model.work
          }
        , Cmd.none
        )



-- VIEW


view : Model -> Html.Html Msg
view model =
  Html.div
    []
    [ Html.div
        []
        [ Html.div
            []
            [ Html.h1
                []
                [ Html.text "Profile" ]

            , Html.hr [] []

            , Html.h2
                []
                [ Html.text "Avatar" ]

            , Html.div
                [ Html.Attributes.class "webgl-profile-avatar-container" ]
                [ viewWebGlAvatarProfile model
                , viewWebGlAvatarTool model
                ]
            ]

        , Html.hr [] []

        , Html.div
            []
            [ Html.h2
                []
                [ Html.text "Password" ]

            , viewPasswordFormProfile model
            ]
        ]
    ]


viewWebGlAvatarProfile : Model -> Html.Html Msg
viewWebGlAvatarProfile model =
  let
    cartesian_plane_mesh = cartesianPlaneMesh model
    squares_mesh = squaresMesh model
    lines_mesh = linesMesh model

    canvas_css_class =
      if Utils.Work.isWorkingOn editingAvatar model.work then
        ""

      else
        "grey-border"

  in
    WebGL.toHtml
      [ Html.Attributes.width model.canvas_width
      , Html.Attributes.height model.canvas_height
      , Html.Attributes.class canvas_css_class
      , Html.Attributes.style "display" "block"
      , Html.Events.on "click" decodeCartesianPlaneClick
      , Html.Events.preventDefaultOn "mousedown" preventSelectionSpan
      ]
      [
        WebGL.entity vertexShader fragmentShader squares_mesh Uniforms
      --, WebGL.entity vertexShader fragmentShader lines_mesh Uniforms
      , WebGL.entity vertexShader fragmentShader cartesian_plane_mesh Uniforms
      ]


viewWebGlAvatarTool : Model -> Html.Html Msg
viewWebGlAvatarTool model =
  if Utils.Work.isWorkingOn loadingAvatar model.work then
    Html.div
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Loading avatar" ]

  else if Utils.Work.isWorkingOn savingAvatar model.work then
    Html.div
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Saving avatar" ]

  else if Utils.Work.isWorkingOn editingAvatarWithSelectTool model.work then
    viewWebGlAvatarSelectTool model

  else if Utils.Work.isWorkingOn editingAvatarWithLineTool model.work then
    viewWebGlAvatarLineTool model

  else if Utils.Work.isWorkingOn editingAvatarWithPencilTool model.work then
    viewWebGlAvatarPencilTool model

  else if Utils.Work.isWorkingOn editingAvatarWithBucketTool model.work then
    viewWebGlAvatarBucketTool model

  else if Utils.Work.isWorkingOn editingAvatarWithSquareTool model.work then
    viewWebGlAvatarSquareTool model

  else if Utils.Work.isWorkingOn editingAvatarWithEllipsisTool model.work then
    viewWebGlAvatarEllipsisTool model

  else if Utils.Work.isWorkingOn startEditingAvatar model.work then
    let
      is_saving_avatar = Utils.Work.isWorkingOn savingAvatar model.work

    in
      Html.div
        []
        [ Html.div
            [ Html.Attributes.class "webgl-tools" ]
            [ Html.h3
                [ Html.Attributes.class "webgl-tools-header" ]
                [ Html.input
                    [ Html.Attributes.type_ "button"
                    , Html.Attributes.value "<"
                    , Html.Attributes.class "webgl-tool-editing-exit"
                    , Html.Attributes.disabled is_saving_avatar
                    , Html.Events.onClick EndEditingAvatar
                    ]
                    []

                , Html.text "Editing tools"
                ]
            ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Square"
                , Html.Attributes.disabled is_saving_avatar
                , AvatarToolSelected SquareTool
                    |> Html.Events.onClick
                ]
                []
            ]

  {-
        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Line"
                , Html.Attributes.disabled is_saving_avatar
                , AvatarToolSelected LineTool
                    |> Html.Events.onClick
                ]
                []
            ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Select"
                , Html.Attributes.disabled is_saving_avatar
                , AvatarToolSelected SelectTool
                    |> Html.Events.onClick
                ]
                []
            ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Pencil"
                , Html.Attributes.disabled is_saving_avatar
                , AvatarToolSelected PencilTool
                    |> Html.Events.onClick
                ]
                []
            ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Bucket"
                , Html.Attributes.disabled is_saving_avatar
                , AvatarToolSelected BucketTool
                    |> Html.Events.onClick
                ]
                []
            ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Ellipsis"
                , Html.Attributes.disabled is_saving_avatar
                , AvatarToolSelected EllipsisTool
                    |> Html.Events.onClick
                ]
                []
            ]
  -}

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Save"
                , Html.Attributes.disabled is_saving_avatar
                , Html.Events.onClick SaveAvatar
                ]
                []
            ]

        , Html.div
            []
            [ Html.small
                []
                [ Html.text learnWebGlDisclaimer ]
            ]
        ]

  else
    Html.div
      []
      [ Html.small
          []
          [ Html.text avatarDisclaimer ]

      , Html.div
          []
          [ Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.value "Update"
              , Html.Events.onClick StartEditingAvatar
              ]
              []
          ]
      ]


viewWebGlAvatarEditingExit : Model -> Html.Html Msg
viewWebGlAvatarEditingExit model =
  let
    is_saving_avatar = Utils.Work.isWorkingOn savingAvatar model.work

  in
    Html.input
      [ Html.Attributes.type_ "button"
      , Html.Attributes.value "<"
      , Html.Attributes.class "webgl-tool-editing-exit"
      , Html.Attributes.disabled is_saving_avatar
      , Html.Events.onClick ExitingAvatarToolEditing
      ]
      []


viewWebGlAvatarSelectTool : Model -> Html.Html Msg
viewWebGlAvatarSelectTool model =
  Html.div
    []
    [ Html.h4
        [ Html.Attributes.class "webgl-tools-header" ]
        [ viewWebGlAvatarEditingExit model
        , Html.text "Select"
        ]
    ]


viewWebGlAvatarLineTool : Model -> Html.Html Msg
viewWebGlAvatarLineTool model =
  let
    is_saving_avatar = Utils.Work.isWorkingOn savingAvatar model.work

  in
    Html.div
      []
      [ viewWebGlAvatarEditingExit model

      , Html.h4
          [ Html.Attributes.class "webgl-tools-header" ]
          [ Html.text "Line" ]

      , Html.div
          []
          [ Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.value "Undo"
              , Html.Attributes.disabled is_saving_avatar
              , Html.Events.onClick UndoLastCmd
              ]
              []
          ]

      , Html.div
          [ Html.Attributes.class "webgl-tools-prop-container" ]
          [ viewWebGlColors model ]
      ]


viewWebGlAvatarPencilTool : Model -> Html.Html Msg
viewWebGlAvatarPencilTool model =
  Html.div
    []
    [ Html.h4
        [ Html.Attributes.class "webgl-tools-header" ]
        [ viewWebGlAvatarEditingExit model
        , Html.text "Pencil"
        ]
    ]


viewWebGlAvatarBucketTool : Model -> Html.Html Msg
viewWebGlAvatarBucketTool model =
  Html.div
    []
    [ Html.h4
        [ Html.Attributes.class "webgl-tools-header" ]
        [ viewWebGlAvatarEditingExit model
        , Html.text "Bucket"
        ]
    ]


viewWebGlAvatarSquareTool : Model -> Html.Html Msg
viewWebGlAvatarSquareTool model =
  let
    is_saving_avatar = Utils.Work.isWorkingOn savingAvatar model.work

  in
    Html.div
      []
      [ viewWebGlAvatarEditingExit model

      , Html.h4
          [ Html.Attributes.class "webgl-tools-header" ]
          [ Html.text "Square" ]

      , Html.div
          []
          [ Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.value "Undo"
              , Html.Attributes.disabled is_saving_avatar
              , Html.Events.onClick UndoLastCmd
              ]
              []
          ]

      , Html.div
          [ Html.Attributes.class "webgl-tools-prop-container" ]
          [ viewWebGlColors model ]
      ]


viewWebGlColors : Model -> Html.Html Msg
viewWebGlColors model =
  let
    is_saving_avatar = Utils.Work.isWorkingOn savingAvatar model.work

  in
    Html.div
      []
      [ Html.text "Colors"
      , Html.div
          []
          ( List.concatMap (\palette ->
              [ Html.div
                  [ Html.Attributes.class "webgl-tools-prop-colors-container" ]
                  ( List.map (\hex_color ->
                      let
                        is_selected_color = model.selected_color == hex_color
                        border =
                          if is_selected_color then
                            "10px ridge #" ++ hex_color
                          else
                            "10px solid #" ++ hex_color

                      in
                        Html.div
                          [ Html.Attributes.style "display" "inline-block"
                          , Html.Attributes.style "cursor" "pointer"
                          , Html.Attributes.style "border" border
                          , Html.Attributes.tabindex 0
                          , Html.Attributes.disabled is_saving_avatar
                          , Html.Events.on "keydown"
                              <| decodeColorKeyDown hex_color
                          , Html.Events.onClick
                              <| UpdateColor hex_color
                          ]
                          []

                    ) palette
                  )
              ]
            )
            getColorsPalett
          )
      ]


viewWebGlAvatarEllipsisTool : Model -> Html.Html Msg
viewWebGlAvatarEllipsisTool model =
  Html.div
    []
    [ Html.h4
        [ Html.Attributes.class "webgl-tools-header" ]
        [ viewWebGlAvatarEditingExit model
        , Html.text "Ellipsis"
        ]
    ]


viewPasswordFormProfile : Model -> Html.Html Msg
viewPasswordFormProfile model =
  let
    updating_password = Utils.Work.isWorkingOn updatingPassword model.work

    loading_text_html =
      if updating_password then
        Html.div
          [ Html.Attributes.class "loadingdotsafter" ]
          [ Html.text "Updating password" ]

      else
        Html.div [] []

    password_error_html =
      case Dict.get "password" model.dict_errors of
        Just error ->
          Html.div
            [ Html.Attributes.class "text-red" ]
            [ Html.text error ]

        Nothing ->
          Html.div [] []

  in
    Html.div
      []
      [ Html.div
          []
          [ Html.text "Update your password" ]

      , Html.div
          []
          [ Html.input
              [ Html.Attributes.type_ "text"
              , Html.Attributes.value model.password
              , Html.Attributes.disabled updating_password
              , Html.Events.onInput TypingPassword
              ]
              []
          ]

      , password_error_html

      , Html.div
          []
          [ Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.disabled updating_password
              , Html.Attributes.class "btn-create"
              , Html.Attributes.value "Update"
              , Html.Events.onClick UpdatePassword
              ]
              []
          ]

      , loading_text_html
      ]



-- MESHES


linesMesh : Model -> WebGL.Mesh Utils.Types.Vertex
linesMesh model =
  let
    iter1 : List Utils.Types.AvatarDrawingCmd -> List Utils.Types.AvatarDrawingCmd
    iter1 drawing_cmds =
      case drawing_cmds of
        Utils.Types.LineDrawingCmd a :: other_cmds ->
          Utils.Types.LineDrawingCmd a
          ::
          iter1 other_cmds

        _ ->
          []

    iter2 : List Utils.Types.AvatarDrawingCmd -> List Utils.Types.Vertex
    iter2 line_cmds =
      case line_cmds of
        Utils.Types.LineDrawingCmd vertex1 :: other_cmds ->
          vertex1
          ::
          iter2 other_cmds

        _ ->
          []

    dc =
      if Utils.Work.notWorking == model.work then
        model.final_avatar

      else
        model.drawing_cmds

  in
    iter1 dc
      |> iter2
      |> WebGL.lineStrip
      --[] |> WebGL.lines


squaresMesh : Model -> WebGL.Mesh Utils.Types.Vertex
squaresMesh model =
  let
    iter : List Utils.Types.AvatarDrawingCmd -> List ( Utils.Types.Vertex, Utils.Types.Vertex, Utils.Types.Vertex )
    iter drawing_cmds =
      case drawing_cmds of
        Utils.Types.SquareDrawingCmd vertexes :: other_cmds ->
          case vertexes of
            vertex1 :: vertex2 :: vertex3 :: vertex4 :: _ ->
              ( vertex1, vertex2, vertex3 )
              ::
              ( vertex2, vertex3, vertex4 )
              ::
              iter other_cmds

            _ ->
              []

        _ ->
          []

    dc =
      if Utils.Work.notWorking == model.work then
        model.final_avatar

      else
        model.drawing_cmds

  in
    iter dc |> WebGL.triangles


cartesianPlaneMesh : Model -> WebGL.Mesh Utils.Types.Vertex
cartesianPlaneMesh model =
  if Utils.Work.isWorkingOn editingAvatar model.work then
    let
      pairedVertexes : List a -> List ( a, a )
      pairedVertexes p =
        case p of
          p1 :: p2 :: rest ->
            ( p1, p2 ) :: pairedVertexes ( p2 :: rest )
          _ ->
            []

      vertex_points =
        pairedVertexes model.vertexes

      lines = List.range model.range_lines_from model.range_lines_to

      total_lines_on_each_side =
        List.length lines |> Bitwise.shiftRightBy 1 |> toFloat

      axis_points =
        List.map (\i -> ( toFloat i ) / total_lines_on_each_side ) lines
          |> List.concatMap
              (\i ->
                let
                  position_horizontal_line_coord_1 =
                    Math.Vector3.vec3 -1 i 0

                  position_horizontal_line_coord_2 =
                    Math.Vector3.vec3  1 i 0

                  position_vertical_line_coord_1 =
                    Math.Vector3.vec3 i 1 0

                  position_vertical_line_coord_2 =
                    Math.Vector3.vec3 i -1 0

                  vcolor =
                    if i == 0 then -- Axis
                      darkGreyVec3

                    else
                      lightGreyVec3

                in
                  [ ( Utils.Types.Vertex position_horizontal_line_coord_1 vcolor
                    , Utils.Types.Vertex position_horizontal_line_coord_2 vcolor
                    )
                  , ( Utils.Types.Vertex position_vertical_line_coord_1 vcolor
                    , Utils.Types.Vertex position_vertical_line_coord_2 vcolor
                    )
                  ]
              )

    in
      List.append vertex_points axis_points |> WebGL.lines

  else
    WebGL.lines []



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


-- MISC DECODERS


decodeColorKeyDown : String -> Json.Decode.Decoder Msg
decodeColorKeyDown hex_color =
  Json.Decode.field "key" Json.Decode.string
    |> Json.Decode.andThen
        (\key ->
          if key == " " || key == "Enter" then
            Json.Decode.succeed <| UpdateColor hex_color
          else
            Json.Decode.succeed NoOp
        )


decodeCartesianPlaneClick : Json.Decode.Decoder Msg
decodeCartesianPlaneClick =
  Json.Decode.map CartesianPlaneCoordsClick
    ( Json.Decode.map2 Coords
        ( Json.Decode.field "offsetX" Json.Decode.int )
        ( Json.Decode.field "offsetY" Json.Decode.int )
    )


preventSelectionSpan : Json.Decode.Decoder ( Msg, Bool )
preventSelectionSpan =
  Json.Decode.succeed ( NoOp, True )



-- MISC WORK


editingAvatarWithSelectTool : Int
editingAvatarWithSelectTool = 1


editingAvatarWithLineTool : Int
editingAvatarWithLineTool = 2


editingAvatarWithPencilTool : Int
editingAvatarWithPencilTool = 4


editingAvatarWithBucketTool : Int
editingAvatarWithBucketTool = 8


editingAvatarWithSquareTool : Int
editingAvatarWithSquareTool = 16


editingAvatarWithEllipsisTool : Int
editingAvatarWithEllipsisTool = 32


startEditingAvatar : Int
startEditingAvatar = 64


savingAvatar : Int
savingAvatar = 128


updatingPassword : Int
updatingPassword = 256


loadingAvatar : Int
loadingAvatar = 512


editingAvatar : Int
editingAvatar =
  Utils.Work.addWork editingAvatarWithSelectTool Utils.Work.notWorking
    |> Utils.Work.addWork editingAvatarWithLineTool
    |> Utils.Work.addWork editingAvatarWithPencilTool
    |> Utils.Work.addWork editingAvatarWithBucketTool
    |> Utils.Work.addWork editingAvatarWithSquareTool
    |> Utils.Work.addWork editingAvatarWithEllipsisTool
    |> Utils.Work.addWork startEditingAvatar



removeAvatarToolWork : Int -> Int
removeAvatarToolWork work =
  Utils.Work.removeWork editingAvatarWithSelectTool work
    |> Utils.Work.removeWork editingAvatarWithLineTool
    |> Utils.Work.removeWork editingAvatarWithPencilTool
    |> Utils.Work.removeWork editingAvatarWithBucketTool
    |> Utils.Work.removeWork editingAvatarWithSquareTool
    |> Utils.Work.removeWork editingAvatarWithEllipsisTool
    |> Utils.Work.removeWork startEditingAvatar


exitAvatarToolEditing : Int -> Int
exitAvatarToolEditing work =
  Utils.Work.removeWork editingAvatarWithSelectTool work
    |> Utils.Work.removeWork editingAvatarWithLineTool
    |> Utils.Work.removeWork editingAvatarWithPencilTool
    |> Utils.Work.removeWork editingAvatarWithBucketTool
    |> Utils.Work.removeWork editingAvatarWithSquareTool
    |> Utils.Work.removeWork editingAvatarWithEllipsisTool



-- MISC WEBGL COLORS


darkGreyVec3 : Math.Vector3.Vec3
darkGreyVec3 =
  Math.Vector3.vec3 0.3 0.3 0.3


lightGreyVec3 : Math.Vector3.Vec3
lightGreyVec3 =
  Math.Vector3.vec3 0.6 0.6 0.6


redVec3 : Math.Vector3.Vec3
redVec3 =
  Math.Vector3.vec3 0 0 0


getColorsPalett : List ( List String )
getColorsPalett =
  [ [ getColorsPalettColor15
    , getColorsPalettColor16
    ]

  , [ getColorsPalettColor8
    , getColorsPalettColor9
    , getColorsPalettColor10
    , getColorsPalettColor11
    , getColorsPalettColor12
    , getColorsPalettColor13
    , getColorsPalettColor14
    ]

  , [ getColorsPalettColor1
    , getColorsPalettColor2
    , getColorsPalettColor3
    , getColorsPalettColor4
    , getColorsPalettColor5
    , getColorsPalettColor6
    , getColorsPalettColor7
    ]

  , [ getColorsPalettColor17
    , getColorsPalettColor18
    , getColorsPalettColor19
    , getColorsPalettColor20
    , getColorsPalettColor21
    , getColorsPalettColor22
    , getColorsPalettColor23
    ]
  ]


getColorsPalettColor1 : String
getColorsPalettColor1 = "FF0000"


getColorsPalettColor2 : String
getColorsPalettColor2 = "FFA500"


getColorsPalettColor3 : String
getColorsPalettColor3 = "FFFF00"


getColorsPalettColor4 : String
getColorsPalettColor4 = "008000"


getColorsPalettColor5 : String
getColorsPalettColor5 = "0000FF"


getColorsPalettColor6 : String
getColorsPalettColor6 = "4B0082"


getColorsPalettColor7 : String
getColorsPalettColor7 = "EE82EE"


getColorsPalettColor8 : String
getColorsPalettColor8 = "FF6666"


getColorsPalettColor9 : String
getColorsPalettColor9 = "FFC966"


getColorsPalettColor10 : String
getColorsPalettColor10 = "FCF482"


getColorsPalettColor11 : String
getColorsPalettColor11 = "A4E87D"


getColorsPalettColor12 : String
getColorsPalettColor12 = "83A3FC"


getColorsPalettColor13 : String
getColorsPalettColor13 = "A893D2"


getColorsPalettColor14 : String
getColorsPalettColor14 = "F8D2F9"


getColorsPalettColor15 : String
getColorsPalettColor15 = "AAAAAA"


getColorsPalettColor16 : String
getColorsPalettColor16 = "333333"


getColorsPalettColor17 : String
getColorsPalettColor17 = "990000"


getColorsPalettColor18 : String
getColorsPalettColor18 = "965603"


getColorsPalettColor19 : String
getColorsPalettColor19 = "999900"


getColorsPalettColor20 : String
getColorsPalettColor20 = "29570F"


getColorsPalettColor21 : String
getColorsPalettColor21 = "042B95"


getColorsPalettColor22 : String
getColorsPalettColor22 = "2C1E48"


getColorsPalettColor23 : String
getColorsPalettColor23 = "B118B4"



-- MISC DRAWING CMDS


appendLineDrawingCmd : Int -> Int -> Model -> Model
appendLineDrawingCmd x y model =
  let
    color = hex2Colorspace model.selected_color
    cs = coords2Clipspace x y model.canvas_width model.canvas_height

    drawing_cmd =
      Utils.Types.Vertex ( Math.Vector3.vec3 cs.xr cs.yr 0.0 ) color
        |> Utils.Types.LineDrawingCmd

  in
    { model
    | drawing_cmds = addDrawingCmd drawing_cmd model.drawing_cmds
    }


appendSquareDrawingCmd : Int -> Int -> Model -> Model
appendSquareDrawingCmd x y model =
  let
    color = hex2Colorspace model.selected_color
    cs = coords2Clipspace x y model.canvas_width model.canvas_height

    drawing_cmd =
      Utils.Types.SquareDrawingCmd
        [ Utils.Types.Vertex
            ( Math.Vector3.vec3 cs.xf cs.yf 0.0 )
            color

        , Utils.Types.Vertex
            ( Math.Vector3.vec3 cs.xc cs.yf 0.0 )
            color

        , Utils.Types.Vertex
            ( Math.Vector3.vec3 cs.xf cs.yc 0.0 )
            color

        , Utils.Types.Vertex
            ( Math.Vector3.vec3 cs.xc cs.yc 0.0 )
            color
        ]

  in
    { model
    | drawing_cmds = addDrawingCmd drawing_cmd model.drawing_cmds
    }


addDrawingCmd : Utils.Types.AvatarDrawingCmd -> List Utils.Types.AvatarDrawingCmd -> List Utils.Types.AvatarDrawingCmd
addDrawingCmd add_cmd all_cmds =
  case add_cmd of
    Utils.Types.LineDrawingCmd new_vertex ->
      let
        iter : List Utils.Types.AvatarDrawingCmd -> List Utils.Types.AvatarDrawingCmd
        iter cmds =
          case cmds of
            Utils.Types.LineDrawingCmd vertex :: other_cmds ->
              if
                Math.Vector3.getX vertex.position ==
                Math.Vector3.getX new_vertex.position &&

                Math.Vector3.getY vertex.position ==
                Math.Vector3.getY new_vertex.position
              then
                other_cmds

              else
                Utils.Types.LineDrawingCmd vertex :: iter other_cmds

            wrong_cmd :: next_cmds ->
              wrong_cmd :: iter next_cmds

            [] ->
              [ add_cmd ]

      in
        iter all_cmds

    Utils.Types.SquareDrawingCmd new_vertexes ->
      let
        iter : List Utils.Types.AvatarDrawingCmd -> List Utils.Types.AvatarDrawingCmd
        iter cmds =
          case cmds of
            Utils.Types.SquareDrawingCmd vertexes :: other_cmds ->
              case vertexes of
                vertex1 :: vertex2 :: vertex3 :: vertex4 :: _ ->
                  case new_vertexes of
                    new_vertex1 :: new_vertex2 :: new_vertex3 :: new_vertex4 :: _ ->
                      let
                        xs =
                          [ Math.Vector3.getX vertex1.position
                          , Math.Vector3.getX vertex2.position
                          , Math.Vector3.getX vertex3.position
                          , Math.Vector3.getX vertex4.position
                          ]

                        xs_new =
                          [ Math.Vector3.getX new_vertex1.position
                          , Math.Vector3.getX new_vertex2.position
                          , Math.Vector3.getX new_vertex3.position
                          , Math.Vector3.getX new_vertex4.position
                          ]

                        ys =
                          [ Math.Vector3.getY vertex1.position
                          , Math.Vector3.getY vertex2.position
                          , Math.Vector3.getY vertex3.position
                          , Math.Vector3.getY vertex4.position
                          ]

                        ys_new =
                          [ Math.Vector3.getY new_vertex1.position
                          , Math.Vector3.getY new_vertex2.position
                          , Math.Vector3.getY new_vertex3.position
                          , Math.Vector3.getY new_vertex4.position
                          ]

                        x_min = Utils.Funcs.minimum xs
                        x_max = Utils.Funcs.maximum xs

                        y_min = Utils.Funcs.minimum ys
                        y_max = Utils.Funcs.maximum ys

                        x_min_new = Utils.Funcs.minimum xs_new
                        x_max_new = Utils.Funcs.maximum xs_new

                        y_min_new = Utils.Funcs.minimum ys_new
                        y_max_new = Utils.Funcs.maximum ys_new

                      in
                        case Utils.Funcs.head8 x_min x_max y_min y_max x_min_new x_max_new y_min_new y_max_new of
                          Nothing ->
                            Utils.Types.SquareDrawingCmd vertexes :: iter other_cmds

                          Just { a1, b1, c1, d1, a2, b2, c2, d2 } ->
                            if
                              round ( a1 * 10 ) == round ( a2 * 10 ) &&

                              round ( b1 * 10 ) == round ( b2 * 10 ) &&

                              round ( c1 * 10 ) == round ( c2 * 10 ) &&

                              round ( d1 * 10 ) == round ( d2 * 10 )

                            then
                              other_cmds

                            else
                              Utils.Types.SquareDrawingCmd vertexes :: iter other_cmds

                    _ ->
                      Utils.Types.SquareDrawingCmd vertexes :: iter other_cmds

                _ ->
                  Utils.Types.SquareDrawingCmd vertexes :: iter other_cmds

            wrong_cmd :: next_cmds ->
              wrong_cmd :: iter next_cmds

            [] ->
              [ add_cmd ]

      in
        iter all_cmds



-- MISC CONVERTERS


selectedTool2Work : AvatarTool -> Int
selectedTool2Work tool =
  case tool of
    SelectTool ->
      editingAvatarWithSelectTool

    LineTool ->
      editingAvatarWithLineTool

    PencilTool ->
      editingAvatarWithPencilTool

    BucketTool ->
      editingAvatarWithBucketTool

    SquareTool ->
      editingAvatarWithSquareTool

    EllipsisTool ->
      editingAvatarWithEllipsisTool


work2SelectedTool : Int -> Maybe AvatarTool
work2SelectedTool work =
  if Utils.Work.isWorkingOn editingAvatarWithSelectTool work then
    Just SelectTool

  else if Utils.Work.isWorkingOn editingAvatarWithLineTool work then
    Just LineTool

  else if Utils.Work.isWorkingOn editingAvatarWithPencilTool work then
    Just PencilTool

  else if Utils.Work.isWorkingOn editingAvatarWithBucketTool work then
    Just BucketTool

  else if Utils.Work.isWorkingOn editingAvatarWithSquareTool work then
    Just SquareTool

  else if Utils.Work.isWorkingOn editingAvatarWithEllipsisTool work then
    Just EllipsisTool

  else
    Nothing


coords2Clipspace : Int -> Int -> Int -> Int -> Clipspace
coords2Clipspace x y max_x max_y =
  let
    clipspace_x =
      toFloat x / toFloat max_x
        |> (*) 2
        |> (+) -1.0
        |> (*) 10

    clipspace_y =
      toFloat y / toFloat max_y
        |> (*) 2
        |> (-) 1
        |> (*) 10

    rx = clipspace_x |> round |> toFloat |> (\a -> a / 10)
    ry = clipspace_y |> round |> toFloat |> (\a -> a / 10)

    cx = clipspace_x |> ceiling |> toFloat |> (\a -> a / 10)
    cy = clipspace_y |> ceiling |> toFloat |> (\a -> a / 10)

    fx = clipspace_x |> floor |> toFloat |> (\a -> a / 10)
    fy = clipspace_y |> floor |> toFloat |> (\a -> a / 10)

  in
    Clipspace
      rx
      ry
      ( if cx == fx then cx + 0.1 else cx )
      ( if cy == fy then cy + 0.1 else cy )
      fx
      fy


hex2Colorspace : String -> Math.Vector3.Vec3
hex2Colorspace hex =
  let
    red = String.slice 0 2 hex
    green = String.slice 2 4 hex
    blue = String.slice 4 6 hex

    maybe_r_int = Utils.Funcs.hexToInt red
    maybe_g_int = Utils.Funcs.hexToInt green
    maybe_b_int = Utils.Funcs.hexToInt blue

  in
    case Utils.Funcs.int3 maybe_r_int maybe_g_int maybe_b_int of
      Just { a, b, c } ->
        Math.Vector3.vec3
          ( toFloat a / 255.0 )
          ( toFloat b / 255.0 )
          ( toFloat c / 255.0 )

      Nothing ->
        Math.Vector3.vec3 0 0 0



-- MISC STRINGS


avatarDisclaimer : String
avatarDisclaimer =
  "Your browser must support the WebGL API " ++
  "for you to be able to update/see the avatars"


learnWebGlDisclaimer : String
learnWebGlDisclaimer =
  "Obs.: There should be more tools here but because I don't know how to " ++
  "use more than 2 meshes that's all you have to work with. " ++
  "The problem was: if I tried to use squares and then lines, " ++
  "the lines wouldn't be drawn. If I tried to use lines and then squares, " ++
  "the squares wouldn't be draw. In the first case, if I removed the " ++
  "squares then the lines would appear... no idea why"





