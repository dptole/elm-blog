module Utils.Types exposing (..)

import Math.Vector3

import Dict



-- DEFAULT TYPES

type Route
  = Home
  | SignUp
  | SignIn
  | Tags
  | TagDetails
  | ReadPost
  | Dashboard
  | DashboardProfile
  | DashboardPost
  | DashboardPostCreate
  | DashboardPostEdit
  | DashboardPostShowPrivate
  | DashboardPostReview
  | DashboardPostReviewDetails
  | DashboardComment
  | DashboardCommentReply
  | DashboardCommentReview
  | DashboardCommentReviewDetails


type PageKind
  = PageKindText
  | PageKindImage


type PostStatus
  = PostStatusDraft
  | PostStatusReviewing
  | PostStatusPublished
  | PostStatusCreated


type PreloadImage
  = EmptyImage
  | LoadingImage
  | LoadedImage


type PostCommentStatus
  = PostCommentCreated
  | PostCommentReviewing
  | PostCommentRejected


type PostCommentReplies
  = PostCommentReplies ( List PostComment )


type CommentsForPost
  = CommentsForPostNotReady
  | CommentsForPostReady String Int
  | CommentsForPostLoading String Int
  | CommentsForPostLoaded ( List PostComment )


type SvgCommentsOrientation
  = SvgCommentsOrientationHorizontal
  | SvgCommentsOrientationVertical


type SvgCommentDataReplies
  = SvgCommentDataReplies ( List SvgCommentData )


type PromptResponse a
  = PromptResponseYes a
  | PromptResponseNo


type AvatarDrawingCmd
  = LineDrawingCmd Vertex
  | SquareDrawingCmd ( List Vertex )



-- SPECIAL SHARED TYPES

type SpecialMsg
  = ReSignIn
  | NoSpecial



-- ERROR HANDLING RECORDS

type alias Post_ =
  { title : String
  , pages : List Page
  , id : String
  , status : PostStatus
  , author_id : String
  , notes : String
  , tags : List String
  , errors : List ( Dict.Dict String String )
  , meta : HttpMeta
  , reqid : String
  }


type alias SignUp_ =
  { user : AuthUser
  , errors : List ( Dict.Dict String String )
  , meta : HttpMeta
  , reqid : String
  }


type alias Auth_ =
  { token : AuthToken
  , user : AuthUser
  , errors : List ( Dict.Dict String String )
  , meta : HttpMeta
  , reqid : String
  }


type alias AuthUser_ =
  { id : String
  , username : String
  , errors : List ( Dict.Dict String String )
  , meta : HttpMeta
  , reqid : String
  }



-- DEFAULT RECORDS

type alias Auth =
  { token : AuthToken
  , user : AuthUser
  }


type alias AuthToken =
  { expires : String
  , id : String
  , user_id : String
  }


type alias AuthUser =
  { id : String
  , username : String
  }


type alias SignOut =
  { success : Bool }


type alias UpdatePassword =
  { success : Bool }


type alias Post =
  { title : String
  , pages : List Page
  , id : String
  , status : PostStatus
  , author_id : String
  , notes : String
  , tags : List String
  }


type alias Page =
  { kind : PageKind
  , content : String
  }


type alias PostNote =
  { note : String }


type alias PublishedPost =
  { id : String
  , published_at : String
  , title : String
  , status : PostStatus
  , tags : List String
  , pages : List Page
  , author : AuthUser
  }


type alias PostComment =
  { id : String
  , reply_to_comment_id : Maybe String
  , created_at : String
  , post_id : String
  , page_index : Int
  , status : PostCommentStatus
  , last_update : String
  , message : String
  , author : AuthUser
  , replies : PostCommentReplies
  }


type alias SvgCommentData =
  { id : String
  , message : String
  , author_name : String
  , created_at : String
  , replies : SvgCommentDataReplies
  }


type alias SvgCommentsModel =
  { data : SvgCommentDataReplies
  , expanded_comment : Maybe SvgCommentData
  , focused_comment : List Int
  , work : Int
  , confs : SvgCommentsConfs
  , orientation : SvgCommentsOrientation
  , last_move : ( Int, Int )
  , flags : MainModelFlags
  }


type alias SvgCommentsConfs =
  { top : Int
  , left : Int
  , width : Int
  , height : Int
  , circle_radius : Int
  , rect_border_radius : Int
  , sqm_x : Int
  , sqm_y : Int
  , last_sqms : ( Int, Int )
  }


type alias PostCommentReviewDetails =
  { comment : PostComment
  , post : PublishedPost
  }


type alias PostTag =
  { id : String
  , name : String
  , posts : Int
  , last_updated : String
  }


type alias SinglePostTag =
  { id : String
  , name : String
  }


type alias TaggedPosts =
  { tag : SinglePostTag
  , posts : List PublishedPost
  }


type alias HomePosts =
  { tags : List SinglePostTag
  , posts : List PublishedPost
  }


type alias DateTime =
  { year : Int
  , month : Int
  , day : Int
  , hour : Int
  , minute : Int
  , second : Int
  , millisecond : Int
  , year1970 : Int
  , leap_days : Int
  }


type alias CommentsReplies =
  { comments : List PostComment
  , post : PublishedPost
  }


type alias UserAvatar =
  { avatar : String
  , id : String
  , user_id : String
  }


type alias Vertex =
  { position : Math.Vector3.Vec3
  , color : Math.Vector3.Vec3
  }


type alias PostStatsMetric =
  { date : String
  , hit : Int
  }


type alias PostStatsGraph =
  { post : PublishedPost
  , metrics : List PostStatsMetric
  }


type alias HttpMetaHeaders =
  { set_cookie : List String
  , content_type : String
  , access_control_allow_origin : String
  , access_control_allow_credentials : String
  }


type alias HttpMeta =
  { headers : HttpMetaHeaders
  , status_code : Int
  }


type alias MainModelFlags =
  { url : MainModelFlagsUrl
  , api : String
  }


type alias MainModelFlagsUrl =
  { hash : String
  , host : String
  , hostname : String
  , href : String
  , origin : String
  , protocol : String
  , port_string : String
  , search_params : List MainModelFlagsUrlSearchParam
  }


type alias MainModelFlagsUrlSearchParam =
  { key : String
  , value : String
  }



