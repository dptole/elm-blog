module Utils.Api exposing (..)

import Utils.ApiRoutes
import Utils.Expects

import Http
import Json.Decode
import Json.Encode



upsertPostRequest : String -> Maybe String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
upsertPostRequest root_path post_id json_body expect_kind expect_decoder =
  case post_id of
    Nothing ->
      let
        endpoint = Utils.ApiRoutes.postDraft root_path
      in
        Http.riskyRequest
          { url = endpoint.url
          , method = endpoint.method
          , timeout = endpoint.timeout
          , tracker = endpoint.tracker
          , headers = endpoint.headers
          , body = Http.jsonBody json_body
          --, expect = Http.expectJson expect_kind expect_decoder
          , expect = Utils.Expects.json expect_kind expect_decoder
          }

    Just _ ->
      let
        endpoint = Utils.ApiRoutes.putDraft root_path
      in
        Http.riskyRequest
          { url = endpoint.url
          , method = endpoint.method
          , timeout = endpoint.timeout
          , tracker = endpoint.tracker
          , headers = endpoint.headers
          , body = Http.jsonBody json_body
          --, expect = Http.expectJson expect_kind expect_decoder
          , expect = Utils.Expects.json expect_kind expect_decoder
          }


addPostNotes : String -> String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
addPostNotes root_path post_id json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.addPostNotes root_path post_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      , expect = Http.expectJson expect_kind expect_decoder
      }


updatePostStatus : String -> String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
updatePostStatus root_path post_id json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.updatePostStatus root_path post_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      , expect = Http.expectJson expect_kind expect_decoder
      }


commitPostRequest : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
commitPostRequest root_path json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.commitDraft root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      --, expect = Http.expectJson expect_kind expect_decoder
      , expect = Utils.Expects.json expect_kind expect_decoder
      }


createAccount : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
createAccount root_path json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.postSignUp root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      --, expect = Http.expectJson expect_kind expect_decoder
      , expect = Utils.Expects.json expect_kind expect_decoder
      }


getMyPosts : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyPosts root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getMePosts root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getMyPost : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyPost root_path post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getMePost root_path post_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getMe : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMe root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getMe root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


signOut : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
signOut root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getSignOut root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


signIn : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
signIn root_path json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.postSignIn root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      --, expect = Http.expectJson expect_kind expect_decoder
      , expect = Utils.Expects.json expect_kind expect_decoder
      }


deletePost : String -> String -> ( Result Http.Error () -> msg ) -> Cmd msg
deletePost root_path post_id expect_kind =
  let
    endpoint = Utils.ApiRoutes.deletePost root_path post_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectWhatever expect_kind
      }


getPostsToReview : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPostsToReview root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPostsToReview root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getPostToReview : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPostToReview root_path post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPostToReview root_path post_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getPublishedPosts : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPublishedPosts root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPublishedPosts root_path
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getPublishedPostsAfter : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPublishedPostsAfter root_path post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPublishedPostsAfter root_path post_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getPublishedPost : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPublishedPost root_path post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPublishedPost root_path post_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }



getPostComment : String -> String -> Int -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPostComment root_path post_id page_index expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPostComment root_path post_id page_index
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getCommentReplies : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentReplies root_path comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentReplies root_path comment_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getCommentsAfter : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsAfter root_path comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentsAfter root_path comment_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


createComment : String -> String -> Int -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
createComment root_path post_id page_index json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.createComment root_path post_id page_index
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      , expect = Http.expectJson expect_kind expect_decoder
      }


replyComment : String -> String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
replyComment root_path comment_id json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.replyComment root_path comment_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      , expect = Http.expectJson expect_kind expect_decoder
      }


justReplyComment : String -> String -> Json.Encode.Value -> ( Result Http.Error () -> msg ) -> Cmd msg
justReplyComment root_path comment_id json_body expect_kind =
  let
    endpoint = Utils.ApiRoutes.replyComment root_path comment_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      , expect = Http.expectWhatever expect_kind
      }


getCommentsReviews : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsReviews root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentsReviews root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getTags : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getTags root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getTags root_path
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getCommentsReviewDetails : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsReviewDetails root_path comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentsReviewDetails root_path comment_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


publishComment : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
publishComment root_path comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.publishComment root_path comment_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


rejectComment : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
rejectComment root_path comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.rejectComment root_path comment_id
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


taggedPosts : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
taggedPosts root_path tag_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.taggedPosts root_path tag_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getCommentsReplies : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsReplies root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentsReplies root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


updatePassword : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
updatePassword root_path json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.updatePassword root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      --, expect = Http.expectJson expect_kind expect_decoder
      , expect = Utils.Expects.json expect_kind expect_decoder
      }


updateAvatar : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
updateAvatar root_path json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.updateAvatar root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.jsonBody json_body
      , expect = Http.expectJson expect_kind expect_decoder
      }


getMyAvatar : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyAvatar root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getMyAvatar root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getMyPostsStatsGraph : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyPostsStatsGraph root_path expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getMyPostsStatsGraph root_path
  in
    Http.riskyRequest
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


getAvatar : String -> String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getAvatar root_path user_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getAvatar root_path user_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectJson expect_kind expect_decoder
      }


hitPostStats : String -> String -> ( Result Http.Error () -> msg ) -> Cmd msg
hitPostStats root_path post_id expect_kind =
  let
    endpoint = Utils.ApiRoutes.hitPostStats root_path post_id
  in
    Http.request
      { url = endpoint.url
      , method = endpoint.method
      , timeout = endpoint.timeout
      , tracker = endpoint.tracker
      , headers = endpoint.headers
      , body = Http.emptyBody
      , expect = Http.expectWhatever expect_kind
      }


