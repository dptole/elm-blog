module Utils.ApiRoutes exposing (..)

import Http



type alias RequestOptions =
  { method : String
  , url : String
  , timeout : Maybe Float
  , tracker : Maybe String
  , headers : List Http.Header
  }


route : String -> String -> Maybe Float -> Maybe String -> List Http.Header -> RequestOptions
route method path timeout tracker headers =
  RequestOptions
    method
    ( String.append rootPath path )
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


rootPath : String
rootPath =
  "http://localhost:9090"


postSignUp : RequestOptions
postSignUp =
  route "POST" "/sign_up" defaultTimeout defaultTracker defaultHeaders


postSignIn : RequestOptions
postSignIn =
  route "POST" "/sign_in" defaultTimeout defaultTracker defaultHeaders


postDraft : RequestOptions
postDraft =
  route "POST" "/post/draft" defaultTimeout defaultTracker defaultHeaders


deletePost : String -> RequestOptions
deletePost post_id =
  route
    "DELETE"
    ( "/post/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


addPostNotes : String -> RequestOptions
addPostNotes post_id =
  route
    "PUT"
    ( "/post/notes/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


updatePostStatus : String -> RequestOptions
updatePostStatus post_id =
  route
    "PUT"
    ( "/post/status/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getPublishedPosts : RequestOptions
getPublishedPosts =
  route "GET" "/posts" defaultTimeout defaultTracker defaultHeaders


getPublishedPost : String -> RequestOptions
getPublishedPost post_id  =
  route
    "GET"
    ( "/post/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


commitDraft : RequestOptions
commitDraft =
  route "POST" "/post/commit" defaultTimeout defaultTracker defaultHeaders


putDraft : RequestOptions
putDraft =
  route "PUT" "/post/draft" defaultTimeout defaultTracker defaultHeaders


updatePassword : RequestOptions
updatePassword =
  route "PUT" "/me/password" defaultTimeout defaultTracker defaultHeaders


updateAvatar : RequestOptions
updateAvatar =
  route "PUT" "/me/avatar" defaultTimeout defaultTracker defaultHeaders


getMyAvatar : RequestOptions
getMyAvatar =
  route "GET" "/me/avatar" defaultTimeout defaultTracker defaultHeaders


getMyPostsStatsGraph : RequestOptions
getMyPostsStatsGraph =
  route "GET" "/me/graphs/post-stats" defaultTimeout defaultTracker defaultHeaders


hitPostStats : String -> RequestOptions
hitPostStats post_id =
  route
    "GET"
    ( "/graphs/post-stats/" ++ post_id ++ "/hit" )
    defaultTimeout
    defaultTracker
    defaultHeaders


getAvatar : String -> RequestOptions
getAvatar user_id =
  route
    "GET"
    ( "/avatar/" ++ user_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getMe : RequestOptions
getMe =
  route "GET" "/me" defaultTimeout defaultTracker defaultHeaders


getSignOut : RequestOptions
getSignOut =
  route "GET" "/sign_out" defaultTimeout defaultTracker defaultHeaders


getMePosts : RequestOptions
getMePosts =
  route "GET" "/me/posts" defaultTimeout defaultTracker defaultHeaders


getPostsToReview : RequestOptions
getPostsToReview =
  route
    "GET"
    "/me/posts/review"
    defaultTimeout
    defaultTracker
    defaultHeaders


getPostToReview : String -> RequestOptions
getPostToReview post_id =
  route
    "GET"
    ( "/me/posts/review/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getMePost : String -> RequestOptions
getMePost post_id =
  route
    "GET"
    ( "/me/post/" ++ post_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsReplies : RequestOptions
getCommentsReplies =
  route
    "GET"
    "/me/comments/replies"
    defaultTimeout
    defaultTracker
    defaultHeaders


getPostComment : String -> Int -> RequestOptions
getPostComment post_id page_index =
  route
    "GET"
    ( "/post/" ++ post_id ++ "/comments/" ++ ( String.fromInt page_index ) )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentReplies : String -> RequestOptions
getCommentReplies comment_id =
  route
    "GET"
    ( "/post/comments/replies/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsAfter : String -> RequestOptions
getCommentsAfter comment_id =
  route
    "GET"
    ( "/post/comments/after/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsReviews : RequestOptions
getCommentsReviews =
  route
    "GET"
    "/post/comments/review"
    defaultTimeout
    defaultTracker
    defaultHeaders


getCommentsReviewDetails : String -> RequestOptions
getCommentsReviewDetails comment_id =
  route
    "GET"
    ( "/post/comments/review/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


publishComment : String -> RequestOptions
publishComment comment_id =
  route
    "POST"
    ( "/post/comment/review/publish/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


rejectComment : String -> RequestOptions
rejectComment comment_id =
  route
    "POST"
    ( "/post/comment/review/reject/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


createComment : String -> Int -> RequestOptions
createComment post_id page_index =
  route
    "POST"
    ( "/post/comment/" ++ post_id ++ "/" ++ ( String.fromInt page_index ) )
    defaultTimeout
    defaultTracker
    defaultHeaders


replyComment : String -> RequestOptions
replyComment comment_id =
  route
    "POST"
    ( "/post/comment/reply/" ++ comment_id )
    defaultTimeout
    defaultTracker
    defaultHeaders


getTags : RequestOptions
getTags =
  route
    "GET"
    "/tags"
    defaultTimeout
    defaultTracker
    defaultHeaders


taggedPosts : String -> RequestOptions
taggedPosts tag_id =
  route
    "GET"
    ( "/posts/tag/" ++ tag_id )
    defaultTimeout
    defaultTracker
    defaultHeaders






