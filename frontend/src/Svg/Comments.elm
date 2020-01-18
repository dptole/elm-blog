module Svg.Comments exposing (..)

import Utils.Api
import Utils.Decoders
import Utils.Funcs
import Utils.Types
import Utils.Work

import Html
import Html.Attributes
import Http
import Svg
import Svg.Attributes
import Svg.Events
import Svg.Keyed



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | NoOp
  | ExpandComment Utils.Types.SvgCommentData
  | HideExpandedComment
  | SetViewport Int Int
  | SetCommentStatus String
  | GotCommentsAfterResponse ( Result Http.Error ( List Utils.Types.PostComment ) )
  | GotCommentRepliesResponse ( Result Http.Error ( List Utils.Types.PostComment ) )



-- INIT


initModel : Utils.Types.MainModelFlags -> Utils.Types.SvgCommentsModel
initModel flags =
  Utils.Types.SvgCommentsModel
    ( Utils.Types.SvgCommentDataReplies [] )  -- data
    Nothing                                   -- expanded_comment
    []                                        -- focused_comment
    Utils.Work.notWorking                     -- work
    initConfs                                 -- confs
    initOrientation                           -- orientation
    (0, 0)                                    -- last_move
    flags                                     -- flags


initModelFromPostComment : Utils.Types.MainModelFlags -> List Utils.Types.PostComment -> Utils.Types.SvgCommentsModel
initModelFromPostComment flags post_comments =
  Utils.Types.SvgCommentsModel
    ( fromPostCommentsToSvgCommentDataReplies
        post_comments
    )                                     -- data
    Nothing                               -- expanded_comment
    ( focusOnFirstComment post_comments ) -- focused_comment
    Utils.Work.notWorking                 -- work
    initConfs                             -- confs
    initOrientation                       -- orientation
    (0, 0)                                -- last_move
    flags                                 -- flags


initModelToCommentReview : Utils.Types.MainModelFlags -> List Utils.Types.PostComment -> Utils.Types.SvgCommentsModel
initModelToCommentReview flags post_comments =
  Utils.Types.SvgCommentsModel
    ( fromPostCommentsToSvgCommentDataReplies
        post_comments
    )                                       -- data
    Nothing                                 -- expanded_comment
    ( focusOnDeepestComment post_comments ) -- focused_comment
    reviewingComment                        -- work
    ( initConfsFromPostComments
        post_comments
    )                                       -- confs
    ( updateOrientationByPostComment
        post_comments
    )                                       -- orientation
    (0, 0)                                  -- last_move
    flags                                   -- flags


initConfs : Utils.Types.SvgCommentsConfs
initConfs =
  Utils.Types.SvgCommentsConfs
    0       -- top
    0       -- left
    400     -- width
    300     -- height
    50      -- circle_radius
    0       -- rect_border_radius
    0       -- sqm_x
    0       -- sqm_y
    (0, 0)  -- last_sqms


initConfsFromPostComments : List Utils.Types.PostComment -> Utils.Types.SvgCommentsConfs
initConfsFromPostComments post_comments =
  let
    ( sqmx, sqmy ) =
      focusOnDeepestComment post_comments
        |> getSqmsFromFocusedComment

  in
    Utils.Types.SvgCommentsConfs
      0       -- top
      0       -- left
      400     -- width
      300     -- height
      50      -- circle_radius
      0       -- rect_border_radius
      sqmx    -- sqm_x
      sqmy    -- sqm_y
      (0, 0)  -- last_sqms


initOrientation : Utils.Types.SvgCommentsOrientation
initOrientation =
  Utils.Types.SvgCommentsOrientationVertical



-- UPDATE


