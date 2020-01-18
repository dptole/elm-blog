module Elements.PostCreate exposing (..)

import Elements.PostPreview

import Utils.Api
import Utils.Decoders
import Utils.Encoders
import Utils.Funcs
import Utils.Types
import Utils.Work

import Browser.Dom
import Dict
import Html
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Task



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | TypingTitle String
  | AddingPage
  | RemovingPage Int
  | TypingPage Int String
  | SelectingPageKind Utils.Types.PageKind Int Bool
  | AddingTag
  | RemovingTag Int
  | TypingTag Int String
  | SavingAsDraft
  | GotSavingAsDraftResponse ( Result Http.Error Utils.Types.Post_ )
  | CommitPost
  | GotCommitPostResponse ( Result Http.Error Utils.Types.Post_ )
  | CancelEdit
  | FetchPost String
  | GotFetchPostResponse ( Result Http.Error Utils.Types.Post )
  | SavingAsPost
  | GotSavingAsPostResponse ( Result Http.Error Utils.Types.Post_ )
  | PreviewPost
  | CancelPreviewPost
  | ResizeTextarea Int ElementSize
  | PreviousPage
  | NextPage
  | GotElementToMovePage ( Result Browser.Dom.Error Browser.Dom.Element )

  -- Elements/PostPreview
  | PostPreviewMsg Elements.PostPreview.Msg



-- MODEL


type alias Model =
  { title : String
  , pages : List TextareaPage
  , tags : List String
  , work : Int
  , post_id : Maybe String
  , error_response : String
  , form_title : String
  , commit_after_post_saved : Bool
  , commit_msg : Msg
  , post_preview : Maybe Elements.PostPreview.Model
  , current_page : Int
  , pagination_scroll : Int
  , dict_errors : Dict.Dict String String
  , http_cmds : Dict.Dict String ( Cmd Msg )
  , flags : Utils.Types.MainModelFlags
  }


type alias ElementSize =
  { offsetHeight : Int
  }


type alias TextareaPage =
  { kind : Utils.Types.PageKind
  , content : String
  , height : Int
  }



-- INIT


initPage : TextareaPage
initPage = TextareaPage Utils.Types.PageKindText "" textareaHeight


initModelFromPost : Utils.Types.MainModelFlags -> Utils.Types.Post -> Model
initModelFromPost flags post =
  Model
    post.title                                -- title
    ( fromPagesToTextareaPages post.pages )   -- pages
    post.tags                                 -- tags
    Utils.Work.notWorking                     -- work
    ( Just post.id )                          -- post_id
    ""                                        -- error_response
    ( "Editing post: " ++ post.title )        -- form_title
    False                                     -- commit_after_post_saved
    SavingAsPost                              -- commit_msg
    Nothing                                   -- post_preview
    0                                         -- current_page
    0                                         -- pagination_scroll
    Utils.Funcs.emptyDict                     -- dict_errors
    Utils.Funcs.emptyDict                     -- http_cmds
    flags                                     -- flags


initModelFetchingPostById : Utils.Types.MainModelFlags -> String -> Model
initModelFetchingPostById flags post_id =
  Model
    ""                    -- title
    [ initPage ]          -- pages
    []                    -- tags
    fetchingPost          -- work
    ( Just post_id )      -- post_id
    ""                    -- error_response
    "Fetching post..."    -- form_title
    False                 -- commit_after_post_saved
    SavingAsDraft         -- commit_msg
    Nothing               -- post_preview
    0                     -- current_page
    0                     -- pagination_scroll
    Utils.Funcs.emptyDict -- dict_errors
    Utils.Funcs.emptyDict -- http_cmds
    flags                 -- flags


