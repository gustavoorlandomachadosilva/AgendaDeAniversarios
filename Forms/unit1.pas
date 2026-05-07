unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  DateUtils, SQLite3Conn, SQLDB, DateTimePicker;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnSalvar: TButton;
    BtnEditar: TButton;
    BtnExcluir: TButton;
    DateNascimento: TDateTimePicker;
    EditNome: TEdit;
    LabelNome: TLabel;
    LabelNascimento: TLabel;
    LabelProximo: TLabel;
    ListBoxAmigos: TListBox;
    PanelTopo: TPanel;
    PanelCentro: TPanel;
    PanelRodape: TPanel;
    SQLiteConn: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;

    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnExcluirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListBoxAmigosClick(Sender: TObject);
  private
    procedure InicializarBanco;
    procedure CarregarDados;
    procedure AtualizarProximo;
    procedure VerificarAniversariosHoje;

    function DiasParaAniversario(dataNasc: TDateTime): Integer;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ ================= BANCO ================= }

procedure TForm1.InicializarBanco;
var
  CaminhoBanco: string;
begin
  CaminhoBanco := GetAppConfigDir(False);

  // cria a pasta se não existir
  if not DirectoryExists(CaminhoBanco) then
    CreateDir(CaminhoBanco);

  SQLiteConn.DatabaseName := CaminhoBanco + 'agenda.db';

  SQLiteConn.Connected := True;

  SQLTransaction1.Active := True;

  SQLQuery1.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS amigos (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'nome TEXT, ' +
    'data_nascimento DATE)';

  SQLQuery1.ExecSQL;

  SQLTransaction1.Commit;
  SQLTransaction1.Active := True;
end;

procedure TForm1.CarregarDados;
begin
  ListBoxAmigos.Clear;

  SQLQuery1.SQL.Text :=
    'SELECT id, nome, data_nascimento FROM amigos ' +
    'ORDER BY ' +
    'CASE ' +
    'WHEN strftime(''%m-%d'', data_nascimento) >= strftime(''%m-%d'', ''now'') ' +
    'THEN strftime(''%m-%d'', data_nascimento) ' +
    'ELSE strftime(''%m-%d'', data_nascimento) || ''-next'' ' +
    'END';

  SQLQuery1.Open;

  while not SQLQuery1.EOF do
  begin
    ListBoxAmigos.Items.AddObject(
      SQLQuery1.FieldByName('nome').AsString + ' - ' +
      DateToStr(SQLQuery1.FieldByName('data_nascimento').AsDateTime),
      TObject(PtrInt(SQLQuery1.FieldByName('id').AsInteger))
    );

    SQLQuery1.Next;
  end;

  SQLQuery1.Close;

  AtualizarProximo;
end;

{ ================= REGRAS ================= }

function TForm1.DiasParaAniversario(dataNasc: TDateTime): Integer;
var
  hoje, aniversario: TDateTime;
  ano, mes, dia: Word;
  l1, l2: Word;
begin
  hoje := Date;

  DecodeDate(hoje, ano, l1, l2);
  DecodeDate(dataNasc, l1, mes, dia);

  aniversario := EncodeDate(ano, mes, dia);

  if aniversario < hoje then
    aniversario := EncodeDate(ano + 1, mes, dia);

  Result := DaysBetween(hoje, aniversario);
end;

procedure TForm1.AtualizarProximo;
var
  i, dias, menor: Integer;
  texto, nome, dataStr: string;
  posicao: Integer;
  data: TDateTime;
  nomeProximo: string;
begin
  menor := 9999;
  nomeProximo := '';

  for i := 0 to ListBoxAmigos.Count - 1 do
  begin
    texto := ListBoxAmigos.Items[i];

    posicao := Pos(' - ', texto);

    nome := Copy(texto, 1, posicao - 1);
    dataStr := Copy(texto, posicao + 3, Length(texto));

    data := StrToDate(dataStr);
    dias := DiasParaAniversario(data);

    if dias < menor then
    begin
      menor := dias;
      nomeProximo := nome;
    end;
  end;

  if nomeProximo <> '' then
  begin
    if menor = 0 then
      LabelProximo.Caption := 'Próximo: ' + nomeProximo + ' (Hoje)'
    else if menor = 1 then
      LabelProximo.Caption := 'Próximo: ' + nomeProximo + ' em 1 dia'
    else
      LabelProximo.Caption := 'Próximo: ' + nomeProximo + ' em ' + IntToStr(menor) + ' dias';
  end
  else
    LabelProximo.Caption := 'Próximo aniversário: -';
end;

procedure TForm1.VerificarAniversariosHoje;
var
  hoje: TDateTime;
  mesHoje, diaHoje: Word;
  mes, dia: Word;
  i: Integer;
  texto, nome, dataStr: string;
  posicao: Integer;
  data: TDateTime;
  lista: string;
  a1, a2: Word;
begin
  hoje := Date;
  DecodeDate(hoje, a1, mesHoje, diaHoje);

  lista := '';

  for i := 0 to ListBoxAmigos.Count - 1 do
  begin
    texto := ListBoxAmigos.Items[i];

    posicao := Pos(' - ', texto);

    nome := Copy(texto, 1, posicao - 1);
    dataStr := Copy(texto, posicao + 3, Length(texto));

    data := StrToDate(dataStr);
    DecodeDate(data, a2, mes, dia);

    if (mes = mesHoje) and (dia = diaHoje) then
    begin
      if lista <> '' then
        lista := lista + LineEnding;

      lista := lista + nome;
    end;
  end;

  if lista <> '' then
    MessageDlg(
      'Aniversários de Hoje',
      'Hoje é aniversário de:' + LineEnding + LineEnding + lista,
      mtInformation,
      [mbOK],
      0
    );
end;

{ ================= EVENTOS ================= }

procedure TForm1.FormCreate(Sender: TObject);
begin
  InicializarBanco;
  CarregarDados;
  VerificarAniversariosHoje;
end;

procedure TForm1.BtnSalvarClick(Sender: TObject);
begin
  if EditNome.Text = '' then
  begin
    ShowMessage('Digite um nome');
    Exit;
  end;

  SQLQuery1.SQL.Text :=
    'INSERT INTO amigos (nome, data_nascimento) VALUES (:nome, :data)';

  SQLQuery1.ParamByName('nome').AsString := EditNome.Text;
  SQLQuery1.ParamByName('data').AsDate := DateNascimento.Date;

  SQLQuery1.ExecSQL;
  SQLTransaction1.Commit;
  SQLTransaction1.Active := True;

  CarregarDados;

  EditNome.Clear;
  DateNascimento.Date := Date;
end;

procedure TForm1.BtnEditarClick(Sender: TObject);
var
  id: Integer;
begin
  if ListBoxAmigos.ItemIndex = -1 then Exit;

  id := PtrInt(ListBoxAmigos.Items.Objects[ListBoxAmigos.ItemIndex]);

  SQLQuery1.SQL.Text :=
    'UPDATE amigos SET nome = :nome, data_nascimento = :data WHERE id = :id';

  SQLQuery1.ParamByName('nome').AsString := EditNome.Text;
  SQLQuery1.ParamByName('data').AsDate := DateNascimento.Date;
  SQLQuery1.ParamByName('id').AsInteger := id;

  SQLQuery1.ExecSQL;
  SQLTransaction1.Commit;
  SQLTransaction1.Active := True;

  CarregarDados;
end;

procedure TForm1.BtnExcluirClick(Sender: TObject);
var
  id: Integer;
begin
  if ListBoxAmigos.ItemIndex = -1 then Exit;

  if MessageDlg('Excluir registro?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    id := PtrInt(ListBoxAmigos.Items.Objects[ListBoxAmigos.ItemIndex]);

    SQLQuery1.SQL.Text := 'DELETE FROM amigos WHERE id = :id';
    SQLQuery1.ParamByName('id').AsInteger := id;

    SQLQuery1.ExecSQL;
    SQLTransaction1.Commit;
    SQLTransaction1.Active := True;

    CarregarDados;
  end;
end;

procedure TForm1.ListBoxAmigosClick(Sender: TObject);
var
  texto, nome, data: string;
  posicao: Integer;
begin
  if ListBoxAmigos.ItemIndex = -1 then Exit;

  texto := ListBoxAmigos.Items[ListBoxAmigos.ItemIndex];

  posicao := Pos(' - ', texto);

  nome := Copy(texto, 1, posicao - 1);
  data := Copy(texto, posicao + 3, Length(texto));

  EditNome.Text := nome;
  DateNascimento.Date := StrToDate(data);
end;

end.