update : Msg -> Utils.Types.SvgCommentsModel -> ( Utils.Types.SvgCommentsModel, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    NoOp ->
      ( model, Cmd.none )

    ExpandComment svg_comment_data ->
      ( { model
        | expanded_comment = Just svg_comment_data
        }
      , Cmd.none
      )

    HideExpandedComment ->
      ( { model
        | expanded_comment = Nothing
        , last_move =
            if
              model.orientation == Utils.Types.SvgCommentsOrientationVertical
            then
              ( 1, 0 )
            else
              ( 0, -1 )
        }
      , Cmd.none
      )

    SetCommentStatus status ->
      ( model, Cmd.none )

    GotCommentRepliesResponse response ->
      let
        model2 = 
          { model
          | work = Utils.Work.removeWork loadingMoreReplies model.work
          , last_move = ( 1, 0 )
          }
      in
        case response of
          Ok replies ->
            let
              model3 = appendPostCommentsReplies replies model2
            in
              ( model3
              , Cmd.none
              )

          Err _ ->
            ( model2
            , Cmd.none
            )

    GotCommentsAfterResponse response ->
      let
        model2 = 
          { model
          | work = Utils.Work.removeWork loadingMoreComments model.work
          , last_move = ( 1, 0 )
          }
      in
        case response of
          Ok post_comments ->
            ( appendPostCommentsAfter post_comments model2
            , Cmd.none
            )

          Err _ ->
            ( model2
            , Cmd.none
            )

    SetViewport sqm_x sqm_y ->
      let
        model2 = updateSqm sqm_x sqm_y model
        is_reviewing_comment =
          Utils.Work.isWorkingOn reviewingComment model2.work

      in
        if Utils.Work.isWorking model.work && not is_reviewing_comment then
          ( model, Cmd.none ) -- working on something, don't update the model

        else if -- went right but there we no more comments, fetch them
          sqm_x > 0 &&
          model.confs.sqm_x == model2.confs.sqm_x &&
          model.orientation == Utils.Types.SvgCommentsOrientationHorizontal
        then
          case getFocusedComment model of
            Just focused_comment ->
              ( { model2
                | work =
                    Utils.Work.addWork loadingMoreComments model2.work
                }
              , if is_reviewing_comment then
                  Cmd.none
                else
                  Utils.Api.getCommentsAfter
                    model.flags.api
                    focused_comment.id
                    GotCommentsAfterResponse
                    Utils.Decoders.postComments
              )

            Nothing ->
              ( model2, Cmd.none )

        else if -- went down to read this comment's replies but there we no more replies, fetch them
          sqm_y < 0 &&
          model.confs.sqm_y == model2.confs.sqm_y &&
          model.orientation == Utils.Types.SvgCommentsOrientationHorizontal
        then
          case getFocusedComment model2 of
            Just focused_comment ->
              ( { model2
                | work =
                    Utils.Work.addWork loadingMoreReplies model2.work
                }
              , if is_reviewing_comment then
                  Cmd.none
                else
                  Utils.Api.getCommentReplies
                    model.flags.api
                    focused_comment.id
                    GotCommentRepliesResponse
                    Utils.Decoders.postComments
              )

            Nothing ->
              ( model2, Cmd.none )

        else if -- went right but there we no replies, fetch them
          sqm_x > 0 &&
          model.confs.sqm_x == model2.confs.sqm_x &&
          model.orientation == Utils.Types.SvgCommentsOrientationVertical
        then
          case getFocusedComment model2 of
            Just focused_comment ->
              ( { model2
                | work =
                    Utils.Work.addWork loadingMoreReplies model2.work
                }
              , if is_reviewing_comment then
                  Cmd.none
                else
                  Utils.Api.getCommentReplies
                    model.flags.api
                    focused_comment.id
                    GotCommentRepliesResponse
                    Utils.Decoders.postComments
              )

            Nothing ->
              ( model2, Cmd.none )

        else if -- went down but there we no more comments, fetch them
          sqm_y < 0 &&
          model.confs.sqm_y == model2.confs.sqm_y &&
          model.orientation == Utils.Types.SvgCommentsOrientationVertical
        then
          case getFocusedComment model of
            Just focused_comment ->
              ( { model2
                | work =
                    Utils.Work.addWork loadingMoreComments model2.work
                }
              , if is_reviewing_comment then
                  Cmd.none
                else
                  Utils.Api.getCommentsAfter
                    model.flags.api
                    focused_comment.id
                    GotCommentsAfterResponse
                    Utils.Decoders.postComments
              )

            Nothing ->
              ( model2, Cmd.none )

        else -- went right or down when there were comments/replies
          ( model2
          , Cmd.none
          )



-- VIEW


view : Utils.Types.SvgCommentsModel -> Html.Html Msg
view model =
  case model.expanded_comment of
    Just _ ->
      Html.div
        []
        []

    Nothing ->
      Html.div
        [ Html.Attributes.class "svgcommentscontainer" ]
        [ Svg.svg
            [ Svg.Attributes.viewBox ( fromConfigsToSvgViewBox model.confs )
            , Svg.Attributes.width <| String.fromInt model.confs.width
            , Svg.Attributes.height <| String.fromInt model.confs.height
            ]
            [ Svg.g
                [ Svg.Attributes.class "groot" ]
                ( viewSvgRootComments
                    model
                    model.data
                    initOrientation
                    ( 0, 0 )
                )
            ]
        ]


viewSvgRootComments : Utils.Types.SvgCommentsModel -> Utils.Types.SvgCommentDataReplies -> Utils.Types.SvgCommentsOrientation -> ( Int, Int ) -> List ( Svg.Svg Msg )
viewSvgRootComments model data orientation coords =
  case data of
    Utils.Types.SvgCommentDataReplies comments ->
      let
        total_comments = List.length comments

        viewSvgRootComment2 =
          viewSvgRootComment
            model
            orientation
            (
              Utils.Funcs.flipHeadAndTail model.focused_comment
                |> getFocusedCommentList model.data
            )
            total_comments
            coords

      in
        List.indexedMap viewSvgRootComment2 comments |> List.concat


viewSvgRootComment : Utils.Types.SvgCommentsModel -> Utils.Types.SvgCommentsOrientation -> List Utils.Types.SvgCommentData -> Int -> ( Int, Int ) -> Int -> Utils.Types.SvgCommentData -> List ( Svg.Svg Msg )
viewSvgRootComment model current_orientation focused_comment_list total_comments (x, y) i comment =
  case current_orientation of
    Utils.Types.SvgCommentsOrientationVertical ->
      viewSvgRootCommentVertical
        model
        focused_comment_list
        total_comments
        (x, y)
        i
        comment

    Utils.Types.SvgCommentsOrientationHorizontal ->
      viewSvgRootCommentHorizontal
        model
        focused_comment_list
        total_comments
        ( x, y )
        i
        comment


viewSvgRootCommentHorizontal : Utils.Types.SvgCommentsModel -> List Utils.Types.SvgCommentData -> Int -> ( Int, Int ) -> Int -> Utils.Types.SvgCommentData -> List ( Svg.Svg Msg )
viewSvgRootCommentHorizontal model focused_comment_list total_comments (x, y) i comment =
  let
    circle_onclick =
      case model.expanded_comment of
        Just _ -> NoOp
        Nothing -> ExpandComment comment

    replies_length =
      case comment.replies of
        Utils.Types.SvgCommentDataReplies replies ->
          List.length replies

    has_children = svgCommentDataRepliesLength comment.replies > 0

    is_in_focused_comment_list =
      List.any (\fcl -> fcl.id == comment.id) focused_comment_list

    is_focused_comment =
      case getFocusedComment model of
        Just fc -> fc.id == comment.id
        Nothing -> False

    should_show_replies =
      is_in_focused_comment_list &&
      has_children

    is_reviewing_comment =
      Utils.Work.isWorkingOn reviewingComment model.work

    should_show_loading =
      Utils.Work.isWorking model.work &&
      is_focused_comment &&
      not is_reviewing_comment

    real_half_width = model.confs.width // 2
    real_half_height = model.confs.height // 2

    half_height = y + real_half_height
    half_width = x + real_half_width

    circle_cx = half_width + i * model.confs.width
    circle_cy = half_height

    line_x1 =
      circle_cx +
      model.confs.circle_radius

    line_vx1 =
      circle_cx

    line_y1 =
      half_height

    line_vy1 =
      half_height +
      model.confs.circle_radius

    line_x2 =
      circle_cx -
      model.confs.circle_radius +
      model.confs.width

    line_vx2 =
      circle_cx

    line_y2 =
      half_height

    line_vy2 =
      half_height -
      model.confs.circle_radius +
      model.confs.height

    loading_msg = getLoadingMessage model.work

    circle =
      ( "h-circle-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.circle
          [ Svg.Attributes.class "h-circle-comment"
          , Svg.Attributes.cx <| String.fromInt circle_cx
          , Svg.Attributes.cy <| String.fromInt circle_cy
          , Svg.Attributes.r <| String.fromInt model.confs.circle_radius
          , Svg.Attributes.title comment.message
          , Svg.Attributes.fill "red"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.strokeWidth "3"
          , Svg.Events.onClick circle_onclick
          ]
          []
      )

    line_next_comment =
      ( "h-line_next_comment-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.line
          [ Svg.Attributes.class "h-line-next-comment"
          , Svg.Attributes.x1 <| String.fromInt line_x1
          , Svg.Attributes.y1 <| String.fromInt line_y1
          , Svg.Attributes.x2 <| String.fromInt line_x2
          , Svg.Attributes.y2 <| String.fromInt line_y2
          , Svg.Attributes.fill "black"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.strokeWidth "3"
          ]
          []
      )

    line_next_reply =
      ( "v-line_next_reply-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.line
          [ Svg.Attributes.class "h-line-next-reply"
          , Svg.Attributes.x1 <| String.fromInt line_vx1
          , Svg.Attributes.y1 <| String.fromInt line_vy1
          , Svg.Attributes.x2 <| String.fromInt line_vx2
          , Svg.Attributes.y2 <| String.fromInt line_vy2
          , Svg.Attributes.fill "black"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.strokeWidth "3"
          ]
          []
      )

    text_loading =
      ( "h-text_loading-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.text_
          [ Svg.Attributes.class "h-load-more-comments"
          , Svg.Attributes.x <| String.fromInt real_half_width
          , Svg.Attributes.y <| String.fromInt real_half_height
          , Svg.Attributes.fill "white"
          , Svg.Attributes.textAnchor "middle"
          , Svg.Attributes.dominantBaseline "central"
          ]
          [ Svg.text loading_msg ]
      )

    text_loading_bg =
      ( "h-text_loading_bg-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.rect
          [ Svg.Attributes.class "h-text-loading-bg"
          , Svg.Attributes.fill "rgba(0, 0, 0, 0.8)"
          , Svg.Attributes.height <| String.fromInt model.confs.height
          , Svg.Attributes.width <| String.fromInt model.confs.width
          , Svg.Attributes.rx <| String.fromInt model.confs.rect_border_radius
          ]
          []
      )

    horizontal_line =
      if should_show_loading then
        [ circle, text_loading_bg, text_loading ]

      else if i + 1 >= total_comments then
        [ circle ]

      else
        [ line_next_comment, circle ]

    vertical_line =
      if should_show_replies then
        [ ( "gh-replies-" ++ comment.id ++ "-" ++ ( String.fromInt i )
        , Svg.Keyed.node
            "g"
            [ Svg.Attributes.class
                ( "gh-replies-" ++ comment.id ++ "-" ++ ( String.fromInt i ) )
            ]
            ( line_next_reply ::
                ( List.indexedMap
                    (\idx c -> ( String.fromInt idx, c ) )
                    ( viewSvgRootComments
                        model
                        comment.replies
                        Utils.Types.SvgCommentsOrientationVertical
                        ( x + i * model.confs.width, y + model.confs.height )
                    )
                )
            )
          )
        ]

      else
        []

    groups_main_css_class =
      Svg.Attributes.class
        ( "gh-" ++ comment.id ++ "-" ++ ( String.fromInt i ) )

    groups_focused_css_class =
      if
        model.orientation == Utils.Types.SvgCommentsOrientationHorizontal &&
        is_focused_comment
      then
        [ Svg.Attributes.class "gfocused" ]
      else
        []

    groups_has_children_css_class =
      if has_children then
        [ Svg.Attributes.class "ghaschildren" ]
      else
        []

    groups_attributes =
      groups_main_css_class ::
      List.concat
        [ groups_focused_css_class
        , groups_has_children_css_class
        ]

  in
    [ Svg.Keyed.node
        "g"
        groups_attributes
        ( List.append horizontal_line vertical_line )
    ]


viewSvgRootCommentVertical : Utils.Types.SvgCommentsModel -> List Utils.Types.SvgCommentData -> Int -> ( Int, Int ) -> Int -> Utils.Types.SvgCommentData -> List ( Svg.Svg Msg )
viewSvgRootCommentVertical model focused_comment_list total_comments (x, y) i comment =
  let
    circle_onclick =
      case model.expanded_comment of
        Just _ -> NoOp
        Nothing -> ExpandComment comment

    replies_length =
      case comment.replies of
        Utils.Types.SvgCommentDataReplies replies ->
          List.length replies

    has_children = svgCommentDataRepliesLength comment.replies > 0

    is_in_focused_comment_list =
      List.any (\fcl -> fcl.id == comment.id) focused_comment_list

    is_focused_comment =
      case getFocusedComment model of
        Just fc -> fc.id == comment.id
        Nothing -> False

    should_show_replies =
      is_in_focused_comment_list &&
      has_children

    is_reviewing_comment =
      Utils.Work.isWorkingOn reviewingComment model.work

    should_show_loading =
      Utils.Work.isWorking model.work &&
      is_focused_comment &&
      not is_reviewing_comment

    real_half_height = model.confs.height // 2
    real_half_width = model.confs.width // 2

    half_height = y + real_half_height
    half_width = x + real_half_width

    circle_cx = half_width
    circle_cy = half_height + i * model.confs.height

    line_x1 =
      circle_cx

    line_hx1 =
      circle_cx +
      model.confs.circle_radius

    line_y1 =
      half_height +
      model.confs.circle_radius +
      i * model.confs.height

    line_hy1 =
      half_height +
      i * model.confs.height

    line_x2 =
      circle_cx

    line_hx2 =
      model.confs.width +
      half_width -
      model.confs.circle_radius

    line_y2 =
      half_height -
      model.confs.circle_radius +
      ( ( 1 + i ) * model.confs.height )

    line_hy2 =
      half_height +
      i * model.confs.height

    loading_msg = getLoadingMessage model.work

    circle =
      ( "v-circle-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.circle
          [ Svg.Attributes.class "v-circle-comment"
          , Svg.Attributes.cx <| String.fromInt circle_cx
          , Svg.Attributes.cy <| String.fromInt circle_cy
          , Svg.Attributes.r <| String.fromInt model.confs.circle_radius
          , Svg.Attributes.title comment.message
          , Svg.Attributes.fill "red"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.strokeWidth "3"
          , Svg.Events.onClick circle_onclick
          ]
          []
      )

    line_next_comment =
      ( "v-line_next_comment-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.line
          [ Svg.Attributes.class "v-line-next-comment"
          , Svg.Attributes.x1 <| String.fromInt line_x1
          , Svg.Attributes.y1 <| String.fromInt line_y1
          , Svg.Attributes.x2 <| String.fromInt line_x2
          , Svg.Attributes.y2 <| String.fromInt line_y2
          , Svg.Attributes.fill "black"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.strokeWidth "3"
          ]
          []
      )

    line_next_reply =
      ( "v-line_next_reply-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.line
          [ Svg.Attributes.class "h-line-next-reply"
          , Svg.Attributes.x1 <| String.fromInt line_hx1
          , Svg.Attributes.y1 <| String.fromInt line_hy1
          , Svg.Attributes.x2 <| String.fromInt line_hx2
          , Svg.Attributes.y2 <| String.fromInt line_hy2
          , Svg.Attributes.fill "black"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.strokeWidth "3"
          ]
          []
      )

    text_loading =
      ( "v-text_loading-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.text_
          [ Svg.Attributes.class "v-load-more-comments"
          , Svg.Attributes.x <| String.fromInt real_half_width
          , Svg.Attributes.y <| String.fromInt real_half_height
          , Svg.Attributes.fill "white"
          , Svg.Attributes.textAnchor "middle"
          , Svg.Attributes.dominantBaseline "central"
          ]
          [ Svg.text loading_msg ]
      )

    text_loading_bg =
      ( "v-text_loading_bg-" ++ comment.id ++ "-" ++ ( String.fromInt i )
      , Svg.rect
          [ Svg.Attributes.class "v-text-loading-bg"
          , Svg.Attributes.fill "rgba(0, 0, 0, 0.8)"
          , Svg.Attributes.height <| String.fromInt model.confs.height
          , Svg.Attributes.width <| String.fromInt model.confs.width
          , Svg.Attributes.rx <| String.fromInt model.confs.rect_border_radius
          ]
          []
      )

    vertical_line =
      if should_show_loading then
        [ circle, text_loading_bg, text_loading ]

      else if i + 1 >= total_comments then
        [ circle ]

      else
        [ line_next_comment, circle ]

    horizontal_line =
      if should_show_replies then
        [ ( "gv-replies-" ++ comment.id ++ "-" ++ ( String.fromInt i )
        , Svg.Keyed.node
            "g"
            [ Svg.Attributes.class
                ( "gv-replies-" ++ comment.id ++ "-" ++ ( String.fromInt i ) )
            ]
            ( line_next_reply ::
                ( List.indexedMap
                    (\idx c -> ( String.fromInt idx, c ) )
                    ( viewSvgRootComments
                        model
                        comment.replies
                        Utils.Types.SvgCommentsOrientationHorizontal
                        ( x + model.confs.width, y + i * model.confs.height )
                    )
                )
            )
          )
        ]

      else
        []

    groups_main_css_class =
      Svg.Attributes.class
        ( "gv-" ++ comment.id ++ "-" ++ ( String.fromInt i ) )

    groups_focused_css_class =
      if
        model.orientation == Utils.Types.SvgCommentsOrientationVertical &&
        is_focused_comment
      then
        [ Svg.Attributes.class "gfocused" ]
      else
        []

    groups_has_children_css_class =
      if has_children then
        [ Svg.Attributes.class "ghaschildren" ]
      else
        []

    groups_attributes =
      groups_main_css_class ::
      List.concat
        [ groups_focused_css_class
        , groups_has_children_css_class
        ]

  in
    [ Svg.Keyed.node
        "g"
        groups_attributes
        ( List.append vertical_line horizontal_line )
    ]



-- MISC


-- MISC CONVERTERS


fromConfigsToSvgViewBox : Utils.Types.SvgCommentsConfs -> String
fromConfigsToSvgViewBox confs =
  ( String.fromInt confs.top ) ++ " " ++
  ( String.fromInt confs.left ) ++ " " ++
  ( String.fromInt confs.width ) ++ " " ++
  ( String.fromInt confs.height )


fromPostCommentToSvgCommentData : Utils.Types.PostComment -> Utils.Types.SvgCommentData
fromPostCommentToSvgCommentData post_comment =
  Utils.Types.SvgCommentData
    post_comment.id
    post_comment.message
    post_comment.author.username
    post_comment.created_at
    (
      case post_comment.replies of
        Utils.Types.PostCommentReplies post_comments ->
          Utils.Types.SvgCommentDataReplies
            ( List.map ( fromPostCommentToSvgCommentData ) post_comments )
    )


fromPostCommentsToSvgCommentDataReplies : List Utils.Types.PostComment -> Utils.Types.SvgCommentDataReplies
fromPostCommentsToSvgCommentDataReplies post_comments =
  List.map fromPostCommentToSvgCommentData post_comments
    |> Utils.Types.SvgCommentDataReplies


focusOnFirstComment : List Utils.Types.PostComment -> List Int
focusOnFirstComment post_comments =
  case post_comments of
    _ :: _ -> [0]
    _ -> []


focusOnDeepestComment : List Utils.Types.PostComment -> List Int
focusOnDeepestComment post_comments =
  case post_comments of
    post_comment :: _ ->
      case post_comment.replies of
        Utils.Types.PostCommentReplies replies ->
          0 :: focusOnDeepestComment replies

    _ ->
      []


getFocusedComment : Utils.Types.SvgCommentsModel -> Maybe Utils.Types.SvgCommentData
getFocusedComment model =
  case List.head model.focused_comment of
    Just selected_index ->
      let
        selected_track = List.drop 1 model.focused_comment

        selectCommentRepliesIndex : Int -> Utils.Types.SvgCommentDataReplies -> Maybe Utils.Types.SvgCommentData
        selectCommentRepliesIndex index data_replies =
          case data_replies of
            Utils.Types.SvgCommentDataReplies replies ->
              List.drop index replies |> List.head

        getCommentChildren : List Int -> Utils.Types.SvgCommentDataReplies -> Maybe Utils.Types.SvgCommentDataReplies
        getCommentChildren track data_replies =
          case track of
            track_head :: track_tail ->
              case data_replies of
                Utils.Types.SvgCommentDataReplies replies ->
                  case List.drop track_head replies |> List.head of
                    Just reply ->
                      getCommentChildren
                        track_tail
                        reply.replies

                    Nothing ->
                      Nothing

            _ ->
              Just data_replies

      in
        case getCommentChildren selected_track model.data of
          Just selected_replies ->
            selectCommentRepliesIndex selected_index selected_replies

          Nothing ->
            Nothing

    Nothing ->
      Nothing



-- MISC GETTER


svgCommentDataRepliesLength : Utils.Types.SvgCommentDataReplies -> Int
svgCommentDataRepliesLength data =
  case data of
    Utils.Types.SvgCommentDataReplies replies ->
      List.length replies


getLoadingMessage : Int -> String
getLoadingMessage work =
  if Utils.Work.isWorkingOn loadingMoreReplies work then
    "Replies..."

  else if Utils.Work.isWorkingOn loadingMoreComments work then
    "Next comment..."

  else
        ""



-- MISC UPDATE MODEL


updateSqm : Int -> Int -> Utils.Types.SvgCommentsModel -> Utils.Types.SvgCommentsModel
updateSqm sqm_x sqm_y model =
  let
    model3 =
      case model.orientation of
        Utils.Types.SvgCommentsOrientationHorizontal ->
          let
            old_confs = model.confs

            sum_sqm_x = old_confs.sqm_x + sqm_x

            sum_sqm_y = old_confs.sqm_y + sqm_y

            data_length =
              List.drop 1 model.focused_comment
                |> getFocusedCommentSiblings model.data
                |> svgCommentDataRepliesLength

            focused_comment_index =
              getFocusedCommentIndex model.focused_comment

            new_sqm_x =
              if sqm_x > 0 && focused_comment_index + 1 >= data_length then
                -- going right beyond last comment
                old_confs.sqm_x
              else
                sum_sqm_x

            new_sqm_y =
              if sqm_y < 0 then -- going down to read this comment's replies
                case getFocusedComment model of
                  Just fc ->
                    if svgCommentDataRepliesLength fc.replies > 0 then
                      sum_sqm_y -- there we replies, you can move
                    else
                      old_confs.sqm_y -- no replies, don't move
                  Nothing ->
                    old_confs.sqm_y
              else
                old_confs.sqm_y -- you can't go up on horizontal orientation

            new_confs =
              { old_confs
              | sqm_x = new_sqm_x
              , sqm_y = new_sqm_y
              , last_sqms = ( model.confs.sqm_x, model.confs.sqm_y )
              }

            focused_comment = updateFocusedComment new_confs model

            focused_comment2 =
              if
                sqm_y < 0 &&
                old_confs.sqm_y /= new_confs.sqm_y
              then
                expandFocusedComment focused_comment
              else
                focused_comment

          in
            { model
            | confs = new_confs
            , focused_comment = focused_comment2
            , orientation = updateOrientation focused_comment2
            }

        Utils.Types.SvgCommentsOrientationVertical ->
          let
            old_confs = model.confs

            sum_sqm_x = old_confs.sqm_x + sqm_x

            sum_sqm_y = old_confs.sqm_y + sqm_y

            data_length =
              List.drop 1 model.focused_comment
                |> getFocusedCommentSiblings model.data
                |> svgCommentDataRepliesLength

            focused_comment_index =
              getFocusedCommentIndex model.focused_comment

            new_sqm_x =
              if sqm_x > 0 then
                case getFocusedComment model of
                  Just fc ->
                    if svgCommentDataRepliesLength fc.replies > 0 then
                      sum_sqm_x
                    else
                      old_confs.sqm_x
                  Nothing ->
                    old_confs.sqm_x
              else
                old_confs.sqm_x

            new_sqm_y =
              if
                -- going down beyond the last comment
                ( sqm_y < 0 && focused_comment_index + 1 >= data_length ) ||
                -- going up when there are no parent orientation
                (
                  sqm_y > 0 &&
                  List.length model.focused_comment == 1 &&
                  focused_comment_index == 0
                )
              then
                old_confs.sqm_y
              else
                sum_sqm_y

            new_confs =
              { old_confs
              | sqm_x = new_sqm_x
              , sqm_y = new_sqm_y
              , last_sqms = ( model.confs.sqm_x, model.confs.sqm_y )
              }

            focused_comment = updateFocusedComment new_confs model

            focused_comment2 =
              if
                sqm_x > 0 &&
                old_confs.sqm_x /= new_confs.sqm_x
              then
                -- if moved right (replies)
                -- and there were replies
                -- expand focused_comment list
                expandFocusedComment focused_comment
              else
                focused_comment

          in
            { model
            | confs = new_confs
            , focused_comment = focused_comment2
            , orientation = updateOrientation focused_comment2
            }

  in
    { model3
    | last_move = ( sqm_x, sqm_y )
    }


updateOrientation : List Int -> Utils.Types.SvgCommentsOrientation
updateOrientation focused_comment =
  if List.length focused_comment |> Utils.Funcs.isEven then
    Utils.Types.SvgCommentsOrientationHorizontal

  else
    Utils.Types.SvgCommentsOrientationVertical


updateOrientationByPostComment : List Utils.Types.PostComment -> Utils.Types.SvgCommentsOrientation
updateOrientationByPostComment post_comments =
  focusOnDeepestComment post_comments
    |> updateOrientation


updateFocusedComment : Utils.Types.SvgCommentsConfs -> Utils.Types.SvgCommentsModel -> List Int
updateFocusedComment new_confs model =
  case model.focused_comment of
    head :: tail ->
      case model.orientation of
        Utils.Types.SvgCommentsOrientationVertical ->
          if model.confs.sqm_y < new_confs.sqm_y then -- went up
            if head == 0 then
              -- go back to parent comments
              let
                fc_length = List.length model.focused_comment
                fc_length2 = fc_length - 1
              in
                List.concat
                  [ List.drop fc_length2 model.focused_comment
                  , List.take fc_length2 model.focused_comment |> List.drop 1
                  ]

            else
              -- go back to the previous comment
              ( head - 1 ) :: tail

          else if model.confs.sqm_y > new_confs.sqm_y then -- went down
            ( head + 1 ) :: tail

          else -- went horizontal
            model.focused_comment

        Utils.Types.SvgCommentsOrientationHorizontal ->
          if model.confs.sqm_x > new_confs.sqm_x then -- went left
            if head == 0 then
              -- go back to parent comments
              let
                fc_length = List.length model.focused_comment
                fc_length2 = fc_length - 1
              in
                List.concat
                  [ List.drop fc_length2 model.focused_comment
                  , List.take fc_length2 model.focused_comment |> List.drop 1
                  ]

            else
              ( head - 1 ) :: tail

          else if model.confs.sqm_x < new_confs.sqm_x then -- went right
            ( head + 1 ) :: tail

          else -- went vertical
            model.focused_comment

    _ ->
      model.focused_comment


appendPostCommentsAfter : List Utils.Types.PostComment -> Utils.Types.SvgCommentsModel -> Utils.Types.SvgCommentsModel
appendPostCommentsAfter post_comments_ model =
  let
    iter : List Int -> Utils.Types.SvgCommentDataReplies -> List Utils.Types.PostComment -> Utils.Types.SvgCommentDataReplies
    iter track data post_comments =
      case track of
        index :: thead :: ttail ->
          case data of
            Utils.Types.SvgCommentDataReplies pc ->
              case List.drop thead pc |> List.head of
                Just svg_comment_data ->
                  let
                    new_svg_comment_data =
                      { svg_comment_data
                      | replies =
                          iter
                            ( index :: ttail )
                            svg_comment_data.replies
                            post_comments
                      }

                  in
                    Utils.Types.SvgCommentDataReplies
                      ( List.concat
                          [ List.take thead pc
                          , [ new_svg_comment_data ]
                          , List.drop ( 1 + thead ) pc
                          ]
                      )

                Nothing ->
                  data

        _ :: [] ->
          case data of
            Utils.Types.SvgCommentDataReplies old_pcs ->
              case fromPostCommentsToSvgCommentDataReplies post_comments of
                Utils.Types.SvgCommentDataReplies new_replies ->
                  Utils.Types.SvgCommentDataReplies
                    ( List.concat
                        [ old_pcs
                        , new_replies
                        ]
                    )

        [] ->
          data

  in
    { model
    | data = iter model.focused_comment model.data post_comments_
    }


appendPostCommentsReplies : List Utils.Types.PostComment -> Utils.Types.SvgCommentsModel -> Utils.Types.SvgCommentsModel
appendPostCommentsReplies replies_ model =
  let
    iter : List Int -> Utils.Types.SvgCommentDataReplies -> List Utils.Types.PostComment -> Utils.Types.SvgCommentDataReplies
    iter track data replies =
      case track of
        index :: thead :: ttail ->
          case data of
            Utils.Types.SvgCommentDataReplies comments ->
              case List.drop thead comments |> List.head of
                Just comment ->
                  let
                    new_comment =
                      { comment
                      | replies =
                          iter
                            ( index :: ttail )
                            comment.replies
                            replies
                      }

                  in
                    Utils.Types.SvgCommentDataReplies
                      ( List.concat
                          [ List.take thead comments
                          , [ new_comment ]
                          , List.drop ( 1 + thead ) comments
                          ]
                      )

                Nothing ->
                  data

        index :: [] ->
          case data of
            Utils.Types.SvgCommentDataReplies comments ->
              case List.drop index comments |> List.head of
                Just comment ->
                  case comment.replies of
                    Utils.Types.SvgCommentDataReplies old_replies ->
                      case fromPostCommentsToSvgCommentDataReplies replies of
                        Utils.Types.SvgCommentDataReplies new_replies ->
                          let
                            new_comment =
                              { comment
                              | replies =
                                  Utils.Types.SvgCommentDataReplies
                                    ( List.append old_replies new_replies )
                              }
                          in
                            Utils.Types.SvgCommentDataReplies
                              ( List.concat
                                  [ List.take index comments
                                  , [ new_comment ]
                                  , List.drop ( 1 + index ) comments
                                  ] 
                              )

                Nothing ->
                  data

        [] ->
          data

  in
    { model
    | data = iter model.focused_comment model.data replies_
    }


expandFocusedComment : List Int -> List Int
expandFocusedComment focused_comment =
  case focused_comment of
    head :: head2 :: tail ->
      List.concat
        [ [ 0 ]
        , [ head2 ]
        , tail
        , [ head ]
        ]

    head :: [] ->
      0 :: head :: []

    [] ->
      focused_comment


getFocusedCommentList : Utils.Types.SvgCommentDataReplies -> List Int -> List Utils.Types.SvgCommentData
getFocusedCommentList data focused_comment =
  case data of
    Utils.Types.SvgCommentDataReplies replies ->
      case focused_comment of
        index :: tail ->
          case List.drop index replies |> List.head of
            Just reply ->
              reply ::
              getFocusedCommentList
                reply.replies
                tail

            Nothing ->
              []

        [] ->
          []


getFocusedCommentSiblings : Utils.Types.SvgCommentDataReplies -> List Int -> Utils.Types.SvgCommentDataReplies
getFocusedCommentSiblings data focused_comment =
  case focused_comment of
    head :: tail ->
      case data of
        Utils.Types.SvgCommentDataReplies replies ->
          case List.drop head replies |> List.head of
            Just reply ->
              getFocusedCommentSiblings
                reply.replies
                tail

            Nothing ->
              data

    [] ->
          data


getFocusedCommentIndex : List Int -> Int
getFocusedCommentIndex focused_comment =
  case List.head focused_comment of
    Just fci -> fci
    Nothing -> -1


getSqmsFromFocusedComment : List Int -> ( Int, Int )
getSqmsFromFocusedComment focused_comment =
  let
    track = Utils.Funcs.tailFirst focused_comment

    track_zip =
      List.indexedMap (\i _ -> i) track
        |> Utils.Funcs.zip track

    reduceToSqms : ( Int, Int ) -> ( Int, Int ) -> ( Int, Int )
    reduceToSqms ( item, index ) ( sqmx2, sqmy2 ) =
      if index == 0 then
        ( sqmx2, item * ( -1 ) + sqmy2 )

      else if Utils.Funcs.isOdd index then
        ( item + 1 + sqmx2, sqmy2 )

      else
        ( sqmx2, ( item + 1 ) * ( -1 ) + sqmy2 )

  in
    List.foldl reduceToSqms (0, 0) track_zip



-- MISC WORK


loadingMoreComments : Int
loadingMoreComments = 1


loadingMoreReplies : Int
loadingMoreReplies = 2


reviewingComment : Int
reviewingComment = 4


