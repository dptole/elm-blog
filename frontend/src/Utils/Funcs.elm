module Utils.Funcs exposing (..)

import Utils.Types

import Bitwise
import Dict
import Html
import Http
import Time



-- MISC LOG


log : a -> ( b, Cmd a ) -> ( b, Cmd a )
log msg tuple =
  --case tuple of
    --( new_model, _ ) ->
      --let
        --_ = Debug.log "MODEL" new_model
        --_ = Debug.log "MSG" msg
        --_ = Debug.log "END" "END"
      --in
        tuple


redirectMsgToSubModule : a      -- sub_module_msg
  -> b                          -- sub_model
  -> ( a -> b -> ( c, Cmd d ) ) -- sub_module_update
  -> ( c -> e -> e )            -- sub_model_update
  -> ( d -> f )                 -- main_module_interceptor_msg
  -> e                          -- model
  -> ( e, Cmd f )
redirectMsgToSubModule a b f g h e =
  let
    ( c, d ) = f a b
  in
    ( g c e, Cmd.map h d )


maybeRedirectMsgToSubModule : a -- sub_module_msg
  -> Maybe b                    -- sub_model
  -> ( a -> b -> ( c, Cmd d ) ) -- sub_module_update
  -> ( c -> e -> e )            -- sub_model_update
  -> ( d -> f )                 -- main_module_interceptor_msg
  -> e                          -- model
  -> ( e, Cmd f )
maybeRedirectMsgToSubModule a b f g h e =
  case b of
    Just i ->
      let
        ( c, d ) = f a i
      in
        ( g c e, Cmd.map h d )
    Nothing ->
      ( e, Cmd.none )



-- MISC MATH


isEven : Int -> Bool
isEven num =
  isOdd num |> not


isOdd : Int -> Bool
isOdd num =
  Bitwise.and num 1 == 1



-- MISC LISTS


flipHeadAndTail : List a -> List a
flipHeadAndTail list =
  List.concat
    [ List.drop 1 list
    , List.take 1 list
    ]


tailFirst : List a -> List a
tailFirst list =
  List.append
    ( List.drop 1 list )
    ( List.take 1 list )


zip : List a -> List b -> List (a, b)
zip list1 list2 =
  List.map2 Tuple.pair list1 list2


prepend : List a -> List a -> List a
prepend list1 list2 =
  List.append list2 list1



-- MISC DATE


publicationDate : String -> String
publicationDate iso8601 =
  ( String.slice 0 10 iso8601 ) ++
  " " ++
  ( String.slice 11 16 iso8601 )



-- MISC DATE CONVERTERS


