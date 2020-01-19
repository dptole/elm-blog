module Utils.ApiRoutes exposing (..)

import Http



type alias RequestOptions =
  { method : String
  , url : String
  , timeout : Maybe Float
  , tracker : Maybe String
  , headers : List Http.Header
  }


route : String -> String -> String -> Maybe Float -> Maybe String -> List Http.Header -> RequestOptions
route root_path method path timeout tracker headers =
  RequestOptions
    method
    ( String.append root_path path )
    timeout
    tracker
    headers


defaultTimeout : Maybe Float
defaultTimeout =
  ( Just 10e3 )


defaultTracker : Maybe String
defaultTracker =
  Nothing


defaultHeaders : List Http.Header
defaultHeaders =
  []



-- ROUTES


postSignUp : String -> RequestOptions
postSignUp root_path =
  route root_path "POST" "/sign_up" defaultTimeout defaultTracker defaultHeaders


postSignIn : String -> RequestOptions
postSignIn root_path =
  route root_path "POST" "/sign_in" defaultTimeout defaultTracker defaultHeaders


postDraft : String -> RequestOptions
postDraft root_path =
  route root_path "POST" "/post/draft" defaultTimeout defaultTracker defaultHeaders


deletePost : String -> String -> RequestOptions
deletePost root_path post_id =
  route root_path
    "DELETE"
    ( "/post/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


addPostNotes : String -> String -> RequestOptions
addPostNotes root_path post_id =
  route root_path
    "PUT"
    ( "/post/notes/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


updatePostStatus : String -> String -> RequestOptions
updatePostStatus root_path post_id =
  route root_path
    "PUT"
    ( "/post/status/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getPublishedPosts : String -> RequestOptions
getPublishedPosts root_path =
  route root_path "GET" "/posts" defaultTimeout defaultTracker defaultHeaders


getPublishedPostsAfter : String -> String -> RequestOptions
getPublishedPostsAfter root_path post_id =
  route root_path
    "GET"
    ( "/posts/after/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getPublishedPost : String -> String -> RequestOptions
getPublishedPost root_path post_id  =
  route root_path
    "GET"
    ( "/post/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


commitDraft : String -> RequestOptions
commitDraft root_path =
  route root_path "POST" "/post/commit" defaultTimeout defaultTracker defaultHeaders


putDraft : String -> RequestOptions
putDraft root_path =
  route root_path "PUT" "/post/draft" defaultTimeout defaultTracker defaultHeaders


updatePassword : String -> RequestOptions
updatePassword root_path =
  route root_path "PUT" "/me/password" defaultTimeout defaultTracker defaultHeaders


updateAvatar : String -> RequestOptions
updateAvatar root_path =
  route root_path "PUT" "/me/avatar" defaultTimeout defaultTracker defaultHeaders


getMyAvatar : String -> RequestOptions
getMyAvatar root_path =
  route root_path "GET" "/me/avatar" defaultTimeout defaultTracker defaultHeaders


getMyPostsStatsGraph : String -> RequestOptions
getMyPostsStatsGraph root_path =
  route root_path "GET" "/me/graphs/post-stats" defaultTimeout defaultTracker defaultHeaders


hitPostStats : String -> String -> RequestOptions
hitPostStats root_path post_id =
  route root_path
    "GET"
    ( "/graphs/post-stats/" ++ post_id ++ "/hit" )
    defaultTimeout
    defaultTracker
    defaultHeaders


getAvatar : String -> String -> RequestOptions
getAvatar root_path user_id =
  route root_path
    "GET"
    ( "/avatar/" ++ user_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getMe : String -> RequestOptions
getMe root_path =
  route root_path "GET" "/me" defaultTimeout defaultTracker defaultHeaders


getSignOut : String -> RequestOptions
getSignOut root_path =
  route root_path "GET" "/sign_out" defaultTimeout defaultTracker defaultHeaders


getMePosts : String -> RequestOptions
getMePosts root_path =
  route root_path "GET" "/me/posts" defaultTimeout defaultTracker defaultHeaders


getPostsToReview : String -> RequestOptions
getPostsToReview root_path =
  route root_path
    "GET"
    "/me/posts/review"
    defaultTimeout
    defaultTracker
    defaultHeaders


getPostToReview : String -> String -> RequestOptions
getPostToReview root_path post_id =
  route root_path
    "GET"
    ( "/me/posts/review/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getMePost : String -> String -> RequestOptions
getMePost root_path post_id =
  route root_path
    "GET"
    ( "/me/post/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsReplies : String -> RequestOptions
getCommentsReplies root_path =
  route root_path
    "GET"
    "/me/comments/replies"
    defaultTimeout
    defaultTracker
    defaultHeaders


getPostComment : String -> String -> Int -> RequestOptions
getPostComment root_path post_id page_index =
  route root_path
    "GET"
    ( "/post/" ++ post_id ++ "/comments/" ++ ( String.fromInt page_index ) )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentReplies : String -> String -> RequestOptions
getCommentReplies root_path comment_id =
  route root_path
    "GET"
    ( "/post/comments/replies/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsAfter : String -> String -> RequestOptions
getCommentsAfter root_path comment_id =
  route root_path
    "GET"
    ( "/post/comments/after/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsReviews : String -> RequestOptions
getCommentsReviews root_path =
  route root_path
    "GET"
    "/post/comments/review"
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsReviewDetails : String -> String -> RequestOptions
getCommentsReviewDetails root_path comment_id =
  route root_path
    "GET"
    ( "/post/comments/review/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


publishComment : String -> String -> RequestOptions
publishComment root_path comment_id =
  route root_path
    "POST"
    ( "/post/comment/review/publish/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


rejectComment : String -> String -> RequestOptions
rejectComment root_path comment_id =
  route root_path
    "POST"
    ( "/post/comment/review/reject/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


createComment : String -> String -> Int -> RequestOptions
createComment root_path post_id page_index =
  route root_path
    "POST"
    ( "/post/comment/" ++ post_id ++ "/" ++ ( String.fromInt page_index ) )
    defaultTimeout
    defaultTracker
    defaultHeaders


replyComment : String -> String -> RequestOptions
replyComment root_path comment_id =
  route root_path
    "POST"
    ( "/post/comment/reply/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getTags : String -> RequestOptions
getTags root_path =
  route root_path
    "GET"
    "/tags"
    defaultTimeout
    defaultTracker
    defaultHeaders


taggedPosts : String -> String -> RequestOptions
taggedPosts root_path tag_id =
  route root_path
    "GET"
    ( "/posts/tag/" ++ tag_id )
    defaultTimeout
    defaultTracker
    defaultHeaders






