CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

 '******************ENCODER CONSTANTS******************
  CS  = 4             'Encoder activation on Pin 4   - Encoder 6 
  SI1  = 6             'Encoder Output on Pin 6       - Encoder 4
  SI2 = 17
  SI3 = 18
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
  NightLED    = 2
  RotateLED    = 3
  DrainLED     = 4
  LightShow    = 5

'******************INTERFACE************************
              
  'LCDPIN = 15

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
  'ValueDate   = 4
  'ValueMonth  = 5
  'ValueDay    = 6
  'ValueYear   = 7
  ConfirmTime = 4
           
           
  LeftPin   = 9     'Brown '
  DownPin   = 10    'Red
  RightPin  = 11   'Orange
  ClickPin  = 12      'Blue
  UpPin     = 13   'Purple
           
  Left     = %01111 
  Down     = %10111 
  Right    = %11011
  Up       = %11110   
  Click    = %11101 
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


   LCDPin = 8
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
  long SecondInput, MinuteInput, HourInput, HourSet, MinuteSet, HalfInput, DateInput, DayInput, MonthInput, YearInput   
  byte time[7], timeset[7]
     
  '***********************INTERFACE VARIABLES************     
  long LCDMode, LCDText, LCDDecInput, LCDPause, ClockSet
  long ValueBeingSet, PauseHour, PauseMinute, PauseSecond, PauseHalf
  byte JoyStickInput

  byte w
    
OBJ
  pst : "PST_Driver"
  'rgb : "WS2812B_RGB_LED_Driver"
  lcd : "serial_LCD"

PUB LCDInterface
  pst.start
  dira[LeftPin..UpPin]~
  JoyStickInput:=ina[LeftPin..UpPin]
  
  dira[LCDPin]~~
  LCDPause:=False

  DecimalHour:=11
  DecimalMinute:=35
  DecimalSecond:=0
  DecimalHalf:=1
  DecimalDate:=12
  DecimalDay:=3
  DecimalMonth:=6
  DecimalYear:=19
  
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
      if DecimalHalf == 1
        lcd.str(string(" PM"))                              
      else
        lcd.str(string(" AM"))
      lcd.gotoxy(0,2)
      case DecimalDay
        0:
          lcd.str(string("Sun "))
        1:
          lcd.str(string("Mon "))
        2:
          lcd.str(string("Tue "))        
        3:
          lcd.str(string("Wed "))
        4:
          lcd.str(string("Thu "))
        5:
          lcd.str(string("Fri "))
        6:
          lcd.str(string("Sat "))
      if DecimalMonth < 10
        lcd.str(string(" "))
      dec(DecimalMonth)
      lcd.str(string("/"))
      if DecimalDate < 10
        lcd.str(string("0"))
      dec(DecimalDate)
      lcd.str(string("/"))
      if DecimalYear < 10
        lcd.str(string("0"))
      dec(DecimalYear)            
      'lcd.str(string("Move down to reset"))
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
      pst.dec(JoystickInput)
      waitcnt(clkfreq/4+cnt)
    case JoystickInput
      Right :
        HourInput:=DecimalHour+1
        if HourInput>12
          HourInput:=1
        if DecimalHour == 11
          if DecimalHalf == 1'(time[2] & %10_0000 == %10_0000) 
            HalfInput:=0
          else
            HalfInput:=1
        else
          HalfInput:=DecimalHalf
        MinuteInput:=DecimalMinute
        SecondInput:=DecimalSecond
        'DecSetTime
        DisplayTime
      Left :
        HourInput:=DecimalHour-1
        if HourInput<1
          HourInput:=12
        if DecimalHour == 12
          if DecimalHalf == 1 
            HalfInput:=0
          else
            HalfInput:=1
        else
          HalfInput:=DecimalHalf
        MinuteInput:=DecimalMinute
        SecondInput:=DecimalSecond
        'DecSetTime
        DisplayTime
      Down:
        ResetClockData    
    CanArmRotate:=True 

PUB ResetClockData

  waitcnt(clkfreq/10+cnt)                               'Not sure if this is necessary
  'PauseHour:=DecimalHour
  'PauseMinute:=DecimalMinute
  'PauseSecond:=DecimalSecond
  'PauseHalf:= time[2] & 10_0000

  PauseHour:=9
  PauseMinute:=35
  PauseSecond:=12
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
  if PauseHalf== %10_0000
    lcd.str(string(" PM"))                              
  else
    lcd.str(string(" AM"))

  lcd.gotoxy(0,1)
  lcd.str(string("Up/Down to increment."))
  lcd.gotoxy(0,2)
  lcd.str(string("Move right to set."))

  ValueBeingSet:=0
  repeat until ClockSet == True
    pst.dec(ValueBeingSet)
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
             PauseHalf:=  %10_0000
           else
             PauseHalf:= 0     
           waitcnt(clkfreq/50+cnt)      
      {ValueDate:
        PauseDate:= ResetValues(PauseDate) }    
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
        if PauseHalf== %10_0000
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
        if PauseHalf== %10_0000
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

  'DecSetTime    
  DisplayTime

PUB DisplayTime | j

  pst.ClearHome
  pst.str(string("The time is: "))
  pst.dec(HourInput)
  pst.str(string(":"))
  if MinuteInput < 10
    pst.str(string("0"))
  pst.dec(MinuteInput)
  pst.str(string(":"))
  if SecondInput < 10
    pst.str(string("0"))
  pst.dec(SecondInput)
  if HalfInput == 1
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

    'waitcnt(clkfreq/10+cnt)
    'pst.ClearHome     
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
       
  {elseif ValueBeingSet == ValueDate
    if ClockValue > 6
      ClockValue:=0
    if ClockValue < 0
      ClockValue:=6

  elseif ValueBeingSet == ValueMonth
    if ClockValue > 12
      ClockValue:=1
    if ClockValue < 1
      ClockValue:=12

  elseif ValueBeingSet == ValueDay
    if ClockValue > 31
      ClockValue:=1
    if ClockValue < 1
      ClockValue:=31

  elseif ValurBeingSet == ValueYear
    if ClockValue > 99
      ClockValue:=0
    if ClockValue < 0
      ClockValue:=99}    
             
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
    if PauseHalf== %10_0000
      lcd.str(string(" PM"))       
    else
      lcd.str(string(" AM"))
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