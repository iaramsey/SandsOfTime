CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

 '******************ENCODER CONSTANTS******************
  CS  = 4             'Encoder activation on Pin 4   - Encoder 6 
  SI  = 6             'Encoder Output on Pin 6       - Encoder 4
  CLK = 5             'Encoder CLK on Pin 5          - Encoder 2

  ArmCS  = 9             'Encoder activation on Pin 7   - Encoder 6 
  ArmSI  = 8             'Encoder Output on Pin 8       - Encoder 4
  ArmCLK = 7             'Encoder CLK on Pin 5          - Encoder 2     
  EncAmount = 4 
   'ArmZero = 0                       'Sets Arm Zero position 
 '******************MOTOR CONSTANTS******************
  EPWMPin    = 26                     'PWM signal sent out to H-bridge chip to control motor's speed  
  EDir       = 27                     'Directional control pin 1=CW 0=CCW (when facing the motor)
                  
  HPWMPin    = 24                     'Hourglass rotation PWM control     'Pin 10 was blown
  HDir       = 25                     'Hourglass rotation direction
                  
  ArmPWMPin  = 22  
  ArmDir     = 23  
                  
  BackLimit  = 14                     'Limit Switch pin. Restricts retraction
  FrontLimit = 13                     'Limit Switch pin. Restricts extension

 'E REFERS TO EXTENSION MOTOR
 'H REFERS TO HOURGLASS ROTATION MOTOR AND HOURGLASS ENCODERS
 'ARM REFERS TO HOUR HAND ROTATION MOTOR AND ENCODER
                                                 
 '******************LED CONSTANTS******************
  LEDPin = 16
  TotalLEDs=1116
  
  R1Start  = 0  
  R1End    = 31 
  R2Start  = 32 
  R2End    = 55 
  R3Start  = 56 
  R3End    = 71 
  R4Start  = 72 
  R4End    = 83 
  R5Start  = 84 
  R5End    = 91 
                
  R1Len    = 32 
  R2Len    = 24 
  R3Len    = 16 
  R4Len    = 12 
  R5Len    = 8
   
  MaxInt = 40                                '15 colors in length, violet is last one     

' LED MODEs
    
  LEDHome      = 0
  ArmRotateLED = 1
  ExtendLED    = 2
  RotateLED    = 3
  DrainLED     = 4
  LightShow    = 5

'******************INTERFACE************************
              
  LCDPIN = 15

'LCDMODES
  LCDClear        = 0
  LCDPosition     = 1
  LCDTime         = 2
  LCDPositionTime = 3
  LCDPrint        = 4
  LCDDec          = 5
  'Grey = 3.3
  'Green = GND


'RESET Variables
  ValueHour   = 0                 'Local constants
  ValueMinute = 1
  ValueSecond = 2
  ValuePM     = 3
  ConfirmTime = 4
           
           
  LeftPin   = 17     'Brown '
  DownPin   = 18    'Red
  RightPin  = 19   'Orange
  ClickPin  = 20      'Blue
  UpPin     = 21   'Purple
           
  Left     = %01111 
  Down     = %10111 
  Right    = %11011
  Up       = %11101   
  Click    = %11110 
  NoInput  = %11111


 '******************CLOCK CONSTANTS******************
'SQW = 4
  CCLK = 3
  CSI = 2
  CSO = 1
  CCS = 0

'Read Addresses   'Each bytes's 8-bits are assigned in the following way (#=bit number, X=not used)...
                    ' *10s  __s                              '12:09:00AM 11/3/15
  _seconds=$00       'X_654_3210                             time[0]:=0<<4 + 0
                    ' *10m  __m
  _minutes=$01       'X_654_3210                             time[1]:=0<<4 + 9                    
                    '   1/0   1/0  *10hr  hr
  _hour=$02          'X_12/24_PM/AM_4____3210                time[2]:=1<<6 + 0<<5 + 1<<4 + 2      
                    '      day
  _day=$03           'XXXXX_210                              time[3]:=2
                    '   *10  date
  _date=$04          'XX_54___3210                           time[4]:=0<<4 + 3
                    'century   *10month month
  _month=$05         '7______XX_4________3210                time[5]:=0<<7 + 1<<4 + 1
                    '*10yr __yr
  _year=$06          '7654__3210                             time[6]:=1<<4 + 5



'Write Address = Read Address + $80          ($80=128=%1000_0000) 

VAR
'************************SECONDARY COG STACKS*********
  long Stack1[400], Stack2[400], Stack3[400], Stack4[100], Stack5[100], Stack6[400], Stack7[500]

