module Elements.PostPreview exposing (..)

import Utils.Decoders
import Utils.Funcs
import Utils.Types
import Utils.Work

import Html
import Html.Attributes
import Html.Events
import Html.Keyed



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | PrevPagePostPreview
  | NextPagePostPreview
  | PostPageImageLoaded
  | PostPageImageErrored
  | ZoomedImage



-- MODEL


type alias Model =
  { post : Maybe Utils.Types.PublishedPost
  , preview_page : Int
  , preview_image : Utils.Types.PreloadImage
  , work : Int
  , date_time : String
  }



-- INIT


initModel : Model
initModel =
  Model
    Nothing                 -- post
    0                       -- preview_page
    Utils.Types.EmptyImage  -- preview_image
    Utils.Work.notWorking   -- work
    ""                      -- date_time


initModelFromPublishedPost : Utils.Types.PublishedPost -> Model
initModelFromPublishedPost post =
  let
    model = { initModel | post = Just post }
  in
    { model | preview_image = preparePreviewImage model }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    ZoomedImage ->
      {-
        This action is here so that the module that controls
        Browser.application can be notified of such event and take
        appropriate action
      -}
      ( model, Cmd.none )

    PostPageImageLoaded ->
      ( { model | preview_image = Utils.Types.LoadedImage }
      , Cmd.none
      )

    PostPageImageErrored ->
      ( { model | preview_image = Utils.Types.EmptyImage }
      , Cmd.none
      )

    PrevPagePostPreview ->
      let
        model2 = { model | preview_page = model.preview_page - 1 }
      in
        ( { model2 | preview_image = preparePreviewImage model2 }
        , Cmd.none
        )

    NextPagePostPreview ->
      let
        model2 = { model | preview_page = model.preview_page + 1 }
      in
        ( { model2 | preview_image = preparePreviewImage model2 }
        , Cmd.none
        )



-- VIEW


view : Model -> Html.Html Msg
view model =
  case model.post of
    Just post ->
      case List.drop model.preview_page post.pages |> List.head of
        Just page ->
          let
            is_first_page =
              model.preview_page == 0

            is_last_page =
              List.drop model.preview_page post.pages
                |> List.length
                |> (>) 2

            is_reviewing =
              Utils.Work.isWorkingOn reviewingComment model.work

            prev_arrow =
              Html.td
                [ Html.Attributes.class "left-arrow" ]
                [ Html.input
                    [ Html.Events.onClick PrevPagePostPreview
                    , Html.Attributes.value "←"
                    , Html.Attributes.disabled
                        ( is_first_page || is_reviewing )
                    , Html.Attributes.type_ "button"
                    ]
                    []
                ]

            next_arrow =
              Html.td
                [ Html.Attributes.class "right-arrow" ]
                [ Html.input
                    [ Html.Events.onClick NextPagePostPreview
                    , Html.Attributes.value "→"
                    , Html.Attributes.disabled
                        ( is_last_page || is_reviewing )
                    , Html.Attributes.type_ "button"
                    ]
                    []
                ]

            page_content =
              case page.kind of
                Utils.Types.PageKindText ->
                  parsePostPageTextContent page.content

                Utils.Types.PageKindImage ->
                  case model.preview_image of
                    Utils.Types.LoadingImage ->
                      {-
                        I wanna try to preload the image so it doesn't just
                        blink and shake the layout a little bit. I want a
                        smooth transition. Because of that I need to tell
                        the VirtualDom not to replace/remove the IMG tag, just
                        update its attributes, otherwise the image would be
                        loaded twice
                      -}
                      [ Html.Keyed.node
                          "div"
                          [ Html.Attributes.class "publishedpost-page-container" ]
                          [ ( "Loader"
                            , Html.div
                                [ Html.Attributes.class "txtloading-page-image"
                                , Html.Attributes.class "loadingdotsafter"
                                ]
                                [ Html.text "Loading image" ]
                            )
                          , ( "Image"
                            , Html.a
                                [ Html.Attributes.href page.content
                                , Html.Attributes.target "_blank"
                                ]
                                [ Html.img
                                    [ Html.Attributes.class
                                        "loading-page-image"
                                    , Utils.Decoders.onLoad PostPageImageLoaded
                                    , Utils.Decoders.onError PostPageImageErrored
                                    , Html.Attributes.alt "Image content"
                                    , Html.Attributes.src page.content
                                    ]
                                    []
                                ]
                            )
                          ]
                      ]

                    Utils.Types.LoadedImage ->
                      [ Html.Keyed.node
                          "div"
                          [ Html.Attributes.class "publishedpost-page-container" ]
                          [ ( "Image"
                            , Html.a
                                [ Html.Attributes.href page.content
                                , Html.Attributes.target "_blank"
                                , Html.Events.onClick ZoomedImage
                                ]
                                [ Html.img
                                    [ Html.Attributes.class
                                        "publishedpost-page-image"
                                    , Html.Attributes.alt "Image content"
                                    , Html.Attributes.src page.content
                                    ]
                                    []
                                ]
                            )
                          ]
                      ]

                    Utils.Types.EmptyImage ->
                      [ Html.div
                          []
                          [ Html.text "Error loading the image" ]
                      , Html.div
                          []
                          [ Html.a
                              [ Html.Attributes.href page.content
                              , Html.Attributes.target "_blank"
                              ]
                              [ Html.text page.content ]
                          ]
                      ]

          in
            Html.div
              []
              [ Html.h1
                  []
                  [ Html.text post.title ]

              , Html.div
                  [ Html.Attributes.class "published-at" ]
                  [ Utils.Funcs.iso8601HumanDateDiff
                      model.date_time
                      post.published_at
                      |> (++) "Published "
                      |> Html.text
                  ]

              , Html.table
                  [ Html.Attributes.class "publishedpost" ]
                  [ Html.thead
                      []
                      []

                  , Html.tbody
                      []
                      [ Html.tr
                          []
                          [ prev_arrow

                          , Html.td
                              [ Html.Attributes.class "publishedpost-page" ]
                              page_content

                          , next_arrow
                          ]
                      ]

                  , Html.tfoot
                      []
                      []
                  ]
              ]

        Nothing ->
          Html.div [] []

    Nothing ->
      Html.div [] []



-- MISC IMAGE


preparePreviewImage : Model -> Utils.Types.PreloadImage
preparePreviewImage model =
  case model.post of
    Just post ->
      case List.drop model.preview_page post.pages |> List.head of
        Just page ->
          case page.kind of
            Utils.Types.PageKindImage ->
              Utils.Types.LoadingImage

            _ ->
              Utils.Types.EmptyImage

        Nothing ->
          Utils.Types.EmptyImage

    Nothing ->
      Utils.Types.EmptyImage



-- MISC WORK


reviewingComment : Int
reviewingComment = 1



-- MISC CONVERTERS


parsePostPageTextContent : String -> List ( Html.Html Msg )
parsePostPageTextContent content =
  String.split "\n" content
    |> List.map (\c -> Html.text c)
    |> List.intersperse ( Html.br [] [] )



