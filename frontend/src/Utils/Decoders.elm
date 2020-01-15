module Utils.Decoders exposing (..)

import Utils.Types

import Dict
import Html
import Html.Events
import Json.Decode
import Json.Decode.Pipeline



-- COMPLETE DECODERS


auth : Json.Decode.Decoder Utils.Types.Auth
auth =
  Json.Decode.succeed Utils.Types.Auth
    |> Json.Decode.Pipeline.required "token"
        ( Json.Decode.succeed Utils.Types.AuthToken
            |> Json.Decode.Pipeline.required "expires" Json.Decode.string
            |> Json.Decode.Pipeline.required "id" Json.Decode.string
            |> Json.Decode.Pipeline.required "user_id" Json.Decode.string
        )
    |> Json.Decode.Pipeline.required "user" user


authToken : Json.Decode.Decoder Utils.Types.AuthToken
authToken =
  Json.Decode.succeed Utils.Types.AuthToken
    |> Json.Decode.Pipeline.required "expires" Json.Decode.string
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "user_id" Json.Decode.string


user : Json.Decode.Decoder Utils.Types.AuthUser
user =
  Json.Decode.succeed Utils.Types.AuthUser
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "username" Json.Decode.string


post : Json.Decode.Decoder Utils.Types.Post
post =
  Json.Decode.succeed Utils.Types.Post
    |> Json.Decode.Pipeline.required "title" Json.Decode.string
    |> Json.Decode.Pipeline.required "pages" postPages
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "status" postStatus
    |> Json.Decode.Pipeline.required "author_id" Json.Decode.string
    |> Json.Decode.Pipeline.required "notes" Json.Decode.string
    |> Json.Decode.Pipeline.required "tags" listOfStrings


postNoPages : Json.Decode.Decoder Utils.Types.Post
postNoPages =
  Json.Decode.succeed Utils.Types.Post
    |> Json.Decode.Pipeline.required "title" Json.Decode.string
    |> Json.Decode.Pipeline.hardcoded [] -- pages
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "status" postStatus
    |> Json.Decode.Pipeline.required "author_id" Json.Decode.string
    |> Json.Decode.Pipeline.required "notes" Json.Decode.string
    |> Json.Decode.Pipeline.required "tags" listOfStrings


publishedPost : Json.Decode.Decoder Utils.Types.PublishedPost
publishedPost =
  Json.Decode.succeed Utils.Types.PublishedPost
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "published_at" Json.Decode.string
    |> Json.Decode.Pipeline.required "title" Json.Decode.string
    |> Json.Decode.Pipeline.required "status" postStatus
    |> Json.Decode.Pipeline.required "tags" listOfStrings
    |> Json.Decode.Pipeline.required "pages" postPages
    |> Json.Decode.Pipeline.required "author" user


publishedPostNoPages : Json.Decode.Decoder Utils.Types.PublishedPost
publishedPostNoPages =
  Json.Decode.succeed Utils.Types.PublishedPost
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "published_at" Json.Decode.string
    |> Json.Decode.Pipeline.required "title" Json.Decode.string
    |> Json.Decode.Pipeline.required "status" postStatus
    |> Json.Decode.Pipeline.required "tags" listOfStrings
    |> Json.Decode.Pipeline.hardcoded [] -- pages
    |> Json.Decode.Pipeline.required "author" user


signOutResponse : Json.Decode.Decoder Utils.Types.SignOut
signOutResponse =
  Json.Decode.succeed Utils.Types.SignOut
    |> Json.Decode.Pipeline.required "success" Json.Decode.bool


userAvatar : Json.Decode.Decoder Utils.Types.UserAvatar
userAvatar =
  Json.Decode.succeed Utils.Types.UserAvatar
    |> Json.Decode.Pipeline.required "avatar" Json.Decode.string
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "user_id" Json.Decode.string


