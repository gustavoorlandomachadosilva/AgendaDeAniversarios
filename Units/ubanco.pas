unit uBanco;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, uModel;

type
  TBanco = class
  private
    Conn: TSQLite3Connection;
    Trans: TSQLTransaction;
    Query: TSQLQuery;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Inicializar;
    procedure Inserir(nome: string; data: TDateTime);
    procedure Atualizar(id: Integer; nome: string; data: TDateTime);
    procedure Excluir(id: Integer);
    function Listar: TList;
  end;

implementation

constructor TBanco.Create;
begin
  Conn := TSQLite3Connection.Create(nil);
  Trans := TSQLTransaction.Create(nil);
  Query := TSQLQuery.Create(nil);

  Conn.Transaction := Trans;
  Query.DataBase := Conn;

  Conn.DatabaseName := 'agenda.db';
  Conn.Connected := True;
  Trans.Active := True;
end;

destructor TBanco.Destroy;
begin
  Query.Free;
  Trans.Free;
  Conn.Free;
  inherited Destroy;
end;

procedure TBanco.Inicializar;
begin
  Query.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS amigos (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'nome TEXT, ' +
    'data_nascimento DATE)';

  Query.ExecSQL;
  Trans.Commit;
  Trans.Active := True;
end;

procedure TBanco.Inserir(nome: string; data: TDateTime);
begin
  Query.SQL.Text :=
    'INSERT INTO amigos (nome, data_nascimento) VALUES (:nome, :data)';

  Query.ParamByName('nome').AsString := nome;
  Query.ParamByName('data').AsDate := data;

  Query.ExecSQL;
  Trans.Commit;
  Trans.Active := True;
end;

procedure TBanco.Atualizar(id: Integer; nome: string; data: TDateTime);
begin
  Query.SQL.Text :=
    'UPDATE amigos SET nome = :nome, data_nascimento = :data WHERE id = :id';

  Query.ParamByName('nome').AsString := nome;
  Query.ParamByName('data').AsDate := data;
  Query.ParamByName('id').AsInteger := id;

  Query.ExecSQL;
  Trans.Commit;
  Trans.Active := True;
end;

procedure TBanco.Excluir(id: Integer);
begin
  Query.SQL.Text :=
    'DELETE FROM amigos WHERE id = :id';

  Query.ParamByName('id').AsInteger := id;

  Query.ExecSQL;
  Trans.Commit;
  Trans.Active := True;
end;

function TBanco.Listar: TList;
var
  amigo: TAmigo;
begin
  Result := TList.Create;

  Query.SQL.Text :=
    'SELECT id, nome, data_nascimento FROM amigos ' +
    'ORDER BY ' +
    'CASE ' +
    'WHEN strftime(''%m-%d'', data_nascimento) >= strftime(''%m-%d'', ''now'') ' +
    'THEN strftime(''%m-%d'', data_nascimento) ' +
    'ELSE strftime(''%m-%d'', data_nascimento) || ''-next'' ' +
    'END';

  Query.Open;

  while not Query.EOF do
  begin
    amigo := TAmigo.Create;
    amigo.Id := Query.FieldByName('id').AsInteger;
    amigo.Nome := Query.FieldByName('nome').AsString;
    amigo.DataNascimento := Query.FieldByName('data_nascimento').AsDateTime;

    Result.Add(amigo);

    Query.Next;
  end;

  Query.Close;
end;

end.
