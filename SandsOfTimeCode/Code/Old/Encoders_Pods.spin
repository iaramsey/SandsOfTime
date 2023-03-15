CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

CS  = 4             'Encoder activation on Pin 4   - Encoder 6 
SI1 = 6             'Encoder Output on Pin 6       - Encoder 4
CLK = 5             'Encoder CLK on Pin 5          - Encoder 2

SI2 = 17    'Encoder Data Out for Pod 5-8
SI3 = 18    'Encoder Data Out for Pod 9-12

EncAmount = 4   ' Number of encoders in each pod (4 for final)
PodNum = 3      ' Number of pods (each requires its own SI pin) 3 for final
OBJ       
  pst : "PST_Driver"

var

long PositionData[13], Stack2[100], j
                       
PUB EncoderTest
pst.start
coginit(2, Encoder, @Stack2)

  repeat
    pst.str(string("Current positions:"))
    pst.NewLine 
    repeat j from 1 to (EncAmount*PodNum)
      pst.str(string("Position "))
      pst.dec(j)
      pst.str(string(": "))
      pst.dec(PositionData[j])
      pst.NewLine

    waitcnt(clkfreq/10+cnt)
    pst.ClearHome
            
PUB Encoder | Data_1_4, Data_5_8, Data_9_12, i, PosFix1, PosFix2, PosFix3
dira[CS]~~
dira[CLK]~~  
dira[SI1]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs
dira[SI2]~
dira[SI3]~
Data_1_4:=0
Data_5_8:=0
Data_9_12:=0 


repeat
  outa[CS]~~
  outa[CS]~
  outa[CLK]~~
  outa[CLK]~                                            
   repeat i from 1 to (EncAmount)
      Data_1_4:=0
      Data_5_8:=0
      Data_9_12:=0
      repeat 16
         outa[CLK]~~                 'Shift through the first 16 bits of data
         Data_1_4:=(Data_1_4 <<1)+ina[SI1]    'Get position data from 16-bit Encoder value, starting with MSB
         Data_5_8:=(Data_5_8 <<1)+ina[SI2]    'Get position data from 16-bit Encoder value, starting with MSB
         Data_9_12:=(Data_9_12 <<1)+ina[SI3]    'Get position data from 16-bit Encoder value, starting with MSB                   
         outa[CLK]~  
      PosFix1:= Data_1_4 >> 6               'Shift 6 bits to right to only use upper 10 position bits
      PosFix2:= Data_5_8 >> 6               'Shift 6 bits to right to only use upper 10 position bits       
      PosFix3:= Data_9_12 >> 6               'Shift 6 bits to right to only use upper 10 position bits
      PositionData[i]:=PosFix1         'Append position array with the current encoder being updated
      PositionData[i+(1*EncAmount)]:=PosFix2               ' Appends data to index 5,6,7,8
      PositionData[i+(2*EncAmount)]:=PosFix3               ' Appends data to index 9,10,11,12
      outa[CLK]~~                  'Intermediate clock pulse to signify end of first encoder's position
      outa[CLK]~
  PositionData[0]:=PositionData[12]                     ' Makes sure that there is no confusion on the 12 or 0 indexing
  outa[CS]~~
  outa[CLK]~~
  waitcnt(clkfreq/10+cnt)