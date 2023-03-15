CON     _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_250_000
        CLK = 2
        DATA = 4
        'CS = 6'Replace with a list of pins for Encoders

VAR
  word value
  word CS


OBJ
  pst      : "PST_Driver"

PUB MAIN | i
  dira[CLK]~~
  dira[DATA]~
  dira[6]~~
  dira[16]~~
  outa[6]~~
  outa[16]~~
  pst.start
  repeat
    repeat i from 0 to 1
      CS:= 6 + 10*i
      outa[CS]~    ' Start reading SPI
      value:=0
      repeat 16
        outa[CLK]~~
        value:=(value << 1)| ina[DATA]
        outa[CLK]~
      pst.dec(value >> 6)
      pst.NewLine
      outa[CS]~~



