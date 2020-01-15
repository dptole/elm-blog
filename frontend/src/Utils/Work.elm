module Utils.Work exposing (..)

import Utils.Types

import Bitwise



notWorking : Int
notWorking = 0


isWorking : Int -> Bool
isWorking work =
  work /= notWorking


isWorkingOn : Int -> Int -> Bool
isWorkingOn work1 work2 =
  Bitwise.and work1 work2 /= notWorking


addWork : Int -> Int -> Int
addWork work1 work2 =
  Bitwise.or work1 work2


removeWork : Int -> Int -> Int
removeWork work1 work2 =
  if isWorkingOn work1 work2 then
    Bitwise.xor work1 work2
  else
    work2

