unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RegExpr;

type
  TValue = Record
     local : boolean;
     value : string;
     count : integer;
  end;
  TGlobal = class(TForm)
    MemoCode: TMemo;
    ButtonLoadFromFileCode: TButton;
    OpenDialogCode: TOpenDialog;
    ButtonMake: TButton;
    MemoResult: TMemo;
    procedure ButtonLoadFromFileCodeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonMakeClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
const
   types = '(long int|float|long float|double|bool|short int|unsigned int|char|int|void)';
var
  Global: TGlobal;
  RegExpro : TRegExpr;
  global_values : array of TValue;

implementation

{$R *.dfm}

function DeleteMultiLineComments(codeSrc : string):string; 
var
  regExpr : TRegExpr;
begin 
  regExpr := TRegExpr.Create;
  regExpr.ModifierM:= True;
  regExpr.Expression:='//.*?$';
  codeSrc:= regExpr.Replace(codeSrc,'');
  regExpr.ModifierS:= True;
  regExpr.Expression:='(/\*.*?\*/)';
  codeSrc:= regExpr.Replace(codeSrc,'');
  regExpr.ModifierS:= False;
  result := codeSrc;
  regExpr.Destroy;
end;

function DeleteElement(code : string; betweenOne, betweenTwo : string):string;
begin
   RegExpro.Expression := '.*('+ betweenOne +').*(' + betweenTwo + ').*';
   if RegExpro.Exec(code) then
   repeat
      Delete(code, RegExpro.MatchPos[1], RegExpro.MatchPos[2] - RegExpro.MatchPos[1] + length(betweenTwo));
   until not RegExpro.ExecNext;
   result := code;
end;

function DeleteOnLineComments(code : string):string;
begin
   RegExpro.Expression := '(/)/';
   if RegExpro.Exec(code) then
      Delete(Code, RegExpro.MatchPos[1], length(code) - RegExpro.MatchPos[1] + 1);
   result := code;
end;


procedure TGlobal.ButtonLoadFromFileCodeClick(Sender: TObject);
begin
   if OpenDialogCode.Execute then
      MemoCode.Lines.LoadFromFile(OpenDialogCode.FileName)
   else
      showmessage('Error');
end;

procedure SearchValue(code : string; NUMBER_VALUES : integer);
var
   i : integer;
begin
   for i := 0 to NUMBER_VALUES - 1 do
   begin
      RegExpro.Expression := '(\W|\[)' + global_values[i].value + '(\W|\])';
      if ( RegExpro.Exec(code) ) then
         if global_values[i].local = false then
            inc(global_values[i].count);
   end;
end;

procedure PrintData(var Aup : integer; module : string; NUMBER_VALUES : integer);
var
   i : integer;
begin
   with Global do
   begin
      MemoResult.Lines.Add(module);
      if NUMBER_VALUES <> 0 then
         for i := 0 to NUMBER_VALUES - 1 do
         begin
            if global_values[i].count > 0 then
            begin
               inc(Aup);
               MemoResult.Lines.Add('   ' + global_values[i].value + '  using');
            end
            else
               MemoResult.Lines.Add('   ' + global_values[i].value + '  not using');
            global_values[i].local := false;
            global_values[i].count := 0;
         end;
   end;
end;

procedure TGlobal.FormCreate(Sender: TObject);
begin
   RegExpro := TRegExpr.create;
end;

procedure TGlobal.ButtonMakeClick(Sender: TObject);
var
   counter : byte;
   i, Pup, Aup : integer;
   NUMBER_VALUES, j : byte;
   module : string;
begin
   MemoResult.Lines.Clear;
   Pup := 0;
   Aup := 0;
   counter := 0;
   module := '';
   number_values := 0;
   for i := 0 to MemoCode.Lines.Count - 1 do
   begin
       MemoCode.Lines[i] := DeleteElement(MemoCode.Lines[i],'"', '"');
   end;
   MemoCode.Lines.Text := DeleteMultiLineComments(MemoCode.Lines.Text);

   // �������� ������ � ������� ��� ������
   // ������� ��� ������������� �����������
   // ������� ��� ������������ �����������
   i := 0;
   if length(MemoCode.Text) > 0 then
   begin
   repeat
      if length(MemoCode.Lines[i]) <> 0 then
      begin
      MemoCode.Lines[i] := DeleteOnLineComments(MemoCode.Lines[i]);
      RegExpro.Expression := ' *' + types + ' +([a-zA-Z]+)\(.*\)';
      if RegExpro.Exec(MemoCode.Lines[i]) then
      begin
         Pup := Pup + NUMBER_VALUES;
         module := Trim(RegExpro.Match[2]);
         inc(i);
      end;
      RegExpro.Expression := '{';
      if RegExpro.Exec(MemoCode.Lines[i]) then
      begin
         inc(counter);
      end;
      RegExpro.Expression := '}';
      if RegExpro.Exec(MemoCode.Lines[i]) then
      begin
         dec(counter);
         if counter = 0 then
         begin
            PrintData(Aup, module, NUMBER_VALUES);
            module := '';
         end;
      end;

         RegExpro.Expression := types + ' +\W*([a-zA-Z_]+)\W';
         if RegExpro.Exec(MemoCode.Lines[i]) then
         begin
            RegExpro.Expression := '(\W)* *([a-zA-Z]+)\W';
            repeat
               if module <> '' then
               begin
                  if NUMBER_VALUES <> 0 then
                     for j := 0 to NUMBER_VALUES - 1 do
                        if Trim(RegExpro.Match[2]) = global_values[j].value then
                            global_values[j].local := true;
               end
               else
               begin
                  inc(NUMBER_VALUES);
                  setLength(global_values, NUMBER_VALUES);
                  global_values[NUMBER_VALUES - 1].value := Trim(RegExpro.Match[2]);
                  global_values[NUMBER_VALUES - 1].local := false;
                  global_values[NUMBER_VALUES - 1].count := -1;
               end;
            until not RegExpro.ExecNext();


      end;
      SearchValue(MemoCode.Lines[i],NUMBER_VALUES);
      end;
      inc(i);
   until (i = MemoCode.Lines.Count);
   if Pup <> 0 then
      MemoResult.Lines.Add('Aup = ' + inttostr(Aup) + '  Pup = ' + inttostr(Pup) + '  Rup = ' + FloatToStr(Aup / Pup))
   else
      MemoResult.Lines.Add('��� ���������� ����������');
   end;
   MemoResult.Lines.Add(IntToStr(NUMBER_VALUES));

end;

end.
