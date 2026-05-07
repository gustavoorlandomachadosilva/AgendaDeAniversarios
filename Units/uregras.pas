unit uRegras;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, DateUtils;

function DiasParaAniversario(dataNasc: TDateTime): Integer;

implementation

function DiasParaAniversario(dataNasc: TDateTime): Integer;
var
  hoje, aniversario: TDateTime;
  ano, mes, dia: Word;
  lixo1, lixo2: Word;
begin
  hoje := Date;

  DecodeDate(hoje, ano, lixo1, lixo2);
  DecodeDate(dataNasc, lixo1, mes, dia);

  aniversario := EncodeDate(ano, mes, dia);

  if aniversario < hoje then
    aniversario := EncodeDate(ano + 1, mes, dia);

  Result := DaysBetween(hoje, aniversario);
end;

end.
