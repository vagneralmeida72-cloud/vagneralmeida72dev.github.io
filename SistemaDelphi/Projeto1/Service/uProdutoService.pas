unit uProdutoService;

interface

uses
  System.SysUtils, FireDAC.Comp.Client, LibFuncoes, uCadastroRepository,
  FireDAC.Stan.Param, Data.DB;

type
  TProdutoService = class
  public
    class function F_Validar(pNome: string; pPreco: Currency; pID: Integer;
      pConnection: TFDConnection): Boolean;
  end;

implementation

class function TProdutoService.F_Validar(pNome: string;
  pPreco: Currency; pID: Integer; pConnection: TFDConnection): Boolean;
var
  vQuery: TFDQuery;
begin
  Result := False;

  if pPreco < 0 then
  begin
    F_Mensagem('O preço não pode ser negativo!', tmAviso);
    Exit;
  end;

  vQuery := TFDQuery.Create(nil);
  try
    vQuery.Connection := pConnection;

    vQuery.SQL.Text :=
      'SELECT ID ' +
      'FROM PRODUTO ' +
      'WHERE UPPER(NOME) = UPPER(:NOME) ' +
      'AND ID <> :ID';

    vQuery.ParamByName('NOME').AsString := Trim(pNome);
    vQuery.ParamByName('ID').AsInteger := pID;

    vQuery.Open;

    if not vQuery.IsEmpty then
    begin
      F_Mensagem('Já existe um produto/serviço com este nome!', tmAviso);
      Exit;
    end;

  finally
    vQuery.Free;
  end;

  Result := True;
end;

end.
