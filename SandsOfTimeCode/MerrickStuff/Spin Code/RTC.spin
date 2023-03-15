CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  CCLK = 3
  CSI = 2
  CSO = 1
  CCS = 0
  
OBJ       
  pst : "PST_Driver"

VAR

byte DecimalSecond, DecimalMinute, DecimalHour, DecimalDate, DecimalMonth, DecimalYear, time[7]
long Stack2[100]

PUB Main
  dira[CCS]~~  
  dira[CSI]~   
  dira[CSO]~~  
  dira[CCLK]~~ 

  outa[CCS]~~
  pst.start
  coginit(2,Clock,@Stack2)

  repeat
    pst.str(string("The time is: "))
    pst.dec(DecimalHour)
    pst.str(string(":"))
    pst.dec(DecimalMinute)
    pst.str(string(":"))
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
    pst.dec(DecimalDate)
    pst.str(string("/"))
    pst.dec(DecimalMonth)
    pst.str(string("/"))
    pst.dec(DecimalYear)
    waitcnt(clkfreq/4+cnt)
    pst.ClearHome
    
PUB Clock

  dira[CCS]~~  
  dira[CSI]~   
  dira[CSO]~~  
  dira[CCLK]~~
  outa[CCS]~~

  'DecSetTime
  GetTime

  repeat
    DecTime
    GetTime
    waitcnt(clkfreq/4+cnt)

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
  