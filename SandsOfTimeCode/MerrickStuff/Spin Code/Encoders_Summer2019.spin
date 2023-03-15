CON

  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  CS =  0
  CLK =  1
  DI = 2
  NumofEnc = 2

OBJ

  pst : "PST_Driver"

VAR

  'word RawData[NumofEnc]        
  word PosData[NumofEnc]         ' Each encoder gets 16-bits to store its position and status bits
  long tracker, data
  long Stack1[100]

PUB Main | i

  dira[CS..CLK]~~
  dira[DI]~
  coginit(3,PST_Display,@Stack1) 
  tracker := 1

  outa[CLK]~~
  outa[CS]~~
  outa[CS]~
  waitcnt(clkfreq/2000000+cnt)                        ' Wait for 500 ns, as denoted by t_CLKFE on datasheet
  outa[CLK]~
  waitcnt(clkfreq/2000000+cnt)                        ' Wait for 500 ns, as denoted by t_CLK/2 on datasheet

  repeat
    repeat i from 0 to (NumofEnc - 1)
      repeat 16
        outa[CLK]~~
        data := (data << 1) + ina[DI]                   ' Append new bit of data to shifted reading
        outa[CLK]~
      PosData[i] := (data >> 6) & 11_1111_1111
    outa[CLK]~~                                          
    outa[CS]~~                                          ' Data should be read


PUB PST_Display

  pst.start

  repeat
    pst.str(string("Position 1: "))
    pst.dec(PosData[0])
    pst.NewLine
    pst.str(string("Position 2: "))
    pst.dec(PosData[1])
    waitcnt(clkfreq/2+cnt)