iso8601HumanDateDiff : String -> String -> String
iso8601HumanDateDiff present relative_date_time =
  let
    present_ms = iso8601ToMillis present

    future_ms = iso8601ToMillis relative_date_time

    diff_ms = present_ms - future_ms |> abs

    diff_seconds_floor =
      toFloat ( secondToMillis 1 )
        |> (/) ( toFloat diff_ms )
        |> floor

    diff_minutes_floor =
      toFloat ( minuteToMillis 1 )
        |> (/) ( toFloat diff_ms )
        |> floor

    diff_hours_floor =
      toFloat ( hourToMillis 1 )
        |> (/) ( toFloat diff_ms )
        |> floor

    diff_days_floor =
      toFloat ( dayToMillis 1 )
        |> (/) ( toFloat diff_ms )
        |> floor

    diff_months = ( toFloat diff_ms ) / approxMonthsMillisInYear

    diff_months_floor = floor diff_months

    diff_years = diff_months / 12 |> floor

    relative_diff =
      if present_ms > future_ms then
        "ago"

      else if present_ms == future_ms then
        "now"

      else
        "from now"

  in
    -- years
    if diff_years > 0 then
      if diff_years > 1 then
        ( String.fromInt diff_years ) ++ " years " ++ relative_diff

      else
        ( String.fromInt diff_years ) ++ " year " ++ relative_diff

    -- months
    else if diff_months_floor > 0 then
      if diff_months_floor > 1 then
        ( String.fromInt diff_months_floor ) ++ " months " ++ relative_diff

      else
        ( String.fromInt diff_months_floor ) ++ " month " ++ relative_diff

    -- days
    else if diff_days_floor > 0 then
      if diff_days_floor > 1 then
        ( String.fromInt diff_days_floor ) ++ " days " ++ relative_diff

      else
        ( String.fromInt diff_days_floor ) ++ " day " ++ relative_diff

    -- hours
    else if diff_hours_floor > 0 then
      if diff_hours_floor > 1 then
        ( String.fromInt diff_hours_floor ) ++ " hours " ++ relative_diff

      else
        ( String.fromInt diff_hours_floor ) ++ " hour " ++ relative_diff

    -- minutes
    else if diff_minutes_floor > 0 then
      if diff_minutes_floor > 1 then
        ( String.fromInt diff_minutes_floor ) ++ " minutes " ++ relative_diff

      else
        ( String.fromInt diff_minutes_floor ) ++ " minute " ++ relative_diff

    -- seconds
    else if diff_seconds_floor > 0 then
      if diff_seconds_floor > 1 then
        ( String.fromInt diff_seconds_floor ) ++ " seconds " ++ relative_diff

      else
        ( String.fromInt diff_seconds_floor ) ++ " second " ++ relative_diff

    else
      "now"


millisToDateTime : Int -> Utils.Types.DateTime
millisToDateTime millis =
  let
    p = Time.millisToPosix millis

    utc = Time.utc

    month = posixMonthToInt utc p

    year = Time.toYear utc p

    year1970 = year - initYear

  in
    Utils.Types.DateTime
      year
      month
      ( Time.toDay utc p )
      ( Time.toHour utc p )
      ( Time.toMinute utc p )
      ( Time.toSecond utc p )
      ( Time.toMillis utc p )
      year1970
      ( countLeapYearsInYearRange initYear year )


posixMonthToInt : Time.Zone -> Time.Posix -> Int
posixMonthToInt utc posix =
  case Time.toMonth utc posix of
    Time.Jan -> 1
    Time.Feb -> 2
    Time.Mar -> 3
    Time.Apr -> 4
    Time.May -> 5
    Time.Jun -> 6
    Time.Jul -> 7
    Time.Aug -> 8
    Time.Sep -> 9
    Time.Oct -> 10
    Time.Nov -> 11
    Time.Dec -> 12


posixToIso8601 : Time.Zone -> Time.Posix -> String
posixToIso8601 utc posix =
  let
    year = Time.toYear utc posix |> lpadInt 4
    month = posixMonthToInt utc posix |> lpadInt 2
    day = Time.toDay utc posix |> lpadInt 2
    hour = Time.toHour utc posix |> lpadInt 2
    minute = Time.toMinute utc posix |> lpadInt 2
    second = Time.toSecond utc posix |> lpadInt 2
    millis = Time.toMillis utc posix |> lpadInt 3

  in
    String.join
      "."
      [ String.join
          "T"
          [ String.join
              "-"
              [ year, month, day ]
          , String.join
              ":"
              [ hour, minute, second ]
          ]
      , millis
      ]


iso8601ToMillis : String -> Int
iso8601ToMillis date_time =
  let
    dt = iso8601ToDateTime date_time

  in
    List.sum
      [ yearToMillis dt.year1970
      , monthToMillis dt.month
      , ( dayToMillis dt.day ) - ( dayToMillis 1 )
      , hourToMillis dt.hour
      , minuteToMillis dt.minute
      , secondToMillis dt.second
      , dt.millisecond
      , dayToMillis dt.leap_days
      ]