initModel : Utils.Types.MainModelFlags -> Model
initModel flags =
  Model
    ""                    -- title
    [ initPage ]          -- pages
    []                    -- tags
    Utils.Work.notWorking -- work
    Nothing               -- post_id
    ""                    -- error_response
    "Create a post"       -- form_title
    False                 -- commit_after_post_saved
    SavingAsDraft         -- commit_msg
    Nothing               -- post_preview
    0                     -- current_page
    0                     -- pagination_scroll
    Utils.Funcs.emptyDict -- dict_errors
    Utils.Funcs.emptyDict -- http_cmds
    flags                 -- flags



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    GotElementToMovePage result ->
      case result of
        Ok el ->
          ( { model
            | pagination_scroll = model.pagination_scroll - ( round el.element.x )
            }
          , Cmd.none
          )

        Err _ ->
          ( model, Cmd.none )

    NextPage ->
      if model.current_page >= List.length model.pages then
        ( model, Cmd.none )

      else
        ( { model
          | current_page = model.current_page + 1
          }
        , getElement GotElementToMovePage
            <| (++) "postcreate-page-block-"
            <| String.fromInt
            <| model.current_page + 2
        )

    PreviousPage ->
      if model.current_page < 1 then
        ( model, Cmd.none )

      else
        ( { model
          | current_page = model.current_page - 1
          }
        , getElement GotElementToMovePage
            <| (++) "postcreate-page-block-"
            <| String.fromInt
            <| model.current_page
        )

    CancelEdit ->
      {-
        Should be handled by the module that runs Browser.application
        because its necessary to update the URL
      -}
      ( model, Cmd.none )

    GotFetchPostResponse response ->
      {-
        Should be handled by the module that runs
        Browser.application because if the user tries to edit a
        post that couldn't be fetched, some kind of URL redirect
        should happen
        
        That way I can keep the URL consistent with the DOM
        
        If this action had to be managed by this module users would run
        into a situation where they had clicked the Edit button, in the
        posts list, some error could occur, the DOM would show
        "Creating a post" with an empty form, but the URL would show
        /dashboard/post/<POST_ID>/edit
      -}
      ( model, Cmd.none )

    PreviewPost ->
      ( { model
        | work = Utils.Work.addWork previewingPost model.work
        , post_preview =
            fromModelToPublishedPost model
              |> Elements.PostPreview.initModelFromPublishedPost
              |> Just
        }
      , Cmd.none
      )

    CancelPreviewPost ->
      ( { model
        | work = Utils.Work.removeWork previewingPost model.work
        , post_preview = Nothing
        }
      , Cmd.none
      )

    TypingTitle title ->
      ( { model | title = title }
      , Cmd.none
      )

    AddingPage ->
      if List.length model.pages + 1 |> isBeyondMaxPageLength then
        ( model, Cmd.none )
      else
        ( { model | pages = List.append model.pages [ initPage ] }
        , Cmd.none
        )

    RemovingPage index ->
      let
        new_pages =
          List.append
            ( List.take index         model.pages )
            ( List.drop ( index + 1 ) model.pages )

      in
        ( { model | pages = new_pages }
        , Cmd.none
        )

    ResizeTextarea index { offsetHeight } ->
      let
        new_pages =
          List.indexedMap (\i page ->
            if i == index then
              TextareaPage page.kind page.content offsetHeight
            else
              page

          ) model.pages

      in
        ( { model | pages = new_pages }
        , Cmd.none
        )

    TypingPage index content ->
      let
        new_pages =
          List.indexedMap (\i page ->
            if i == index then
              if isBeyondMaxPageContentLength page.kind content then
                page
              else
                TextareaPage page.kind content page.height
            else
              page

          ) model.pages

      in
        ( { model | pages = new_pages }
        , Cmd.none
        )

    SelectingPageKind kind index selected ->
      let
        new_pages =
          List.indexedMap (\i page ->
            if i == index then
              TextareaPage kind
                ( restrictPageContent page )
                page.height

            else
              page

          ) model.pages

      in
        update model.commit_msg { model | pages = new_pages }

    AddingTag ->
      let
        new_tags =
          if List.length model.tags + 1 |> isBeyondMaxPageTags then
            model.tags
          else
            List.append model.tags [""]

      in
        ( { model | tags = new_tags }
        , Cmd.none
        )

    RemovingTag index ->
      let
        new_tags =
          List.append
            ( List.take index         model.tags )
            ( List.drop ( index + 1 ) model.tags )

      in
        ( { model | tags = new_tags }
        , Cmd.none
        )

    TypingTag index content ->
      let
        new_tags =
          List.indexedMap (\i tag ->
            if i == index then
              content
            else
              tag
          ) model.tags

      in
        ( { model | tags = new_tags }
        , Cmd.none
        )

    SavingAsDraft ->
      if Utils.Work.isWorking model.work then
        ( model, Cmd.none )

      else
        let
          http_cmd =
            Utils.Api.upsertPostRequest
              model.flags.api
              model.post_id
              ( Utils.Encoders.upsertPostRequest
                  model.post_id
                  model.title
                  ( fromTextareaPagesToPages model.pages )
                  model.tags
              )
              GotSavingAsDraftResponse
              Utils.Decoders.post_

        in
          ( { model
            | work = Utils.Work.addWork savingDraft model.work
            , error_response = "Saving the post's draft..."
            , dict_errors = Utils.Funcs.emptyDict
            , http_cmds = Dict.insert "SavingAsDraft" http_cmd model.http_cmds
            }
          , http_cmd
          )

    GotSavingAsDraftResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork savingDraft model.work
          , commit_after_post_saved = False
          , http_cmds = Dict.remove "SavingAsDraft" model.http_cmds
          }

      in
        case response of
          Ok new_draft ->
            if List.length new_draft.errors > 0 then
              ( { model2
                | dict_errors = Utils.Funcs.mergeDicts new_draft.errors
                , work = Utils.Work.removeWork savingDraft model2.work
                , error_response = ""
                }
              , Cmd.none
              )

            else
              let
                error_response =
                  case model2.post_id of
                    Just _ -> "Post's draft successfully updated."
                    Nothing -> "Post's draft successfully created."

                model3 =
                  { model2
                  | post_id = Just new_draft.id
                  , error_response = error_response
                  }

              in
                if model.commit_after_post_saved then
                  update
                    CommitPost
                    { model3
                    | commit_after_post_saved = False
                    , work =
                        Utils.Work.removeWork
                          committingDraft
                          ( Utils.Work.removeWork savingPost model2.work )
                    }

                else
                  ( model3, Cmd.none )

          Err _ ->
            ( { model2
              | error_response =
                  "The draft will be saved when all fields are valid"
              , work =
                  Utils.Work.removeWork
                    committingDraft
                    ( Utils.Work.removeWork savingPost model2.work )
              }
            , Cmd.none
            )

    SavingAsPost ->
      if Utils.Work.isWorking model.work then
        ( model, Cmd.none )

      else
        let
          http_cmd =
            Utils.Api.commitPostRequest
              model.flags.api
              ( Utils.Encoders.upsertPostRequest
                  model.post_id
                  model.title
                  ( fromTextareaPagesToPages model.pages )
                  model.tags
              )
              GotSavingAsPostResponse
              Utils.Decoders.post_

        in
          ( { model
            | work = Utils.Work.addWork savingPost model.work
            , error_response = "Saving the post..."
            , http_cmds = Dict.insert "SavingAsPost" http_cmd model.http_cmds
            , dict_errors = Utils.Funcs.emptyDict
            }
          , http_cmd
          )

    GotSavingAsPostResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork savingPost model.work
          , commit_after_post_saved = False
          , http_cmds = Dict.remove "SavingAsPost" model.http_cmds
          }

      in
        case response of
          Ok post ->
            if List.length post.errors > 0 then
              ( { model
                | dict_errors = Utils.Funcs.mergeDicts post.errors
                , work =
                    Utils.Work.removeWork
                      committingDraft
                      ( Utils.Work.removeWork savingPost model2.work )
                }
              , Cmd.none
              )

            else
              let
                model3 =
                  { model2
                  | post_id = Just post.id
                  , error_response = "Post successfully updated."
                  }

              in
                if model.commit_after_post_saved then
                  update
                    CommitPost
                    { model3
                    | commit_after_post_saved = False
                    , work =
                        Utils.Work.removeWork
                          committingDraft
                          ( Utils.Work.removeWork savingPost model2.work )
                    }

                else
                  ( model3, Cmd.none )

          Err _ ->
            ( { model2
              | error_response =
                  "The post will be saved when all fields are valid"
              , work =
                  Utils.Work.removeWork
                    committingDraft
                    ( Utils.Work.removeWork savingPost model2.work )
              }
            , Cmd.none
            )

    CommitPost ->
      if Utils.Work.isWorkingOn committingDraft model.work then
        ( model, Cmd.none )

      else if
        Utils.Work.isWorkingOn savingDraft model.work ||
        Utils.Work.isWorkingOn savingPost model.work
      then
        ( { model
          | commit_after_post_saved = True
          , work = Utils.Work.addWork committingDraft model.work
          }
        , Cmd.none
        )

      else
        let
          http_cmd =
            Utils.Api.commitPostRequest
              model.flags.api
              ( Utils.Encoders.upsertPostRequest
                  model.post_id
                  model.title
                  ( fromTextareaPagesToPages model.pages )
                  model.tags
              )
              GotCommitPostResponse
              Utils.Decoders.post_

        in
          ( { model
            | work = Utils.Work.addWork committingDraft model.work
            , error_response = "Saving post..."
            , http_cmds = Dict.insert "CommitPost" http_cmd model.http_cmds
            , dict_errors = Utils.Funcs.emptyDict
            }
          , http_cmd
          )

    GotCommitPostResponse response ->
      let
        model2 =
          { model
          | http_cmds = Dict.remove "CommitPost" model.http_cmds
          }

      in
        case response of
          Ok json ->
            if List.length json.errors > 0 then
              ( { model2
                | dict_errors = Utils.Funcs.mergeDicts json.errors
                , work = Utils.Work.removeWork committingDraft model2.work
                , error_response = ""
                }
              , Cmd.none
              )

            else
              let
                model3 = initModel model2.flags
              in
                ( { model3
                  | error_response = "Post created successfully."
                  }
                , Cmd.none
                )

          Err _ ->
            ( { model2
              | error_response = "Some fields are invalid, try again..."
              , work = Utils.Work.removeWork committingDraft model2.work
              }
            , Cmd.none
            )

    FetchPost post_id ->
      ( { model
        | work = Utils.Work.addWork fetchingPost model.work
        }
      , Utils.Api.getMyPost
          model.flags.api
          post_id
          GotFetchPostResponse
          Utils.Decoders.privatePostResponse
      )

    -- Elements/PostPreview
    PostPreviewMsg pp_msg ->
      case model.post_preview of
        Just pp_model ->
          let
            ( pp_model2, pp_cmd ) = Elements.PostPreview.update pp_msg pp_model
          in
            ( { model | post_preview = Just pp_model2 }
            , Cmd.map PostPreviewMsg pp_cmd
            )

        Nothing ->
          ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
  let
    is_committing = Utils.Work.isWorkingOn committingDraft model.work
    is_previewing = Utils.Work.isWorkingOn previewingPost model.work

    title_error_html =
      case Dict.get "title" model.dict_errors of
        Just error ->
          Html.div
            [ Html.Attributes.class "text-red" ]
            [ Html.text error ]

        Nothing ->
          Html.div [] []

    pages_error_html =
      case Dict.get "pages" model.dict_errors of
        Just error ->
          Html.div
            [ Html.Attributes.class "text-red" ]
            [ Html.text error ]

        Nothing ->
          Html.div [] []

    tag_error_html =
      case Dict.get "tags" model.dict_errors of
        Just error ->
          Html.div
            [ Html.Attributes.class "text-red" ]
            [ Html.text error ]

        Nothing ->
          Html.div [] []

  in
    if is_previewing then
      Html.div
        []
        [ previewPost model
        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Return"
                , Html.Events.onClick CancelPreviewPost
                ]
                []
            ]
        ]

    else
      Html.form
        [ Html.Attributes.class "post-create-form"
        , Html.Events.onSubmit CommitPost
        ]
        [ Html.h1
            []
            [ Html.text model.form_title ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.placeholder "Title"
                , Html.Attributes.type_ "text"
                , Html.Attributes.value model.title
                , Html.Attributes.disabled is_committing
                , Html.Attributes.class "post-create-title"
                , Html.Events.onInput TypingTitle
                , Html.Events.onBlur model.commit_msg
                ]
                []
            ]

        , title_error_html

        , Html.div
            []
            [ Html.h2
                []
                [ String.concat
                    [ "Pages "
                    , String.fromInt <| List.length model.pages
                    , "/"
                    , String.fromInt maxPageLength
                    ]
                    |> Html.text
                ]

            , viewPages model
            ]

        , pages_error_html

        , Html.div
            [ Html.Attributes.class "post-create-tags-container" ]
            [ Html.h2
                []
                [ String.concat
                    [ "Tags "
                    , String.fromInt <| List.length model.tags
                    , "/"
                    , String.fromInt maxPageTags
                    ]
                    |> Html.text
                ]

            , viewTags model
            ]

        , tag_error_html

        , viewControlButtons model

        , Html.div
            [ Html.Attributes.class "post-create-submit-message" ]
            [ Html.text model.error_response ]
        ]


