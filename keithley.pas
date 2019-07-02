unit keithley;

{$mode objfpc}{$H+}

interface
   function  output (Sender: TObject; ampl:string; frq:string; imp:string; state:string; Tpause:integer; init:string; ch_end:string):string;
   function  VRMS (Sender:TObject; mode:string; range:string; nplc:string; trigger_count:string;
                  Tpause:integer; init:string;ch_end:string):string;
   function  THD (Sender: TObject;range:string; nb_harm:string; digit:string; Tpause:integer ;
                  init:string; ch_end:string) : string;
   function  FRQ (Sender: TObject;range:string; Tpause:integer; init:string; ch_end:string ) : string;
   function  SNR(Sender: TObject;range:string; nb_harm:string; digit:string; Tpause:integer;
                  init:string; ch_end:string) : string;
   function  FormatResult (Sender: TObject;phase:string) : string;
   procedure init_k(Sender: TObject;level:string; ch_end:string; Tpause:integer);
   procedure pause(dt:DWORD);
   procedure send_serial(Sender: TObject;str:string;ch_end:string;milli_s:integer);
   function calibre(val:extended):string;

implementation
//{$R *.lfm}
 uses 
  Classes, SysUtils, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, LazSerial,
  strutils, LResources, Spin, ComCtrls, fileinfo, Unit1;

{ Tkeithley }

