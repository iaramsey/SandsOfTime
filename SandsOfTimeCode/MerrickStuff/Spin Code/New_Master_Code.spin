CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

 '******************ENCODER CONSTANTS******************
  HGCS  = 4             'Encoder activation on Pin 4   - Encoder 6 
  HGSI  = 6             'Encoder Output on Pin 6       - Encoder 4
  HGCLK = 5             'Encoder CLK on Pin 5          - Encoder 2

  ArmCS  = 9             'Encoder activation on Pin 7   - Encoder 6 
  ArmSI  = 8             'Encoder Output on Pin 8       - Encoder 4
  ArmCLK = 7             'Encoder CLK on Pin 5          - Encoder 2     
  EncoderAmount = 4 
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
  
OBJ       
  pst : "PST_Driver"                       
  rgb : "WS2812B_RGB_LED_Driver_v2"           'Include WS2812B_RGB_LED_Driver object and call it "rgb" for short
  lcd : "serial_LCD" 
DAT
'**Encoder Values for all clock values (12 is included on both ends for redundancy)
ArmAbsPosition long  1023, 942, 858, 773, 694, 609, 523, 432, 343, 252, 172, 87, 1023         

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
        
RStart word 0,32,56,72,84     'array of Start adddresses for each ring   

REnd word 31,55,71,83,91      'array of End adddresses for each ring

RLen word 32,24,16,12,8       'array of LED length for each ring   


VAR 
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
   
PUB Main | Lit, CurrentHourPosition, AlreadySet

  dira[EPWMpin..EDir]~~                 'Set directions of PWMpin and Dir pins of all 3 motors to outputs
  dira[ArmPWMpin..ArmDir]~~             'Set directions of PWMpin and Dir pins of all 3 motors to outputs
  dira[HPWMpin]~~
  dira[HDir]~~                     
  dira[FrontLimit]~                     'Set Limit switch pins as inputs
  dira[BackLimit]~
  dira[LEDPin]~~
  dira[LCDPin]~~
  pst.start                                     'Start the "'pst_Driver" object on Cog 2 
{
  ************** COG DETAILS ****************
   Cog 0   -   Main Code
   Cog 1   -   TEMP - PST
   Cog 2   -   PWM of Extension and Arm motors
   Cog 3   -   LCD                               **Has issues with lights and pst or pwm are on          
   Cog 4   -   HGEncoders 
   Cog 5   -   ArmEncoders        
   Cog 6   -   Lights 
   Cog 7   -   Clock            
  }
  EncoderIdle:=False                            'Make encoder check at normal intervals
  CanArmRotate:=True 

  'PWMPin1:=EPWMPin
  'PWMPin2:=ArmPWMPin 
  coginit(2,PWM(EPWMPin, ArmPWMPin),@Stack2)    'Start PWM method on Cog 1    

  'Lights
  rgb.start(LEDPin, TotalLEDs)
  rgb.alloff
                                                                             
  coginit(6, Lights, @Stack3)                   'Start Lights method on Cog 3

  'LEDMode:= LEDHome
  LEDMode:= ArmRotateLED
  coginit(4, Encoder, @Stack4)                  'Start HGEncoder update method on Cog 4 
  coginit(5, ArmEncoder, @Stack5)                  'Start ArmEncoder update method on Cog 5        
                                                'Need to double check memory requirements of all these
  'LCDMode:=LCDClear                                       
 ' coginit(7, LCDInterface, @Stack6)                                     
 
  
HourSet:=11
MinuteSet:=59
 
EncoderIdle:=True                   'Set the clock chip's time
SecondInput:= 40
MinuteInput:=MinuteSet
HourInput:=HourSet

  
coginit(7, Clock, @Stack7)            'Start Clock update method on Cog 5 - this may not run all the time

  
waitcnt(cnt+clkfreq/10)                'Wait for clock method to start before running methods

SetTime
waitcnt(cnt+clkfreq/10)




DisplayTime   
CurrentHourNumber:=DecimalHour     'Set Start Time upon Startup
MinuteHG:=DecimalMinute/5
MinuteRing:=MinuteHG
HourRing:=CurrentHourNumber
                                       
'***********MOVE ARM TO STARTING POSITION

ResetExtension

waitcnt(clkfreq/4+cnt) 


'*****TestCode*******

'TestCode

CurrentHourPosition:=ArmAbsPosition[CurrentHourNumber]    'Lookup the absolute position of the Current Hour



'***********Startup Code cehcking if arm is in correct position 
'waitcnt(clkfreq*1+cnt)

'Special case for 12 o clock as usual
'Don't try to rotate if arm is within 20 of correct position  
if CurrentHourNumber == 12 
  if (ArmPositionData > 8) or (ArmPositionData < 1018)
     AlreadySet:=False
  else
     AlreadySet:=True   
if (||(CurrentHourPosition - ArmPositionData) > 5)
  if (||(CurrentHourPosition - ArmPositionData) < 1018)
     AlreadySet:=False
     pst.Str(String("Not Set"))

     
     
  pst.newline
  pst.str(string("Hour-Position: "))
  pst.dec((||(CurrentHourPosition - ArmPositionData) ))
else
  AlreadySet:=True
  
waitcnt(clkfreq/2+cnt)


if AlreadySet == False
     EncoderIdle:=False
    'LCDText:=String("SettingArm")
    'LCDMode:=LCDPrint
    pst.str(String("Already Set is False")  )
 
    ArmRotateCurrentPosition(CurrentHourNumber, ArmPositionData)
     
    'LCDText:=String("ArmSet")
    'LCDMode:=LCDPrint
    waitcnt(clkfreq/10+cnt)     
EncoderIdle:=True  

                           'Don't allow the Arm to set an hourglass if reset on a 5 minute Interval