viewPages : Model -> Html.Html Msg
viewPages model =
  let
    is_committing = Utils.Work.isWorkingOn committingDraft model.work

    is_add_page_disabled =
      isBeyondMaxPageLength ( List.length model.pages + 1 )

    is_pagination_disabled = List.length model.pages < 2 || is_committing

    is_pagination_previous_disabled = model.current_page < 1

    is_pagination_next_disabled = model.current_page + 1 >= List.length model.pages

    pages_html1 =
      List.indexedMap
      ( viewPage
          model.commit_msg
          is_committing
          ( List.length model.pages < 2 )
      )
      model.pages

    pages_html =
      List.intersperse
        ( Html.hr [] [] )
        pages_html1

  in
    Html.div
      []
      [ Html.input
          [ Html.Events.onClick AddingPage
          , Html.Attributes.type_ "button"
          , Html.Attributes.value "Add page"
          , Html.Attributes.class "btn-create"
          , Html.Attributes.disabled ( is_add_page_disabled || is_committing )
          ]
          []

      , Html.div
          [ Html.Attributes.class "postcreate-page-container" ]
          pages_html

{-
      , Html.div
          [ Html.Attributes.class "post-create-pagination" ]
          [ Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.value "←"
              , Html.Attributes.class "post-create-previous-page"
              , Html.Attributes.disabled
                  ( is_pagination_disabled || is_pagination_previous_disabled )
              , Html.Events.onClick PreviousPage
              ]
              []

          , Html.span
              [ Html.Attributes.class "post-create-page-number" ]
              [ Html.text <| String.fromInt <| model.current_page + 1 ]

          , Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.value "→"
              , Html.Attributes.class "post-create-next-page"
              , Html.Attributes.disabled
                  ( is_pagination_disabled || is_pagination_next_disabled )
              , Html.Events.onClick NextPage
              ]
              []
          ]