postComment : Json.Decode.Decoder Utils.Types.PostComment
postComment =
  Json.Decode.succeed Utils.Types.PostComment
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.optional "reply_to_comment_id"
        ( Json.Decode.nullable Json.Decode.string ) Nothing
    |> Json.Decode.Pipeline.required "created_at" Json.Decode.string
    |> Json.Decode.Pipeline.required "post_id" Json.Decode.string
    |> Json.Decode.Pipeline.required "page_index" Json.Decode.int
    |> Json.Decode.Pipeline.required "status" postCommentStatus
    |> Json.Decode.Pipeline.required "created_at" Json.Decode.string
    |> Json.Decode.Pipeline.required "message" Json.Decode.string
    |> Json.Decode.Pipeline.required "author" user
    |> Json.Decode.Pipeline.hardcoded ( Utils.Types.PostCommentReplies [] ) -- replies


postCommentRecursive : Json.Decode.Decoder Utils.Types.PostComment
postCommentRecursive =
  Json.Decode.succeed Utils.Types.PostComment
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.optional "reply_to_comment_id"
        ( Json.Decode.nullable Json.Decode.string ) Nothing
    |> Json.Decode.Pipeline.required "created_at" Json.Decode.string
    |> Json.Decode.Pipeline.required "post_id" Json.Decode.string
    |> Json.Decode.Pipeline.required "page_index" Json.Decode.int
    |> Json.Decode.Pipeline.required "status" postCommentStatus
    |> Json.Decode.Pipeline.required "created_at" Json.Decode.string
    |> Json.Decode.Pipeline.required "message" Json.Decode.string
    |> Json.Decode.Pipeline.required "author" user
    |> Json.Decode.Pipeline.optional "replies"
        postCommentRepliesLoop ( Utils.Types.PostCommentReplies [] )


postPage : Json.Decode.Decoder Utils.Types.Page
postPage =
  Json.Decode.succeed Utils.Types.Page
    |> Json.Decode.Pipeline.required "kind" postPageKind
    |> Json.Decode.Pipeline.required "content" Json.Decode.string


graphPostStats : Json.Decode.Decoder Utils.Types.PostStatsGraph
graphPostStats =
  Json.Decode.succeed Utils.Types.PostStatsGraph
    |> Json.Decode.Pipeline.required "post" publishedPostNoPages
    |> Json.Decode.Pipeline.required "metrics" postStats


postStat : Json.Decode.Decoder Utils.Types.PostStatsMetric
postStat =
  Json.Decode.succeed Utils.Types.PostStatsMetric
    |> Json.Decode.Pipeline.required "date" Json.Decode.string
    |> Json.Decode.Pipeline.required "hit" Json.Decode.int


getTag : Json.Decode.Decoder Utils.Types.PostTag
getTag =
  Json.Decode.succeed Utils.Types.PostTag
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "name" Json.Decode.string
    |> Json.Decode.Pipeline.required "posts" Json.Decode.int
    |> Json.Decode.Pipeline.required "last_updated" Json.Decode.string


singlePostTag : Json.Decode.Decoder Utils.Types.SinglePostTag
singlePostTag =
  Json.Decode.succeed Utils.Types.SinglePostTag
    |> Json.Decode.Pipeline.required "id" Json.Decode.string
    |> Json.Decode.Pipeline.required "name" Json.Decode.string


commentReply : Json.Decode.Decoder Utils.Types.CommentsReplies
commentReply =
  Json.Decode.succeed Utils.Types.CommentsReplies
    |> Json.Decode.Pipeline.required "comments"
        ( Json.Decode.list postCommentRecursive )
    |> Json.Decode.Pipeline.required "post" publishedPost


homePosts : Json.Decode.Decoder Utils.Types.HomePosts
homePosts =
  Json.Decode.succeed Utils.Types.HomePosts
    |> Json.Decode.Pipeline.required "tags"
        ( Json.Decode.list singlePostTag )
    |> Json.Decode.Pipeline.required "posts"
        ( Json.Decode.list publishedPostNoPages )



-- COMPOSED DECODERS


postCommentReviewDetails : Json.Decode.Decoder Utils.Types.PostCommentReviewDetails
postCommentReviewDetails =
  Json.Decode.succeed Utils.Types.PostCommentReviewDetails
    |> Json.Decode.Pipeline.required "comment" postCommentRecursive
    |> Json.Decode.Pipeline.required "post" publishedPost


