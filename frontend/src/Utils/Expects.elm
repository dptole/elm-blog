module Utils.Expects exposing (..)

import Http
import Json.Decode



-- https://package.elm-lang.org/packages/elm/http/2.0.0/Http#expectStringResponse
json : ( Result Http.Error a -> msg ) -> Json.Decode.Decoder a -> Http.Expect msg
json toMsg decoder =
  Http.expectStringResponse toMsg <|
    \response ->
      case response of
        Http.BadUrl_ url ->
          Err ( Http.BadUrl url )

        Http.Timeout_ ->
          Err Http.Timeout

        Http.NetworkError_ ->
          Err Http.NetworkError

        Http.BadStatus_ metadata body ->
          -- Err ( Http.BadStatus metadata.statusCode )
          case Json.Decode.decodeString decoder body of
            Ok value ->
              Ok value

            Err err ->
              Err ( Http.BadBody ( Json.Decode.errorToString err ) )

        Http.GoodStatus_ metadata body ->
          case Json.Decode.decodeString decoder body of
            Ok value ->
              Ok value

            Err err ->
              Err ( Http.BadBody ( Json.Decode.errorToString err ) )


