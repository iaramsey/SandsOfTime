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
  byte DecimalSecond, DecimalMinute, DecimalHour, DecimalDate, DecimalMonth, DecimalYear, DecimalHalf, DecimalDay
  long SecondInput, MinuteInput, HourInput, HourSet, MinuteSet, DayInput, MonthInput, DateInput, YearInput, HalfInput    
  byte time[7], timeset[7]
     
  '***********************INTERFACE VARIABLES************     
  long LCDMode, LCDText, LCDDecInput
  long ValueBeingSet, PauseDecHour, PauseDecMinute, PauseDecSecond, PausePM
  byte JoyStickInput

  byte choice, w, x
    
OBJ
  pst : "PST_Driver"

PUB Main
  dira[CCS]~~  
  dira[CSI]~   
  dira[CSO]~~  
  dira[CCLK]~~ 

  outa[CCS]~~
  pst.start

repeat  
  DisplayTime
  pst.NewLine
  pst.str(string("Is this correct? (0 for no, 1 for yes, 2 for Spring Forward, 3 for Fall Back)"))
  choice:=pst.getDec
  case choice
    0 :
      pst.ClearHome
      pst.str(string("Enter the hour (1-12): "))
      HourInput:=pst.getDec
      pst.NewLine
      pst.str(string("Enter the minute (0-59): "))
      MinuteInput:=pst.getDec
      pst.NewLine
      pst.str(string("Enter the seconds (0-59): "))
      SecondInput:=pst.getDec   
      pst.NewLine
      pst.str(string("AM(0) or PM(1): "))
      HalfInput:=pst.getDec
      pst.NewLine
      pst.str(string("Enter the day number Sunday(0)-Saturday(6): "))
      DayInput:=pst.getDec
      pst.NewLine
      pst.str(string("Enter the month (1-12): "))
      MonthInput:=pst.getDec
      pst.NewLine
      pst.str(string("Enter the date (1-31): "))
      DateInput:=pst.getDec 
      pst.NewLine
      pst.str(string("Enter the year (00-99): "))
      YearInput:=pst.getDec 
   
      DecSetTime
      DisplayTime
      waitcnt(clkfreq*3+cnt)
      pst.ClearHome
               
    1 :
      pst.ClearHome
      pst.str(string("The time is correct."))
      waitcnt(clkfreq*3+cnt)

    2 :
      HourInput:=DecimalHour+1
      MinuteInput:=DecimalMinute
      SecondInput:=DecimalSecond
      HalfInput:=DecimalHalf
      DayInput:=DecimalDay
      DateInput:=DecimalDate
      MonthInput:=DecimalMonth
      YearInput:=DecimalYear
      DecSetTime
      DisplayTime
      waitcnt(clkfreq*3+cnt)
      pst.ClearHome

    3 :
      HourInput:=DecimalHour-1
      MinuteInput:=DecimalMinute
      SecondInput:=DecimalSecond
      HalfInput:=DecimalHalf
      DayInput:=DecimalDay
      DateInput:=DecimalDate
      MonthInput:=DecimalMonth
      YearInput:=DecimalYear
      DecSetTime
      DisplayTime
      waitcnt(clkfreq*3+cnt)
      pst.ClearHome

  pst.ClearHome
  pst.str(string("Would you like to reset again? No(0) Yes(1): "))
  x:=pst.getDec
  if x == 0
    pst.ClearHome
    quit

repeat
  DisplayTime
  waitcnt(clkfreq/10+cnt)       

PUB DisplayTime

  GetTime
  DecTime

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

PUB DecTime

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

  DecimalHalf:= time[2] & 10_0000

  DecimalDay:=time[3]

PUB GetTime  | i      ''Refresh time[0] through time[6] values
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
                                                             
  '5:54:00PM 11/19/18
  SetSecondTens:=SecondInput/10                                        
  SetSecondOnes:=SecondInput-10*SetSecondTens
  SetMinuteTens:=MinuteInput/10                                        
  SetMinuteOnes:=MinuteInput-10*SetMinuteTens
  SetHourTens:=HourInput/10                                            
  SetHourOnes:=HourInput-10*SetHourTens
  SetPM:=1
  SetDateTens:=DateInput/10
  SetDateOnes:=DateInput-10*SetDateTens                                                      '1 is PM 0 is AM
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
  