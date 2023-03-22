CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

CLK = 14
SI = 13
SO = 12
CS = 11                                                                                                                   ' 02


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

  steppingPin = 15
  stepDir     = 8
  sleepPin    = 12

'Write Address = Read Address + $80          ($80=128=%1000_0000)
OBJ
  pst : "PST_Driver"

VAR
  byte time[7]
      'time[0]=seconds
      'time[1]=minutes
      'time[2]=hours
      'time[3]=day
      'time[4]=date
      'time[5]=month
      'time[6]=year
  long t[7]


PUB Main | i,temp
  'RTC Comm Pins
  dira[CS]~~
  dira[SI]~
  dira[SO]~~
  dira[CLK]~~
  outa[CS]~~

  'Stepper Pins
  dira[steppingPin]~~     'pin 15 is for stepping
  dira[stepDir]~~      'pin 8 is for direction
  dira[sleepPin]~~      'pin 12 is for controlling sleep to prevent overheats
  outa[sleepPin]~~
  outa[stepDir]~

  pst.start
  {
                                                   '_seconds=$00       'X_654_3210
  '9:23:45PM 3/15/16                                                  ' *10m  __m
  time[0]:=4<<4 + 5                                  '_minutes=$01       'X_654_3210
  time[1]:=2<<4 + 3                                                    '   1/0   1/0  *10hr  hr
  time[2]:=1<<6 + 1<<5 + 0<<4 + 9                    '_hour=$02          'X_12/24_PM/AM_4____3210
  time[3]:=2                                                           '      day
  time[4]:=1<<4 + 5                                  '_day=$03           'XXXXX_210
  time[5]:=0<<7 + 0<<4 + 3                                             '   *10  date
  time[6]:=1<<4 + 6                                  '_date=$04          'XX_54___3210
                                                                       'century   *10month month
  SetTime                                            '_month=$05         '7______XX_4________3210
                                                                       '*10yr __yr
                                                     '_year=$06          '7654__3210
                       '                          day      1/0   1/0  10  hr     10m ___m     _seconds
                                        '  XXXXX_210___X_12/24_PM/AM_4_3210___X_654_3210___X_654_3210
  '                                        time[3]     time[2]                time[1]      time[0]

  }

  repeat
    GetTime
    DisplayTime
    convertToReadable
    if (t[0]//3 == 0)
      pst.str(string(" stepping"))
      outa[sleepPin]~~
      waitcnt(clkfreq/1000+cnt)
      repeat i from 1 to 2000           '200 steps total for motor
        outa[steppingPin]~~
        waitcnt(clkfreq/1000+cnt)
        outa[steppingPin]~
        waitcnt(clkfreq/1000+cnt)
      waitcnt(clkfreq+cnt)
      outa[steppingPin]~

    outa[sleepPin]~
'    repeat i from 0 to 6
'      pst.dec(t[i])
'      pst.str(string(":"))
    waitcnt(clkfreq+cnt)
    pst.ClearHome

PUB CovertToSeconds




  repeat
    GetTime
    DisplayTime
    waitcnt(clkfreq+cnt)
    pst.ClearHome

  {repeat
    pst.str(string("Enter Address"))
    a:=pst.getdec
    pst.newline
    pst.bin(ReadAddress(a),8)
    pst.newlines(2)
  }
PUB convertToReadable
  t[0]:=(time[0]>>4)*10 + (time[0] & $0f)    'seconds
  t[1]:=(time[1]>>4)*10 + (time[1] & %1111)   'minutes
  t[2]:=(time[2] & $10)*10 + (time[2] & %1111)    'hours
  t[3]:=time[3]                                      'day of week
  t[4]:=(time[4]>>4)*10 + (time[4] & $0f)              'date
  t[5]:=(time[5] & $10)*10 + (time[5] & $0f)            'month
  t[6]:=(time[5]>>7)*100 + (time[6]>>4)*10 + (time[6] & $0f)   'year
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
  pst.str(string("    "))
  case time[3]
    0:pst.str(string("Sunday"))
    1:pst.str(string("Monday"))
    2:pst.str(string("Tuesday"))
    3:pst.str(string("Wednesday"))
    4:pst.str(string("Thursday"))
    5:pst.str(string("Friday"))
    6:pst.str(string("Saturday"))
  'pst.str(string(","))
  'case ((time[5] & |<4)>>4)*10 + time[5]&%1111
  '  0:pst.str(string("Sunday"))

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