iso8601ToPosix : String -> Time.Posix
iso8601ToPosix date_time =
  iso8601ToMillis date_time
    |> Time.millisToPosix


iso8601ToDateTime : String -> Utils.Types.DateTime
iso8601ToDateTime date_time =
  let
    year =
      String.slice 0 4 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    month =
      String.slice 5 7 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    day =
      String.slice 8 10 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    hour =
      String.slice 11 13 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    minute =
      String.slice 14 16 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    second =
      String.slice 17 19 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    millisecond =
      String.slice 20 23 date_time
        |> String.toInt
        |> Maybe.withDefault -1

    year1970 = year - initYear

  in
    if
      not (
        isValidYear year &&
        isValidMonth month &&
        isValidDayOfMonthOfYear day month year &&
        isValidHour hour &&
        isValidMinute minute &&
        isValidSecond second &&
        isValidMillisecond millisecond
      )
    then
      Utils.Types.DateTime
        initYear
        1
        1
        0
        0
        0
        0
        0
        0

    else
      Utils.Types.DateTime
        year
        month
        day
        hour
        minute
        second
        millisecond
        year1970
        ( countLeapYearsInYearRange initYear year )


yearToMillis : Int -> Int
yearToMillis year =
  if year < 0 then
    0

  else
    year * ( 365 * 24 * 60 * 60 * 1000 )


monthToMillis : Int -> Int
monthToMillis month =
  let
    iter : Int -> Int
    iter m =
      let
        month2 = m - 1

      in
        if month2 == 2 then
          ( iter month2 ) + 2419200000 -- 28 days

        else if List.member month2 [1, 3, 5, 7, 8, 10, 12] then
          ( iter month2 ) + 2678400000 -- 31 days

        else if List.member month2 [4, 6, 9, 11] then
          ( iter month2 ) + 2592000000 -- 30 days

        else
          0

  in
    iter month


dayToMillis : Int -> Int
dayToMillis day =
  if day < 0 then
    0

  else
    day * 24 |> hourToMillis


hourToMillis : Int -> Int
hourToMillis hour =
  if hour < 0 then
    0

  else
    hour * 60 |> minuteToMillis


minuteToMillis : Int -> Int
minuteToMillis minute =
  if minute < 0 then
    0

  else
    minute * 60 |> secondToMillis


secondToMillis : Int -> Int
secondToMillis second =
  if second < 0 then
    0

  else
    second * 1000



-- MISC DATE VALIDATORS


isLeapYear : Int -> Bool
isLeapYear year =
  modBy 400 year == 0 ||
  (
    modBy   4 year == 0 &&
    modBy 100 year /= 0
  )


isValidYear : Int -> Bool
isValidYear year =
  year > 1969 && year < 10000


isValidMonth : Int -> Bool
isValidMonth month =
  month > 0 && month < 13


isValidHour : Int -> Bool
isValidHour hour =
  hour >= 0 && hour < 24


isValidMinute : Int -> Bool
isValidMinute minute =
  minute >= 0 && minute < 60


isValidSecond : Int -> Bool
isValidSecond second =
  second >= 0 && second < 60


isValidMillisecond : Int -> Bool
isValidMillisecond millisecond =
  millisecond >= 0 && millisecond < 1000


isValidDayOfMonthOfYear : Int -> Int -> Int -> Bool
isValidDayOfMonthOfYear day month year =
  day > 0 && isValidYear year && isValidMonth month &&
  ( ( day < 32 && List.member month [1, 3, 5, 7, 8, 10, 12] ) ||
    ( day < 31 && List.member month [4, 6, 9, 11] ) ||
    ( day < 30 && isLeapYear year ) ||
    ( day < 29 )
  )


countLeapYearsInYearRange : Int -> Int -> Int
countLeapYearsInYearRange from_year to_year =
  let
    iter : Int -> Int -> Int
    iter current_year leaps =
      if current_year == to_year then
        leaps

      else if isLeapYear current_year then
        iter
          ( current_year + 1 )
          ( leaps + 1 )

      else
        iter
          ( current_year + 1 )
          leaps

  in
    iter from_year 0



