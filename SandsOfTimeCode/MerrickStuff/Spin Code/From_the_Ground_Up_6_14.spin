CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

 '******************ENCODER CONSTANTS******************
  CS  = 4             'Encoder activation on Pin 4   - Encoder 6 
  SI1  = 6             'Encoder Output on Pin 6       - Encoder 4
  'SI2 = 17
  'SI3 = 18
  CLK = 5             'Encoder CLK on Pin 5          - Encoder 2

  ArmCS  = 9             'Encoder activation on Pin 7   - Encoder 6 
  ArmSI  = 8             'Encoder Output on Pin 8       - Encoder 4
  ArmCLK = 7             'Encoder CLK on Pin 5          - Encoder 2     
  EncAmount = 4
  PodNum = 3
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
  NightLED     = 2
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
  Click    = %11101   
  Up       = %11110 
  NoInput  = %11111

  {
  LeftPin  = 19
  DownPin  = 20
  RightPin = 21

  Left     = %011
  Down     = %101
  Right    = %110
  }
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
  long Stack1[600], Stack2[600], Stack3[600], Stack4[400], Stack5[400], Stack6[600], Stack7[400]

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
  byte DecimalSecond, DecimalMinute, DecimalHour, DecimalDate, DecimalMonth, DecimalYear, DecimalHalf, DecimalDay
  long SecondInput, MinuteInput, HourInput, HourSet, MinuteSet, HalfInput, DateInput, DayInput, MonthInput, YearInput   
  byte time[7], timeset[7]
     
  '***********************INTERFACE VARIABLES************     
  long LCDMode, LCDText, LCDDecInput, LCDPause, ClockSet, SettingTime
  long ValueBeingSet, PauseHour, PauseMinute, PauseSecond, PauseHalf
  byte JoyStickInput

  byte w
    
OBJ
  pst : "PST_Driver"
  rgb : "WS2812B_RGB_LED_Driver"
  lcd : "serial_LCD"
  
DAT
'**Encoder Values for all clock values (12 is included on both ends for redundancy)
' ArmAbsPosition long  1023, 942, 858, 773, 694, 609, 523, 432, 343, 252, 172, 87, 1023 ' Old values w/ Jackson        
ArmAbsPosition long  1022, 940, 856, 770, 687, 597, 512, 432, 337, 252, 172, 87, 1022

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

PUB Main | Lit, CurrentHourPosition, AlreadySet, j ' *** Main code loop, uses global variables that are changed by external cogs

' *** Set up pin directions
  dira[EPWMpin..EDir]~~                 'Set directions of PWMpin and Dir pins of all 3 motors to outputs
  dira[ArmPWMpin..ArmDir]~~             'Set directions of PWMpin and Dir pins of all 3 motors to outputs
  dira[HPWMpin]~~
  dira[HDir]~~                     
  dira[FrontLimit]~                     'Set Limit switch pins as inputs
  dira[BackLimit]~
  'dira[LEDPin]~~
  
' *** Boot up external cogs 
  'pst.start                                             ' ************** COG DETAILS ****************
  coginit(2,PWM(EPWMPin, ArmPWMPin),@Stack2)            ' Cog 0   -   Main Code
  'coginit(4, Encoder, @Stack4)                          ' Cog 1   -   TEMP - PST
  coginit(6, Lights, @Stack6)                           ' Cog 2   -   PWM of Extension and Arm motors
  coginit(7, Clock, @Stack7)                            ' Cog 3   -   could put LCD here if I get there
  coginit(5, ArmEncoder, @Stack5)                       ' Cog 4   -   Encoders 
  coginit(3, LCDInterface, @Stack3)                     ' Cog 5   -   Arm Encoder        
                                                        ' Cog 6   -   Lights 
                                                        ' Cog 7   -   Clock
  waitcnt(clkfreq+cnt) 
    
' *** Initialize Variables
  CurrentHourNumber:=DecimalHour
  CurrentHourPosition:=ArmAbsPosition[CurrentHourNumber]                        ' Target encoder position based on time (0-1023)
  MinuteHG:=DecimalMinute/5
  MinuteRing:=MinuteHG                                                          ' MinuteRing triggers the minute LED disk
  HourRing:=CurrentHourNumber                                                   ' HourRIng triggers the hour LED disk
  LCDPause:=True
  CanArmRotate:=True