-}
      ]


viewPage : Msg -> Bool -> Bool -> Int -> TextareaPage -> Html.Html Msg
viewPage commit_msg is_committing is_remove_page_disabled index page =
  let
    counter =
      [ String.concat
          [ String.fromInt <| String.length page.content
          , "/"
          , String.fromInt <| maxPageContentLength page.kind
          , " characters"
          ]
          |> Html.text
      ]
  in
    Html.div
      [ Html.Attributes.class "postcreate-page-block"
      , Html.Attributes.id ( "postcreate-page-block-" ++ ( String.fromInt <| index + 1 ) )
      ]
      [ Html.div
          [ Html.Attributes.class "post-create-page-kind" ]
          [ viewPageKindList commit_msg is_committing index page ]

      , Html.div
          []
          [ viewPageContent commit_msg is_committing index page ]

      , Html.div
          []
          counter

      , Html.div
          []
          [ Html.input
              [ Html.Events.onClick ( RemovingPage index )
              , Html.Attributes.class "btn-danger"
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Remove page"
              , Html.Attributes.disabled
                  ( is_remove_page_disabled || is_committing )
              ]
              []
          ]
      ]


viewPageKindList : Msg -> Bool -> Int -> TextareaPage -> Html.Html Msg
viewPageKindList commit_msg is_committing page_index page =
  Html.div
    []
    [ Html.text ( "#" ++ ( String.fromInt <| page_index + 1 ) )

    , Html.label
        []
        [ Html.input
            [ Html.Attributes.checked
                ( page.kind == Utils.Types.PageKindText )

            , Html.Attributes.placeholder
                "Text of the page"

            , Html.Attributes.disabled is_committing

            , Html.Attributes.type_
                "radio"

            , Html.Attributes.name
                ( (++) "pk" <| String.fromInt page_index )

            , Html.Events.onCheck
                ( SelectingPageKind
                    Utils.Types.PageKindText
                    page_index
                )
            ]
            []

        , Html.text "Text"
        ]

    , Html.label
        []
        [ Html.input
            [ Html.Attributes.checked
                ( page.kind == Utils.Types.PageKindImage )

            , Html.Attributes.placeholder
                "https://example.com/image.jpg"

            , Html.Attributes.disabled is_committing

            , Html.Attributes.type_
                "radio"

            , Html.Attributes.name
                ( (++) "pk" <| String.fromInt page_index )

            , Html.Events.onCheck
                ( SelectingPageKind
                    Utils.Types.PageKindImage
                    page_index
                )
            ]
            []

        , Html.text "Image"
        ]
    ]