-- MISC DATE CONSTANTS


initYear : Int
initYear =
  1970


approxMonthsMillisInYear : Float
approxMonthsMillisInYear =
  30.416 * 24 * 60 * 60 * 1000



-- MISC STRING


lpadInt : Int -> Int -> String
lpadInt pad n =
  String.fromInt n |> String.padLeft pad '0'


hexCharToInt : Char -> Maybe Int
hexCharToInt char =
  case char of
    '0' -> Just 0
    '1' -> Just 1
    '2' -> Just 2
    '3' -> Just 3
    '4' -> Just 4
    '5' -> Just 5
    '6' -> Just 6
    '7' -> Just 7
    '8' -> Just 8
    '9' -> Just 9
    'a' -> Just 10
    'b' -> Just 11
    'c' -> Just 12
    'd' -> Just 13
    'e' -> Just 14
    'f' -> Just 15
    _ -> Nothing


hexToInt : String -> Maybe Int
hexToInt hex =
  let
    maybe_ints =
      String.toLower hex
        |> String.toList
        |> List.map hexCharToInt
        |> List.foldl (\i acc ->
            case Maybe.map2 Tuple.pair i acc of
              Just (n, a) ->
                Just (n :: a)
              Nothing ->
                Nothing
            ) (Just [])

  in
    case maybe_ints of
      Just ints ->
        List.indexedMap (\i n ->
          if i == 0 then
            n
          else
            16 ^ i * n
        ) ints
          |> List.sum
          |> Just

      Nothing ->
        Nothing


minimum : List comparable -> List comparable
minimum comps =
  case comps of
    f :: s :: tail ->
      minimum
        ( ( min f s )
          ::
          tail
        )
    f :: tail ->
      [ f ]
    [] ->
      []


maximum : List comparable -> List comparable
maximum comps =
  case comps of
    f :: s :: tail ->
      maximum
        ( ( max f s )
          ::
          tail
        )
    f :: tail ->
      [ f ]
    [] ->
      []


maximumFloat : List Float -> Float
maximumFloat floats =
  case floats of
    first :: second :: tail ->
      maximumFloat
        ( ( max first second )
          ::
          tail
        )

    first :: [] ->
      first

    [] ->
      infinity


minimumFloat : List Float -> Float
minimumFloat floats =
  case floats of
    first :: second :: tail ->
      minimumFloat
        ( ( min first second )
          ::
          tail
        )

    first :: [] ->
      first

    [] ->
      negInfinity


int3 : Maybe a -> Maybe a -> Maybe a -> Maybe { a : a, b : a, c : a }
int3 maybe_a maybe_b maybe_c =
  case Maybe.map2 Tuple.pair maybe_a maybe_b of
    Nothing ->
      Nothing

    Just ( a, b ) ->
      case maybe_c of
        Nothing ->
          Nothing

        Just c ->
          Just
            { a = a
            , b = b
            , c = c
            }


head4 : List a -> List a -> List a -> List a -> Maybe { a : a, b : a, c : a, d : a }
head4 list_a list_b list_c list_d =
  case Maybe.map2 Tuple.pair ( List.head list_a ) ( List.head list_b ) of
    Nothing ->
      Nothing

    Just ( head_a, head_b ) ->
      case Maybe.map2 Tuple.pair ( List.head list_c ) ( List.head list_d ) of
        Nothing ->
          Nothing

        Just ( head_c, head_d ) ->
          Just
            { a = head_a
            , b = head_b
            , c = head_c
            , d = head_d
            }