const
  CR=#13;
  LF=#10;
  {CRLF=#13#10;
  LFCR=#10#13;}

function output (Sender: TObject; ampl:string; frq:string; imp:string; state:string; Tpause:integer;
                              init:string; ch_end:string):string;
{
ampl:amplitude en VRMS  (0 -2 VRMS) /50ohms et 600 ohms
                        (0 - 4 VRMS) / HIZ
frq : fréquence en hertz (10Hz-20kHz)
          two-channel function generator.
imp : impédance (50/600/HIZ)
state : on/off
Tpause : millisecond (0 - 254)
init : RSTCLS / RST / CLS / NONE
ch_end : CR / LF / CRLF / LFCR
}
var
  resultat:string;
begin
  init_k(sender,init,ch_end,Tpause );
  send_serial(sender,concat(':outp:freq ',frq),ch_end,Tpause);
  send_serial(sender,concat(':outp:imp ',imp),ch_end,Tpause);
  send_serial(sender,concat(':outp:ampl ',ampl),ch_end,Tpause);
  send_serial(sender,':outp:chan2 isine',ch_end,Tpause);
  send_serial(sender,concat(':outp ',state),ch_end,Tpause);
  sleep(1000);
  form1.e_fec.Text:=frq;
  form1.e_fec.Refresh;
  form1.e_calibre.Text:='';
  form1.e_calibre.Refresh;
  form1.e_vrms.Text:='';
  form1.e_vrms.Refresh;
  form1.e_fmes.Text:='';
  form1.e_fmes.Refresh;
  writeln(tfout,'');
  write(tfout,concat('F_INC',',',inttostr(f),','));
end;

function VRMS (Sender: TObject;mode:string; range:string; nplc:string; trigger_count:string;
               Tpause:integer; init:string;ch_end:string):string;
 {
  mode : AC/DC
  range : " 0.1" / " 1" / " 10" / " 100" / " 1000" / " auto on"
           (un espace avant chaque choix dans la string)
  nplc : 0.1 (fast) 1 (med) 10 (slow)
  trigger_count : nb d'echantillons mini 1
  Tpause : millisecond (0 - 254)
  init : RSTCLS / RST / CLS
  ch_end : CR / LF / CRLF / LFCR
 }

var
  cpt:integer;
  resultat:string;
begin
  cpt:=0;
  form1.e_calibre.Text := range;
  form1.e_calibre.Refresh;
  init_k(sender,init, ch_end, Tpause);
  send_serial(sender,concat(':sens:func ''volt:',mode,''''),ch_end,Tpause);
  send_serial(sender,concat(':SENS:VOLT:',mode,':RANG',range),ch_end,Tpause);
  //send_serial(sender,concat(':SENS:VOLT:',mode,':NPLC 1',nplc),ch_end,Tpause);
  send_serial(sender,concat(':SENS:VOLT:',mode,':AVER:STAT OFF'),ch_end,Tpause);
  send_serial(sender,':SYST:AZER:STAT OFF',ch_end,Tpause);
  send_serial(sender,concat(':TRIG:COUN ',trigger_count),ch_end,Tpause);
  sleep(500);
  send_serial(sender,':fetch?',ch_end,Tpause);
  sleep(1000);
  resultat := FormatResult(sender,inrun);
  form1.e_vrms.Text:=resultat;
  form1.e_vrms.Refresh;
end;

function THD (Sender:TObject; range:string; nb_harm:string; digit:string; Tpause:integer;
               init:string; ch_end:string) : string;
{
range : " 0.1" / " 1" / " 10" / " 100" / " 750" / " auto on"
         (un espace avant chaque choix dans la string)
nb_harm : 2 - 64
digit : 4 - 7
Tpause : millisecond (0 - 254)
init : RSTCLS / RST / CLS
ch_end : CR / LF / CRLF / LFCR
}
var
  resultat:string;
begin
  init_k(sender,init, ch_end, Tpause);
  send_serial(sender,':sens:func ''dist''',ch_end,Tpause);
  send_serial(sender,':sens:dist:type thd',ch_end,Tpause);
  send_serial(sender,concat(':sens:dist:harm ',nb_harm),ch_end,Tpause);
  send_serial(sender,':unit:dist perc',ch_end,Tpause);
  //send_serial(sender,':sens:dist:sfil none',ch_end,Tpause);
  send_serial(sender,concat(':SENS:DIST:RANG',range),ch_end,Tpause);
  //send_serial(sender,':sens:dist:lco 20',ch_end,Tpause);
  //send_serial(sender,':sens:dist:hco 20000',ch_end,Tpause);
  //send_serial(sender,':sens:dist:lco:stat on',ch_end,Tpause);
  //send_serial(sender,':sens:dist:hco:stat on',ch_end,Tpause);
  //send_serial(sender,concat(':sens:dist:dig ',digit),ch_end,Tpause);
  sleep(500);
  send_serial(sender,':fetch?',ch_end,Tpause);
  sleep(1000);
  resultat := FormatResult(sender,inrun);
end;

function FRQ (Sender:TObject; range:string; Tpause:integer; init:string; ch_end:string ):string;
{
range : " 0.1" / " 1" / " 10" / " 100" / " 1000" / " auto on"
         (un espace avant chaque choix dans la string)
Tpause : millisecond (0 - 254)
init : RSTCLS / RST / CLS
ch_end : CR / LF / CRLF / LFCR
}
var
  cpt:integer;
  resultat:string;
begin
  cpt:=0;
  init_k(sender,init, ch_end, Tpause);
  send_serial(sender,concat(':SENS:VOLT:AC',':RANG',range),ch_end,Tpause);
  send_serial(sender,':sens:func ''freq''',ch_end,Tpause);
  //send_serial(sender,concat(':sens:freq:thr:volt:rang',range),ch_end,Tpause);
  sleep(500);
  send_serial(sender,':fetch?',ch_end,Tpause);
  sleep(1000);
  resultat := FormatResult(sender,inrun);
  form1.e_fmes.Text:=resultat;
  form1.e_fmes.Refresh;
end;

function SNR(Sender:TObject; range:string; nb_harm:string; digit:string; Tpause:integer ;
               init:string; ch_end:string) : string;
{
range : " 0.1" / " 1" / " 10" / " 100" / " 750" / " auto on"
         (un espace avant chaque choix dans la string)
nb_harm : 2 - 64
digit : 4 - 7
Tpause : millisecond (0 - 254)
init : RSTCLS / RST / CLS
ch_end : CR / LF / CRLF / LFCR
}
var
  resultat:string;
begin
  init_k(sender,init, ch_end, Tpause);
  send_serial(sender,':sens:func ''dist''',ch_end,Tpause);
  send_serial(sender,':sens:dist:type SINAD',ch_end,Tpause);
  //send_serial(':SENSe:DISTortion:FREQuency 01000.000',ch_end,Tpause);
  send_serial(sender,concat(':sens:dist:harm ',nb_harm),ch_end,Tpause);
  send_serial(sender,concat(':sens:dist:rang',range),ch_end,Tpause);
  //send_serial(sender,concat(':sens:dist:dig ',digit),ch_end,Tpause);
  sleep(1000);
  send_serial(sender,':fetch?',ch_end,Tpause);
  sleep(1000);
  resultat := FormatResult(sender,inrun);
end;

function FormatResult (Sender:TObject; phase:string):string;
{
formatage de la sorties des mesures a un standard définie unique
vérification d'erreur
}
var
  str:string;
  value:extended;

function rcv_conv (txt:string):extended;
  begin
    rcv_conv:= 0;
    DecimalSeparator:='.';
    try
      rcv_conv:=StrToFloat(txt);
    except
       On E:Exception do
         ShowMessage (concat('Exception when converting :',txt,':',E.Message));
    end;
  end;

begin
  if not (phase='output') then
  begin
    if form1.lazserial1.Active then str:=form1.lazserial1.readData;
    form1.m_dialogue.Lines.Add(concat (str, '<<'));
    form1.m_dialogue.Refresh;
    delchars(str,CR);
    delchars(str,LF);
    case str of
      '+9.9E37'  :
      begin
        write(tfout,concat(phase,',','OVR+',','));
        FormatResult := 'OVR+';
        flush(tfout);
        if phase='vrms' then cal:=' 100';
      end;
      '-9.9E37'  :
      begin
        write(tfout,concat(phase,',','OVR-',','));
        FormatResult := 'OVR-';
        flush(tfout);
        if phase='vrms' then cal:=' 0.1';
      end;
      '0E00' :
      begin
        write(tfout,concat(phase,',','UND',','));
        FormatResult := 'UND';
        flush(tfout);
        if phase='vrms' then cal:=' 0.1'
      end;
      '' :
      begin
        write(tfout,concat(phase,',','EMPT',','));
        FormatResult := 'EMPT';
        flush(tfout);
        if phase='vrms' then cal:=' 100'
      end;
      else
      begin
        //delchars(str,'+');
        //delchars(str,'-');
        value:=round(rcv_conv(str)*1000)/1000;
        write(tfout,concat(phase,',',floattostr(value)),',');
        FormatResult:=floattostr(value);
        flush(tfout);
        if phase='vrms' then calibre(value);
      end;
    end;
    form1.e_calibre.Text := cal;
    form1.e_calibre.Refresh;
  end
  else
  begin
    writeln(tfout,'');
    write(tfout,concat('F_INC',',',inttostr(f),','));
  end;
end;

procedure init_k(Sender: TObject;level:string; ch_end:string; Tpause:integer);
{
réalise l'envoi de l'init en fonction du niveau demandé
level : RSTCLS / RST / CLS
ch_end : CR / LF / CRLF / LFCR
Tpause : millisecond (0 - 254)
}

begin
  if ((level='RSTCLS') or (level='RST')) then form1.lazserial1.WriteData('*RST'+ch_end); pause(Tpause);
  if ((level='RSTCLS') or (level='CLS')) then form1.lazserial1.WriteData('*CLS'+ch_end); pause(Tpause);
end;

procedure pause(dt:DWORD);
{
centralise le code de mise en attente
milli_s : 0 - 254
}
var
    tc : DWORD;
begin
    tc := GetTickCount;
    while (GetTickCount < tc + dt) and (not Application.Terminated) do
      Application.ProcessMessages;
end;


procedure send_serial(Sender: TObject;str:string;ch_end:string;milli_s:integer);
{
 Centralise le code et evite les mouvement memoire d'objets
 Sender : passage d'objet de form1
 str : chaine a envoyer 255 max longueur
 ch_end : caractere de fin de chaine   CR / LF / CRLF / LFCR
 pause : millisecond 0 - 254
}

begin
  form1.m_dialogue.Lines.Add(concat ('>>',str));
  form1.m_dialogue.Refresh;
  if form1.lazserial1.Active then form1.lazserial1.WriteData(concat(str,ch_end));
  pause (milli_s);
end;

function calibre(val:extended):string;
{
mesure : mesure de tension faite sous calibre 10v
calibre a utiliser ensuite pour les mesures tension et etc
" 0.1" / " 1" / " 10" /
}
begin
 cal := ' 100';
 val := val*1000;
 if (0 < val) and (val <= 60) then cal := ' 0.1';
 if (60 < val) and (val  <= 600) then cal := ' 1';
 if (600 < val) and (val <= 6000) then cal := ' 10';
 write(tfout,concat('CAL',',',cal,','));
end;

end.