ClockPause:=False 
CanArmRotate:=True






 
'**********MAIN ARM ROTATION CODE*******   
repeat
  if ClockPause ==True          'If interface has set ClockPause, disallow arm from rotating
    CanArmRotate:=False
  'LCDPositionTime

 
  DisplayTime                     'Show time on pst - change this to LCD later
  pst.newLine                       
  pst.dec(ArmTarget)                
  pst.str(string("ArmPosition:"))   
  pst.dec(ArmPosition)               
  waitcnt(clkfreq/10+cnt)
  pst.newLine
                             {
  lcd.gotoxy(0,3)        '(col,line)
   lcd.str(string("CH, MinHG: "))
  dec(CurrentHourNumber)
  lcd.str(string(", "))
  dec(MinuteHG)       
                 }
   
  'If CurrentHourNumber <> MinuteHG and CurrentHourNumber <> 12

  pst.dec(CanArmRotate)
  If(CanArmRotate == True)             'Check if rotation has been disallowed because arm just moved
    If ((DecimalMinute // 5) == 0)     'At 5 minute intervals, run HG rotation
         
                 
         EncoderIdle:=False            'Activate speedy encoders (check more frequently)
         MinuteHG:= DecimalMinute/5    'Set target hourglass based on current minute
         'MinuteRing:=MinuteHG         'This is currently set in the extensison code
         LEDMode:=ArmRotateLED  
         pst.newLine
         pst.str(string("Rotating"))
         InterfacePause:=True          'Disallow interface from resetting time until move is finished
                                       'May change this later and make arm abort and move to 12 or something
                                
         ArmRotate(MinuteHG, CurrentHourNumber)             'ArmRotate(TargetHour, CurrentHour)
         'LEDMode:=DrainLED
         Extension                        'Extends, rotates, and retracts arm.

         'Check this below - it's possible that the extension could take a full minute?                               
         If (DecimalMinute  == 0) AND (DecimalSecond < 55)  'Set Hour hand position in 60 minute increments     
           CurrentHourNumber:=DecimalHour          'Do this before ArmRotate so that the hour hand will move to the new correct hour
           HourRing:=CurrentHourNumber
           if HourRing == 12
              HourRing:= 0                  
          'Does there need to be a variable here that makes this only happen once per hour instead of for 60 seconds during xx:00:XX
           
           'MinuteHG:=12  'CheckThis                 'Set Target to the hour, set current hour to 12
                                  


             
        If CurrentHourNumber <> MinuteHG AND CurrentHourNumber <> 12       'Don't try to rotate if arm is already in correct position

                                               'Checked after MinuteHG has been set correctly
           'lcdText:=String("SettingArm")
           'lcdMode:=LCDPrint         
          ArmRotate(CurrentHourNumber, MinuteHG)     'Rotate back to correct positions by reversing above - ArmRotate(TargetHour, CurrentHour)
          
        elseif CurrentHourNumber == 12 AND MinuteHG <> 0
          ArmRotate(CurrentHourNumber, MinuteHG)     'Rotate back to correct positions by reversing above - ArmRotate(TargetHour, CurrentHour) 

           
    CanArmRotate:=False                              'Disallow arm from rotating after doing a move until 1 minute has passed (See below)

  If (DecimalMinute // 5) => 1                       'Wait 1 minute (remainder 1) until the clock is allowed to rotate again
    CanArmRotate:=True
    EncoderIdle:=True


  'Write Hourglass watchdog checking if an hourglass has been messed with here.
    
                                                           'Allow encoders to check less frequently

   
Pub Lights
dira[LEDPin]~~  
rgb.start(LEDPin,TotalLEDs)                       'Start the RGB driver on with output on Pin 0

waitcnt(clkfreq+cnt)   
rgb.AllOff

                    
repeat

 rgb.alloff     
   case LEDMode
      ArmRotateLED:
        rgb.alloff
        'rgb.SetSection(R1Start+92*DecimalMinute/5,R5End+92*DecimalMinute/5, rgb#Magenta)
        RainbowMinuteHG
        waitcnt(clkfreq/2+cnt)
        
      ExtendLED:
        
        rgb.AllOff
        
      RotateLED:
        rgb.AllOff
        
      DrainLED:
        rgb.alloff
        Rotary_Sweep(DecimalMinute/5)
        waitcnt(clkfreq/2+cnt) 
        rgb.AllOff
              
      LEDHome:        
         RainbowMotion
         waitcnt(clkfreq/2+cnt)
         rgb.alloff
      {
repeat
    'rgb.SetSection(0+93*(DecimalHour),92+93*(DecimalHour), Int(rgb#blue))
 
  RainbowMotion'(DecimalHour)
  
  waitcnt(clkfreq/2+cnt)
 ' Rotary_Sweep(DecimalHour)
  'waitcnt(clkfreq/2)
  rgb.AllOff
         }                                    
 {
  Rotary_Sweep
  Target_Sweep
  Int_Sweep
  Pie
  waitcnt(clkfreq/4+cnt)
  repeat 5
    SecondHand
    'ManualControl
  }   
Pub ResetExtension
    Outa[EDir]~   '~~ is extend    
    EDutyCycle:=100
    repeat until retract == True       'Extend until arm at retract position ** Set by encoder position and limit switch
      'waitcnt(clkfreq*(ExtTime)+cnt)  
      if ina[BackLimit] == 1           'Check for contact with limit switch
        retract:=True

    pst.str(string("Retracted!"))    
    retract:=False
    EDutyCycle~

{Pub ResetArm(ResetHour) | reset, Okay, PositionDifference, CrossingZero, Clockwise, WatchDogStart, TargetHourPosition

  CrossingZero:=False   
  ArmDutyCycle:=100
 'repeat until ||(ArmPosition - (CurrentHour))=<5       '9 is 9pm
  ArmPosition:= ArmPositionData
  DisplayTimeLCD
  lcd.gotoxy(0,2)        '(col,line)  
  lcd.str(string("Arm Position:  "))
  dec(ArmPosition) 'minutes tens place  

 waitcnt(cnt+clkfreq/10)                   

TargetHourPosition:=ArmAbsPosition[3]            '340-511 = -171
if ResetHour == 12
     TargetHourPosition:=0            'Set TargetPosition to 0 (12pm) so that the code will recognize when ArmPosition > Target      
ArmTarget:=TargetHourPosition         'Set the target encoder position as the hour that needs to be changed

PositionDifference:=ArmTarget-ArmPosition

If ArmTarget < ArmPosition
  CrossingZero:=True
 
'***********************************COUNTER-ClOCKWISE**************************************     
if Clockwise == False                 
  outa[ArmDir]~                              'Set Motor direction CounterClockwise

  ArmDutyCycle:=100                        'Set Arm rotation speed via PWM

 {   
  WatchDogStart:=cnt                    'Set WatchDog start to the current counter time
  if CrossingZero== True                'CASE 4 - Crossing zero in a CounterClockwise Direction 1..0<--1023..1022
  {
   MSB:=((ArmPositionData <<9) & %1)
    repeat until MSB == 0 }
    
    repeat until ArmPosition =<400        'In CASE 4, the Armposition MUST be >512
      ArmPosition:= ArmPositionData
     } 
    { if TwelveAdjustment == True 
      if (ArmPosition-||(Armtarget-1023)) < 85      '||(0 - 1023)
        ArmDutyCycle:=50  }
      
         
  repeat until ||(ArmPosition - ArmTarget) < 8   'Rotate until arm position is greater than target, since encoders increase counterclockwise   
      if (WatchDogStart+clkfreq*10 == cnt)   'Wait until 10 seconds have elapsed since the WatchDog was started 
        quit                    
      if ||(ArmTarget-ArmPosition) < 60
        ArmDutyCycle:=60           
      ArmPosition:= ArmPositionData
     
    lcd.cls
    DisplayTimeLCD
    lcd.gotoxy(0,2)        '(col,line)  
    lcd.str(string("Arm Position:  "))
    dec(ArmPosition) 'minutes tens place  

CrossingZero:=False
'??TwelveAdjustment:=False  
ArmDutyCycle~
ClockWise~
TargetReached:=True

}
       

 
Pub Extension | extend, WaitToRotate,ArmSetPoint
     
    HGposition:= HGPositionData[MinuteHG]   ' Record Position of Current minute encoder
    

      outa[EDir]~~                      'Set Extension motor direction outward
      EDutyCycle:=70                   'Set Extension motor's duty cycle ** Probably want this to slow down based on encoder position as it nears the gear 

      repeat until contact == True      'Extend until arm at contact position 
        outa[HDir]~~
        outa[HPWMPin]~~  

        if ina[FrontLimit] == 1         'Check for high signal by making contact with limit
          contact:=True
          MinuteRing:=MinuteHG
      contact:=False                    'Reset limit Switch
      EDutyCycle~                      'Turn off extension motor

      
      pst.NewLine
      pst.str(string("Contact!"))
      waitcnt(cnt+clkfreq)             'Pause for motor to stop

    if HGPosition =>400 And HGPosition=<600
      HGTarget:= 0 'Assumes a CounterClockwise rotation
    else
      HGTarget:= 512
      
    outa[HPWMPin]~~                   'Redundant w/ above      
    WaitToRotate:=cnt                 'WatchDog
    
    ArmSetPoint:=ArmPositionData      'Get Arm initial position

    repeat until {||(HGPosition - HGTarget) < 4 or ||(HGPosition - HGTarget) > 1019 or}  cnt => (WaitToRotate+Clkfreq*10)
    
    
   ' if ||(HGPosition - HGtarget) > 0                                         
      {pst.NewLine
      pst.str(string("HGPosition: "))
      pst.dec(HGPosition)    }
      
      outa[ArmDir]~          'Move arm against rotation
      
      'if ||(HGPosition - HGTarget) < 20
      ArmPosition:=ArmPositionData

      
      if ||(ArmPosition - ArmSetPoint) > 10          'This used to be 20
         if ||(ArmPosition - ArmSetPoint) > 900     'Case for this code around 12 o clock
            if ArmPosition < 512
               outa[ArmDir]~~
            else                                     'This may need to be tweaked so that it's less fidgety
               outa[ArmDir]~                        'AKA only change ArmDir back the other direction if it passes SetPoint by 10 degrees                                   
         else
            if ArmPosition > ArmSetPoint
               outa[ArmDir]~~          'Move
            else
               outa[ArmDir]~  

        ArmDutyCycle:= 30         '********IMPORTANT****** This depends on the direction of hourglass rotation
         
      HGPosition:=HGPositionData[MinuteHG]       'Need to check that this corresponds with the correct hourglass
        pst.clearhome
        pst.dec(HGTarget)
        pst.str(String("-Targ  -")) 
        pst.dec(HGPosition)
        waitcnt(clkfreq/100+cnt)
      'else
       '  ArmDutyCycle:= 0
    {  if ||(HGPosition - HGtarget) < 20
          HGDutyCycle:=40
        
        PWMPin2:=HPWMPin
        PWMDutyCycle2:=HDutyCycle      }
  
    ArmDutyCycle~
    outa[HPWMPin]~                       'Again, may want to slow down as near target
    
    {
    PWMPin1:=EPWMPin
    PWMDutyCycle1:=EDutyCycle           }     'Code to slow down the clock

    
    Flipping := False                   'Stop Running ManualControl Light method   
    pst.NewLine                  
    pst.str(string("Flipped!"))
    'StartTime := True                  'Start Running SecondHand light method
   
              
    Outa[EDir]~                        'Set Extension motor direction inward      
    EDutyCycle:=100                    'Set Extension motor's duty cycle ** Probably want this to slow down based on encoder position
                                       'as it nears the gear
    repeat until retract == True       'Extend until arm at retract position ** Set by encoder position and limit switch
      if ina[BackLimit] == 1           'Check for contact with limit switch, noted by a HIGH signal
        retract:=True
    retract:=False                     'Reset limit switch
         
    EDutyCycle~                        'Turn off extension motor  
    pst.NewLine                  
    pst.str(string("Done!"))
    pst.NewLine                        'Reset variables
    retract:= False
    Extend:=False
  
    'MinuteHG:=MinuteHG+1   
    







PUB ArmRotate(TargetHour,CurrentHour) | TwelveAdjustment, CrossingZero,CurrentHourPosition, TargetHourPosition, ArmCase, HourDifference, RotDistance, Clockwise, WatchdogStart, reset, PositionDifference
        'Set the Vertical zero of the encoders - =0 hopefully   
'9PM =
'Display the method
{
  lcd.cls          
  lcd.gotoxy(0,0)
  lcd.str(string("ArmRotate"))
  waitcnt(clkfreq*2+cnt)          }
'lcdText:=String("Leaving 0 repeat")
'lcdMode:=LCDPrint  

                                     

CrossingZero:=False
TwelveAdjustment:=False
pst.str(String("Current hour "))
pst.dec(CurrentHour)
pst.str(String("Target hour "))
pst.dec(TargetHour)
'waitcnt(Clkfreq*4+cnt)
if TargetHour == 0
 TargetHour:=12
if CurrentHour == 0
 CurrentHour:=12
 
CurrentHourPosition:=ArmAbsPosition[CurrentHour]
TargetHourPosition:=ArmAbsPosition[TargetHour]            'MAKE SURE THIS BECOMES ARMTARGET




if TargetHour == 12
  TwelveAdjustment:= True

   
PositionDifference:=TargetHourPosition-CurrentHourPosition

                                              'Check if the rotation would be > 180 degrees    
if ||(PositionDifference) < 512                                                                 'Decreases Clockwise e.g. 12 is 0 but

  '**CASE 1**               
    If (PositionDifference) > 0    '       If targetHour is farther clockwise than current hour         
       Clockwise:= False
       CrossingZero:=False         
       pst.newLine
       pst.str(string("CASE 1"))
       ArmCase:=1

  '**CASE 2**                      '340-511 = -171   
    else  
        ClockWise:=True
        CrossingZero:=False           
        pst.newLine              
        pst.str(string("CASE 2"))
        pst.newLine              
        ArmCase:=2
   
else '||(PositionDifference) > 512             'Can SPIN somehow get into this if the above is triggered?

  '**CASE 3**                 
    If (PositionDifference) > 0     'If target hour is farther counterclockwise than current hour
         Clockwise:= True             'Tell arm to go backwards because it's far
         CrossingZero:=True         'Required so that the clock waits until crossed zero to determine the clock's stopping point
         pst.newLine              
         pst.str(string("CASE 3"))
         ArmCase:=3
  '**CASE 4**       
    else   ' < 0
         ClockWise:= False
         CrossingZero:=True         'Required so that the clock waits until crossed zero to determine the clock's stopping point
         pst.newLine                
         pst.str(string("CASE 4"))
         ArmCase:=4
           
 'Circle Math is so confusing
 

ArmTarget:=TargetHourPosition         'Set the target encoder position as the hour that needs to be changed
ArmPosition:= ArmPositionData  
           


if TargetHour== 12      'IMPORTANT I think if Twelve is ever the target, Crossing Zero must be true
  CrossingZero:=True                'i.e. Case 3 or Case 4
    pst.str(String("Case "))
    pst.dec(ArmCase)   
                                    'Maybe write a separate 12 rotate code here like below

pst.str(String("Current hour "))
pst.dec(CurrentHour)
pst.str(String("Target hour "))
pst.dec(TargetHour)
pst.newline
pst.str(String("Current pos "))
pst.dec(ArmPosition)
pst.str(String("Target Pos "))
pst.dec(ArmTarget)

waitcnt(clkfreq*2+cnt)    
if CurrentHour == 12 'or CurrentHourNumber == 0   This is bad, I think CurrentHourNumber is global      'If the current hour is 12:    
  if TargetHour =<6          'Move clockwise if target hour is 6
    Clockwise:=True                                                            'Does this work for 1:00pm
    outa[ArmDir]~~
    ArmDutyCycle:=100   
    repeat until ArmPosition =>600        'Don't Move on until on the Decreasing/Clockwise side of zero
      ArmPosition:= ArmPositionData
      'lcdMode:=LCDPositionTime 
      
  else
    Clockwise:=False       ' if it's greater than 6, go counter clockwise
    outa[ArmDir]~
    ArmDutyCycle:=100   
    repeat until ArmPosition =<400        'Don't Move on until on the Increasing/CounterClockwise side of zero     
      ArmPosition:= ArmPositionData
      'lcdMode:=LCDPositionTime
  CrossingZero:=False        'Already corrected for this by waiting  - not doing this would cause a lap
  waitcnt(clkfreq/2+cnt)     'wait .5s to check position if crossing zero is true
           
'***********************************ClOCKWISE (CASE 2 & 3)**********************************************************************************************  
if Clockwise == True     'C             'Check whether rotation protocol has been started.
                                         
  outa[ArmDir]~~                        'Set Arm direction direction Clockwise
  ArmDutyCycle:=100                      'Set Arm rotation speed via PWM

  waitcnt(clkfreq/20+cnt)     'wait .05s to check position if crossing zero is true         
  'lcdMode:=LCDPositionTime 

       pst.clearhome                    
       pst.dec(ArmTarget)             
       pst.str(string("ArmPosition:"))
       pst.dec(ArmPosition)

     
  'WatchDogStart:=cnt                    'Set WatchDog start to the current counter time
  if CrossingZero == True                'CASE 3 - Crossing zero in a Clockwise Direction: 1..0-->1023..1022
   {MSB:=((ArmPositionData >> 9) & %1)
    repeat until MSB == 1                'Check the MSB aka 1000 or 0   }

    pst.clearhome                   
    pst.dec(ArmTarget)              
    pst.str(string("ArmPosition:")) 
    pst.dec(ArmPosition)            
                                    
    'I think you can't do this if crossing zero is set bc of 12
    'Need a different variable
    pst.str(string("CZ"))    

    
    repeat until ArmPosition =>600        'In CASE 3, the Armposition MUST be <512    
       ArmPosition:= ArmPositionData
       'lcdMode:=LCDPositionTime 
       
                
      if TwelveAdjustment == True 
       if (ArmPosition-||(Armtarget-1023)) < 40      '||(0 - 1023)
         ArmDutyCycle:=50 
         
    waitcnt(clkfreq/20+cnt)     'wait .05s to check position if crossing zero is true
     
        
  repeat until (ArmPosition < ArmTarget)   'Rotate until arm position is lower than target, since encoders decrease clockwise   
    'if (WatchDogStart+clkfreq*10 == cnt)   'Wait until 10 seconds have elapsed since the WatchDog was started 
     ' quit

    pst.clearhome
    pst.str(string("C"))                       
    pst.dec(ArmTarget)             
    pst.str(string("ArmPosition:"))
    pst.dec(ArmPosition)      
                        
    if ||(ArmTarget-ArmPosition) < 40     'Slow down when close
      ArmDutyCycle:=80
    ArmPosition:= ArmPositionData

    'lcd.cls
    'LCDMode:=LCDPositionTime 
    'DisplayTimeLCD     

 

   
'***********************************COUNTER-ClOCKWISE (CASE 1 & 4)**************************************************************************************        
if Clockwise == False
    
  if TargetHour == 12 or ArmTarget == 1023
     ArmTarget:=0                   'Set TargetPosition to 0 (12pm) so that the code will recognize when ArmPosition > Target

  outa[ArmDir]~                              'Set Motor direction CounterClockwise

  ArmDutyCycle:=100                       'Set Arm rotation speed via PWM
  waitcnt(clkfreq/20+cnt)     'wait .05s to check position if crossing zero is true           
  WatchDogStart:=cnt                    'Set WatchDog start to the current counter time
     
  if CrossingZero== True                'CASE 4 - Crossing zero in a CounterClockwise Direction 1..0<--1023..1022
  {
   MSB:=((ArmPositionData <<9) & %1)
    repeat until MSB == 0 }

    pst.clearhome                   
    pst.dec(ArmTarget)              
    pst.str(string("ArmPosition:")) 
    pst.dec(ArmPosition)            
                                    
    'I think you can't do this if crossing zero is set bc of 12
    'Need a different variable
    pst.str(string("CZ"))    
    repeat until ArmPosition =<400        'In CASE 4, the Armposition MUST be >512 
       ArmPosition:= ArmPositionData     
       'lcdMode:=LCDPositionTime 

       

       {
      if TargetHour == 12
        if (1023-ArmPosition < 85)    
          ArmDutyCycle:=50
         }
          
    waitcnt(clkfreq/20+cnt)     'wait .05s to check position         
  'lcd.cls          
  'lcdMode:=LCDPositionTime           
    'lcdText:=String("Leaving 0 repeat")
    'lcdMode:=LCDPrint
  
  repeat until (ArmPosition > ArmTarget)   'Rotate until arm position is greater than target, since encoders increase counterclockwise   
    {if (WatchDogStart+clkfreq*10 == cnt)   'Wait until 10 seconds have elapsed since the WatchDog was started 
      quit}
       pst.clearhome
       pst.str(string("CC"))                       
       pst.dec(ArmTarget)             
       pst.str(string("ArmPosition:"))
       pst.dec(ArmPosition)             
                        
    if ||(ArmTarget-ArmPosition) < 40
        ArmDutyCycle:=80
           
    ArmPosition:= ArmPositionData     
    'LCDMode:=LCDPositionTime 
    'DisplayTime'lcd
  


 {    
     ArmTarget:=ArmPositionData + 1023/12*(RotDistance)     'Encoder decreases in the clockwise direction
     if ArmTarget > 1023
         ArmTarget:= ArmTarget - 1023      'Could this accidently subtract twice if it jumps between 1023?
     'ArmTarget:=ArmZero + 1023/12  <- comment back in once zero is set  'Set target 360/12 degrees of rotation away from current position
                                                'Aboslute reference by using ArmZero
    } 

CrossingZero:=False
TwelveAdjustment:=False  
ArmDutyCycle~
ClockWise:=False

pst.clearhome
pst.str(string("Done!"))
waitcnt(clkfreq/2+cnt)   

 'Now reset arm
 'either go back 15 degrees or run this code again

PUB ArmRotateCurrentPosition(TargetHour,CurrentPosition) | TwelveAdjustment, CrossingZero, CurrentHourPosition, TargetHourPosition, HourDifference, RotDistance, Clockwise, WatchdogStart, reset, q, PositionDifference,   ArmCase
        'Set the Vertical zero of the encoders - =0 hopefully   
'9PM = 9

  ''lcd.cls          
  'lcd.gotoxy(0,0)
  'lcd.str(string("ArmRotateCurrentPos"))
  waitcnt(clkfreq*2+cnt)


CrossingZero:=False
TwelveAdjustment:=False
CurrentHourPosition:=CurrentPosition


if TargetHour == 0
 TargetHour:=12
 
TargetHourPosition:=ArmAbsPosition[TargetHour]            '340-511 = -171
if TargetHour == 12
  TwelveAdjustment:= True


PositionDifference:=TargetHourPosition-CurrentHourPosition

                                                  'Check if the rotation would be > 180 degrees    
if ||(PositionDifference) < 512                                                                 'Decreases Clockwise e.g. 12 is 0 but

  '**CASE 1**               
    If (PositionDifference) > 0    '       If targetHour is farther clockwise than current hour         
       Clockwise:= False
       CrossingZero:=False
       pst.newLine
       pst.str(string("CASE 1"))
       ArmCase:=1
  '**CASE 2**                      '340-511 = -171   
    else  
         ClockWise:=True
         CrossingZero:=False
         pst.newLine              
         pst.str(string("CASE 2"))
         pst.newLine              
         ArmCase:=2 
else '||(PositionDifference) > 512

  '**CASE 3**                 
    If (PositionDifference) > 0     'If target hour is farther counterclockwise than current hour
         Clockwise:= True             'Tell arm to go backwards because it's far
         CrossingZero:=True         'Required so that the clock waits until crossed zero to determine the clock's stopping point
         pst.newLine              
         pst.str(string("CASE 3"))
         ArmCase:=3 
  '**CASE 4**       
    else   ' < 0
         ClockWise:= False
         CrossingZero:=True         'Required so that the clock waits until crossed zero to determine the clock's stopping point
         pst.newLine                
         pst.str(string("CASE 4"))
         ArmCase:=4     

ArmTarget:=TargetHourPosition         'Set the target encoder position as the hour that needs to be changed
ArmPosition:= ArmPositionData  

'lcdMode:=LCDPositionTime   



pst.newLine                       
pst.dec(ArmTarget)                
pst.str(string("ArmPosition:"))   
pst.dec(ArmPosition)              




if TargetHour==12      'IMPORTANT I think if Twelve is ever the target, Crossing Zero must be true   
  CrossingZero:=True                'i.e. Case 3 or Case 4
    pst.str(String("Case "))
    pst.dec(ArmCase)   
                                    'Maybe write a separate 12 rotate code here like below


if ArmPosition =<40 or ArmPosition =>980       'If the current hour is about 12:    
  if TargetHour =<6                           'Move clockwise if target hour is 6
    Clockwise:=True                                                            'Does this work for 1:00pm
    outa[ArmDir]~~
    ArmDutyCycle:=80   
    repeat until ArmPosition =>600        'Don't Move on until on the Decreasing/Clockwise side of zero
      ArmPosition:= ArmPositionData
      'lcdMode:=LCDPositionTime 
    
  if TargetHour >6 AND TargetHour<12
    Clockwise:=False       ' if it's greater than 6, go counter clockwise
    outa[ArmDir]~
    ArmDutyCycle:=80   
    repeat until ArmPosition =>400        'Don't Move on until on the Increasing/CounterClockwise side of zero     
      ArmPosition:= ArmPositionData
      'lcdMode:=LCDPositionTime
      
  if TargetHour <> 12    
    CrossingZero:=False  'Already corrected for this by waiting
                                
'***********************************ClOCKWISE**************************************
   

if Clockwise == True     'C           'Check whether rotation protocol has been started.
  outa[ArmDir]~~                      'Set Arm direction direction Clockwise
  ArmDutyCycle:=80                    'Set Arm rotation speed via PWM
    
  'lcdMode:=LCDPositionTime   
   
 ' WatchDogStart:=cnt                    'Set WatchDog start to the current counter time
  if CrossingZero == True                'CASE 3 - Crossing zero in a Clockwise Direction: 1..0-->1023..1022
    pst.str(String("Crossing Zero = True") )
      {
    MSB:=((ArmPositionData >> 9) & %1)
    repeat until MSB == 1     'Check the MSB aka 1000 or 0   }
    repeat until ArmPosition =>600        'In CASE 3, the Armposition MUST be <512
       ArmPosition:= ArmPositionData
     
       if TargetHour == 12                         'Slow down if you're nearing zero when the target is 12 o clock
        if (ArmPosition-||(Armtarget-1023)) < 85      '||(0 - 1023)   'Explain this
          ArmDutyCycle:=50 
          
      'lcdMode:=LCDPositionTime 
    waitcnt(clkfreq/20+cnt)     'wait .05s to check position if crossing zero is true
          
  repeat until (ArmPosition < ArmTarget)   'Rotate until arm position is lower than target, since encoders decrease clockwise   
    {if (WatchDogStart+clkfreq*10 == cnt)   'Wait until 10 seconds have elapsed since the WatchDog was started 
      quit}
                          
    if ||(ArmTarget-ArmPosition) < 60     'Slow down when close
      ArmDutyCycle:=60
    ArmPosition:= ArmPositionData
    
    'LCDMode:=LCDPositionTime 
   

 pst.str(String("Done"))




     
 
     '**ArmTarget using relative positioning**
 
 
 
     'ArmTarget:=ArmPositionData - (1023/12)*(RotDistance) 'Encoder decreases in the clockwise direction
 
 
 
     '**ArmTarget using relative positioning**
     {                                                           '
     if ArmTarget < 0                                     'Maybe + (1023/12)*(CurrentHour-TargetHour)
       ArmTarget:= ArmTarget + 1023 
     'ArmTarget:=ArmZero + 1023/12  <- comment back in once zero is set  'Set target 360/12 degrees of rotation away from current position
     }                                               'Aboslute reference by using ArmZero    'ArmZero = 0 for now

     
'***********************************COUNTER-ClOCKWISE**************************************

  pst.newline
  pst.str(String("1"))
     
if Clockwise == False
  if TargetHour == 12
     ArmTarget:=0                   'Set TargetPosition to 0 (12pm) so that the code will recognize when ArmPosition > Target
  outa[ArmDir]~
  
                              'Set Motor direction CounterClockwise
  if ||(ArmTarget-ArmPosition) < 40
    ArmDutyCycle:=50
  else
    ArmDutyCycle:=100                       'Set Arm rotation speed via PWM

 pst.newline
 pst.str(String("2"))   
  'WatchDogStart:=cnt                    'Set WatchDog start to the current counter time                              
  if CrossingZero== True                'CASE 4 - Crossing zero in a CounterClockwise Direction 1..0<--1023..1022 {
    pst.str(String("Crossing Zero = True")  )    
   {MSB:=((ArmPositionData <<9) & %1)
    repeat until MSB == 0 }   
    repeat until ArmPosition =<400        'In CASE 4, the Armposition MUST be >512 
      ArmPosition:= ArmPositionData        
      if TargetHour == 12 
       if (1023-ArmPosition) < 40      '||(0 - 1023)
         ArmDutyCycle:=50  

    waitcnt(clkfreq/20+cnt)     'wait .05s to check position if crossing zero is true
  pst.newline
  pst.str(String("3"))   
     ' DisplayPositionTarget(ArmPosition, ArmTarget) 
            
  repeat until (ArmPosition > ArmTarget)  'Rotate until arm position is greater than target, since encoders increase counterclockwise   
      {if (WatchDogStart+clkfreq*10 == cnt)   'Wait until 10 seconds have elapsed since the WatchDog was started 
        quit}                    
    if ||(ArmTarget-ArmPosition) < 60
      ArmDutyCycle:=60
           
    ArmPosition:= ArmPositionData
    'DisplayPositionTarget(ArmPosition, ArmTarget)   

  pst.newline
  pst.str(String("Done"))
   
 {    
     ArmTarget:=ArmPositionData + 1023/12*(RotDistance)     'Encoder decreases in the clockwise direction
     if ArmTarget > 1023
         ArmTarget:= ArmTarget - 1023      'Could this accidently subtract twice if it jumps between 1023?
     'ArmTarget:=ArmZero + 1023/12  <- comment back in once zero is set  'Set target 360/12 degrees of rotation away from current position
                                                'Aboslute reference by using ArmZero
    }
    
CrossingZero:=False
TwelveAdjustment:=False

ArmDutyCycle~
ClockWise:=False
'TargetReached:=True


 'Now reset arm
 'either go back 15 degrees or run this code again

PUB TestCode | i, j, k

EncoderIdle:=False                  'Set the clock chip's time
cogstop(5)  
repeat i from 1 to 12
  repeat j from 0 to 59
 { repeat k from 1 to 2
    if k==1
      j:=55
    else
      j:= 0           }
    SecondInput:= 40
    MinuteInput:=j
    HourInput:=i     
     
    waitcnt(cnt+clkfreq/2)                'Wait for clock method to start before running methods     


   CurrentHourNumber:=i
   DecimalMinute:=j
   
   
   {
   DisplayTimeLCD
   lcd.gotoxy(0,1)        '(col,line)      
   lcd.str(string("Arm Position:  "))
   dec(ArmPositionData) 'minutes tens place
   lcd.gotoxy(0,2)        '(col,line)      
   lcd.str(string("CurrentHourNumber:  "))
   lcd.gotoxy(0,3)        '(col,line)      
   lcd.str(string("MinuteHG:  "))
   }



           
    'DisplayTime
    pst.newLine                       
    pst.dec(ArmTarget)                
    pst.str(string("ArmPosition:"))   
    pst.dec(ArmPosition)               
    
    pst.newLine     
   pst.dec(i)
   pst.str(string("-i TestCode  j-"))
   pst.dec(j)
   pst.newline
   pst.dec(CurrentHourNumber)
   pst.str(string("-i TestCode  j//5 - "))
   pst.dec(DecimalMinute//5)
   waitcnt(clkfreq/2+cnt)    
   'If(CanArmRotate == True)    
     'If ((DecimalMinute // 5) == 0)     'At 5 minute intervals, run HG rotation
   
          'LEDMode:=ArmRotateLED           
          EncoderIdle:=False            'Activate speedy encoders (check more frequently)
          MinuteHG:= DecimalMinute/5
          pst.newLine
          pst.str(string("Rotating"))
                                                           'Set target hourglass based on current minute
          ArmRotate(MinuteHG, CurrentHourNumber)                        'ArmRotate(TargetHour, CurrentHour)
          'LEDMode:=LEDHome
          Extension
                                           'Let motor finish extending
          If (DecimalMinute  == 0)  'Set Hour hand position in 60 minute increments     
            CurrentHourNumber:=DecimalHour          'Do this before ArmRotate so that the hour hand will move to the new correct hour
            HourRing:=CurrentHourNumber
            'MinuteHG:=12  'CheckThis                 'Set Target to the hour, set current hour to 12
                                        'Variable to make sure this is done only once an hour
   
   
        If CurrentHourNumber <> MinuteHG       'Don't try to rotate if arm is already in correct position
           
          ' lcd.cls
           'lcd.str(string("Resetting Arm "))
           ArmRotate(CurrentHourNumber, MinuteHG)
            
     'CanArmRotate:=False
          
   If (DecimalMinute // 5) => 1                              'Wait 1 minute (remainder 1) until the clock is allowed to rotate again
     CanArmRotate:=True

                                                          'Allow encoders to check less frequently
  'lcd.cls                 'Clear LCD
   j+=4
   

  
   
PUB Encoder | Data, i, j, PosFix, parity




  dira[HGCLK]~~
  dira[HGCS]~~  
  dira[HGSI]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs


   
repeat        
  outa[HGCLK]~~
  outa[HGCS]~~
  waitcnt(clkfreq/100000+cnt)         ' 500 ns minimum     - 10 us
  outa[HGCS]~
  waitcnt(clkfreq/100000+cnt)         ' 500 ns minimum     - 10 us
  outa[HGCLK]~                                            
  waitcnt(clkfreq/100000+cnt)         ' 500 ns minimum     - 10 us      
  repeat i from 0 to (EncoderAmount-1)
    repeat 16
       outa[HGCLK]~~                  'Shift through the first 16 bits of data
       waitcnt(clkfreq/200000+cnt)   'delay half a clock period  - 5 us
       outa[HGCLK]~  
       Data:=(Data<<1)+(ina[HGSI] & %1)   'Get position data from 16-bit Encoder value, starting with MSB
       waitcnt(clkfreq/200000+cnt)   'delay half a clock period  - 5 us
    HGRawData[i]:=Data
   if i < (EncoderAmount-1)                           'Only do a dummy clock pulse if it's not the last encoder
    outa[HGCLK]~~                     'Dummy clock pulse to signify end of first encoder's position
    waitcnt(clkfreq/200000+cnt)      'delay half a clock period  - 5 us
    outa[HGCLK]~
    waitcnt(clkfreq/200000+cnt)      'delay half a clock period  - 5 us
  outa[HGCLK]~~
  outa[HGCS]~~                        'Data has now been read

  repeat i from 0 to (EncoderAmount -1)
    repeat j from 0 to 15
      parity+= (HGRawData[i]>>j & %1)                                 

  if (parity // 2) > 0              'Check data parity for error
    error:= True
  else
    error:=False

 
  repeat i from 0 to (EncoderAmount -1)
    HGPositionData[i]:= (HGRawData[i] >> 6)  & %1111_1111_11                'Shift 6 bits to right to only use upper 10 position bits   
    HGStatusData[i]:=HGRawData[i]  & %11_1111                        'Append position array with the current encoder being updated

 if EncoderIdle==True                      'Only check encoder every 1 second if idle mode is true
    waitcnt(clkfreq*1+cnt)
 else
    
  waitcnt(clkfreq/10000+cnt)
    
PUB ArmEncoder | Data, i, j, PosFix, parity




  dira[ArmCLK]~~
  dira[ArmCS]~~  
  dira[ArmSI]~               'SI Pin set to input to receive encoder data, CLK and CS set as outputs



   
repeat        
  outa[ArmCLK]~~
  outa[ArmCS]~~
  waitcnt(clkfreq/100000+cnt)         ' 500 ns minimum     - 10 us
  outa[ArmCS]~
  waitcnt(clkfreq/100000+cnt)         ' 500 ns minimum     - 10 us
  outa[ArmCLK]~                                            
  waitcnt(clkfreq/100000+cnt)         ' 500 ns minimum     - 10 us
    repeat 16
       outa[ArmCLK]~~                  'Shift through the first 16 bits of data
       waitcnt(clkfreq/200000+cnt)   'delay half a clock period  - 5 us
       outa[ArmCLK]~  
       Data:=(Data<<1)+(ina[ArmSI] & %1)   'Get position data from 16-bit Encoder value, starting with MSB
       waitcnt(clkfreq/200000+cnt)   'delay half a clock period  - 5 us
    ArmRawData:=Data
    {
   if i < (EncoderAmount-1)                           'Only do a dummy clock pulse if it's not the last encoder
    outa[ECLK]~~                     'Dummy clock pulse to signify end of first encoder's position
    waitcnt(clkfreq/200000+cnt)      'delay half a clock period  - 5 us
    outa[ECLK]~
    waitcnt(clkfreq/200000+cnt)      'delay half a clock period  - 5 us
    }
  outa[ArmCLK]~~
  outa[ArmCS]~~                        'Data has now been read

  repeat i from 0 to (EncoderAmount -1)
    repeat j from 0 to 15
      parity+= (ArmRawData[i]>>j & %1)                                 

  if (parity // 2) > 0              'Check data parity for error
    error:= True
  else
    error:=False

 

    ArmPositionData:= (ArmRawData >> 6)  & %1111_1111_11                'Shift 6 bits to right to only use upper 10 position bits   
    ArmStatusData:=ArmRawData  & %11_1111                        'Append position array with the current encoder being updated

  if EncoderIdle==True                      'Only check encoder every 2 seconds if idle mode is true
     waitcnt(clkfreq*1+cnt)
   
  else
     
   waitcnt(clkfreq/10000+cnt)
   
                     
PUB PWM(pin1, pin2) | endcnt    'This method creates a 10kHz PWM signal (duty cycle is set by the
                                ' DutyCycleVariables) clock must be 100MHz

'*** I think there's a better way to do this.

                                
  dira[pin1]~~
  dira[pin2]~~                   'Set the direction of "pin" to be an output for this cog 
  ctra[5..0]:=pin1               'Set the "A pin" of this cog's "A Counter" to be "pin"
  ctra[30..26]:=%00100          'Set this cog's "A Counter" to run in single-ended NCO/PWM mode
                                ' (where frqa always acccumulates to phsa and the 
                                '  Apin output state is bit 31 of the phsa value)                              
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


Pub SecondHand | i, TotalTime, T1, T2, T3, T4, T5, TAll 

  TotalTime:= 60               'Total Time to go around
  T1:=TotalTime/R1Len          'Equal divisions of time for each LED based on ring length
  T2:=TotalTime/R2Len
  T3:=TotalTime/R3Len
  T4:=TotalTime/R4Len
  T5:=TotalTime/R5Len  
  TAll:= TotalTime/TotalLEDs

{ ctra[30..26]:=%1000
  ctra[5..0]:=Lit
  phsa~ 
  frqa:= T1
         }
    'rgb.SetSection(R1Start, i, rgb#orange)
    {repeat i from 0 to R5End 
      rgb.LED(Lit, rgb#blue) 
      waitcnt( }
   { repeat i from 0 to R5End 
      rgb.SetSection(R1Start, i, rgb#blue) 
      waitcnt(clkfreq*TAll+cnt)}     
  if StartTime == True
      rgb.alloff
      repeat i from 0 to R1End 
        rgb.SetSection(R1Start, i, rgb#green) 
        waitcnt(clkfreq*T1/10+cnt)
      rgb.AllOff

  


{Pub ManualControl

If Flipping == True
  rgb.alloff 
  position:= HGPosition
  rgb.LED((position/(1024/R1Len)), rgb#blue)
    if ||(position/(1024/R1Len) - PrevPosition) > 0
      rgb.LED(PrevPosition, rgb#off)
      'rgb.AllOff
      'pst.str(string("Position is:" ))
      'pst.dec((position/(1024/R1Len))) 
      'pst.NewLine
      'pst.dec(PrevPosition)            
      PrevPosition:=position/(1024/(R1Len))
   }

'***************************************CLOCK SECTION***************************************

PUB Clock | a, SetSecondTens, SetSecondOnes, SetMinuteTens, SetMinuteOnes, SetHourTens, SetHourOnes, SetPM  
  dira[CCS]~~  
  dira[CSI]~   
  dira[CSO]~~  
  dira[CCLK]~~ 
              

  outa[CCS]~~
  'time



  
  


  
  {

                                            
  time[3]:=1                    '0 = sunday                           '      day                                      
  time[4]:=1<<4 + 9                                                   '_day=$03           'XXXXX_210                                         
  time[5]:=0<<7 + 1<<4 + 1                                            '   *10  date                                                 
  time[6]:=1<<4 + 8                                                   '_date=$04          'XX_54___3210
                                                                
  }                                                                     'century   *10month month              
                                                                       '_month=$05         '7______XX_4________3210                                                                      '*10yr __yr                    
  DecSetTime

                                                                        '_year=$06          '7654__3210                  
                                                               'Uncomment this to reset time                                                   

  'SetTime                                                             '       day      1/0   1/0  10  hr     10m ___m     _seconds
                                                                 '  XXXXX_210___X_12/24_PM/AM_4_3210___X_654_3210___X_654_3210
                                                                  '  time[3]     time[2]                time[1]      time[0] 
 

  'lcd.init(-1, 7, 9600)  
  'CLS

  GetTime
  {                     
  alarm[0]:=time[0]                            
  alarm[1]:=time[1]+1                              
  alarm[2]:=time[2]                        
  alarm[3]:=time[3] + 1<<6                                    
  SetAlarm                   


  WriteAddress($8F,%1100_1000)        'Clear Alarm 1 Flag                                
  WriteAddress($8E,%0000_0111)        'Turn on Alarm 1  
  }
  repeat
    DecTime
    GetTime
   ' DisplayTimeLCD
    {DisplayAlarmLCD
    repeat 1000 
      if ina[SQW]==0
        CLS
        lcd.str(string("ALARM!!!"))
        repeat 40
          outa[6]:=!outa[6]
          waitcnt(clkfreq/4+cnt)
        outa[6]~
        WriteAddress($8F,%1100_1000)        'Clear Alarm 1 Flag
          
        SetAlarm 
      }
      'DisplayTime
      waitcnt(clkfreq/4+cnt) 
       
    'CLS

  'pst.start        
  'pst.ClearHome
  {repeat time                                                                    
    pst.str(string("Enter Address"))                                          
    a:=pst.getdec
    pst.newline
    pst.bin(ReadAddress(a),8)
    pst.newlines(2)
  }

'Read Addresses   'Each bytes's 8-bits are assigned in the following way (#=bit number, X=not used)...
                  ' *10s  __s                              '12:09:00AM 11/3/15
Pub DecTime

  DecimalSecond:= 10*((time[0] & %111_0000)>>4) + (time[0] & %1111)     'Adds tens to ones place to get a single decimal number
                                                                         '11:50:59 --> 10*5 + 9 = 59
   
  DecimalMinute:= 10*((time[1] & %111_0000)>>4) + (time[1] & %1111)     'Adds tens to ones place to get a single decimal number
                                                                         '11:50:59 --> 10*5 + 0 = 50
                                                                         
  DecimalHour:= 10*((time[2] & %1_0000)>>4) + (time[2] & %1111)        'Adds tens to ones place to get a single decimal number
                                                                         '11:50:59 --> 10*1 + 1 = 11                                                                       
   
  DecimalDate:= 10*((time[4] & %11_0000)>>4) + (time[4] & %1111)        'Adds tens to ones place to get a single decimal number
                                                                         '01/31/19 --> 10*3 + 1 = 31
                                                                         
  DecimalMonth:= 10*((time[4] & %1_0000)>>4) + (time[4] & %1111)       'Adds tens to  ones place to get a single decimal number
                                                                         '01/31/19 --> 10*0 + 1 = 01                                                                      
   
  DecimalYear:= 10*((time[4] & %1111_0000)>>4) + (time[4] & %1111)        'Adds tens to ones place to get a single decimal number (Last two digits only)
                                                                         '01/31/19 --> 10*1 + 9 = 19
                                                                       

PUB DisplayTime
  pst.ClearHome
  
  pst.str(string("Current Time:"))
  pst.newline 
  pst.dec(DecimalHour)
  pst.str(string(":"))
  
  pst.dec(DecimalMinute)
  pst.str(string(":"))
             
  pst.dec(DecimalSecond)
  if (time[2] & %10_0000)==%10_0000
    pst.str(string("PM"))       'hours tens place
  else
    pst.str(string("AM"))
    
  pst.str(string("   "))
  case time[3]
    0:pst.str(string("Sun"))
    1:pst.str(string("Mon"))
    2:pst.str(string("Tues"))
    3:pst.str(string("Wed"))
    4:pst.str(string("Thurs"))
    5:pst.str(string("Fri"))
    6:pst.str(string("Sat"))
  pst.NewLine  
 ' pst.str(string(", "))
 ' (time[5] & |<4)>>4)*10 + time[5] & %1111)



 
 
PUB ReadAddress(a) : value |i
  outa[CCS]~
  repeat i from 7 to 0
    outa[CCLK]~~
    outa[CSO]:=a>>i & 1
    outa[CCLK]~

  repeat 8
    outa[CCLK]~~ 
    value:=value<<1+ina[CSI]
    outa[CCLK]~

  outa[CCS]~~

PUB WriteAddress(a,value)  | i
  outa[CCS]~
  repeat i from 7 to 0     
    outa[CCLK]~~
    outa[CSO]:=a>>i & 1
    outa[CCLK]~
  repeat i from 7 to 0
    outa[CCLK]~~ 
    outa[CSO]:=value>>i & 1
    outa[CCLK]~  
  outa[CCS]~~
   

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
      outa[CSO]:=time[i]>>j & 1
      outa[CCLK]~  
  outa[CCS]~~

PUB DecSetTime |  SetSecondTens, SetSecondOnes, SetMinuteTens, SetMinuteOnes, SetHourTens, SetHourOnes, SetPM 
                                                                
                                                               
  '5:54:00PM 11/19/18
  SetSecondTens:=SecondInput/10                                        
  SetSecondOnes:=SecondInput-10*SetSecondTens
  SetMinuteTens:=MinuteInput/10                                        
  SetMinuteOnes:=MinuteInput-10*SetMinuteTens
  SetHourTens:=HourInput/10                                            
  SetHourOnes:=HourInput-10*SetHourTens
  SetPM:=1                                                        '1 is PM 0 is AM
  time[0]:=SetSecondTens<<4+SetSecondOnes 

  time[1]:=SetMinuteTens<<4+SetMinuteOnes                                 
          '12 hr   AM/PM                                                '   1/0   1/0  *10hr  hr                              
  time[2]:=1<<6 + 1<<5 + SetHourTens<<4 + SetHourOnes                


  SetTime
  {

                                            
  time[3]:=1                    '0 = sunday                                 
  time[4]:=1<<4 + 9                                                                                
  time[5]:=0<<7 + 1<<4 + 1                                                                
  time[6]:=1<<4 + 8                                                 
                                                                
  }                                                                     'century   *10month month              
                                                                           
 
                                                  

 
'**************************************CLOCK SET CODE W/ INTERFACE*****************  
PUB LCDInterface
 dira[LeftPin..UpPin]~

 waitcnt(clkfreq/10+cnt) 
     

 'pst.NewLine

 'coginit(2, LCDMethods, @Stack2)

 '(clkfreq/2+Cnt) 
 'pst.str(String("PST up"))

'Continuously check for joystick inputs - Down will pause clock and let clock chip be set via time interface.

 
repeat                            '
  repeat until JoyStickInput == Down and InterfacePause:=False       'Wait for any joystick input
    lcd.init(LCDPin, 9600, 4)
    lcd.cursor(0)
    lcd.cls              
    lcd.str(string("Move Down  <-->"))
    lcd.gotoxy(0,1)
    lcd.str(string(" to set     ><  "))
    lcd.gotoxy(0,2)
    lcd.str(string("  Time     <--> ")) 
    lcd.gotoxy(4,4)
     
     
    if JoyStickInput == Click
      lcd.cls
      lcd.Str(String("Lives of great men"))
      lcd.gotoxy(0,1)
      lcd.Str(String("all remind us"   ))
      waitcnt(clkfreq*4+cnt)
      lcd.cls
      lcd.Str(String("We can make "     ))
      lcd.gotoxy(0,1) 
      lcd.Str(String("our lives sublime,"))
      lcd.gotoxy(0,2)
      waitcnt(clkfreq*4+cnt)
      lcd.cls 
      lcd.Str(String("And, departing, "    ))
      lcd.gotoxy(0,1) 
      lcd.Str(String("leave behind us"))
      lcd.gotoxy(0,2)
      waitcnt(clkfreq*4+cnt)
      lcd.cls    
      lcd.Str(String("Footprints on "    ))
      lcd.gotoxy(0,1) 
      lcd.Str(String("the sands of Time"))
      waitcnt(clkfreq*4+cnt)
      
     
    waitcnt(clkfreq+cnt)
     
    JoyStickInput:=ina[LeftPin..UpPin]

  ClockPause:=True                          'IMPORTANT VARIABLE
  ResetClockData
  ClockPause:=False

PUB ResetClockData  | ClockSet
                    
'Input to start this

'Pause something
'***********Set Minute using Hourglass**************

ClockSet:=False
waitcnt(cnt+clkfreq/10)

PauseDecHour:=12'DecimalHour         'Take snapshot of the current time when interface is activated
PauseDecMinute:=0'DecimalMinute
PauseDecSecond:=0'DecimalHour
PausePM:=1'time[2] & 10_0000   'A 1 is PM a 0 is AM

 

{
    pst.str(JoyStickInput)       
    'waitcnt(clkfreq+cnt)
    
    LCDMode:=LCDDec
    
    'lcd.cls
    'lcd.str(string("Mornings"))    
    waitcnt(clkfreq/4+cnt)      
 }



  lcd.cursor(2)  'Blinking Cursor
  lcd.cls
  dec(PauseDecHour)     'hours                            
  lcd.str(string(":"))
  dec(PauseDecMinute) 'minutes tens place
  lcd.str(string(":"))            
  dec(PauseDecSecond) 'seconds tens place
  if PausePM== %10_0000
    lcd.str(string(" PM"))       'hours tens place
  else
    lcd.str(string(" AM"))
  lcd.gotoxy(0,1)
  lcd.str(string("Up/Down to increment."))
  lcd.gotoxy(0,2)
  lcd.str(string("Move right to set."))  

'repeat  
 JoyStickInput:=ina[LeftPin..UpPin]


     {
repeat until ClockSet == True  'Set by hitting finish button
  repeat until HourSet == True    
    ResetValues(PauseDecHour, True)     'SetHour
    repeat until MinuteSet == True
      ResetValues(PauseDecMinute, False)  'SetMinute
      repeat until SecondSet == True
        ResetValues(PauseDecSecond, False)  'SetSecond
        repeat until PMSet == True  'SetPM
          if JoyStickInput == Right
            PMSet == True
          if JoyStickInput == Up
             PauseSecond:= 1
             waitcnt(clkfreq/20+cnt)              'TBT to switch bounce lab
          if JoyStickInput == Down
             PauseSecond:= 0
             waitcnt(clkfreq/20+cnt)      'hours tens place
         
          lcd.clrln(0)
          dec(PauseDecHour)     'hours                            
          lcd.str(string(":"))
          dec(PauseDecMinute) 'minutes tens place
          lcd.str(string(":"))            
          dec(PauseDecSecond) 'seconds tens place     'hours
          if PausePM== %10_0000
            lcd.str(string(" PM"))       'hours tens place
          else
            lcd.str(string(" AM"))
          if JoyStickInput == Left
            SecondSet := False
            quit  }
ValueBeingSet:= 0            
repeat until ClockSet == True  'Set by hitting finish button

  Case  ValueBeingSet
      ValueHour:
        
        PauseDecHour:= ResetValues(PauseDecHour)     'SetHour  
      ValueMinute:
        PauseDecMinute:= ResetValues(PauseDecMinute)
      ValueSecond:
        PauseDecSecond:= ResetValues(PauseDecSecond)
      ValuePM:
            
            if JoyStickInput == Up or JoyStickInput == Down
               if PausePM ==  0
                 PausePM:=  %10_0000
               else
                 PausePM:= 0     
               waitcnt(clkfreq/50+cnt)      'TBT to switch bounce lab
           
            lcd.clrln(0)
            dec(PauseDecHour)     'hours                            
            lcd.str(string(":"))
            dec(PauseDecMinute) 'minutes tens place
            lcd.str(string(":"))            
            dec(PauseDecSecond) 'seconds tens place     'hours
            if PausePM== %10_0000
              lcd.str(string(" PM"))       'hours tens place
            else
              lcd.str(string(" AM"))
            JoyStickInput:=ina[LeftPin..UpPin]   
            if JoyStickInput == Left
               ValueBeingSet -= 1
               waitcnt(clkfreq/4+cnt)  
            if JoyStickInput == Right
               ValueBeingSet += 1
               waitcnt(clkfreq/4+cnt)
            waitcnt(clkfreq/10+cnt)       
      ConfirmTime:
       '**** DisplayTime ****
        lcd.cls
        dec(PauseDecHour)     'hours                            
        lcd.str(string(":"))
        dec(PauseDecMinute) 'minutes tens place
        lcd.str(string(":"))            
        dec(PauseDecSecond) 'seconds tens place
        if PausePM== %10_0000
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
        waitcnt(clkfreq/20+cnt)
lcd.cls

  
    
HourInput:=PauseDecHour          'Set the clock chip's time, only once ClockSet = true   
MinuteInput:=PauseDecMinute
SecondInput:=PauseDecSecond
 
'EncoderIdle:=True                  
'SecondInput:= 50
'MinuteInput:=MinuteSet
'HourInput:=HourSet                      
Pub ResetValues(ClockValue) : NewValue                'SetMinutes

  'DisplayTimeLCD                         
  'LCDMode:=DisplayCurrentTime
  'dec(MinuteSet) 'minutes tens place
 'lcd.gotoxy(1,1)    'Go to hour ones place
  if JoyStickInput == Up
     ClockValue += 1

     'Return ClockValue
     waitcnt(clkfreq/50+cnt)              'TBT to switch bounce lab
  if JoyStickInput == Down
     ClockValue -= 1
     'return ClockValue
     waitcnt(clkfreq/50+cnt)              
  if ValueBeingSet == ValueHour  
    if ClockValue >12
       ClockValue:= 1
    if ClockValue <1
       ClockValue:= 12
  else  
    if ClockValue >59
       ClockValue:= 0
    if ClockValue <0
       ClockValue:= 59         
 '****Displays Current Time******
  waitcnt(clkfreq/10+cnt)                 'Logic tree to decide whether to display the currently being set value, or value as it stands in the clock
  if JoyStickInput <> NoInput  
    lcd.clrln(0)
    if ValueBeingSet == ValueHour  
       dec(ClockValue)     'hours
    else
       dec(PauseDecHour)                               
    lcd.str(string(":"))
    if ValueBeingSet == ValueMinute  
       dec(ClockValue)     'hours
    else
       dec(PauseDecMinute) 
    lcd.str(string(":"))            
    if ValueBeingSet == ValueSecond 
       dec(ClockValue)     'hours
        
    else
       dec(PauseDecSecond)  'seconds tens place     'hours
    if PausePM== %10_0000
      lcd.str(string(" PM"))       'hours tens place
    else
      lcd.str(string(" AM"))
  else
    if ValueBeingSet == ValueHour                     'From here on is slightly unnecessary code that just puts the cursor underneath the value currently being changed
     if ClockValue >9                                 'Cursor position varies based on whether the previous values were one or two digits
        lcd.gotoxy(1,0)
     else
        lcd.gotoxy(0,0)  
       'hours

       
    if ValueBeingSet == ValueMinute
     if PauseDecHour>9
       if ClockValue >9  
        lcd.gotoxy(4,0)
       else
        lcd.gotoxy(3,0)
     else
       if ClockValue>9
        lcd.gotoxy(3,0)
       else
        lcd.gotoxy(2,0)

             
    if ValueBeingSet == ValueSecond
     if PauseDecHour > 9 
       if PauseDecMinute >9
         if ClockValue >9  
           lcd.gotoxy(7,0)
         else
           lcd.gotoxy(6,0)
     else 
       if PauseDecMinute >9
         if ClockValue >9  
           lcd.gotoxy(6,0)
         else
           lcd.gotoxy(5,0)
           
       else
         if ClockValue >9
           lcd.gotoxy(5,0)
         else
           lcd.gotoxy(4,0)    

                                    
  waitcnt(cnt+clkfreq/20)
  JoyStickInput:=ina[LeftPin..UpPin]
  if JoyStickInput == Left
    if ValueBeingSet > 0
      ValueBeingSet -= 1
      waitcnt(clkfreq/4+cnt)
  if JoyStickInput == Right
      ValueBeingSet += 1
      waitcnt(clkfreq/4+cnt)
      
      'Return ClockValue

  NewValue:= ClockValue
  
  {
     Case ValueBeingSet            
          ValueMinute:
            HourSet := False              
          ValueSecond:
            MinuteSet := False 
     ValueBeingSet == False
     quit      }


'HourSet:=11
'MinuteSet:=59
 
'EncoderIdle:=True                   'Set the clock chip's time
'SecondInput:= 50
'MinuteInput:=MinuteSet
'HourInput:=HourSet                           
PUB LCDMethods
  lcd.init(LCDPin, 9600, 4) 
  waitcnt(clkfreq/2+cnt)
   dira[LCDPin]~~
   LCDMode:=LCDClear

   lcd.cls
   
   repeat
     Case LCDMode
     
        LCDClear:
          lcd.cls
          waitcnt(clkfreq/2+cnt)
        LCDPosition:
          lcd.cls
          'DisplayPositionTarget(ArmPosition, ArmTarget)
          waitcnt(clkfreq/2+cnt)          
        LCDTime:
          lcd.cls
          'DisplayTimeLCD
          waitcnt(clkfreq/2+cnt)     
        LCDPositionTime:
          lcd.cls
         ' DisplayPositionTarget(ArmPosition, ArmTarget)
          lcd.gotoxy(0,2)
         ' DisplayTimeLCD
          waitcnt(clkfreq/2+cnt)
        LCDPrint:
          lcd.cls
          lcd.gotoxy(0,0)
          lcd.str(LCDText) 
          waitcnt(clkfreq/2+cnt)
            
        LCDDec:
          lcd.gotoxy(0,1)
          dec(LCDDecInput)        
    waitcnt(clkfreq/10+cnt)      
PUB DisplayPositionTarget(Position, Target)
    lcd.cls 
    lcd.gotoxy(0,0)        '(col,line)  
    lcd.str(string("Arm Position:  "))
    dec(Position) 'minutes tens place
    lcd.gotoxy(0,1)        '(col,line)  
    lcd.str(string("Arm Target:  "))
    dec(Target) 'minutes tens place
    {lcd.gotoxy(0,2)        '(col,line)  
    lcd.str(string("CH, MinHG: "))
    dec(CurrentHourNumber)
    lcd.str(string(", "))
    dec(MinuteHG)         }

PUB DisplayTimeLCD
  'CLS
  'CLS
  'CLS
  'SetCursor(0) 

  dec(DecimalHour)     'hours                            
  lcd.str(string(":"))
  dec(DecimalMinute) 'minutes tens place
  lcd.str(string(":"))            
  dec(DecimalSecond) 'seconds tens place

  if (time[2] & %10_0000)==%10_0000
    lcd.str(string("PM"))       'hours tens place
  else
    lcd.str(string("AM"))

  {
  case time[3]
    0:lcd.str(string("Sunday"))
    1:lcd.str(string("Monday"))
    2:lcd.str(string("Tuesday"))
    3:lcd.str(string("Wednesday"))
    4:lcd.str(string("Thursday"))
    5:lcd.str(string("Friday"))
    6:lcd.str(string("Saturday"))
  'pst.str(string(","))
  'case ((time[5] & |<4)>>4)*10 + time[5]&%1111  
  '  0:pst.str(string("Sunday"))  
       }


PUB DisplayAlarmLCD
  'SetCursor(192) 
  if (alarm[2] & %1_0000)==%1_0000
    lcd.str(string("1"))       'hours tens place
  else
    lcd.str(string(" "))
  dec(alarm[2] & %1111)     'hours
  lcd.str(string(":"))
  dec((alarm[1] & %111_0000)>>4) 'minutes tens place
  dec(alarm[1] & %000_1111) 'minutes 
  lcd.str(string(":"))            
  dec((alarm[0] & %111_0000)>>4) 'seconds tens place
  dec(alarm[0] & %000_1111) 'seconds 
  if (alarm[2] & %10_0000)==%10_0000
    lcd.str(string("PM"))       'hours tens place
  else
    lcd.str(string("AM"))
  lcd.str(string("  "))
  dec(ReadAddress($0F) & 1)

  

{PUB SetCursor(x)
{position         1       2       3       4       5       6       7       8       9      10      11      12      13      14      15      16
line 1          128     129     130     131     132     133     134     135     136     137     138     139     140     141     142     143
line 2          192     193     194     195     196     197     198     199     200     201     202     203     204     205     206     207}  
  lcd.putc(254)
  lcd.putc(x)  
 }
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
  'ClearRight
    
    






















 
'*******************************************LED SECTION****************************************888
        
Pub Int(color) : IntColor

  IntColor:= rgb.Intensity(color, MaxInt)          'Wrapper function to quickly set a max intensity value across board
   
Pub Int_Sweep | V_Int, i, j, FadeRate
 V_Int:= 0
 FadeRate:=100            'How long to fade in and out - 2 is half second
 repeat j from 0 to 8                             
  repeat i from 0 to MaxInt                   
    rgb.SetSection(R1Start,R5End,V_Int)      'Gradually fade up to max intensity
    V_Int := rgb.Intensity(Colors[j], i)     'Step through intensity - waitcnt determines how long this takes, equal time per intensity value
    waitcnt(clkfreq/FadeRate+cnt)   
  repeat i from 0 to MaxInt
    rgb.SetSection(R1Start,R5End,V_Int)         'Gradually fade down to 0 
    V_Int := rgb.Intensity(Colors[j], MaxInt-i)
    waitcnt(clkfreq/FadeRate+cnt)  
  
          
Pub Rotary_Sweep(DiscNumber) | i, j, Speed, EntryMode
    'rgb.SetSection(R1Start, i, rgb#orange)
    EntryMode:=LEDMode
    Speed:=100
   repeat until EntryMode <> LEDMode                                 'Time per LED step. 1 = 1 second
    repeat j from 0 to 6
      repeat i from (R1Start+92*DiscNumber) to (R5End+92*DiscNumber) 
        rgb.SetSection(R1Start+92*DiscNumber, i, Int(Rainbow[j])) 
        waitcnt(clkfreq/Speed+cnt)
        if LEDMode<>EntryMode
           abort 
Pub Pie  | i, j, k, q
repeat k from 0 to 14
  repeat j from 1 to 8
    
    repeat i from 0 to 4
      if i == 3
       i ++
      rgb.SetSection(RStart[i] , RStart[i] + RLen[i]/8*j , Int(Colors[k]))
         
    waitcnt(clkfreq/10+cnt)
               
Pub Target_Sweep | Speed, i, j
    Speed:=15

  repeat j from 0 to 14                                       'Loops through each of the 15 colors
    repeat i from 0 to 4                                      'Loops through each of the five rings
      rgb.SetSection(RStart[i], REnd[i], Int(Colors[j]))      'Move inwards radially
      waitcnt(clkfreq/Speed+cnt)
      rgb.SetSection(RStart[i], REnd[i], rgb#off)
      'waitcnt(clkfreq/(1000)+cnt)  
   repeat i from 0 to 4
      rgb.SetSection(RStart[4-i], REnd[4-i], Int(Colors[j]))  'Move outwards radially
      waitcnt(clkfreq/(Speed)+cnt)
      if i == 4                                               'If it's the last ring, don't end on an off command
        waitcnt(clkfreq/(100)+cnt)                             '
        quit   
      rgb.SetSection(RStart[4-i], REnd[4-i], rgb#off)
        waitcnt(clkfreq/(100)+cnt)
PUB RainbowFadeDisc(DiscNumber) | i, j, k, VarColor, Ringi, Ringj, Ringk,FadeRate,EntryMode
FadeRate:=100
EntryMode:=LEDMode
rgb.alloff
repeat until LEDMode <> EntryMode 
  {rgb.SetSection(R1Start+92*DiscNumber,R5End+92*DiscNumber,int( rgb#blue_)      
  waitcnt(clkfreq/FadeRate+cnt) }



repeat k from 0 to 80
  VarColor:= k   
  rgb.SetSection(R1Start+92*DiscNumber,R5End+92*DiscNumber, VarColor)      
  waitcnt(clkfreq/FadeRate+cnt)
 if LEDMode<>EntryMode
  abort 
repeat 11
  repeat j from 0 to 80
     VarColor:=j<<8 + k
    rgb.SetSection(R1Start+92*DiscNumber,R5End+92*DiscNumber, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)
    k-=1
     if LEDMode<>EntryMode
      abort
  Ringi++
  Ringj++
  Ringk++      
  repeat i from 0 to 80
    VarColor:= i<<16 + j<<8 + k   
    j-=1
    rgb.SetSection(R1Start+92*DiscNumber,R5End+92*DiscNumber, VarColor)        
     waitcnt(clkfreq/FadeRate+cnt)
      if LEDMode<>EntryMode
        abort
  Ringi++
  Ringj++
  Ringk++      
  repeat k from 0 to 80
    VarColor:= i<<16 + j<<8 + k   
    i-=1
    rgb.SetSection(R1Start+92*DiscNumber,R5End+92*DiscNumber, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)
     if LEDMode<>EntryMode
       abort


 
PUB RainbowMotion | i, j, k, VarColor, Ringi, Ringj, Ringk,FadeRate, EntryMode
'rgb.alloff
{
Ringi:=3
Ringj:=6
Ringk:=9
}
EntryMode:=LEDMode
FadeRate:=20 
repeat k from 0 to 80
  VarColor:= k   
  rgb.SetSection(0,TotalLEDs-1, VarColor)      
  'rgb.SetSection(R1Start,R5End+93*RingN, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)
    if LEDMode<>EntryMode
       return
repeat 11
{
  Ringi++
  Ringj++
  Ringk++
  }
  repeat j from 0 to 80
    
    VarColor:=j<<8 + k
    {  
    rgb.SetSection(R1Start+93,R5End+93*(Ringi), VarColor)
    rgb.SetSection(R1Start+93*(Ringi),R5End+93*(Ringj), VarColor)
    rgb.SetSection(R1Start+93*(Ringj),R5End+93*(Ringk), VarColor)  }
      
    rgb.SetSection(0,TotalLEDs-1, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)
    if LEDMode<>EntryMode
       return  
    k-=1
  Ringi++
  Ringj++
  Ringk++      
  repeat i from 0 to 80
    VarColor:= i<<16 + j<<8 + k   
    j-=1
    {
    rgb.SetSection(R1Start+93*(Ringi),R5End+93*(Ringi), VarColor)
    rgb.SetSection(R1Start+93*(Ringj),R5End+93*(Ringj), VarColor)
    rgb.SetSection(R1Start+93*(Ringk),R5End+93*(Ringk), VarColor)
    }
    rgb.SetSection(0,TotalLEDs-1, VarColor)        
    if LEDMode<>EntryMode
       return
    waitcnt(clkfreq/FadeRate+cnt)
  Ringi++
  Ringj++
  Ringk++      
  repeat k from 0 to 80
    VarColor:= i<<16 + j<<8 + k   
    i-=1
    {
    rgb.SetSection(R1Start+93*(Ringi),R5End+93*(Ringi), VarColor)
    rgb.SetSection(R1Start+93*(Ringj),R5End+93*(Ringj), VarColor)
    rgb.SetSection(R1Start+93*(Ringk),R5End+93*(Ringk), VarColor)
    } 
    rgb.SetSection(0,TotalLEDs-1, VarColor)
    if LEDMode<>EntryMode
       return    
    waitcnt(clkfreq/FadeRate+cnt)

    
    {
  Ringi++
  Ringj++
  Ringk++                        
     } 
PUB RainbowMinuteHG | i, j, k, a,b,c, q, VarColor,VarColorFast, VarColorShifted,FadeRate, EntryMode, descend
'rgb.alloff
{
Ringi:=3
Ringj:=6                 '#> <#
Ringk:=9
}

if MinuteRing == 12      'Make 12 0 because 12 is 0th position in ring array
  MinuteRing:= 0

  
EntryMode:=LEDMode
FadeRate:=30
q:=0
repeat k from 0 to 80

  VarColor:= k                    
  VarColorShifted:=k<<16  
 ' rgb.SetSection(0,TotalLEDs-1, VarColor)
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
      rgb.SetAllColors(VarColor)      
    rgb.SetSection(R1Start+92*HourRing, R5End+92*(HourRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing
     
    rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), rgb#off)      
    rgb.SetSection(R1Start+92*MinuteRing, ((q+92)//92)+(MinuteRing*92), VarColorShifted)  

  
  'rgb.SetSection(R1Start,R5End+93*RingN, VarColor)
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
      rgb.SetAllColors(VarColor)  
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
      rgb.SetAllColors(VarColor)  
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
      rgb.SetAllColors(VarColor)  
    rgb.SetSection(R1Start+92*HourRing, R5End+92*(HourRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing
                          
    rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), rgb#off)       
    rgb.SetSection(R1Start+92*MinuteRing, ((q+92)//92)+(MinuteRing*92), VarColorShifted)  
     

    if LEDMode<>EntryMode
       quit    
    waitcnt(clkfreq/FadeRate+cnt)


{    'Backup of working code

PUB RainbowMinuteHG | i, j, k, a,b,c, VarColor,VarColorFast, VarColorShifted, Ringi, Ringj, Ringk,FadeRate, EntryMode
'rgb.alloff
{
Ringi:=3
Ringj:=6                 '#> <#
Ringk:=9
}

if MinuteRing == 12      'Make 12 0 because 12 is 0th position in ring array
  MinuteRing:= 0

  
EntryMode:=LEDMode
FadeRate:=20 
repeat k from 0 to 80
  c:=k*2  <#160   
  VarColor:= k
  VarColorShifted:=k<<16  
 ' rgb.SetSection(0,TotalLEDs-1, VarColor)


  rgb.SetSection(R1Start, R5End+92*(MinuteRing-1), VarColor)       'Do a Set section from beginning through the ring before the MinuteRing
   
  rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing
   
  rgb.SetSection(R1Start+92*(MinuteRing+1), R5End*12, VarColor)     'Do a Set section from the ring after the MinuteRing to the end  

  
  'rgb.SetSection(R1Start,R5End+93*RingN, VarColor)
    waitcnt(clkfreq/FadeRate+cnt)
    if LEDMode<>EntryMode
       quit
repeat until LEDMode <> EntryMode 
{
  Ringi++
  Ringj++              
  Ringk++
  }
  repeat j from 0 to 80
    b:=j*2  <#160
    VarColor:=j<<8 + k
    VarColorFast:= b<<8 + a
    VarColorShifted:=  k<<16 + j 
    'VarColorShifted:=  i<<8 + j
    {  
    rgb.SetSection(R1Start+93,R5End+93*(Ringi), VarColor)
    rgb.SetSection(R1Start+93*(Ringi),R5End+93*(Ringj), VarColor)
    rgb.SetSection(R1Start+93*(Ringj),R5End+93*(Ringk), VarColor)  }
      
    rgb.SetSection(R1Start, R5End+92*(MinuteRing-1), VarColor)       'Do a Set section from beginning through the ring before the MinuteRing

    rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing

    rgb.SetSection(R1Start+92*(MinuteRing+1), R5End*12, VarColor)     'Do a Set section from the ring after the MinuteRing to the end  
    waitcnt(clkfreq/FadeRate+cnt)
    if LEDMode<>EntryMode
       quit   
    k-=1
    c-=1  ' Maybe change this rate to -=2
  Ringi++
  Ringj++
  Ringk++      
  repeat i from 0 to 80
    VarColor:= i<<16 + j<<8 + k
    VarColorFast:= c<<16 + b<<8 + a
    VarColorShifted:= k<<16 +i<<8 + j   
    a:=i*2  <#160    
    j-=1
    b-=1
    {
    rgb.SetSection(R1Start+93*(Ringi),R5End+93*(Ringi), VarColor)
    rgb.SetSection(R1Start+93*(Ringj),R5End+93*(Ringj), VarColor)
    rgb.SetSection(R1Start+93*(Ringk),R5End+93*(Ringk), VarColor)
    }
    rgb.SetSection(R1Start, R5End+92*(MinuteRing-1), VarColor)       'Do a Set section from beginning through the ring before the MinuteRing

    rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing

    rgb.SetSection(R1Start+92*(MinuteRing+1), R5End*12, VarColor)     'Do a Set section from the ring after the MinuteRing to the end      
    if LEDMode<>EntryMode
       quit 
    waitcnt(clkfreq/FadeRate+cnt)
  Ringi++
  Ringj++
  Ringk++      
  repeat k from 0 to 80
    VarColor:= i<<16 + j<<8 + k
    VarColorFast:= c<<16 + b<<8 + a
    VarColorShifted:=k<<16 + i<<8 + j    
    i-=1
    a-=1    'get a and b back down to zero
    b-=1
 
    
    {
    rgb.SetSection(R1Start+93*(Ringi),R5End+93*(Ringi), VarColor)
    rgb.SetSection(R1Start+93*(Ringj),R5End+93*(Ringj), VarColor)
    rgb.SetSection(R1Start+93*(Ringk),R5End+93*(Ringk), VarColor)
    } 
    rgb.SetSection(R1Start, R5End+92*(MinuteRing-1), VarColor)       'Do a Set section from beginning through the ring before the MinuteRing

    rgb.SetSection(R1Start+92*MinuteRing, R5End+92*(MinuteRing), VarColorShifted)    'Do a Set section through the ring before the MinuteRing

    rgb.SetSection(R1Start+92*(MinuteRing+1), R5End*12, VarColor)     'Do a Set section from the ring after the MinuteRing to the end  
    if LEDMode<>EntryMode
       quit    
    waitcnt(clkfreq/FadeRate+cnt)
                                                             }                                                                