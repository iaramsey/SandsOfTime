CON     _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_250_000
        CLK = 15
        DATA = 14
        CS = 13'Replace with a list of pins for Encoders

VAR
  word value

OBJ
  pst      : "PST_Driver"

PUB MAIN | i
  dira[CLK]~~
  outa[CLK]~~
  dira[DATA]~
  dira[CS]~~
  outa[CS]~~
  pst.start
  repeat
    outa[CS]~
    outa[CLK]~    ' Start reading SPI
    value:=0
    repeat 16
      outa[CLK]~~
      value:=(value << 1)+ina[DATA]
      outa[CLK]~
    pst.dec(value >> 6)
    pst.NewLine
    outa[CLK]~~                  'Intermediate clock pulse to signify end of first encoder's position
    outa[CLK]~
    outa[CS]~~


