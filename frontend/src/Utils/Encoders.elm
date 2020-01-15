module Utils.Encoders exposing (..)

import Utils.Types

import Json.Encode



user : String -> String -> Json.Encode.Value
user username password =
  Json.Encode.object
    [ ( "username", Json.Encode.string username )
    , ( "password", Json.Encode.string password )
    ]


postDraftPageRequest : Utils.Types.Page -> Json.Encode.Value
postDraftPageRequest page =
  Json.Encode.object
    [ ( "content", Json.Encode.string page.content )
    , ( "kind", pageKindToString page.kind |> Json.Encode.string )
    ]


upsertPostRequest : Maybe String -> String -> List Utils.Types.Page -> List String -> Json.Encode.Value
upsertPostRequest id title pages tags =
  case id of
    Nothing ->
      Json.Encode.object
        [ ( "title", Json.Encode.string title )
        , ( "tags", Json.Encode.list Json.Encode.string tags )
        , ( "pages", Json.Encode.list ( postDraftPageRequest ) pages )
        ]

    Just post_id ->
      Json.Encode.object
        [ ( "id", Json.Encode.string post_id )
        , ( "title", Json.Encode.string title )
        , ( "tags", Json.Encode.list Json.Encode.string tags )
        , ( "pages", Json.Encode.list ( postDraftPageRequest ) pages )
        ]


postNotes : String -> Json.Encode.Value
postNotes notes =
  Json.Encode.object
    [ ( "notes", Json.Encode.string notes ) ]


postStatus : Utils.Types.PostStatus -> Json.Encode.Value
postStatus status =
  Json.Encode.object
    [ ( "status", postStatusToString status |> Json.Encode.string ) ]


comment : String -> Json.Encode.Value
comment message =
  Json.Encode.object
    [ ( "message", Json.Encode.string message ) ]


updatePassword : String -> Json.Encode.Value
updatePassword password =
  Json.Encode.object
    [ ( "password", Json.Encode.string password ) ]


updateAvatar : String -> Json.Encode.Value
updateAvatar avatar =
  Json.Encode.object
    [ ( "avatar", Json.Encode.string avatar ) ]



-- TYPE WORK AROUND


pageKindToString : Utils.Types.PageKind -> String
pageKindToString kind =
  case kind of
    Utils.Types.PageKindText -> "text"
    Utils.Types.PageKindImage -> "image"


postStatusToString : Utils.Types.PostStatus -> String
postStatusToString status =
  case status of
    Utils.Types.PostStatusDraft -> "draft"
    Utils.Types.PostStatusReviewing -> "reviewing"
    Utils.Types.PostStatusPublished -> "published"
    Utils.Types.PostStatusCreated -> "created"



-- SYNTATIC SUGAR


signInRequest : String -> String -> Json.Encode.Value
signInRequest =
  user


signUpRequest : String -> String -> Json.Encode.Value
signUpRequest =
  user


createComment : String -> Json.Encode.Value
createComment =
  comment


replyComment : String -> Json.Encode.Value
replyComment =
  comment


