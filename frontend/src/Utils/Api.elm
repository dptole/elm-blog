module Utils.Api exposing (..)

import Utils.ApiRoutes
import Utils.Expects

import Http
import Json.Decode
import Json.Encode



upsertPostRequest : Maybe String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
upsertPostRequest post_id json_body expect_kind expect_decoder =
  case post_id of
    Nothing ->
      Http.riskyRequest
        { url = Utils.ApiRoutes.postDraft.url
        , method = Utils.ApiRoutes.postDraft.method
        , timeout = Utils.ApiRoutes.postDraft.timeout
        , tracker = Utils.ApiRoutes.postDraft.tracker
        , headers = Utils.ApiRoutes.postDraft.headers
        , body = Http.jsonBody json_body
        --, expect = Http.expectJson expect_kind expect_decoder
        , expect = Utils.Expects.json expect_kind expect_decoder
        }

    Just _ ->
      Http.riskyRequest
        { url = Utils.ApiRoutes.putDraft.url
        , method = Utils.ApiRoutes.putDraft.method
        , timeout = Utils.ApiRoutes.putDraft.timeout
        , tracker = Utils.ApiRoutes.putDraft.tracker
        , headers = Utils.ApiRoutes.putDraft.headers
        , body = Http.jsonBody json_body
        --, expect = Http.expectJson expect_kind expect_decoder
        , expect = Utils.Expects.json expect_kind expect_decoder
        }


addPostNotes : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
addPostNotes post_id json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.addPostNotes post_id
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


updatePostStatus : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
updatePostStatus post_id json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.updatePostStatus post_id
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


commitPostRequest : Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
commitPostRequest json_body expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.commitDraft.url
    , method = Utils.ApiRoutes.commitDraft.method
    , timeout = Utils.ApiRoutes.commitDraft.timeout
    , tracker = Utils.ApiRoutes.commitDraft.tracker
    , headers = Utils.ApiRoutes.commitDraft.headers
    , body = Http.jsonBody json_body
    --, expect = Http.expectJson expect_kind expect_decoder
    , expect = Utils.Expects.json expect_kind expect_decoder
    }


createAccount : Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
createAccount json_body expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.postSignUp.url
    , method = Utils.ApiRoutes.postSignUp.method
    , timeout = Utils.ApiRoutes.postSignUp.timeout
    , tracker = Utils.ApiRoutes.postSignUp.tracker
    , headers = Utils.ApiRoutes.postSignUp.headers
    , body = Http.jsonBody json_body
    --, expect = Http.expectJson expect_kind expect_decoder
    , expect = Utils.Expects.json expect_kind expect_decoder
    }


getMyPosts : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyPosts expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getMePosts.url
    , method = Utils.ApiRoutes.getMePosts.method
    , timeout = Utils.ApiRoutes.getMePosts.timeout
    , tracker = Utils.ApiRoutes.getMePosts.tracker
    , headers = Utils.ApiRoutes.getMePosts.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getMyPost : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyPost post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getMePost post_id
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


getMe : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMe expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getMe.url
    , method = Utils.ApiRoutes.getMe.method
    , timeout = Utils.ApiRoutes.getMe.timeout
    , tracker = Utils.ApiRoutes.getMe.tracker
    , headers = Utils.ApiRoutes.getMe.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


signOut : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
signOut expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getSignOut.url
    , method = Utils.ApiRoutes.getSignOut.method
    , timeout = Utils.ApiRoutes.getSignOut.timeout
    , tracker = Utils.ApiRoutes.getSignOut.tracker
    , headers = Utils.ApiRoutes.getSignOut.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


signIn : Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
signIn json_body expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.postSignIn.url
    , method = Utils.ApiRoutes.postSignIn.method
    , timeout = Utils.ApiRoutes.postSignIn.timeout
    , tracker = Utils.ApiRoutes.postSignIn.tracker
    , headers = Utils.ApiRoutes.postSignIn.headers
    , body = Http.jsonBody json_body
    --, expect = Http.expectJson expect_kind expect_decoder
    , expect = Utils.Expects.json expect_kind expect_decoder
    }


deletePost : String -> ( Result Http.Error () -> msg ) -> Cmd msg
deletePost post_id expect_kind =
  let
    endpoint = Utils.ApiRoutes.deletePost post_id
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


getPostsToReview : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPostsToReview expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getPostsToReview.url
    , method = Utils.ApiRoutes.getPostsToReview.method
    , timeout = Utils.ApiRoutes.getPostsToReview.timeout
    , tracker = Utils.ApiRoutes.getPostsToReview.tracker
    , headers = Utils.ApiRoutes.getPostsToReview.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getPostToReview : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPostToReview post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPostToReview post_id
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