viewPageContent : Msg -> Bool -> Int -> TextareaPage -> Html.Html Msg
viewPageContent commit_msg is_committing page_index page =
  case page.kind of
    Utils.Types.PageKindText ->
      Html.textarea
        [ Html.Attributes.value page.content
        , Html.Attributes.placeholder "Text content"
        , Html.Attributes.disabled is_committing
        , Html.Attributes.style "height" ( String.fromInt page.height ++ "px" )
        , Html.Events.onInput ( TypingPage page_index )
        , Html.Events.onBlur commit_msg
        , ResizeTextarea page_index |> decodeTargetSize |> Html.Events.on "mouseout"
        ]
        []

    Utils.Types.PageKindImage ->
      Html.input
        [ Html.Attributes.value page.content
        , Html.Attributes.placeholder "Valid image URL"
        , Html.Attributes.type_ "text"
        , Html.Events.onInput ( TypingPage page_index )
        , Html.Attributes.disabled is_committing
        , Html.Events.onBlur commit_msg
        ]
        []


viewTags : Model -> Html.Html Msg
viewTags model =
  let
    is_committing = Utils.Work.isWorkingOn committingDraft model.work

    is_add_tag_disabled =
      List.length model.tags + 1 |> isBeyondMaxPageTags

  in
    Html.div
      []
      [ Html.div
          []
          [ Html.input
              [ Html.Events.onClick AddingTag
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Add tag"
              , Html.Attributes.class "btn-create"
              , Html.Attributes.disabled
                  ( is_add_tag_disabled || is_committing )
              ]
              []
          ]

      , Html.div
          [ Html.Attributes.class "post-create-tags" ]
          ( List.indexedMap ( viewTag is_committing ) model.tags )
      ]


