module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
  describe "Fake test"
    [ test "First fake test" <|
      \_ ->
        let
          expected = 1
          actual = 1
        in
          Expect.equal expected actual
    ]
