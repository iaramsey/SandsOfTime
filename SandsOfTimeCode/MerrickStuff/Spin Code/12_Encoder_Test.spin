CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  CS  = 4             'Encoder activation on Pin 4   - Encoder 6 
  SI  = 6             'Encoder Output on Pin 6       - Encoder 4
  CLK = 5             'Encoder CLK on Pin 5          - Encoder 2

  EncAmount = 4
  
OBJ       
  pst : "PST_Driver"

var

long PositionData[100], Stack2[100], j
                       
PUB EncoderTest
pst.start
coginit(2, Encoder, @Stack2)

  repeat  
    pst.str(string("Current positions:"))
    pst.NewLine 
    repeat j from 1 to (EncAmount)
      pst.dec(j)
      pst.str(string(" o'clock HG Position: "))
      pst.dec(PositionData[j])
      pst.NewLine

    waitcnt(clkfreq+cnt)
    pst.ClearHome
            
PUB Encoder | Data, i, PosFix
dira[CS]~~
dira[CLK]~~  
dira[SI]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs
Data:=0 


repeat
  outa[CS]~~
  outa[CS]~
  outa[CLK]~~
  outa[CLK]~                                            
   repeat i from 1 to (EncAmount)
      Data:=0
      repeat 16
         outa[CLK]~~                 'Shift through the first 16 bits of data
         Data:=(Data <<1)+ina[SI]    'Get position data from 16-bit Encoder value, starting with MSB                   
         outa[CLK]~  
      PosFix:= Data >> 6               'Shift 6 bits to right to only use upper 10 position bits
       
      PositionData[i]:=PosFix         'Append position array with the current encoder being updated 
      outa[CLK]~~                  'Intermediate clock pulse to signify end of first encoder's position
      outa[CLK]~
  outa[CS]~~
  outa[CLK]~~
  'PositionData[0]:=PositionData[12]
  'waitcnt(clkfreq/1000+cnt)