' *** Start LEDs 
  LEDMode := ArmRotateLED                               ' Regular LED mode where the hour and minute HG are different colors
  
' *** Reset Arm
  waitcnt(clkfreq*2+cnt)
  ResetExtension                                        ' Makes sure that the arm is retracted before it trys to turn

' *** Determine if Arm is already set
  if CurrentHourNumber == 12                                                    ' Determine if 12 o'clock case is necessary
    if (ArmPositionData > 8) or (ArmPositionData < 1018)                        ' Is current pos within range of target?
      AlreadySet:=False
    else
      AlreadySet:=True 
  else                                                                          ' If it's not 12 o'clock
    if (||(CurrentHourPosition - ArmPositionData) > 5) and (||(CurrentHourPosition - ArmPositionData) < 1018)
      AlreadySet:=False                                                         ' Set false if current pos is not within range  
    else
      AlreadySet:=True                                                          ' Set true if within range
  waitcnt(clkfreq/2+cnt)                                                        

  if AlreadySet == False                                                        ' If we need to move
    CurrentHourNumber:=DecimalHour
    ArmRotate(CurrentHourNumber, ArmPositionData,1)                             ' Rotate to target if not in range
    waitcnt(clkfreq/10+cnt)
  waitcnt(clkfreq*2+cnt)

  LCDPause:=False
