module Elements.PostDashboard exposing (..)

import Utils.Api
import Utils.Decoders
import Utils.Funcs
import Utils.Graphs
import Utils.Graphs.Bars
import Utils.Routes
import Utils.Types
import Utils.Work

import Dict
import Html
import Html.Attributes
import Http
import Math.Vector3
import WebGL



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | FetchPostsGraphs
  | GotFetchPostsGraphsResponse ( Result Http.Error ( List Utils.Types.PostStatsGraph ) )



-- MODEL


type alias Model =
  { graphs : List Utils.Types.PostStatsGraph
  , work : Int
  , date_time : String
  , http_cmds : Dict.Dict String ( Cmd Msg )
  }


type alias Uniforms =
  {}



-- INIT


initModel : Model
initModel =
  Model
    []                      -- graphs
    Utils.Work.notWorking   -- work
    ""                      -- date_time
    Utils.Funcs.emptyDict   -- http_cmds



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    FetchPostsGraphs ->
      let
        http_cmd =
          Utils.Api.getMyPostsStatsGraph
            GotFetchPostsGraphsResponse
            Utils.Decoders.graphsPostStats

      in
        ( { model
          | work = Utils.Work.addWork fetchingPostStats model.work
          , http_cmds = Dict.insert "FetchPostsGraphs" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotFetchPostsGraphsResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingPostStats model.work
          , http_cmds = Dict.remove "FetchPostsGraphs" model.http_cmds
          }

      in
        case response of
          Ok graphs ->
            ( { model2
              | graphs = graphs
              }
            , Cmd.none
            )

          Err _ ->
            ( model2
            , Cmd.none
            )



-- VIEW


view : Model -> Html.Html Msg
view model =
  let
    total_graphs = countPostStats model.graphs

    stats_title =
      if Utils.Work.isWorkingOn fetchingPostStats model.work then
        "Post stats"
      else
        "Post stats (" ++ ( String.fromInt total_graphs ) ++ ")"

  in
    Html.div
      []
      [ Html.div
          []
          [ Html.h1
              []
              [ Html.text stats_title ]
          ]

      , Html.hr [] []

      , viewPostStats model
      ]


viewPostStats : Model -> Html.Html Msg
viewPostStats model =
  let
    total_graphs = countPostStats model.graphs

  in
    if Utils.Work.isWorkingOn fetchingPostStats model.work then
      Html.div
        [ Html.Attributes.class "loadingdotsafter" ]
        [ Html.text "Fetching stats" ]

    else if total_graphs < 1 then
      Html.div
        []
        [ Html.text "It seems you haven't published any post yet" ]

    else
      Html.div
        []
        ( 
          ( List.indexedMap (\i graph ->
            let
              data = List.map .hit graph.metrics |> List.map toFloat

              periods = List.map .date graph.metrics

              post_link =
                Utils.Routes.buildRoute
                  [ graph.post.id ]
                  Utils.Routes.readPost

            in
              Html.div
                []
                [ Html.h2
                    []
                    [ Html.text <| String.fromInt <| 1 + i

                    , Html.text ") "

                    , Html.a
                        [ Html.Attributes.href post_link ]
                        [ Html.text graph.post.title ]

                    , Html.text " - "

                    , Html.span
                        [ Html.Attributes.class "published-at" ]
                        [ Html.text "Published "

                        , Utils.Funcs.iso8601HumanDateDiff
                            model.date_time
                            graph.post.published_at
                              |> Html.text
                        ]
                    ]

                , Html.div
                    [ Html.Attributes.class "graph-flex-vert-spc-around" ]
                    [ Utils.Graphs.Bars.default data periods
                    , Utils.Graphs.table data periods
                    ]
                ]
            )
            model.graphs
          )
          |> List.intersperse ( Html.hr [] [] )
        )



-- MISC


-- MISC WORK


fetchingPostStats : Int
fetchingPostStats = 1



-- MISC COUNTERS


countPostStats : List Utils.Types.PostStatsGraph -> Int
countPostStats post_stats_graph =
  List.length post_stats_graph