taggedPosts : Json.Decode.Decoder Utils.Types.TaggedPosts
taggedPosts =
  Json.Decode.succeed Utils.Types.TaggedPosts
    |> Json.Decode.Pipeline.required "tag" singlePostTag
    |> Json.Decode.Pipeline.required "posts" ( Json.Decode.list publishedPost )



-- ERROR HTTP DECODERS


httpMeta : Json.Decode.Decoder Utils.Types.HttpMeta
httpMeta =
  Json.Decode.succeed Utils.Types.HttpMeta
    |> Json.Decode.Pipeline.required "headers" httpMetaHeaders
    |> Json.Decode.Pipeline.required "status_code" Json.Decode.int


httpErrors : Json.Decode.Decoder ( List ( Dict.Dict String String ) )
httpErrors =
  Json.Decode.list
    ( Json.Decode.dict Json.Decode.string )



-- SINGLE FIELD DECODERS


getTags : Json.Decode.Decoder ( List Utils.Types.PostTag )
getTags =
  Json.Decode.field "tags" ( Json.Decode.list getTag )


privatePostsResponse : Json.Decode.Decoder ( List Utils.Types.Post )
privatePostsResponse =
  Json.Decode.field "posts" ( Json.Decode.list postNoPages )


publishedPosts : Json.Decode.Decoder ( List Utils.Types.PublishedPost )
publishedPosts =
  Json.Decode.field "posts" ( Json.Decode.list publishedPost )


privatePostResponse : Json.Decode.Decoder Utils.Types.Post
privatePostResponse =
  Json.Decode.field "post" post


postComments : Json.Decode.Decoder ( List Utils.Types.PostComment )
postComments =
  Json.Decode.field "comments" ( Json.Decode.list postComment )


commentReplies : Json.Decode.Decoder ( List Utils.Types.CommentsReplies )
commentReplies =
  Json.Decode.field "replies" ( Json.Decode.list commentReply )


graphsPostStats : Json.Decode.Decoder ( List Utils.Types.PostStatsGraph )
graphsPostStats =
  Json.Decode.field "graphs" ( Json.Decode.list graphPostStats )



-- SYNTATIC SUGAR DECODERS


postPages : Json.Decode.Decoder ( List Utils.Types.Page )
postPages = Json.Decode.list postPage


postsForReviewResponse : Json.Decode.Decoder ( List Utils.Types.Post )
postsForReviewResponse = privatePostsResponse


postStats : Json.Decode.Decoder ( List Utils.Types.PostStatsMetric )
postStats = Json.Decode.list postStat


listOfStrings : Json.Decode.Decoder ( List String )
listOfStrings = Json.Decode.list Json.Decode.string



-- RECURSIVE DECODERS


postCommentRepliesLoop : Json.Decode.Decoder Utils.Types.PostCommentReplies
postCommentRepliesLoop =
  (\_ -> postCommentRecursive)
    |> Json.Decode.lazy
    |> Json.Decode.list
    |> Json.Decode.map Utils.Types.PostCommentReplies



-- CUSTOM DECODERS


postStatus : Json.Decode.Decoder Utils.Types.PostStatus
postStatus =
  let
    _ =
      case Utils.Types.PostStatusDraft of
        {-
        This is just a reminder
        
        If I expand Utils.Types.PostStatus the compiler will not warn me
        about the missing pattern in the decoder function below.
        If the server sends page.kind values that don't match the patterns
        present in the case expression of the function decodePageStatus,
        the user will experience a BadBody error
        -}
        Utils.Types.PostStatusDraft -> 0
        Utils.Types.PostStatusCreated -> 0
        Utils.Types.PostStatusReviewing -> 0
        Utils.Types.PostStatusPublished -> 0

    decodePageStatus : String -> Json.Decode.Decoder Utils.Types.PostStatus
    decodePageStatus string =
      case string of
        "draft" -> Json.Decode.succeed Utils.Types.PostStatusDraft
        "created" -> Json.Decode.succeed Utils.Types.PostStatusCreated
        "reviewing" -> Json.Decode.succeed Utils.Types.PostStatusReviewing
        "published" -> Json.Decode.succeed Utils.Types.PostStatusPublished
        other -> Json.Decode.fail ( "Unknown post.status: " ++ other )
      
  in
    Json.Decode.andThen ( decodePageStatus ) Json.Decode.string


