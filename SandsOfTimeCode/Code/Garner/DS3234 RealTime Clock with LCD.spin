CON
  _xinfreq=5_000_000
  _clkmode=xtal1+pll16x


SQW = 4
CLK = 3
SI = 2
SO = 1
CS = 0


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
  lcd : "simple_serial"  


VAR
  byte time[7]
      'time[0]=seconds
      'time[1]=minutes
      'time[2]=hours
      'time[3]=day
      'time[4]=date
      'time[5]=month
      'time[6]=year

  byte alarm[4]
      'alarm[0]=seconds
      'alarm[1]=minutes
      'alarm[2]=hours
      'alarm[3]=day        

PUB Main | a
  dira[CS]~~
  dira[SI]~
  dira[SO]~~
  dira[CLK]~~


  outa[CS]~~
                                                                                                     
                                                   '_seconds=$00       'X_654_3210                  
  '11:24:30AM 01/15/16                                                  ' *10m  __m                            
  time[0]:=3<<4 + 0                                  '_minutes=$01       'X_654_3210                                       
  time[1]:=2<<4 + 4                                                     '   1/0   1/0  *10hr  hr                              
  time[2]:=1<<6 + 0<<5 + 1<<4 + 1                    '_hour=$02          'X_12/24_PM/AM_4____3210                                          
  time[3]:=4                                                           '      day                                      
  time[4]:=1<<4 + 4                                  '_day=$03           'XXXXX_210                                         
  time[5]:=0<<7 + 0<<4 + 1                                             '   *10  date                                                 
  time[6]:=1<<4 + 6                                  '_date=$04          'XX_54___3210                       
                                                                       'century   *10month month              
  SetTime                                            '_month=$05         '7______XX_4________3210            
                                                                       '*10yr __yr                    
                                                     '_year=$06          '7654__3210                  
                                                     

                                          '       day      1/0   1/0  10  hr     10m ___m     _seconds
                                        '  XXXXX_210___X_12/24_PM/AM_4_3210___X_654_3210___X_654_3210
  '                                        time[3]     time[2]                time[1]      time[0] 
  
   

  lcd.init(-1, 7, 9600)  
  CLS

  GetTime                      
  alarm[0]:=time[0]                            
  alarm[1]:=time[1]+1                              
  alarm[2]:=time[2]                        
  alarm[3]:=time[3] + 1<<6                                    
  SetAlarm                   


  WriteAddress($8F,%1100_1000)        'Clear Alarm 1 Flag                                
  WriteAddress($8E,%0000_0111)        'Turn on Alarm 1  
  
  repeat
    GetTime
    DisplayTimeLCD
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
      waitcnt(clkfreq/4+cnt) 
       
    CLS

  'pst.start        
  'pst.ClearHome
  {repeat                                                                     
    pst.str(string("Enter Address"))                                          
    a:=pst.getdec
    pst.newline
    pst.bin(ReadAddress(a),8)
    pst.newlines(2)
  }
   
PUB DisplayTime
  if (time[2] & %1_0000)==%1_0000
    pst.str(string("1"))       'hours tens place
  else
    pst.str(string(" "))
  pst.dec(time[2] & %1111)     'hours
  pst.str(string(":"))
  pst.dec((time[1] & %111_0000)>>4) 'minutes tens place
  pst.dec(time[1] & %000_1111) 'minutes 
  pst.str(string(":"))            
  pst.dec((time[0] & %111_0000)>>4) 'seconds tens place
  pst.dec(time[0] & %000_1111) 'seconds 
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
 ' pst.str(string(", "))
 ' (time[5] & |<4)>>4)*10 + time[5] & %1111)
  
  
PUB ReadAddress(a) : value |i
  outa[CS]~
  repeat i from 7 to 0
    outa[CLK]~~
    outa[SO]:=a>>i & 1
    outa[CLK]~

  repeat 8
    outa[CLK]~~ 
    value:=value<<1+ina[SI]
    outa[CLK]~

  outa[CS]~~

PUB WriteAddress(a,value)  | i
  outa[CS]~
  repeat i from 7 to 0     
    outa[CLK]~~
    outa[SO]:=a>>i & 1
    outa[CLK]~
  repeat i from 7 to 0
    outa[CLK]~~ 
    outa[SO]:=value>>i & 1
    outa[CLK]~  
  outa[CS]~~
   

PUB GetTime  | i      ''Refresh time[0] through time[6] values
  outa[CS]~
  repeat 8        'Set starting address to be $00=seconds
    outa[CLK]~~
    outa[SO]:=0
    outa[CLK]~
  repeat i from 0 to 6
    repeat 8
      outa[CLK]~~ 
      time[i]:=time[i]<<1+ina[SI]
      outa[CLK]~  
  outa[CS]~~


PUB SetTime  | i,j
  outa[CS]~
  repeat i from 7 to 0      'Set starting address to be $80=seconds
    outa[CLK]~~
    outa[SO]:=$80>>i & 1
    outa[CLK]~
  repeat i from 0 to 6
    repeat j from 7 to 0
      outa[CLK]~~ 
      outa[SO]:=time[i]>>j & 1
      outa[CLK]~  
  outa[CS]~~


PUB SetAlarm  | i,j
  outa[CS]~
  repeat i from 7 to 0      'Set starting address to be $80=seconds
    outa[CLK]~~
    outa[SO]:=$87>>i & 1
    outa[CLK]~
  repeat i from 0 to 3
    repeat j from 7 to 0
      outa[CLK]~~ 
      outa[SO]:=alarm[i]>>j & 1
      outa[CLK]~  
  outa[CS]~~





PUB DisplayTimeLCD
  if (time[2] & %1_0000)==%1_0000
    lcd.str(string("1"))       'hours tens place
  else
    lcd.str(string(" "))
  dec(time[2] & %1111)     'hours
  lcd.str(string(":"))
  dec((time[1] & %111_0000)>>4) 'minutes tens place
  dec(time[1] & %000_1111) 'minutes 
  lcd.str(string(":"))            
  dec((time[0] & %111_0000)>>4) 'seconds tens place
  dec(time[0] & %000_1111) 'seconds 
  if (time[2] & %10_0000)==%10_0000
    lcd.str(string("PM"))       'hours tens place
  else
    lcd.str(string("AM"))
  {SetCursor(192)
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
  SetCursor(192) 
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

  
PUB CLS                            'Clears Screen and sets cursor to position 1
  SetCursor(128)                   'Set Cursor home (1,1)
  lcd.str(string("                                "))   

PUB SetCursor(x)
{position         1       2       3       4       5       6       7       8       9      10      11      12      13      14      15      16
line 1          128     129     130     131     132     133     134     135     136     137     138     139     140     141     142     143
line 2          192     193     194     195     196     197     198     199     200     201     202     203     204     205     206     207}  
  lcd.tx(254)
  lcd.tx(x)  

PUB dec(value)   | i
  if value < 0
    -value
    lcd.tx("-")

  i := 1_000_000_000
  repeat 10
    if value => i
      lcd.tx(value / i + "0")                       ' "0"=48 and 48+(a # 0-9)=the ASCII character value for that #
      value //= i
      result~~
    elseif result or i == 1
      lcd.tx("0")
    i /= 10
  'ClearRight
    