module Utils.Graphs exposing (..)

import Utils.Funcs

import Html
import Html.Attributes


table : List Float -> List String -> Html.Html msg
table data periods =
  let
    data_periods = List.map2 Tuple.pair data periods

  in
    Html.table
      [ Html.Attributes.class "hoverable"
      , Html.Attributes.attribute "border" "1"
      , Html.Attributes.attribute "rules" "cols"
      ]
      [ Html.thead
          []
          [ Html.tr
              []
              [ Html.th
                  []
                  [ Html.text "Date" ]

              , Html.th
                  []
                  [ Html.text "Clicks" ]
              ]
          ]

      , Html.tbody
          []
          ( List.map (\(d, p) ->
              Html.tr
                []
                [ Html.td
                    []
                    [ Html.text p ]
                , Html.td
                    []
                    [ Html.text <| String.fromFloat d ]
                ]
            ) data_periods
          )
      ]