httpMetaHeaders : Json.Decode.Decoder Utils.Types.HttpMetaHeaders
httpMetaHeaders =
  Json.Decode.succeed Utils.Types.HttpMetaHeaders
    |> Json.Decode.Pipeline.optional "set-cookie" listOfStrings []
    |> Json.Decode.Pipeline.optional "content-type" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "access-control-allow-origin" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "access-control-allow-credentials" Json.Decode.string ""


postPageKind : Json.Decode.Decoder Utils.Types.PageKind
postPageKind =
  let
    _ =
      case Utils.Types.PageKindText of
        {-
        This is just a reminder
        
        If I expand Utils.Types.PageKind the compiler will not warn me
        about the missing pattern in the decoder function below.
        If the server sends page.kind values that don't match the patterns
        present in the case expression of the function decodePageKind,
        the user will experience a BadBody error
        -}
        Utils.Types.PageKindText -> 0
        Utils.Types.PageKindImage -> 0

    decodePageKind : String -> Json.Decode.Decoder Utils.Types.PageKind
    decodePageKind string =
      case string of
        "text" -> Json.Decode.succeed Utils.Types.PageKindText
        "image" -> Json.Decode.succeed Utils.Types.PageKindImage
        other -> Json.Decode.fail ( "Unknown page.kind: " ++ other )
      
  in
    Json.Decode.andThen ( decodePageKind ) Json.Decode.string


postCommentStatus : Json.Decode.Decoder Utils.Types.PostCommentStatus
postCommentStatus =
  let
    _ =
      case Utils.Types.PostCommentCreated of
        {-
        This is just a reminder
        
        If I expand Utils.Types.PostCommentStatus the compiler will not warn
        me about the missing pattern in the decoder function below.
        If the server sends page.kind values that don't match the patterns
        present in the case expression of the function decodePostCommentStatus,
        the user will experience a BadBody error
        -}
        Utils.Types.PostCommentCreated -> 0
        Utils.Types.PostCommentReviewing -> 0
        Utils.Types.PostCommentRejected -> 0

    decodePostCommentStatus : String
      -> Json.Decode.Decoder Utils.Types.PostCommentStatus
    decodePostCommentStatus string =
      case string of
        "created" -> Json.Decode.succeed Utils.Types.PostCommentCreated
        "reviewing" -> Json.Decode.succeed Utils.Types.PostCommentReviewing
        "rejected" -> Json.Decode.succeed Utils.Types.PostCommentRejected
        other -> Json.Decode.fail ( "Unknown comment.status: " ++ other )
      
  in
    Json.Decode.andThen ( decodePostCommentStatus ) Json.Decode.string



-- ERROR HANDLING DECODERS


user_ : Json.Decode.Decoder Utils.Types.AuthUser_
user_ =
  Json.Decode.succeed Utils.Types.AuthUser_
    |> Json.Decode.Pipeline.optional "id" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "username" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "errors" httpErrors httpErrorDefault
    |> Json.Decode.Pipeline.optional "meta" httpMeta httpMetaDefault
    |> Json.Decode.Pipeline.optional "reqid" Json.Decode.string ""


auth_ : Json.Decode.Decoder Utils.Types.Auth_
auth_ =
  Json.Decode.succeed Utils.Types.Auth_
    |> Json.Decode.Pipeline.optional "token" authToken ( Utils.Types.AuthToken "" "" "" )
    |> Json.Decode.Pipeline.optional "user" user ( Utils.Types.AuthUser "" "" )
    |> Json.Decode.Pipeline.optional "errors" httpErrors httpErrorDefault
    |> Json.Decode.Pipeline.optional "meta" httpMeta httpMetaDefault
    |> Json.Decode.Pipeline.optional "reqid" Json.Decode.string ""


