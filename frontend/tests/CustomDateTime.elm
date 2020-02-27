module CustomDateTime exposing (..)

import Expect
import Test
import Time
import Utils.Funcs


suite : Test.Test
suite =
  Test.describe "Test custom date time functionality"
    [ Test.test "should count leap years in the sample" <|
      \_ ->
        let
          first_leap_year = List.head correctLeapYears |> Maybe.withDefault 0
          last_leap_year = List.reverse correctLeapYears |> List.head |> Maybe.withDefault 0

          actual = Utils.Funcs.countLeapYearsInYearRange first_leap_year last_leap_year

        in
          -- countLeapYearsInYearRange is inclusive at the start and exclusive at the end
          -- This means that the last year, even if its a leap year, will not be accounted for
          Expect.equal actual 109

    ---------------------------------------------------------------------------

    , Test.test "should validate if iso8601ToDateTime returns the correct leap day" <|
      \_ ->
        let
          list_of_leap_days =
            List.map
              (\year ->
                ( String.fromInt year ) ++ "-02-29T00:00:00.000"
                  |> Utils.Funcs.iso8601ToDateTime
                  |> .day
                  |> Expect.equal 

              )
              correctLeapYears

        in
          Expect.all list_of_leap_days 29

    ---------------------------------------------------------------------------

    , Test.test "should validate if iso8601ToPosix returns the correct leap day" <|
      \_ ->
        let
          list_of_leap_days =
            List.map
              (\year ->
                ( String.fromInt year ) ++ "-02-29T00:00:00.000"
                  |> Utils.Funcs.iso8601ToPosix
                  |> Time.toDay Time.utc
                  |> Expect.equal 

              )
              correctLeapYears

        in
          Expect.all list_of_leap_days 29

    ---------------------------------------------------------------------------

    , Test.test "should validate incorrect list of leap years" <|
      \_ ->
        let
          expectations =
            List.map
              (\year -> Expect.equal <| Utils.Funcs.isLeapYear year )
              incorrectLeapYears

        in
          Expect.all expectations False

    ---------------------------------------------------------------------------

    , Test.test "should validate correct list of leap years" <|
      \_ ->
        let
          expectations =
            List.map
              (\year -> Expect.equal <| Utils.Funcs.isLeapYear year )
              correctLeapYears

        in
          Expect.all expectations True

    ---------------------------------------------------------------------------

    , Test.test "should validate the correct list of dates" <|
      \_ ->
        let
          expectations =
            List.map
              (\(day, month, year) -> Expect.equal <| Utils.Funcs.isValidDayOfMonthOfYear day month year )
              correctLastDayOfTheMonth

        in
          Expect.all expectations True

    ---------------------------------------------------------------------------

    , Test.test "should validate the incorrect list of dates" <|
      \_ ->
        let
          expectations =
            List.map
              (\(day, month, year) -> Expect.equal <| Utils.Funcs.isValidDayOfMonthOfYear day month year )
              incorrectLastDayOfTheMonth

        in
          Expect.all expectations False

    ]


correctLastDayOfTheMonth : List ( Int, Int, Int )
correctLastDayOfTheMonth =
  [ -- non-leap years
    ( 31,  1, 2100 ), ( 28,  2, 2100 ), ( 31,  3, 2100 ),
    ( 30,  4, 2100 ), ( 31,  5, 2100 ), ( 30,  6, 2100 ),
    ( 31,  7, 2100 ), ( 31,  8, 2100 ), ( 30,  9, 2100 ),
    ( 31, 10, 2100 ), ( 30, 11, 2100 ), ( 31, 12, 2100 ),

    -- leap years
    ( 31,  1, 2400 ), ( 29,  2, 2400 ), ( 31,  3, 2400 ),
    ( 30,  4, 2400 ), ( 31,  5, 2400 ), ( 30,  6, 2400 ),
    ( 31,  7, 2400 ), ( 31,  8, 2400 ), ( 30,  9, 2400 ),
    ( 31, 10, 2400 ), ( 30, 11, 2400 ), ( 31, 12, 2400 )
  ]


incorrectLastDayOfTheMonth : List ( Int, Int, Int )
incorrectLastDayOfTheMonth =
  [ -- non-leap years
    ( 32,  1, 2100 ), ( 29,  2, 2100 ), ( 32,  3, 2100 ),
    ( 31,  4, 2100 ), ( 32,  5, 2100 ), ( 31,  6, 2100 ),
    ( 32,  7, 2100 ), ( 32,  8, 2100 ), ( 31,  9, 2100 ),
    ( 32, 10, 2100 ), ( 31, 11, 2100 ), ( 32, 12, 2100 ),

    -- leap years
    ( 32,  1, 2400 ), ( 30,  2, 2400 ), ( 32,  3, 2400 ),
    ( 31,  4, 2400 ), ( 32,  5, 2400 ), ( 31,  6, 2400 ),
    ( 32,  7, 2400 ), ( 32,  8, 2400 ), ( 31,  9, 2400 ),
    ( 32, 10, 2400 ), ( 31, 11, 2400 ), ( 32, 12, 2400 )
  ]


incorrectLeapYears : List Int
incorrectLeapYears =
  [ 1900, 2100, 2200, 2300 ]


correctLeapYears : List Int
correctLeapYears =
  [ 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008,
    2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048,
    2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088,
    2092, 2096, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132,
    2136, 2140, 2144, 2148, 2152, 2156, 2160, 2164, 2168, 2172,
    2176, 2180, 2184, 2188, 2192, 2196, 2204, 2208, 2212, 2216,
    2220, 2224, 2228, 2232, 2236, 2240, 2244, 2248, 2252, 2256,
    2260, 2264, 2268, 2272, 2276, 2280, 2284, 2288, 2292, 2296,
    2304, 2308, 2312, 2316, 2320, 2324, 2328, 2332, 2336, 2340,
    2344, 2348, 2352, 2356, 2360, 2364, 2368, 2372, 2376, 2380,
    2384, 2388, 2392, 2396, 2400, 2404, 2408, 2412, 2416, 2420
  ]
