module Utils.Routes exposing (..)

import Utils.Funcs
import Utils.Types

import Url



root : String
root = "/"


home : String
home = "/src/Main.elm"


signUp : String
signUp = "/sign_up"


signIn : String
signIn = "/sign_in"


tags : String
tags = "/tags"


tagDetails : String
tagDetails = "/tag/:tag_id"


readPost : String
readPost = "/post/:post_id"


dashboard : String
dashboard = "/dashboard"


dashboardProfile : String
dashboardProfile = "/dashboard/profile"


dashboardPost : String
dashboardPost = "/dashboard/post"


dashboardPostReview : String
dashboardPostReview = "/dashboard/post/review"


dashboardPostReviewDetails : String
dashboardPostReviewDetails = "/dashboard/post/review/:post_id"


dashboardPostCreate : String
dashboardPostCreate = "/dashboard/post/create"


dashboardPostShow : String
dashboardPostShow = "/dashboard/post/show"


dashboardPostEdit : String
dashboardPostEdit = "/dashboard/post/:post_id/edit"


dashboardComment : String
dashboardComment = "/dashboard/comment"


dashboardCommentReply : String
dashboardCommentReply = "/dashboard/comment/reply"


dashboardCommentReview : String
dashboardCommentReview = "/dashboard/comment/review"


dashboardCommentReviewDetails : String
dashboardCommentReviewDetails = "/dashboard/comment/review/:comment_id"


routesMapping : List ( String, Utils.Types.Route )
routesMapping =
  [ ( home, Utils.Types.Home )
  , ( root, Utils.Types.Home )
  , ( signUp, Utils.Types.SignUp )
  , ( readPost, Utils.Types.ReadPost )
  , ( signIn, Utils.Types.SignIn )
  , ( tags, Utils.Types.Tags )
  , ( tagDetails, Utils.Types.TagDetails )
  , ( dashboard, Utils.Types.Dashboard )
  , ( dashboardProfile, Utils.Types.DashboardProfile )
  , ( dashboardPost, Utils.Types.DashboardPost )
  , ( dashboardPostReview, Utils.Types.DashboardPostReview )
  , ( dashboardPostReviewDetails, Utils.Types.DashboardPostReviewDetails )
  , ( dashboardPostCreate, Utils.Types.DashboardPostCreate )
  , ( dashboardPostShow, Utils.Types.DashboardPostShowPrivate )
  , ( dashboardPostEdit, Utils.Types.DashboardPostEdit )
  , ( dashboardComment, Utils.Types.DashboardComment )
  , ( dashboardCommentReply, Utils.Types.DashboardCommentReply )
  , ( dashboardCommentReview, Utils.Types.DashboardCommentReview )
  , ( dashboardCommentReviewDetails, Utils.Types.DashboardCommentReviewDetails )
  ]


buildRoute : List String -> String -> String
buildRoute params raw_route =
  let
    iter : List String -> List String -> List String -> String
    iter r p c =
      let
        r_head = List.head r |> Maybe.withDefault "/"
        r_tail = List.tail r |> Maybe.withDefault []
        p_head = List.head p |> Maybe.withDefault r_head
        p_tail = List.tail p |> Maybe.withDefault []
      in
        if String.slice 0 1 r_head == ":" then
          List.append c [ p_head ] |> iter r_tail p_tail

        else if r_head /= "/" then
          List.append c [ r_head ] |> iter r_tail p

        else
          String.join "/" c

  in
    iter ( String.split "/" raw_route ) params []


getAllRoutes : String -> List ( Utils.Types.Route, List ( String, String ) )
getAllRoutes path =
  let
    path_slices = String.split "/" path
    path_slices_length = List.length path_slices
  in
    List.filterMap (\(route, kind) ->
      let
        route_slices = String.split "/" route
        route_slices_length = List.length route_slices
        zipped = Utils.Funcs.zip path_slices route_slices

        matching_paths =
          List.filterMap (\(pslice, rslice) ->
            if
              ":" == String.slice 0 1 rslice ||
              pslice == rslice
            then
              Just ( pslice, rslice )
            else
              Nothing
          ) zipped

        extracted_params =
          List.filterMap (\(pslice, rslice) ->
            if ":" == String.slice 0 1 rslice then
              Just ( String.slice 1 ( String.length rslice ) rslice, pslice )
            else
              Nothing
          ) zipped

      in
        if route_slices_length /= path_slices_length then
          Nothing

        else if List.length matching_paths == path_slices_length then
          Just ( kind, extracted_params )

        else
          Nothing

    ) routesMapping


getParamByName : String -> List ( String, String ) -> Maybe String
getParamByName param_name params_list =
  List.filterMap(\(pname, pvalue) ->
    if pname == param_name then
      Just pvalue
    else
      Nothing
  ) params_list
    |> List.head


getRoute : String -> Maybe ( Utils.Types.Route, List ( String, String ) )
getRoute path =
  getAllRoutes path |> List.head

