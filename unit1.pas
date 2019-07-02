unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, LazSerial,
  strutils, LResources, Spin, ComCtrls, fileinfo, math;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button11: TButton;
    Button2: TButton;
    Button3: TButton;
    cb_auto: TCheckBox;
    CheckBox1: TCheckBox;
    combobox2: TComboBox;
    e_vrms: TEdit;
    e_fec: TEdit;
    e_calibre: TEdit;
    e_fmes: TEdit;
    Label10: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    combobox1: TComboBox;
    FloatSpinEdit1: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LazSerial1: TLazSerial;
    m_dialogue: TMemo;
    ProgressBar1: TProgressBar;
    SaveDialog1: TSaveDialog;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    SpinEdit3: TSpinEdit;
    procedure Button11Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure combobox1Change(Sender: TObject);
    procedure combobox1EditingDone(Sender: TObject);
    procedure combobox2Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LazSerial1RxData(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure SpinEdit2Change(Sender: TObject);

private
     { private declarations }
public
    { public declarations }
end;

var
  Form1: TForm1;
  tfOut: TextFile;
  inrun:string;
  cpt :integer;
  wait:boolean;
  cal:string;
  f:int64;
  C_FNAME:string;
  O_imp :string;
  I_imp :string;
  pas:integer;

const
  CR=#13;
  LF=#10;
  CRLF=#13#10;
  LFCR=#10#13;

implementation

uses keithley;
{$R *.lfm}

{ TForm1 }
{ Corrections TODO: progress bar et vérification de la disponibilité du port
  avant ouverture}

procedure TForm1.Button11Click(Sender: TObject);

var
  f_prec:int64;
  f_real:extended ;
  go_out:byte;
  resultat_mesure:string;
begin
  if pas = 0 then
  begin
    AssignFile(tfOut, C_FNAME);
    rewrite(tfOut);
    flush(tfout);
    if not lazserial1.Active then lazserial1.Active := true;
    f := spinedit1.Value;
  end;
  if cb_auto.Checked = true then
  begin
    button11.enabled := false;
    go_out := 0;
    repeat
//------------------------------------------------------------
      inrun:='output';
      output(sender,floattostr(FloatSpinEdit1.value),inttostr(f),O_imp,'on',300,'NONE',CRLF);
//------------------------------------------------------------
      inrun:='vrms';
      vrms(sender,'ac',' 10','1','3',300,'NONE',CRLF);
//------------------------------------------------------------
      inrun:='vrms_cal';
      vrms(sender,'ac',cal,'1','3',300,'NONE',CRLF);
//------------------------------------------------------------
      inrun:='thd';
      thd(sender,cal,'10','7',300,'NONE',CRLF);
//------------------------------------------------------------
      inrun:=('frq');
      frq(sender,cal,300,'NONE',CRLF);
//------------------------------------------------------------
      inrun:=('snr');
      SNR(sender,cal,'10','7',300,'NONE',CRLF);
//------------------------------------------------------------
      f_prec := f;
      f_real:=f;
      repeat
        f_real:=f_real+((f_real*spinedit3.Value) / 100);
      until f_real >= f_prec+1;
      f:=round(f_real);
      if go_out=1 then inc(go_out);
      if ((f > spinedit2.Value) and (go_out=0)) then
      begin
        f:= spinedit2.Value;
        go_out := 1;
      end;
      if cb_auto.Checked = false then go_out:=3;
      progressbar1.Position:= trunc(20*log10(f));
      progressbar1.Update;
      form1.Refresh;
      form1.Repaint;
      form1.Update;
    until go_out>=2;
    button11.enabled:=true;
    CloseFile(tfOut);
  end
  else
  begin
//------------------------------------------------------------
    inrun:='output';
    output(sender,floattostr(FloatSpinEdit1.value),inttostr(f),O_imp,'on',300,'NONE',CRLF);
//------------------------------------------------------------
    inrun:='vrms';
    vrms(sender,'ac',' 10','1','3',300,'NONE',CRLF);
//------------------------------------------------------------
    inrun:='vrms_cal';
    vrms(sender,'ac',cal,'1','3',300,'NONE',CRLF);
//------------------------------------------------------------
    inrun:='thd';
    thd(sender,cal,'10','7',300,'NONE',CRLF);
//------------------------------------------------------------
    inrun:=('frq');
    frq(sender,cal,300,'NONE',CRLF);
//------------------------------------------------------------
    inrun:=('snr');
    SNR(sender,cal,'10','7',300,'NONE',CRLF);
//------------------------------------------------------------
    f_real:=f;
    f_real:=f_real+((f_real*spinedit3.Value) / 100);
    f:=round(f_real);
    if (f > spinedit2.Value) then
    begin
      f:= spinedit2.Value;
    end;
    progressbar1.Position:= trunc(f);
    progressbar1.Update;
    button11.Caption:='Next';
    form1.Refresh;
    form1.Repaint;
    form1.Update;
    inc(pas);
  end;
//------------------------------------------------------------
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Lazserial1.ShowSetupDialog;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
TNAME:string;
begin
  //ShowMessage('Une erreur normal c''est produite ....');
 savedialog1.execute;
 TNAME := savedialog1.FileName ;
 if not (TNAME = '') then C_FNAME := TNAME
  else ShowMessage ('Le ficher est localisé dans le repertoire du programme');
end;

procedure TForm1.Button3Click(Sender: TObject);

begin
    if lazserial1.Active then
    begin
      lazserial1.active:=false;
      //lazserial1.Close;
      //lazserial1.Free;
    end;
    cb_auto.Checked:= false;
    //CloseFile(tfOut);
    //form1.Close;
    //form1.Destroy;
    //Application.Destroy;
    Close;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  //m_dialogue.Clear;
end;

procedure TForm1.CheckBox1Change(Sender: TObject);
begin
  if CheckBox1.Checked = true then
  begin
    e_fec.Visible:=true;
    e_calibre.Visible:=true;
    e_vrms.Visible:=true;
    e_fmes.Visible:=true;
    m_dialogue.Visible:=true;
    Label7.Visible:=true;
    Label8.Visible:=true;
    Label9.Visible:=true;
    Label10.Visible:=true;
  end
  else
  begin
    e_fec.Visible:=false;
    e_calibre.Visible:=false;
    e_vrms.Visible:=false;
    e_fmes.Visible:=false;
    m_dialogue.Visible:=false;
    Label7.Visible:=false;
    Label8.Visible:=false;
    Label9.Visible:=false;
    Label10.Visible:=false;
    end;
end;

procedure TForm1.combobox1Change(Sender: TObject);
begin
    case ComboBox1.ItemIndex of
      0: O_imp:='HIZ';
      1: O_imp:='OHM600';
      2: O_imp:='OHM50';
    end;
label5.Caption:=concat('OUTPUT',' : ',O_imp);
end;

procedure TForm1.combobox1EditingDone(Sender: TObject);
begin

end;

procedure TForm1.combobox2Change(Sender: TObject);
begin
  case ComboBox2.ItemIndex of
    0: I_imp:='HIZ';
    1: I_imp:='600';
    2: I_imp:='50';
  end;
label6.Caption:=concat('INPUT',' : ',I_imp);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
end;

procedure TForm1.FormCreate(Sender: TObject);

begin
  cpt:=0;
  pas:=0;
  C_FNAME := 'textfile.txt';
  O_imp := 'HIZ';
  I_imp := 'HIZ';
  progressbar1.Min:=trunc(20*log10(spinedit1.Value));
  progressbar1.Max:=trunc(20*log10(spinedit2.Value));
  progressbar1.Position:=progressbar1.Min;
  m_dialogue.Text := '';
  e_fec.Text := '';
  e_calibre.Text:='';
  e_vrms.Text:='';
  e_fmes.Text:='';
  //form1.Caption:=concat ('Qualification Audio REV : ',inttostr(form1.sh));
  //form1.Caption:=application.Title+' version '+BundleVer;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
end;

procedure TForm1.LazSerial1RxData(Sender: TObject);

begin

end;

procedure TForm1.SpinEdit1Change(Sender: TObject);
begin
  progressbar1.Min:=trunc(20*log10(spinedit1.Value));
  progressbar1.Max:=trunc(20*log10(spinedit2.Value));
  progressbar1.Position:=progressbar1.Min;
end;

procedure TForm1.SpinEdit2Change(Sender: TObject);
begin
  progressbar1.Min:=trunc(20*log10(spinedit1.Value));
  progressbar1.Max:=trunc(20*log10(spinedit2.Value));
  progressbar1.Position:=progressbar1.Min;
end;

end.

