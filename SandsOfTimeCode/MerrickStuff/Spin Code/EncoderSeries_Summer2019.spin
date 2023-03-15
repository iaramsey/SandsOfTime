CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

CS = 0     'Encoder Pin 6
SI =  2    'Encoder Date Out, Pin 4
CLK = 1    'Encoder Pin 2

EncAmount = 2
OBJ       
  pst : "PST_Driver"

var

long PositionData[5] 
                       
PUB EncoderTest
pst.start

  repeat
    Encoder          'Get Hourglass position from encoder
    pst.str(string("Current positions:"))
    pst.NewLine 
    pst.str(string("Position 0: " ))
    pst.dec(PositionData[0])
    pst.NewLine
    pst.str(string("Position 1: " ))
    pst.dec(PositionData[1])
    waitcnt(clkfreq/2+cnt)
    pst.ClearHome
            
PUB Encoder | Data, i, PosFix
dira[CLK]~~
dira[CS]~~  
dira[SI]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs
Data:=0 


outa[CLK]~~
outa[CS]~~
outa[CS]~
outa[CLK]~                                            
 repeat i from 0 to (EncAmount-1)
    Data:=0
    repeat 16
       outa[CLK]~~                 'Shift through the first 16 bits of data
       Data:=(Data <<1)+ina[SI]    'Get position data from 16-bit Encoder value, starting with MSB                   
       outa[CLK]~  
    PosFix:= Data >> 6               'Shift 6 bits to right to only use upper 10 position bits
     
    PositionData[i]:=PosFix         'Append position array with the current encoder being updated 
    outa[CLK]~~                  'Intermediate clock pulse to signify end of first encoder's position
    outa[CLK]~