'************************LIGHT VARIABLES**************
  long LEDMode, MinuteRing, HourRing
 
'************************MOTOR VARIABLES************** 
  long EDutyCycle, HDutyCycle  'DutyCycle=high time of PWM signal
  long ExtTime, retract, contact, StartTime, Flipping, idle  
  long ArmDutyCycle, ArmPosition, ArmTarget, rotate, TargetReached
  long PrevPosition, HGposition, HGPrevPosition, HGtarget 
  long PWMPin1, PWMPin2
  
'************************ENCODER VARIABLES************        
  long ArmRawData[3], ArmStatusData[3], ArmPositionData[3]
  long HGRawData[30], HGStatusData[30], HGPositionData[30]  
  long error, EncoderIdle
  long CurrentHourNumber, MinuteHG
  

  '***********************CLOCK VARIABLES************

  long HourReset, CanArmRotate, ClockPause, InterfacePause           'True/False variables on whether the arm can do a move
  byte DecimalSecond, DecimalMinute, DecimalHour, DecimalDate, DecimalMonth, DecimalYear
  long SecondInput, MinuteInput, HourInput, HourSet, MinuteSet   
  byte time[7]
     
  '***********************INTERFACE VARIABLES************     
  long LCDMode, LCDText, LCDDecInput
  long ValueBeingSet, PauseDecHour, PauseDecMinute, PauseDecSecond, PausePM
  byte JoyStickInput

  byte choice

  long maxAddress
    
OBJ
  pst : "PST_Driver"
  rgb : "WS2812B_RGB_LED_Driver"
  lcd : "serial_LCD"
  
DAT
'**Encoder Values for all clock values (12 is included on both ends for redundancy)
ArmAbsPosition long  1023, 942, 858, 773, 694, 609, 523, 432, 343, 252, 172, 87, 1023         

'**LEDS
Colors  long  rgb#red              'Array called "Colors" containing the 15 preprogrammed colors
        long  rgb#orange            'e.g. red can be referenced by calling Colors[0]
        long  rgb#salmon
        long  rgb#yellow
        long  rgb#chartreuse
        long  rgb#green
        long  rgb#lime
        long  rgb#aquamarine
        long  rgb#cyan
        long  rgb#blue
        long  rgb#violet
        long  rgb#magenta
        long  rgb#red              'Array called "Colors" containing the 15 preprogrammed colors
        long  rgb#orange            'e.g. red can be referenced by calling Colors[0]
        long  rgb#salmon
        long  rgb#yellow
        long  rgb#chartreuse
        long  rgb#green
        long  rgb#lime
        long  rgb#aquamarine
        long  rgb#cyan
        long  rgb#blue
        long  rgb#violet
        long  rgb#magenta

       
Rainbow long rgb#red
        long rgb#orange
        long rgb#yellow
        long rgb#green
        long rgb#blue
        long rgb#indigo
        long rgb#violet
        
RStart  word 0,32,56,72,84       'array of Start adddresses for each ring
REnd    word 31,55,71,83,91      'array of End adddresses for each ring
RLen    word 32,24,16,12,8       'array of LED length for each ring

PUB Main

  pst.start


  
  coginit(6, Lights, @Stack7)
  'rgb.start(LEDPin, TotalLEDs)
  'rgb.alloff
  LEDMode:= RotateLED
  'LEDMode:=Lightshow
  HourRing:=2
  MinuteRing:=7
  repeat
    pst.str(string("Choose light mode. 1 for 2:15, 2 for LIGHSHOW: "))
    choice:=pst.getDec
    case choice
      1 :
        LEDMode:=ArmRotateLED
      2 :
        LEDMode:=Lightshow
    pst.ClearHome 

PUB Lights ' *** COG 6 *** Controls which LED scence is playing based on global variable LEDMode

  dira[LEDPin]~~  
  rgb.start(LEDPin,TotalLEDs)                       'Start the RGB driver on with output on Pin 0
   
  waitcnt(clkfreq+cnt)                              ' Wait for a second
  rgb.AllOff
                      
  repeat
   rgb.AllOff     
     case LEDMode
        ArmRotateLED:
          rgb.AllOff
          'ClockLED
          TieDye
          'RainbowMinuteHG
          waitcnt(clkfreq/2+cnt)
          
        ExtendLED:
          rgb.AllOff
          
        RotateLED:
          rgb.AllOff
          
        DrainLED:
          rgb.AllOff
          'Rotary_Sweep(DecimalMinute/5)
          waitcnt(clkfreq/2+cnt) 
          rgb.AllOff
                
        LEDHome:        
           'RainbowMotion
           waitcnt(clkfreq/2+cnt)
           rgb.alloff

        Lightshow:                                      ' This is the old lightshow code from the EEPROM
          IndivRainbow
          rgb.AllOff
          'waitcnt(clkfreq+cnt)
          SolidColorPass
          waitcnt(clkfreq+cnt)
          rgb.AllOff  
          'Rotary_Sweep                          
          'rgb.AllOff
          'waitcnt(clkfreq/2+cnt)  
          'RainbowMotion
          'waitcnt(clkfreq/2+cnt)    

