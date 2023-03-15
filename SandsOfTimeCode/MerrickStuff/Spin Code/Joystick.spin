 _xinfreq=6_250_000 
 _clkmode=xtal1+pll16x

Left= 9
Down = 10
Right = 11
Click = 12
Up = 13
OBJ
 pst : "PST_Driver"

VAR
byte JoystickInput
PUB Joystick
 dira[Left..Up]~
  
 pst.start
 pst.NewLine

 repeat
  case ina[Left..Up]
    %01111 :
      JoystickInput:=%10000
      pst.str(string("Left"))
    %10111 :
      JoystickInput:=%01000
      pst.str(string("Down"))
    %11011 :
      JoystickInput:=%00100
      pst.str(string("Right"))      
    %11101 :
      JoystickInput:=%00010
      pst.str(string("Click"))      
    %11110 :
      JoystickInput:=%00001
      pst.str(string("Up"))  
  pst.NewLine
  pst.Bin(JoystickInput,5)
  waitcnt(clkfreq+cnt)
  pst.ClearHome