viewTag : Bool -> Int -> String -> Html.Html Msg
viewTag is_committing index tag =
  Html.div
    [ Html.Attributes.class "post-create-tag" ]
    [ Html.input
        [ Html.Events.onInput ( TypingTag index )
        , Html.Attributes.type_ "text"
        , Html.Attributes.value tag
        , Html.Attributes.disabled is_committing
        , Html.Attributes.placeholder "Tag / Category"
        , Html.Events.onBlur SavingAsDraft
        ]
        []

    , Html.input
        [ Html.Events.onClick ( RemovingTag index )
        , Html.Attributes.type_ "button"
        , Html.Attributes.disabled is_committing
        , Html.Attributes.value "Remove tag"
        , Html.Attributes.class "btn-danger"
        ]
        []
    ]


viewControlButtons : Model -> Html.Html Msg
viewControlButtons model =
  let
    is_committing = Utils.Work.isWorkingOn committingDraft model.work

    is_empty_post_id =
      case model.post_id of
        Just _ -> False
        Nothing -> True

    save_button =
      Html.input
        [ Html.Attributes.disabled ( is_empty_post_id || is_committing )
        , Html.Events.onClick CommitPost
        , Html.Attributes.type_ "button"
        , Html.Attributes.value "Save"
        , Html.Attributes.class "btn-create"
        ]
        []

    preview_button =
      Html.input
        [ Html.Events.onClick PreviewPost
        , Html.Attributes.disabled is_committing
        , Html.Attributes.type_ "button"
        , Html.Attributes.value "Preview"
        ]
        []

    more_buttons =
      case model.post_id of
        Just _ ->
          [ Html.input
              [ Html.Attributes.disabled is_committing
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Cancel"
              , Html.Events.onClick CancelEdit
              ]
              []
          ]

        Nothing ->
          []

    buttons = save_button :: preview_button :: more_buttons

  in
    Html.div
      [ Html.Attributes.class "post-create-control" ]
      buttons