createAccount_ : Json.Decode.Decoder Utils.Types.SignUp_
createAccount_ =
  Json.Decode.succeed Utils.Types.SignUp_
    |> Json.Decode.Pipeline.optional "user" user ( Utils.Types.AuthUser "" "" )
    |> Json.Decode.Pipeline.optional "errors" httpErrors httpErrorDefault
    |> Json.Decode.Pipeline.optional "meta" httpMeta httpMetaDefault
    |> Json.Decode.Pipeline.optional "reqid" Json.Decode.string ""


post_ : Json.Decode.Decoder Utils.Types.Post_
post_ =
  Json.Decode.succeed Utils.Types.Post_
    |> Json.Decode.Pipeline.optional "title" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "pages" postPages []
    |> Json.Decode.Pipeline.optional "id" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "status" postStatus Utils.Types.PostStatusDraft
    |> Json.Decode.Pipeline.optional "author_id" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "notes" Json.Decode.string ""
    |> Json.Decode.Pipeline.optional "tags" listOfStrings []
    |> Json.Decode.Pipeline.optional "errors" httpErrors httpErrorDefault
    |> Json.Decode.Pipeline.optional "meta" httpMeta httpMetaDefault
    |> Json.Decode.Pipeline.optional "reqid" Json.Decode.string ""



-- HTML DECODERS


onLoad : msg -> Html.Attribute msg
onLoad msg =
  Html.Events.on
    "load"
    ( Json.Decode.succeed msg )


onError : msg -> Html.Attribute msg
onError msg =
  Html.Events.on
    "error"
    ( Json.Decode.succeed msg )



-- OPTIONAL DECODERS (DEFAULT VALUES)


httpMetaDefault : Utils.Types.HttpMeta
httpMetaDefault =
  Utils.Types.HttpMeta
    ( Utils.Types.HttpMetaHeaders -- headers
        []                        -- set_cookie
        ""                        -- content_type
        ""                        -- access_control_allow_origin
        ""                        -- access_control_allow_credentials
    )
    0                             -- status_code


httpErrorDefault : List a
httpErrorDefault =
  [] -- errors



-- BROWSER FLAGS DECODERS


flags : Json.Decode.Value -> Utils.Types.MainModelFlags -> Utils.Types.MainModelFlags
flags js_flags fallback =
  Json.Decode.decodeValue Json.Decode.string js_flags
    |> Result.andThen (Json.Decode.decodeString mainModelFlags)
    |> Result.withDefault fallback


mainModelFlags : Json.Decode.Decoder Utils.Types.MainModelFlags
mainModelFlags =
  Json.Decode.succeed Utils.Types.MainModelFlags
    |> Json.Decode.Pipeline.required "url" mainModelFlagsUrl


mainModelFlagsUrl : Json.Decode.Decoder Utils.Types.MainModelFlagsUrl
mainModelFlagsUrl =
  Json.Decode.succeed Utils.Types.MainModelFlagsUrl
    |> Json.Decode.Pipeline.required "hash" Json.Decode.string
    |> Json.Decode.Pipeline.required "host" Json.Decode.string
    |> Json.Decode.Pipeline.required "hostname" Json.Decode.string
    |> Json.Decode.Pipeline.required "href" Json.Decode.string
    |> Json.Decode.Pipeline.required "origin" Json.Decode.string
    |> Json.Decode.Pipeline.required "protocol" Json.Decode.string
    |> Json.Decode.Pipeline.required "port_string" Json.Decode.string
    |> Json.Decode.Pipeline.required "search_params" mainModelFlagsUrlSearchParams


mainModelFlagsUrlSearchParams : Json.Decode.Decoder ( List Utils.Types.MainModelFlagsUrlSearchParam )
mainModelFlagsUrlSearchParams =
  Json.Decode.list mainModelFlagsUrlSearchParam


mainModelFlagsUrlSearchParam : Json.Decode.Decoder Utils.Types.MainModelFlagsUrlSearchParam
mainModelFlagsUrlSearchParam =
  Json.Decode.succeed Utils.Types.MainModelFlagsUrlSearchParam
    |> Json.Decode.Pipeline.required "key" Json.Decode.string
    |> Json.Decode.Pipeline.required "value" Json.Decode.string


