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
  EncAmount = 1 
   'ArmZero = 0                       'Sets Arm Zero position 
 '******************MOTOR CONSTANTS******************
  EPWMPin    = 26                     'PWM signal sent out to H-bridge chip to control motor's speed  
  EDir       = 27                     'Directional control pin 1=CW 0=CCW (when facing the motor)
                  
  HPWMPin    = 24                     'Hourglass rotation PWM control     'Pin 10 was blown
  HDir       = 25                     'Hourglass rotation direction
                  
  ArmPWMPin  = 22  
  ArmDir     = 23  
                  
  BackLimit  = 13                     'Limit Switch pin. Restricts retraction
  FrontLimit = 14                     'Limit Switch pin. Restricts extension

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
  long Stack1[400], Stack2[400], Stack3[400], Stack4[100], Stack5[100], Stack6[400], Stack7[100]

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

  byte exit
  long target, CH, k,j
    
OBJ
  pst : "PST_Driver"
  rgb : "WS2812B_RGB_LED_Driver"
  lcd : "serial_LCD"
  
DAT
'**Encoder Values for all clock values (12 is included on both ends for redundancy)
ArmAbsPosition long  1023, 940, 858, 773, 694, 609, 523, 432, 343, 252, 172, 45, 1023         

'**LEDS
Colors  long  rgb#red              'Array called "Colors" containing the 15 preprogrammed colors
        long  rgb#green            'e.g. red can be referenced by calling Colors[0]
        long  rgb#blue
        long  rgb#white
        long  rgb#cyan
        long  rgb#magenta
        long  rgb#yellow
        long  rgb#chartreuse 
        long  rgb#orange
        long  rgb#aquamarine
        long  rgb#pink 
        long  rgb#turquoise
        long  rgb#realwhite
        long  rgb#indigo
        long  rgb#violet
       
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

  dira[EPWMpin..EDir]~~                 'Set directions of PWMpin and Dir pins of all 3 motors to outputs
  dira[ArmPWMpin..ArmDir]~~             'Set directions of PWMpin and Dir pins of all 3 motors to outputs
  dira[FrontLimit]~                     'Set Limit switch pins as inputs
  dira[BackLimit]~
  dira[HPWMpin]~~
  dira[HDir]~~ 

  ArmDutyCycle~
  EDutyCycle~
  pst.start
  coginit(3,Encoder,@Stack3)
  coginit(2,PWM(EPWMPin, ArmPWMPin),@Stack2)

  {repeat
    pst.str(string("Arm Position; "))
    pst.dec(ArmPositionData)
    waitcnt(clkfreq/10+cnt)
    pst.ClearHome}

  pst.str(string("Enter target hour (1-12): "))
  target:=pst.getDec
  ArmRotate(target,ArmPositionData,1)
  CH:=target
  
  repeat
    pst.str(string("Enter target hour (1-12): "))
    target:=pst.getDec
    ArmRotate(target,CH,0)
    CH:=target
    pst.ClearHome 

  {ArmRotate(1,ArmPositionData,1)
  repeat j from 1 to 12
    repeat k from 1 to 12
      ArmRotate(k,j,0)
      pst.str(string("Arrived at "))
      pst.dec(k)
      pst.str(string(" from "))
      pst.dec(j)
      waitcnt(clkfreq+cnt)
      ArmRotate(j,k,0)
      pst.NewLine
      pst.str(string("Arrived back at "))
      pst.dec(j)
      pst.str(string(" from "))
      pst.dec(k)
      waitcnt(clkfreq+cnt)
      pst.ClearHome}
         
    