head8 : List a -> List a -> List a -> List a -> List a -> List a -> List a -> List a -> Maybe { a1 : a, b1 : a, c1 : a, d1 : a, a2 : a, b2 : a, c2 : a, d2 : a }
head8 list_a list_b list_c list_d list_e list_f list_g list_h =
  case Maybe.map2 Tuple.pair ( List.head list_a ) ( List.head list_b ) of
    Nothing ->
      Nothing

    Just ( head_a, head_b ) ->
      case Maybe.map2 Tuple.pair ( List.head list_c ) ( List.head list_d ) of
        Nothing ->
          Nothing

        Just ( head_c, head_d ) ->
          case Maybe.map2 Tuple.pair ( List.head list_e ) ( List.head list_f ) of
            Nothing ->
              Nothing

            Just ( head_e, head_f ) ->
              case Maybe.map2 Tuple.pair ( List.head list_g ) ( List.head list_h ) of
                Nothing ->
                  Nothing

                Just ( head_g, head_h ) ->
                  Just
                    { a1 = head_a
                    , b1 = head_b
                    , c1 = head_c
                    , d1 = head_d
                    , a2 = head_e
                    , b2 = head_f
                    , c2 = head_g
                    , d2 = head_h
                    }


isNothing : Maybe a -> Bool
isNothing m =
  case m of
    Nothing -> True
    _ -> False


listNumberString2IndexedRecords : List number -> List String -> List { index : Int, a : number, b : String }
listNumberString2IndexedRecords list_a list_b =
  List.indexedMap (\i _ -> i) list_a
    |> List.map3 (\a b i -> { index = i, a = a, b = b } ) list_a list_b


negInfinity : Float
negInfinity = -infinity


infinity : Float
infinity = 1 / 0


extractErrorsFromDicts : List ( Dict.Dict String String ) -> List ( String, String )
extractErrorsFromDicts dicts =
  List.filterMap (\(k, v) ->
    case v of
      Nothing -> Nothing
      Just value -> Just (k, value)
  )
    <| List.concatMap
        (\(dict, keys) -> List.map (\key -> (key, Dict.get key dict)) keys)
    <| List.map
        (\dict -> (dict, Dict.keys dict)) dicts


htmlSeparator1 : List ( Html.Html msg ) -> List ( Html.Html msg )
htmlSeparator1 =
  List.intersperse ( Html.br [] [] )


mergeDicts : List ( Dict.Dict comparable b ) -> Dict.Dict comparable b
mergeDicts dicts =
  List.foldl (\dict acc ->
    Dict.foldl (\key value acc2 ->
      Dict.insert key value acc2
    ) acc dict
  ) ( Dict.fromList [] ) dicts


emptyDict : Dict.Dict comparable a
emptyDict =
  Dict.fromList []


isHttpStatusUnauthorized : Http.Error -> Bool
isHttpStatusUnauthorized error =
  case error of
    Http.BadStatus status ->
      status == 401
    _ ->
      False


handleHttpUnauthorizedError : ( msg -> model -> ( model, Cmd msg ) ) -> model -> ( Utils.Types.SpecialMsg -> sub_module_special ) -> ( sub_module_special -> msg ) -> ( model -> model ) -> ( model, Cmd msg )
handleHttpUnauthorizedError update model sub_module_special_type wrapper_type transform_model =
  transform_model model
    |> update ( sub_module_special_type Utils.Types.ReSignIn |> wrapper_type )


handleHttpError : Http.Error -> ( msg -> model -> ( model, Cmd msg ) ) -> model -> Cmd msg -> ( Utils.Types.SpecialMsg -> sub_module_special ) -> ( sub_module_special -> msg ) -> ( model -> model ) -> ( model -> ( model, Cmd msg ) ) -> ( model, Cmd msg )
handleHttpError error update model cmd sub_module_special_type wrapper_type transform_model default_behavior =
  if isHttpStatusUnauthorized error then
    handleHttpUnauthorizedError
      update
      model
      sub_module_special_type
      wrapper_type
      transform_model

  else
    default_behavior model