' *** MAIN CLOCK LOOP          
  repeat                                                                        
    repeat until ((DecimalMinute//5) <> 0) and (CanArmRotate==True)             ' Get stuck here until the 5-minute multiple minute (5,10,etc.) has passed (i.e becomes 6,11,etc.)
      LEDMode:=ArmRotateLED
    repeat until (DecimalMinute//5) == 0 and (CanArmRotate==True)               ' Get stuck here until a five-minute cycle has started
      LEDMode:=ArmRotateLED
    LCDPause:=True
    MinuteHG:=DecimalMinute/5                                                   ' Retrieve which HG we have to rotate to 
    DecideLEDMode
    ArmRotate(MinuteHG, CurrentHourNumber,0)                                    ' Rotate from the current hour to the needed minute
    Extension                                                                   ' Extend the arm, rotate the HG
    ResetExtension                                                              ' Retract the arm
    ResetExtension                                                              ' Redundancy to ensure that we retract (had issues)
    CurrentHourNumber:=DecimalHour                                              ' Get new hour number, which could have changed since the last cycle 6:55-7:00
    if CurrentHourNumber == 12
      HourRing:=0
    else
      HourRing:=CurrentHourNumber
    ArmRotate(CurrentHourNumber,MinuteHG,0)                                     ' Rotate back to new hour position
    LCDPause:=False
    LEDMode:=ArmRotateLED 
    
      
DAT '*** Encoder reading method(s)
{PUB Encoder | Data_1_4, Data_5_8, Data_9_12, i, PosFix1, PosFix2, PosFix3 ' *** Reads HG encoder data and produces an array of values
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
      HGPositionData[i]:=PosFix1         'Append position array with the current encoder being updated
      HGPositionData[i+(1*EncAmount)]:=PosFix2               ' Appends data to index 5,6,7,8
      HGPositionData[i+(2*EncAmount)]:=PosFix3               ' Appends data to index 9,10,11,12
      outa[CLK]~~                  'Intermediate clock pulse to signify end of first encoder's position
      outa[CLK]~
  HGPositionData[0]:=HGPositionData[12]                     ' Makes sure that there is no confusion on the 12 or 0 indexing
  outa[CS]~~
  outa[CLK]~~
  waitcnt(clkfreq/10+cnt)
}
PUB ArmEncoder | Data, i, PosFix ' *** COG 5 *** Reads arm encoder data  

  dira[ArmCLK]~~
  dira[ArmCS]~~  
  dira[ArmSI]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs
  Data:=0 

  repeat
    outa[ArmCS]~~
    outa[ArmCS]~
    outa[ArmCLK]~~
    outa[ArmCLK]~                                        
      Data:=0
      repeat 16
         outa[ArmCLK]~~                    'Shift through the first 16 bits of data
         Data:=(Data <<1)+ina[ArmSI]       'Get position data from 16-bit Encoder value, starting with MSB                   
         outa[ArmCLK]~  
      PosFix:= Data >> 6                'Shift 6 bits to right to only use upper 10 position bits

    ArmPositionData := Posfix 
    outa[ArmCS]~~
    outa[ArmCLK]~~ 
   
DAT '*** Start of motor movement methods
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
      repeat until ArmTarget =< ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData     

    2 :                                                 ' CW and no CZ
      repeat until ||(ArmTarget-ArmPosition) =< 40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ArmTarget => ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
      
    3 :                                                 ' CW and CZ
      repeat until ArmPosition => 1018                  
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ||(ArmTarget-ArmPosition) =< 40      
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ArmTarget => ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData  
      
    4 :                                                 ' CCW and CZ
      repeat until ArmPosition =< 5
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ||(ArmTarget-ArmPosition) =<40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ArmTarget < ArmPosition
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
      
    5 :                                                 ' CW and CZ to 12
      repeat until ArmPosition =< 40
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ArmPosition >= 1018
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData
      
    6 :                                                 ' CCW and CZ to 12
      repeat until ArmPosition => 983
        ArmDutyCycle:=100
        ArmPosition:=ArmPositionData
      repeat until ArmPosition =< 5
        ArmDutyCycle:=40
        ArmPosition:=ArmPositionData

  ArmDutyCycle~                                         ' Turn off arm motor

PUB Extension | ArmSetPoint, HGCase, Startcnt ' *** Extends the arm and flips the HG, also makes sure that the arm doesn't stray away from HG

  ArmSetPoint:=ArmPositionData

  outa[EDir]~~
  EDutyCycle:=70

  HGPosition:=HGPositionData[MinuteHG]            ' *** Again, need to check on the indexing

  repeat until ina[FrontLimit] == 1
    outa[HDir]~~                                        ' Set direction and duty cycle for HG rotating motor so it will mesh upon contact
    outa[HPWMPin]~~

  MinuteRing:=MinuteHG                                  ' Changes the minute spotlight to the new disk
  EDutyCycle~                                           ' Stop extending
  waitcnt(clkfreq*3+cnt)
  {if HGPosition => 400 and HGPosition < 600            ' If HG is at about 512
    HGCase:=1
  else
    HGCase:=2    

  MinuteHG:=DecimalMinute/5
  case HGCase
    1:                                                  ' Going from 512 to 0
      repeat until HGPosition > 1018 or HGPosition < 5  ' Go until HG gets to ~0
        HGPosition:=HGPositionData[MinuteHG]            ' *** Again, need to check on the indexing
          if ArmSetPoint > 1013 or ArmSetpoint < 10       ' Special case for 12 o'clock 
            if ArmPositionData < 1013 and ArmPositionData > 900                   ' Arm is tending towards 1 o'clock
              outa[ArmDir]~~
              ArmDutyCycle:=30
            elseif ArmPositionData > 10 and ArmPositionData < 150                 ' Arm is tending towards 11 o'clock
              outa[ArmDir]~
              ArmDutyCycle:=30
            else
              ArmDutyCycle~
             
          else
            if ||(ArmPositionData - ArmSetPoint) > 10     ' If the arm is starting to get pushed away from the HG we turn on the motor to fight back
              if ArmPositionData > ArmSetPoint
                outa[ArmDir]~~
              else
                outa[ArmDir]~
              ArmDutyCycle:=30   
            else
              ArmDutyCycle~                                 ' Turn arm rotation off if within the allowable range 

    2:                                                  ' Going from 0 to 512
      repeat until HGPosition < 517 and HGPosition > 507
        HGPosition:=HGPositionData[MinuteHG]            ' *** Again, need to check on the indexing
        if ArmSetPoint > 1013 or ArmSetpoint < 10       ' Special case for 12 o'clock 
          if ArmPositionData < 1013 and ArmPositionData > 900                   ' Arm is tending towards 1 o'clock
            outa[ArmDir]~~
            ArmDutyCycle:=30
          elseif ArmPositionData > 10 and ArmPositionData < 150                 ' Arm is tending towards 11 o'clock
            outa[ArmDir]~
            ArmDutyCycle:=30
          else
            ArmDutyCycle~
           
        else
          if ||(ArmPositionData - ArmSetPoint) > 10     ' If the arm is starting to get pushed away from the HG we turn on the motor to fight back
            if ArmPositionData > ArmSetPoint
              outa[ArmDir]~~
            else
              outa[ArmDir]~
            ArmDutyCycle:=30   
          else
            ArmDutyCycle~                                 ' Turn arm rotation off if within the allowable range  }

  outa[HPWMPin]~
  ArmDutyCycle~
  
PUB ResetExtension ' *** Retracts arm, simple

  outa[EDir]~                                           ' ~~ is extend

  repeat until ina[BackLimit] == 1
      EDutyCycle := 100                                 ' Triggers the PWM cog to move extension motor

  EDutyCycle~
    
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

DAT '*** Start of RTC Clock Methods    
PUB Clock ' *** COG 7 *** Constantly updates the time variables from RTC

  dira[CCS]~~  
  dira[CSI]~   
  dira[CSO]~~  
  dira[CCLK]~~
  outa[CCS]~~

  GetTime
  'DecTime
  SettingTime:=False
  repeat
    repeat' until SettingTime:=True
      DecTime
      GetTime
      waitcnt(clkfreq/4+cnt)
      if SettingTime == True
        quit
    DecSetTime
     
PUB DecTime ' *** Converts the binary retrieved from RTC into usable decimal time units (hour, minute, seconds, day, year, etc.)

  DecimalSecond:= 10*((time[0] & %111_0000)>>4) + (time[0] & %1111)     'Adds tens to ones place to get a single decimal number
                                                                         '11:50:59 --> 10*5 + 9 = 59
   
  DecimalMinute:= 10*((time[1] & %111_0000)>>4) + (time[1] & %1111)     'Adds tens to ones place to get a single decimal number
                                                                         '11:50:59 --> 10*5 + 0 = 50
                                                                         
  DecimalHour:= 10*((time[2] & %1_0000)>>4) + (time[2] & %1111)        'Adds tens to ones place to get a single decimal number
                                                                         '11:50:59 --> 10*1 + 1 = 11                                                                       
   
  DecimalDate:= 10*((time[4] & %11_0000)>>4) + (time[4] & %1111)        'Adds tens to ones place to get a single decimal number
                                                                         '01/31/19 --> 10*3 + 1 = 31
                                                                         
  DecimalMonth:= 10*((time[5] & %1_0000)>>4) + (time[5] & %1111)       'Adds tens to  ones place to get a single decimal number
                                                                         '01/31/19 --> 10*0 + 1 = 01                                                                      
   
  DecimalYear:= 10*((time[6] & %1111_0000)>>4) + (time[6] & %1111)        'Adds tens to ones place to get a single decimal number (Last two digits only)
                                                                         '01/31/19 --> 10*1 + 9 = 19
  if time[2] & %10_0000 == 10_0000
    DecimalHalf:=1
  else
    DecimalHalf:=0

  DecimalDay:=time[3]

PUB GetTime  | i ' *** Retrieves raw binary data from RTC

  outa[CCS]~
  repeat 8        'Set starting address to be $00=seconds
    outa[CCLK]~~
    outa[CSO]:=0
    outa[CCLK]~
  repeat i from 0 to 6
    repeat 8
      outa[CCLK]~~ 
      time[i]:=time[i]<<1+ina[CSI]
      outa[CCLK]~  
  outa[CCS]~~

{PUB DisplayTime | j

  
  pst.ClearHome
  pst.str(string("The time is: "))
  pst.dec(DecimalHour)
  pst.str(string(":"))
  if DecimalMinute < 10
    pst.str(string("0"))
  pst.dec(DecimalMinute)
  pst.str(string(":"))
  if DecimalSecond < 10
    pst.str(string("0"))
  pst.dec(DecimalSecond)
  if (time[2] & %10_0000)==%10_0000
    pst.str(string("PM"))       'hours tens place
  else
    pst.str(string("AM"))
  pst.NewLine
  pst.str(string("The date is: "))
  case time[3]
    0:pst.str(string("Sun"))
    1:pst.str(string("Mon"))
    2:pst.str(string("Tues"))
    3:pst.str(string("Wed"))
    4:pst.str(string("Thurs"))
    5:pst.str(string("Fri"))
    6:pst.str(string("Sat"))
  pst.str(string(" "))
  pst.dec(DecimalMonth)
  pst.str(string("/"))
  pst.dec(DecimalDate)
  pst.str(string("/"))
  pst.dec(DecimalYear)
  {pst.NewLine
  pst.str(string("Current positions:"))
  pst.NewLine 
    repeat j from 1 to (EncAmount*PodNum)
      pst.str(string("Position "))
      pst.dec(j)
      pst.str(string(": "))
      pst.dec(HGPositionData[j])
      pst.NewLine }

    'waitcnt(clkfreq/10+cnt)
    'pst.ClearHome     
 }
PUB SetTime  | i,j
  outa[CCS]~
  repeat i from 7 to 0      'Set starting address to be $80=seconds
    outa[CCLK]~~
    outa[CSO]:=$80>>i & 1
    outa[CCLK]~
  repeat i from 0 to 6
    repeat j from 7 to 0
      outa[CCLK]~~ 
      outa[CSO]:=timeset[i]>>j & 1
      outa[CCLK]~  
  outa[CCS]~~

PUB DecSetTime |  SetSecondTens, SetSecondOnes, SetMinuteTens, SetMinuteOnes, SetHourTens, SetHourOnes, SetPM, SetDateTens, SetDateOnes, SetMonthTens, SetMonthOnes, SetYearTens, SetYearOnes 
  
  waitcnt(clkfreq/2+cnt)
  SetSecondTens:=SecondInput/10                                        
  SetSecondOnes:=SecondInput-10*SetSecondTens
  SetMinuteTens:=MinuteInput/10                                        
  SetMinuteOnes:=MinuteInput-10*SetMinuteTens
  SetHourTens:=HourInput/10                                            
  SetHourOnes:=HourInput-10*SetHourTens
  {if HalfInput == %10_0000 
    SetPM:=1
  else
    SetPM:=0 }
  SetDateTens:=DateInput/10
  SetDateOnes:=DateInput-10*SetDateTens                                                      
  SetMonthTens:=MonthInput/10
  SetMonthOnes:=MonthInput-10*SetMonthTens
  SetYearTens:=YearInput/10
  SetYearOnes:=YearInput-10*SetYearTens 

  timeset[0]:=SetSecondTens<<4+SetSecondOnes 

  timeset[1]:=SetMinuteTens<<4+SetMinuteOnes                                 
          '12 hr   AM/PM                                                '   1/0   1/0  *10hr  hr                              
  timeset[2]:=1<<6 + HalfInput<<5 + SetHourTens<<4 + SetHourOnes

  timeset[3]:=DayInput

  timeset[4]:= SetDateTens<<4+SetDateOnes

  timeset[5]:= SetMonthTens<<4+SetMonthOnes

  timeset[6]:= SetYearTens<<4+SetYearOnes

  SetTime
  
  SettingTime:=False
  
DAT '*** Start of RGB LED methods
PUB Lights ' *** COG 6 *** Controls which LED scence is playing based on global variable LEDMode

  dira[LEDPin]~~  
  rgb.start(LEDPin,TotalLEDs)                       'Start the RGB driver on with output on Pin 0
   
  waitcnt(clkfreq+cnt)                              ' Wait for a second
  rgb.AllOff

  {repeat
    'rgb.AllOff
    SolidColorPass
    'rgb.SetAllColors(rgb.Intensity(rgb#blue,10))
    waitcnt(clkfreq+cnt)
    
  'rgb.SetSection(0,50,rgb.Intensity(rgb#blue,64))
  'SolidColorPass
  repeat
    rgb.AllOff
    rgb.SetAllColors(rgb.Intensity(rgb#blue,64))
    waitcnt(clkfreq/2+cnt) }
 
  
  repeat     
     case LEDMode
        ArmRotateLED:
          rgb.AllOff
          RainbowMinuteHG
          waitcnt(clkfreq/2+cnt)
          
        NightLED:
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
          rgb.AllOff
          SolidColorPass
          waitcnt(clkfreq/2+cnt)  
          RainbowMotion
          rgb.AllOff
          waitcnt(clkfreq/2+cnt)
          SolidColorPass

PUB DecideLEDMode ' *** Decides which LED modes to play. Will include holidays and lightshows moving forward

    if DecimalMinute <> 0                                                       ' Set LED mode here, if it is the top of the hour (i.e 12:00, 1:00, etc.) play the lightshow
        LEDMode:=ArmRotateLED                                                     ' This is the regular light code, where the minute and hour light up differently
    else
        LEDMode:=Lightshow

    'if (DecimalHour > 7 and time[2] & 10_0000 == 10_0000) or (DecimalHour < 8 and time[2] & 10_0000 == 0)
     ' LEDMode:=NightLED
            
PUB RainbowMinuteHG | i, j, k, a,b,c, q, VarColor,VarColorFast, VarColorShifted,FadeRate, EntryMode, descend

  if MinuteRing == 12      'Make 12 0 because 12 is 0th position in ring array
    MinuteRing:= 0
   
  if HourRing == 12      'Make 12 0 because 12 is 0th position in ring array
    HourRing:= 0
    
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
        'rgb.SetSection(5, R5End+92*11, VarColor)
        rgb.SetAllColors(rgb#off)      

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
        'rgb.SetSection(5, R5End+92*11, VarColor)
        rgb.SetAllColors(rgb#off)
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
        'rgb.SetSection(5, R5End+92*11, VarColor)
        rgb.SetAllColors(rgb#off)
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
        'rgb.SetSection(5, R5End+92*11, VarColor)
        rgb.SetAllColors(rgb#off)      

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
          repeat i from 0 to 91
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

DAT ' *** Start of LCD-Reset Interface methods
PUB LCDInterface

  dira[LeftPin..UpPin]~
  JoyStickInput:=ina[LeftPin..UpPin]
  
  dira[LCDPin]~~
  'LCDPause:=False                                                               ' Take this out once the main loop is running
  
  repeat
    repeat until LCDPause == False and JoystickInput == Down
      lcd.init(LCDPin, 9600, 4)
      lcd.cursor(0)
      lcd.cls
      lcd.gotoxy(0,0)
      
      lcd.str(string("The time is:"))
      lcd.gotoxy(0,1)
      if DecimalHour < 10
        lcd.str(string(" "))
      dec(DecimalHour)                                                                 
      lcd.str(string(":"))
      if DecimalMinute < 10
        lcd.str(string("0"))
      dec(DecimalMinute)                                   
      lcd.str(string(":"))
      if DecimalSecond < 10
        lcd.str(string("0"))            
      dec(DecimalSecond)
      {if DecimalHalf == 1
        lcd.str(string(" PM"))                              
      else
        lcd.str(string(" AM"))}
      if (time[2] & %10_0000)==%10_0000
        lcd.str(string(" PM"))       'hours tens place
      else
        lcd.str(string(" AM"))
         
      lcd.gotoxy(0,3)
      lcd.str(string("Push down to reset")) 
      lcd.gotoxy(4,4)
      JoyStickInput:=ina[LeftPin..UpPin]
      waitcnt(clkfreq/4+cnt)
      
      if LCDPause == True and JoystickInput == Down
        repeat until JoystickInput<>Down
          lcd.init(LCDPin, 9600, 4)
          lcd.cursor(0)
          lcd.cls 
          lcd.gotoxy(0,1)            
          lcd.str(string("Please wait until"))
          lcd.gotoxy(0,2)
          lcd.str(string("the arm is stopped")) 
          lcd.gotoxy(4,4)
          waitcnt(clkfreq/4+cnt)
          JoystickInput:=ina[LeftPin..UpPin]           
    repeat until JoystickInput <> Down
      JoyStickInput:=ina[LeftPin..UpPin]     
    CanArmRotate:=False
    repeat until JoystickInput <> NoInput
      JoyStickInput:=ina[LeftPin..UpPin] 
      lcd.init(LCDPin, 9600, 4)
      lcd.cursor(0)
      lcd.cls
      lcd.gotoxy(0,0)              
      lcd.str(string("Choose type of reset:"))
      lcd.gotoxy(0,1)
      lcd.str(string("Left-Fall Back"))
      lcd.gotoxy(0,2)
      lcd.str(string("Right-Spring Forward"))
      lcd.gotoxy(0,3)
      lcd.str(string("Down-Full Reset"))
      waitcnt(clkfreq/4+cnt)

    case JoystickInput
      Right :
        HourInput:=DecimalHour+1
        if HourInput>12
          HourInput:=1
        if DecimalHour == 11
          if time[2] & %10_0000 == 10_0000 
            HalfInput:=0          
          else
            HalfInput:=1
        else
          if time[2] & %10_0000 == 10_0000 
            HalfInput:=1          
          else
            HalfInput:=0
        MinuteInput:=DecimalMinute
        SecondInput:=DecimalSecond
        DayInput:=DecimalDay
        DateInput:=DecimalDate
        MonthInput:=DecimalMonth
        YearInput:=DecimalYear
        SettingTime:=True

        'DisplayTime
      Left :
        HourInput:=DecimalHour-1
        if HourInput<1
          HourInput:=12
        if DecimalHour == 12
          if time[2] & %10_0000 == 10_0000 
            HalfInput:=1
          else
            HalfInput:=0
        else
          if time[2] & %10_0000 == 10_0000 
            HalfInput:=0          
          else
            HalfInput:=1
        MinuteInput:=DecimalMinute
        SecondInput:=DecimalSecond
        DayInput:=DecimalDay
        DateInput:=DecimalDate
        MonthInput:=DecimalMonth
        YearInput:=DecimalYear
        SettingTime:=True

        'DisplayTime
      Down:
        ResetClockData    
    CanArmRotate:=True
    
PUB ResetClockData

  waitcnt(clkfreq/10+cnt)                               'Not sure if this is necessary
  PauseHour:=DecimalHour
  PauseMinute:=DecimalMinute
  PauseSecond:=DecimalSecond
  if time[2] & %10_0000 == %10_0000
    PauseHalf:=1
  else
    PauseHalf:=0

  lcd.cursor(2)                                         'Blinking Cursor
  lcd.cls
  lcd.gotoxy(1,0)
  if PauseHour < 10
    lcd.str(string(" "))
  dec(PauseHour)                                                                 
  lcd.str(string(":"))
  dec(PauseMinute)                                   
  lcd.str(string(":"))            
  dec(PauseSecond)
  if PauseHalf == 1
    lcd.str(string(" PM"))                              
  else
    lcd.str(string(" AM"))

  lcd.gotoxy(0,2)
  lcd.str(string("Up/Down to increment."))
  lcd.gotoxy(0,3)
  lcd.str(string("Move right to set."))

  ValueBeingSet:=0
  repeat until ClockSet == True
    case ValueBeingSet
      ValueHour:        
        PauseHour:= ResetValues(PauseHour)
              
      ValueMinute:
        PauseMinute:= ResetValues(PauseMinute)
        
      ValueSecond:
        PauseSecond:= ResetValues(PauseSecond)
        
      ValuePM:
        if JoyStickInput == Up or JoyStickInput == Down
           if PauseHalf ==  0
             PauseHalf:=  1
           else
             PauseHalf:= 0     
           waitcnt(clkfreq/50+cnt)   
        lcd.clrln(0)
        if PauseHour < 10
          lcd.str(string(" "))
        dec(PauseHour)                                 
        lcd.str(string(":"))
        if PauseMinute < 10
          lcd.str(string("0"))
        dec(PauseMinute) 
        lcd.str(string(":"))
        if PauseSecond < 10
          lcd.str(string("0"))            
        dec(PauseSecond) 
        if PauseHalf== 1
          lcd.str(string(" PM"))       
        else
          lcd.str(string(" AM"))
         
        JoyStickInput:=ina[LeftPin..UpPin]   
        if JoyStickInput == Left
           ValueBeingSet -= 1 
           waitcnt(clkfreq/4+cnt)  
        if JoyStickInput == Right
           ValueBeingSet += 1
           waitcnt(clkfreq/4+cnt)
        waitcnt(clkfreq/4+cnt)
        
      ConfirmTime:
        lcd.cls
        dec(PauseHour)     'hours                            
        lcd.str(string(":"))
        if PauseMinute < 10
          lcd.str(string("0"))        
        dec(PauseMinute) 'minutes tens place
        lcd.str(string(":"))
        if PauseSecond < 10
          lcd.str(string("0"))                    
        dec(PauseSecond) 'seconds tens place
        if PauseHalf== 1
          lcd.str(string(" PM"))       'hours tens place
        else
          lcd.str(string(" AM"))
             
        lcd.gotoxy(0,1) 
        lcd.str(string("Time Correct?"))
        lcd.gotoxy(0,2)
        lcd.str(string("Right to confirm"))
        lcd.gotoxy(0,3)
        lcd.str(string("Left to go back"))
        JoyStickInput:=ina[LeftPin..UpPin]  
        if JoyStickInput == Right
           ClockSet:= True
           ValueBeingSet:=-1
        if JoyStickInput == Left
           ClockSet:=False
           ValueBeingSet:= 0
           lcd.cls  
        waitcnt(clkfreq/4+cnt)

  ClockSet:=False
  lcd.cls

  HourInput:=PauseHour
  MinuteInput:=PauseMinute
  SecondInput:=PauseSecond
  HalfInput:=PauseHalf
  DayInput:=DecimalDay
  DateInput:=DecimalDate
  MonthInput:=DecimalMonth
  YearInput:=DecimalYear

  SettingTime:=True
  'DecSetTime    

PUB ResetValues(ClockValue) : NewValue

  if JoyStickInput == Up
     ClockValue += 1
     waitcnt(clkfreq/50+cnt)              
  if JoyStickInput == Down
     ClockValue -= 1
     waitcnt(clkfreq/50+cnt)

  if ValueBeingSet == ValueHour  
    if ClockValue > 12
       ClockValue:= 1
    if ClockValue < 1
       ClockValue:= 12
         
  else  
    if ClockValue > 59
       ClockValue:= 0
    if ClockValue < 0
       ClockValue:= 59

  waitcnt(clkfreq/10+cnt)                               'Not sure if this is necessary
  if JoyStickInput <> NoInput  
    lcd.clrln(0)
    if ValueBeingSet == ValueHour
      if ClockValue < 10
        lcd.str(string(" "))  
      dec(ClockValue)     
    else
      if PauseHour < 10
        lcd.str(string(" "))    
      dec(PauseHour)                               
    lcd.str(string(":"))
    if ValueBeingSet == ValueMinute
      if ClockValue < 10
        lcd.str(string("0"))
      dec(ClockValue)     
    else
      if PauseMinute < 10
        lcd.str(string("0"))
      dec(PauseMinute) 
    lcd.str(string(":"))            
    if ValueBeingSet == ValueSecond
      if ClockValue < 10
        lcd.str(string("0")) 
      dec(ClockValue)        
    else
      if PauseSecond < 10
        lcd.str(string("0"))
      dec(PauseSecond)  
    if PauseHalf== 1
      lcd.str(string(" PM"))       
    else
      lcd.str(string(" AM"))
    lcd.clrln(1)

  else
  ' *** Cursor position varies based on whether the previous values were one or two digits 
    case ValueBeingSet
      ValueHour :
        lcd.gotoxy(1,0) 
      ValueMinute :
        lcd.gotoxy(4,0)
      ValueSecond :
        lcd.gotoxy(7,0)


  waitcnt(cnt+clkfreq/20)
  
  JoyStickInput:=ina[LeftPin..UpPin]
  if JoyStickInput == Left
    if ValueBeingSet > 0
      ValueBeingSet -= 1
      waitcnt(clkfreq/4+cnt)
  if JoyStickInput == Right
      ValueBeingSet += 1
      waitcnt(clkfreq/4+cnt)

  NewValue:= ClockValue

PUB dec(value)   | i
  if value < 0
    -value
    lcd.putc("-")

  i := 1_000_000_000
  repeat 10
    if value => i
      lcd.putc(value / i + "0")                       ' "0"=48 and 48+(a # 0-9)=the ASCII character value for that #
      value //= i
      result~~
    elseif result or i == 1
      lcd.putc("0")
    i /= 10
      