getPublishedPosts : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPublishedPosts expect_kind expect_decoder =
  Http.request
    { url = Utils.ApiRoutes.getPublishedPosts.url
    , method = Utils.ApiRoutes.getPublishedPosts.method
    , timeout = Utils.ApiRoutes.getPublishedPosts.timeout
    , tracker = Utils.ApiRoutes.getPublishedPosts.tracker
    , headers = Utils.ApiRoutes.getPublishedPosts.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getPublishedPost : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPublishedPost post_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPublishedPost post_id
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


getPostComment : String -> Int -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getPostComment post_id page_index expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getPostComment post_id page_index
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


getCommentReplies : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentReplies comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentReplies comment_id
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


getCommentsAfter : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsAfter comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentsAfter comment_id
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


createComment : String -> Int -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
createComment post_id page_index json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.createComment post_id page_index
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


replyComment : String -> Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
replyComment comment_id json_body expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.replyComment comment_id
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


justReplyComment : String -> Json.Encode.Value -> ( Result Http.Error () -> msg ) -> Cmd msg
justReplyComment comment_id json_body expect_kind =
  let
    endpoint = Utils.ApiRoutes.replyComment comment_id
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


getCommentsReviews : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsReviews expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getCommentsReviews.url
    , method = Utils.ApiRoutes.getCommentsReviews.method
    , timeout = Utils.ApiRoutes.getCommentsReviews.timeout
    , tracker = Utils.ApiRoutes.getCommentsReviews.tracker
    , headers = Utils.ApiRoutes.getCommentsReviews.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getTags : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getTags expect_kind expect_decoder =
  Http.request
    { url = Utils.ApiRoutes.getTags.url
    , method = Utils.ApiRoutes.getTags.method
    , timeout = Utils.ApiRoutes.getTags.timeout
    , tracker = Utils.ApiRoutes.getTags.tracker
    , headers = Utils.ApiRoutes.getTags.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getCommentsReviewDetails : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsReviewDetails comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getCommentsReviewDetails comment_id
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


publishComment : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
publishComment comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.publishComment comment_id
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


rejectComment : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
rejectComment comment_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.rejectComment comment_id
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


taggedPosts : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
taggedPosts tag_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.taggedPosts tag_id
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


getCommentsReplies : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getCommentsReplies expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getCommentsReplies.url
    , method = Utils.ApiRoutes.getCommentsReplies.method
    , timeout = Utils.ApiRoutes.getCommentsReplies.timeout
    , tracker = Utils.ApiRoutes.getCommentsReplies.tracker
    , headers = Utils.ApiRoutes.getCommentsReplies.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


updatePassword : Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
updatePassword json_body expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.updatePassword.url
    , method = Utils.ApiRoutes.updatePassword.method
    , timeout = Utils.ApiRoutes.updatePassword.timeout
    , tracker = Utils.ApiRoutes.updatePassword.tracker
    , headers = Utils.ApiRoutes.updatePassword.headers
    , body = Http.jsonBody json_body
    --, expect = Http.expectJson expect_kind expect_decoder
    , expect = Utils.Expects.json expect_kind expect_decoder
    }


updateAvatar : Json.Encode.Value -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
updateAvatar json_body expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.updateAvatar.url
    , method = Utils.ApiRoutes.updateAvatar.method
    , timeout = Utils.ApiRoutes.updateAvatar.timeout
    , tracker = Utils.ApiRoutes.updateAvatar.tracker
    , headers = Utils.ApiRoutes.updateAvatar.headers
    , body = Http.jsonBody json_body
    , expect = Http.expectJson expect_kind expect_decoder
    }


getMyAvatar : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyAvatar expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getMyAvatar.url
    , method = Utils.ApiRoutes.getMyAvatar.method
    , timeout = Utils.ApiRoutes.getMyAvatar.timeout
    , tracker = Utils.ApiRoutes.getMyAvatar.tracker
    , headers = Utils.ApiRoutes.getMyAvatar.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getMyPostsStatsGraph : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getMyPostsStatsGraph expect_kind expect_decoder =
  Http.riskyRequest
    { url = Utils.ApiRoutes.getMyPostsStatsGraph.url
    , method = Utils.ApiRoutes.getMyPostsStatsGraph.method
    , timeout = Utils.ApiRoutes.getMyPostsStatsGraph.timeout
    , tracker = Utils.ApiRoutes.getMyPostsStatsGraph.tracker
    , headers = Utils.ApiRoutes.getMyPostsStatsGraph.headers
    , body = Http.emptyBody
    , expect = Http.expectJson expect_kind expect_decoder
    }


getAvatar : String -> ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Cmd msg
getAvatar user_id expect_kind expect_decoder =
  let
    endpoint = Utils.ApiRoutes.getAvatar user_id
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


hitPostStats : String -> ( Result Http.Error () -> msg ) -> Cmd msg
hitPostStats post_id expect_kind =
  let
    endpoint = Utils.ApiRoutes.hitPostStats post_id
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