PUB TieDye | x,i,j,k,FR,EntryMode,Inten

  EntryMode:=LEDMode
  'j:=3
  'k:=0
  FR:=10
  Inten:=35

  repeat 10
    repeat i from 0 to 11
      repeat j from 0 to 11
        rgb.SetSection(R1Start+92*j,R1End+92*j,rgb.Intensity(Colors[i+j],Inten))
        rgb.SetSection(R2Start+92*j,R2End+92*j,rgb.Intensity(Colors[i+1+j],Inten))
        rgb.SetSection(R3Start+92*j,R3End+92*j,rgb.Intensity(Colors[i+2+j],Inten))
        rgb.SetSection(R4Start+92*j,R4End+92*j,rgb.Intensity(Colors[i+3+j],Inten))
        rgb.SetSection(R5Start+92*j,R5End+92*j,rgb.Intensity(Colors[i+4+j],Inten)) 
      waitcnt(clkfreq/FR+cnt)
   
   
PUB RainbowMinuteHG | i, j, k, a,b,c, q, VarColor,VarColorFast, VarColorShifted,FadeRate, EntryMode, descend

  if MinuteRing == 12      'Make 12 0 because 12 is 0th position in ring array
    MinuteRing:= 0
   
  if HourRing == 12      'Make 12 0 because 12 is 0th position in ring array
    HourRing:= 0

  HourRing:=3
  MinuteRing:=7    
  EntryMode:=LEDMode
  FadeRate:=30
  q:=0
  repeat k from 0 to 80
   
    VarColor:= k                    
    VarColorShifted:=k<<16  
      if q => 91
        descend:=True 
      if q=< 0
        descend := False
   
      if descend == True
        q--
      else
        q++  
   
      if HourRing == 0
       rgb.SetSection(5, R5End+92*11, VarColor)
      else
        'rgb.SetAllColors(VarColor)
        rgb.SetAllColors(rgb#off)      

      rgb.SetSection(R1Start+92*HourRing, R5End+92*(HourRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing
      rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), rgb#off)      
      rgb.SetSection(R1Start+92*MinuteRing, ((q+92)//92)+(MinuteRing*92), VarColorShifted)  

      waitcnt(clkfreq/FadeRate+cnt)
      if LEDMode<>EntryMode
         quit      
  repeat until LEDMode <> EntryMode 
    repeat j from 0 to 80  
      VarColor:=j<<8 + k
      VarColorFast:= b<<8 + a
      VarColorShifted:=  k<<16 + j 
      if q => 91
        descend:=True 
      if q=< 0
        descend := False
      if descend == True
        q--
      else
        q++  
   
      if HourRing == 0
       rgb.SetSection(5, R5End+92*11, VarColor)
      else
        'rgb.SetAllColors(VarColor)
        rgb.SetAllColors(rgb#off)      
 

      rgb.SetSection(R1Start+92*HourRing, R5End+92*(HourRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing           
      rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), rgb#off) 
      rgb.SetSection(R1Start+92*MinuteRing, ((q+92)//92)+(MinuteRing*92), VarColorShifted)      

      waitcnt(clkfreq/FadeRate+cnt)
      if LEDMode<>EntryMode
         quit   
      k-=1
   
    repeat i from 0 to 80   
      VarColor:= i<<16 + j<<8 + k
      VarColorShifted:= k<<16 +i<<8 + j   
      j-=1      
      if q => 91
        descend:=True 
      if q=< 0
        descend := False   
      if descend == True
        q--
      else
        q++  
   
      if HourRing == 0
       rgb.SetSection(5, R5End+92*11, VarColor)
      else
        'rgb.SetAllColors(VarColor)
        rgb.SetAllColors(rgb#off)      
 

      rgb.SetSection(R1Start+92*HourRing, R5End+92*(HourRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing                    
      rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), rgb#off)     
      rgb.SetSection(R1Start+92*MinuteRing, ((q+92)//92)+(MinuteRing*92), VarColorShifted)  

      if LEDMode<>EntryMode
         quit 
      waitcnt(clkfreq/FadeRate+cnt)
      
    repeat k from 0 to 80
   
      VarColor:= i<<16 + j<<8 + k
      VarColorShifted:=k<<16 + i<<8 + j    
      i-=1   
      if q => 91
        descend:=True 
      if q=< 0
        descend := False   
      if descend == True                                         
        q--
      else
        q++   
      if HourRing == 0
       rgb.SetSection(5, R5End+92*11, VarColor)
      else
        'rgb.SetAllColors(VarColor)
        rgb.SetAllColors(rgb#off)      
  

      rgb.SetSection(R1Start+92*HourRing, R5End+92*(HourRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing                            
      rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), rgb#off)       
      rgb.SetSection(R1Start+92*MinuteRing, ((q+92)//92)+(MinuteRing*92), VarColorShifted)       
   
      if LEDMode<>EntryMode
         quit    
      waitcnt(clkfreq/FadeRate+cnt)
   
Pub Rotary_Sweep | i, j, k, Speed ' *** Sub-method for the Rotary sweep motion; used in the lightshow mode
   
      Speed:=1500                    'Time per LED step. 1 = 1 second
        repeat j from 0 to 5
          repeat i from 0 to 92
            repeat k from 0 to 11
             rgb.SetSection(R1Start+k*92, i+k*92, Int(Colors[j+k]))
             waitcnt(clkfreq/Speed+cnt)
        rgb.AllOff

Pub SolidColorPass | k,j,i, EntryMode ' *** Sub-method for the Solid Color Pass; used in the lightshow mode

  repeat 5
    repeat k from 0 to 11 
      rgb.SetSection(R1Start+k*92,R5End+k*92, Int(Colors[k]))                        
      waitcnt(clkfreq/10+cnt)
      
    repeat k from 0 to 11 
      rgb.SetSection(R1Start+k*92,R5End+k*92, Int(0) )
      waitcnt(clkfreq/10+cnt)
    rgb.AllOff      
   
    waitcnt(clkfreq/10+cnt)

PUB ColorHandoff | i,j,k,w

    repeat j from 0 to 3
      repeat k from 0 to 11
        rgb.SetSection(R1Start+k*92,R5End+k*92, Int(Colors[k+j]))                        
        waitcnt(clkfreq/10+cnt)
      'rgb.AllOff
       

PUB Holiday(Color1, Color2)



PUB IndivRainbow | i,j,k,Disk

  'j:=0
  repeat 15
    repeat j from 0 to 11
      repeat Disk from 0 to 11
        repeat i from 0 to 31
          rgb.LED(i+(Disk*92),rgb.Intensity(Colors[(i/3)+j],100))
          {j++
          if j > 12
            j:=0}
  repeat k from 0 to 11 
    rgb.SetSection(R1Start+k*92,R5End+k*92, Int(0) )
    waitcnt(clkfreq/10+cnt)
  rgb.AllOff  
  rgb.AllOff
  waitcnt(clkfreq/2+cnt)

       
PUB RainbowMotion | i, j, k, VarColor, Ringi, Ringj, Ringk,FadeRate ' *** Sub-method for Rainbow Motion; used in the lightshow mode

FadeRate:=20 
repeat k from 0 to 80
  VarColor:= k   
  rgb.SetSection(0,TotalLEDs-1, VarColor)
  waitcnt(clkfreq/FadeRate+cnt)
    
repeat 3
  repeat j from 0 to 80 
    VarColor:=j<<8 + k 
    rgb.SetSection(0,TotalLEDs-1, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)
    k-=1
    
  repeat i from 0 to 80
    VarColor:= i<<16 + j<<8 + k   
    j-=1
    rgb.SetSection(0,TotalLEDs-1, VarColor) 
    waitcnt(clkfreq/FadeRate+cnt)
    
  Ringi++
  Ringj++
  Ringk++
     
  repeat k from 0 to 80
    VarColor:= i<<16 + j<<8 + k   
    i-=1 
    rgb.SetSection(0,TotalLEDs-1, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)

PUB Int(color) : IntColor ' *** Sub-sub-method for int; called by the LED sub-methods to set intesity

  IntColor:= rgb.Intensity(color, MaxInt)          'Wrapper function to quickly set a max intensity value across board