PUB ArmRotate(TargetHour, CurrentHour, Flag) | CurrentHourPosition, TargetHourPosition, ArmCase, Clockwise, PositionDifference ' *** Rotates the arm given current/taget positions

  Clockwise:=False

  if TargetHour == 0
    TargetHour:=12
  if CurrentHour == 0
    CurrentHour:=12 

  if Flag == 0                                          ' Flag 0 means that both inputs are hour numbers 0-12
    CurrentHourPosition:=ArmAbsPosition[CurrentHour]      ' Retrieve encoder pos for target and current hour
    TargetHourPosition:=ArmAbsPosition[TargetHour]
  elseif Flag == 1                                      ' Flag 1 means that an encoder position has been passed in 0-1023
    CurrentHourPosition:=CurrentHour                    
    TargetHourPosition:=ArmAbsPosition[TargetHour]

  PositionDifference:=TargetHourPosition-CurrentHourPosition

  if ||(PositionDifference) < 512
    if PositionDifference > 0                           ' 0 < PD < 512
      Clockwise:=False
      ArmCase:=1
    else                                                ' -512 < PD < 0
      Clockwise:=True
      ArmCase:=2
    
  else
    if PositionDifference > 0                           ' 512 < PD < 1023
      Clockwise:=True
      ArmCase:=3
    else                                                ' -1023 < PD < -512
      Clockwise:=False
      ArmCase:=4            

  ArmTarget:=TargetHourPosition         
  ArmPosition:= ArmPositionData

  if TargetHour == 12
    if Clockwise == True
      ArmCase:=5
    else
      ArmCase:=6  

  if Clockwise == True                                  ' Might be able to just do this
    outa[ArmDir]~~
  else
    outa[ArmDir]~
  
  case ArmCase
    1 :                                                 ' CCW and no CZ
      repeat until ||(ArmTarget-ArmPosition) =< 40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome
      repeat until ArmTarget =< ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
            

    2 :                                                 ' CW and no CZ
      repeat until ||(ArmTarget-ArmPosition) =< 40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome            
      repeat until ArmTarget => ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      
    3 :                                                 ' CW and CZ
      repeat until ArmPosition => 1018                  
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome              
      repeat until ||(ArmTarget-ArmPosition) =< 40      
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome              
      repeat until ArmTarget => ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
          
      
    4 :                                                 ' CCW and CZ
      repeat until ArmPosition =< 5
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      repeat until ||(ArmTarget-ArmPosition) =<40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      repeat until ArmTarget =< ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      
    5 :                                                 ' CW and CZ to 12
      repeat until ArmPosition =< 40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      repeat until ArmPosition >= 1018
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      
    6 :                                                 ' CCW and CZ to 12
      repeat until ArmPosition => 983
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        
      repeat until ArmPosition =< 5
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
        pst.dec(ArmPositionData)
        waitcnt(clkfreq/10+cnt)
        pst.ClearHome        
        

  ArmDutyCycle~                                         ' Turn off arm motor
 
PUB Encoder | Data, i, PosFix ' *** COG 4 *** Reads encoder data and produces an array of all the values 

  dira[ArmCLK]~~
  dira[ArmCS]~~  
  dira[ArmSI]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs
  Data:=0 
   
   
  repeat
    outa[ArmCS]~~
    outa[ArmCS]~
    outa[ArmCLK]~~
    outa[ArmCLK]~                                        
    'repeat i from 0 to (EncAmount-1)
      Data:=0
      repeat 16
         outa[ArmCLK]~~                    'Shift through the first 16 bits of data
         Data:=(Data <<1)+ina[ArmSI]       'Get position data from 16-bit Encoder value, starting with MSB                   
         outa[ArmCLK]~  
      PosFix:= Data >> 6                'Shift 6 bits to right to only use upper 10 position bits
       
      'HGPositionData[i]:=PosFix         'Append position array with the current encoder being updated 
      'outa[ArmCLK]~~                       'Intermediate clock pulse to signify end of first encoder's position
      'outa[ArmCLK]~
    ArmPositionData := Posfix ' ****** THIS IS PROBABLY WRONG; DEPENDS WHERE IN THE CHAIN THE ARM ENC IS, IF AT ALL *******
    outa[ArmCS]~~
    outa[ArmCLK]~~

PUB PWM(pin1, pin2) | endcnt ' *** COG 2 *** Controls the speed of the arm and extension motors dictated by the global duty cycle variables
'This method creates a 10kHz PWM signal (duty cycle is set by the DutyCycleVariables) clock must be 100MHz                            
  dira[pin1]~~
  dira[pin2]~~                   'Set the direction of "pin" to be an output for this cog 
  ctra[5..0]:=pin1               'Set the "A pin" of this cog's "A Counter" to be "pin"
  ctra[30..26]:=%00100          'Set this cog's "A Counter" to run in single-ended NCO/PWM mode
                                ' (where frqa always acccumulates to phsa and the Apin output state is bit 31 of the phsa value)                              
  ctrb[5..0]:=pin2               'Set the B pin of this cog's B Counter to be "pin2"
  ctrb[30..26]:=%00100          'Set this cog's B Counter" to run in single-ended NCO/PWM mode
                                                                            
  frqa:=1                       'Set counter's frqa value to 1 (1 is added to phsa at each clock) 
  frqb:=1
  endcnt:=cnt                   'Store the current system counter's value as "endcnt"
                                  
  repeat                        'Repeat the following lines forever
    phsa:=-(100*EDutyCycle)      'Send a high pulse for specified number of microseconds ** 10 nanoseconds*100 = 1 microsecond
    phsb:=-(100*ArmDutyCycle)      'Send a high pulse for specified number of microseconds
    endcnt:=endcnt+10_000       'Calculate the system counter's value after 100 microseconds
    waitcnt(endcnt)             'Wait until 100 microseconds have elapsed
      