previewPost : Model -> Html.Html Msg
previewPost model =
  case model.post_preview of
    Just post_preview ->
      Elements.PostPreview.view post_preview
        |> Html.map PostPreviewMsg

    Nothing ->
      Html.div [] []



-- MISC


-- MISC CONSTANTS


maxPageTags : Int
maxPageTags = 3


maxPageLength : Int
maxPageLength = 31


maxPageContentLength : Utils.Types.PageKind -> Int
maxPageContentLength kind =
  case kind of
    Utils.Types.PageKindText -> 255
    Utils.Types.PageKindImage -> 1023


textareaHeight : Int
textareaHeight = 250



-- MISC VALIDATORS


isBeyondMaxPageTags : Int -> Bool
isBeyondMaxPageTags pages_tags =
  pages_tags > maxPageTags


isBeyondMaxPageLength : Int -> Bool
isBeyondMaxPageLength pages_length =
  pages_length > maxPageLength


isBeyondMaxPageContentLength : Utils.Types.PageKind -> String -> Bool
isBeyondMaxPageContentLength kind content =
  String.length content > maxPageContentLength kind


restrictPageContent : TextareaPage -> String
restrictPageContent page =
  String.slice 0 ( maxPageContentLength page.kind ) page.content



-- MISC WORK


savingDraft : Int
savingDraft = 1


fetchingPost : Int
fetchingPost = 2


committingDraft : Int
committingDraft = 4


savingPost : Int
savingPost = 8


previewingPost : Int
previewingPost = 16



-- MISC CONVERTERS


fromModelToPublishedPost : Model -> Utils.Types.PublishedPost
fromModelToPublishedPost model =
  Utils.Types.PublishedPost
    ""
    "YYYY-MM-DDTHH:II:SS.XXXZ"
    model.title
    Utils.Types.PostStatusDraft
    model.tags
    ( fromTextareaPagesToPages model.pages )
    ( Utils.Types.AuthUser
        ""
        ""
    )


fromTextareaPagesToPages : List TextareaPage -> List Utils.Types.Page
fromTextareaPagesToPages =
  List.map (\page ->
    Utils.Types.Page page.kind page.content
  )


fromPagesToTextareaPages : List Utils.Types.Page -> List TextareaPage
fromPagesToTextareaPages =
  List.map (\page ->
    TextareaPage page.kind page.content textareaHeight
  )



-- MISC VALIDATORS


isCommittingDraft : Model -> Bool
isCommittingDraft model =
  Utils.Work.isWorkingOn committingDraft model.work



-- MISC DECODERS


decodeTargetSize : ( ElementSize -> Msg ) -> Json.Decode.Decoder Msg
decodeTargetSize msg =
  Json.Decode.map ElementSize
    ( Json.Decode.field "target"
        ( Json.Decode.field "offsetHeight" Json.Decode.int )
    )
  |> Json.Decode.map msg



-- MISC TASK


getElement : ( Result Browser.Dom.Error Browser.Dom.Element -> Msg ) -> String -> Cmd Msg
getElement msg id =
  Browser.Dom.getElement id |> Task.attempt msg





