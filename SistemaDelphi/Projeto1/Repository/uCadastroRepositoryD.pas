unit uCadastroRepositoryD;

interface

uses
  System.SysUtils,
  System.Variants,
  Data.DB,
  Datasnap.DBClient,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param;

type
  TCadastroRepository = class
  private
    FConnection: TFDConnection;

    procedure ValidarIdentificador(
      const pValor, pDescricao: string);

    function ExecutarInsercao(
      const pTabela: string;
      pDataSet: TDataSet): Variant;

    procedure ExecutarAlteracao(
      const pTabela: string;
      pDataSet: TDataSet);

    procedure DefinirIDNoDataSet(
      pDataSet: TDataSet;
      const pID: Variant);

    procedure PrepararChaveEstrangeira(
      pDetalhes: TClientDataSet;
      const pCampoFK: string;
      const pIDPrincipal: Variant);
    procedure PersistirDetalhes(const pTabelaDetalhe, pCampoFK: string;
      pDetalhes: TClientDataSet; const pIDPrincipal: Variant);

  public
    constructor Create(pConnection: TFDConnection);

    function F_Inserir(
      pTabela: string;
      pDataSet: TDataSet): Boolean;

    function F_Alterar(
      pTabela: string;
      pDataSet: TDataSet): Boolean;

    function F_Excluir(
      pTabela: string;
      pID: Variant): Boolean;

    procedure F_SalvarPrincipalDetalhes(
      const pTabelaPrincipal: string;
      pPrincipal: TDataSet;
      pDetalhes: TClientDataSet;
      const pTabelaDetalhe, pCampoFK: string);
  end;

implementation

constructor TCadastroRepository.Create(
  pConnection: TFDConnection);
begin
  inherited Create;

  if not Assigned(pConnection) then
    raise Exception.Create(
      'A conexão com o banco não foi informada.');

  FConnection := pConnection;
end;

procedure TCadastroRepository.ValidarIdentificador(
  const pValor, pDescricao: string);
var
  I: Integer;
  C: Char;
begin
  if Trim(pValor) = '' then
    raise Exception.Create(
      pDescricao + ' não foi informado.');

  for I := 1 to Length(pValor) do
  begin
    C := pValor[I];
    if not CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      raise Exception.Create(
        'Identificador inválido para ' +
        pDescricao + ': ' + pValor);
  end;
end;

function TCadastroRepository.ExecutarInsercao(
  const pTabela: string;
  pDataSet: TDataSet): Variant;
var
  Q: TFDQuery;
  I: Integer;
  F: TField;
  vCampos: string;
  vParametros: string;
begin
  ValidarIdentificador(pTabela, 'tabela');

  if not Assigned(pDataSet) then
    raise Exception.Create(
      'O DataSet não foi informado.');

  vCampos := '';
  vParametros := '';

  for I := 0 to pDataSet.FieldCount - 1 do
  begin
    F := pDataSet.Fields[I];

    if SameText(F.FieldName, 'ID') then
      Continue;

    if F.FieldKind <> fkData then
      Continue;

    ValidarIdentificador(F.FieldName, 'campo');

    if vCampos <> '' then
    begin
      vCampos := vCampos + ', ';
      vParametros := vParametros + ', ';
    end;

    vCampos := vCampos + F.FieldName;
    vParametros := vParametros + ':' + F.FieldName;
  end;

  if vCampos = '' then
    raise Exception.Create(
      'Nenhum campo disponível para inserção.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;

    Q.SQL.Text :=
      'INSERT INTO ' + pTabela +
      ' (' + vCampos + ')' +
      ' VALUES (' + vParametros + ')' +
      ' RETURNING ID';

    for I := 0 to pDataSet.FieldCount - 1 do
    begin
      F := pDataSet.Fields[I];

      if SameText(F.FieldName, 'ID') then
        Continue;

      if F.FieldKind <> fkData then
        Continue;

      if F.IsNull then
        Q.ParamByName(F.FieldName).Clear
      else
        Q.ParamByName(F.FieldName).Value := F.Value;
    end;

    Q.Open;

    if Q.IsEmpty or Q.FieldByName('ID').IsNull then
      raise Exception.Create(
        'O banco não retornou o ID gerado.');

    Result := Q.FieldByName('ID').Value;
  finally
    Q.Free;
  end;
end;

procedure TCadastroRepository.ExecutarAlteracao(
  const pTabela: string;
  pDataSet: TDataSet);
var
  Q: TFDQuery;
  I: Integer;
  F: TField;
  vSQL: string;
  vPrimeiro: Boolean;
  vID: Variant;
begin
  ValidarIdentificador(pTabela, 'tabela');

  if not Assigned(pDataSet) then
    raise Exception.Create(
      'O DataSet não foi informado.');

  if not Assigned(pDataSet.FindField('ID')) then
    raise Exception.Create(
      'O campo ID não foi encontrado.');

  vID := pDataSet.FieldByName('ID').Value;

  if VarIsNull(vID) or VarIsEmpty(vID) then
    raise Exception.Create(
      'O ID não foi informado.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;

    vSQL := 'UPDATE ' + pTabela + ' SET ';
    vPrimeiro := True;

    for I := 0 to pDataSet.FieldCount - 1 do
    begin
      F := pDataSet.Fields[I];

      if SameText(F.FieldName, 'ID') then
        Continue;

      if F.FieldKind <> fkData then
        Continue;

      ValidarIdentificador(F.FieldName, 'campo');

      if not vPrimeiro then
        vSQL := vSQL + ', ';

      vSQL := vSQL +
        F.FieldName + ' = :' + F.FieldName;

      vPrimeiro := False;
    end;

    if vPrimeiro then
      raise Exception.Create(
        'Não existem campos para atualizar.');

    vSQL := vSQL + ' WHERE ID = :P_ID';

    Q.SQL.Text := vSQL;

    for I := 0 to pDataSet.FieldCount - 1 do
    begin
      F := pDataSet.Fields[I];

      if SameText(F.FieldName, 'ID') then
        Continue;

      if F.FieldKind <> fkData then
        Continue;

      if F.IsNull then
        Q.ParamByName(F.FieldName).Clear
      else
        Q.ParamByName(F.FieldName).Value := F.Value;
    end;

    Q.ParamByName('P_ID').Value := vID;

    Q.ExecSQL;

    if Q.RowsAffected = 0 then
      raise Exception.Create(
        'Nenhum registro foi alterado.');
  finally
    Q.Free;
  end;
end;

procedure TCadastroRepository.DefinirIDNoDataSet(
  pDataSet: TDataSet;
  const pID: Variant);
var
  vEraSomenteLeitura: Boolean;
begin
  if not Assigned(pDataSet.FindField('ID')) then
    raise Exception.Create(
      'O DataSet principal precisa possuir o campo ID.');

  if pDataSet.State = dsBrowse then
    pDataSet.Edit;

  vEraSomenteLeitura :=
    pDataSet.FieldByName('ID').ReadOnly;

  try
    pDataSet.FieldByName('ID').ReadOnly := False;
    pDataSet.FieldByName('ID').Value := pID;
  finally
    pDataSet.FieldByName('ID').ReadOnly :=
      vEraSomenteLeitura;
  end;

  if pDataSet.State in [dsInsert, dsEdit] then
    pDataSet.Post;
end;

function TCadastroRepository.F_Inserir(
  pTabela: string;
  pDataSet: TDataSet): Boolean;
var
  vID: Variant;
  vTransacaoLocal: Boolean;
begin
  vTransacaoLocal := not FConnection.InTransaction;

  if vTransacaoLocal then
    FConnection.StartTransaction;

  try
    vID := ExecutarInsercao(pTabela, pDataSet);

    if vTransacaoLocal then
      FConnection.Commit;

    Result := True;
  except
    if vTransacaoLocal and FConnection.InTransaction then
      FConnection.Rollback;

    raise;
  end;
end;

function TCadastroRepository.F_Alterar(
  pTabela: string;
  pDataSet: TDataSet): Boolean;
var
  vTransacaoLocal: Boolean;
begin
  vTransacaoLocal := not FConnection.InTransaction;

  if vTransacaoLocal then
    FConnection.StartTransaction;

  try
    ExecutarAlteracao(pTabela, pDataSet);

    if vTransacaoLocal then
      FConnection.Commit;

    Result := True;
  except
    if vTransacaoLocal and FConnection.InTransaction then
      FConnection.Rollback;

    raise;
  end;
end;

function TCadastroRepository.F_Excluir(
  pTabela: string;
  pID: Variant): Boolean;
var
  Q: TFDQuery;
  vTransacaoLocal: Boolean;
begin
  ValidarIdentificador(pTabela, 'tabela');

  if VarIsNull(pID) or VarIsEmpty(pID) then
    raise Exception.Create(
      'O ID não foi informado.');

  vTransacaoLocal := not FConnection.InTransaction;

  if vTransacaoLocal then
    FConnection.StartTransaction;

  Q := TFDQuery.Create(nil);
  try
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'DELETE FROM ' + pTabela + ' WHERE ID = :P_ID';

      Q.ParamByName('P_ID').Value := pID;
      Q.ExecSQL;

      Result := Q.RowsAffected > 0;

      if vTransacaoLocal then
        FConnection.Commit;
    except
      if vTransacaoLocal and FConnection.InTransaction then
        FConnection.Rollback;

      raise;
    end;
  finally
    Q.Free;
  end;
end;


procedure TCadastroRepository.PrepararChaveEstrangeira(
  pDetalhes: TClientDataSet;
  const pCampoFK: string;
  const pIDPrincipal: Variant);
var
  vIDField: TField;
  vFKField: TField;
begin
  if not Assigned(pDetalhes) or not pDetalhes.Active then
    raise Exception.Create(
      'O DataSet de detalhes não está ativo.');

  vFKField := pDetalhes.FindField(pCampoFK);
  if not Assigned(vFKField) then
    raise Exception.Create(
      'O campo de relacionamento "' + pCampoFK +
      '" não existe nos detalhes.');

  vIDField := pDetalhes.FindField('ID');
  if not Assigned(vIDField) then
    raise Exception.Create(
      'O DataSet de detalhes precisa possuir o campo ID.');

  pDetalhes.First;

  while not pDetalhes.Eof do
  begin
    vIDField := pDetalhes.FieldByName('ID');
    vFKField := pDetalhes.FieldByName(pCampoFK);

    if vIDField.IsNull or (vIDField.AsInteger = 0) then
    begin
      if pDetalhes.State = dsBrowse then
        pDetalhes.Edit;

      vFKField.Value := pIDPrincipal;
      pDetalhes.Post;
    end;

    pDetalhes.Next;
  end;
end;


procedure TCadastroRepository.F_SalvarPrincipalDetalhes(
  const pTabelaPrincipal: string;
  pPrincipal: TDataSet;
  pDetalhes: TClientDataSet;
  const pTabelaDetalhe, pCampoFK: string);
var
  vEstadoOriginal: TDataSetState;
  vID: Variant;
begin
  ValidarIdentificador(
    pTabelaPrincipal, 'tabela principal');

  ValidarIdentificador(
    pTabelaDetalhe, 'tabela de detalhes');

  ValidarIdentificador(
    pCampoFK, 'campo de relacionamento');

  if not Assigned(pPrincipal) then
    raise Exception.Create(
      'O DataSet principal não foi informado.');

  if not Assigned(pDetalhes) or not pDetalhes.Active then
    raise Exception.Create(
      'O DataSet de detalhes não está ativo.');

  if not FConnection.Connected then
    raise Exception.Create(
      'A conexão com o banco não está aberta.');

  if not Assigned(pPrincipal.FindField('ID')) then
    raise Exception.Create(
      'O cadastro principal precisa possuir o campo ID.');

  if pPrincipal.State = dsInsert then
    vEstadoOriginal := dsInsert
  else if pPrincipal.State = dsEdit then
    vEstadoOriginal := dsEdit
  else
    raise Exception.Create(
      'O cadastro principal precisa estar em inclusão ou edição.');

  pPrincipal.Post;

  FConnection.StartTransaction;
  try
    if vEstadoOriginal = dsInsert then
    begin
      vID := ExecutarInsercao(
        pTabelaPrincipal, pPrincipal);

      DefinirIDNoDataSet(pPrincipal, vID);
    end
    else
    begin
      ExecutarAlteracao(
        pTabelaPrincipal, pPrincipal);

      vID := pPrincipal.FieldByName('ID').Value;
    end;

    if VarIsNull(vID) or VarIsEmpty(vID) then
      raise Exception.Create(
        'Não foi possível obter o ID da venda.');

    PersistirDetalhes(
      pTabelaDetalhe,
      pCampoFK,
      pDetalhes,
      vID);

    FConnection.Commit;

    pDetalhes.MergeChangeLog;
  except
    if FConnection.InTransaction then
      FConnection.Rollback;

    raise;
  end;
end;

procedure TCadastroRepository.PersistirDetalhes(
  const pTabelaDetalhe, pCampoFK: string;
  pDetalhes: TClientDataSet;
  const pIDPrincipal: Variant);
var
  Q: TFDQuery;
  vStatusFilter: TUpdateStatusSet;
  vIDDetalhe: Variant;
  vIDField: TField;
  vEraSomenteLeitura: Boolean;
begin
  if not Assigned(pDetalhes) or not pDetalhes.Active then
    raise Exception.Create(
      'O DataSet de detalhes não está ativo.');

  PrepararChaveEstrangeira(
    pDetalhes, pCampoFK, pIDPrincipal);

  vStatusFilter := pDetalhes.StatusFilter;

  try
    { Inclusões e alterações }
    pDetalhes.StatusFilter := [usInserted, usModified];
    pDetalhes.First;

    while not pDetalhes.Eof do
    begin
      case pDetalhes.UpdateStatus of
        usInserted:
          begin
            vIDDetalhe := ExecutarInsercao(
              pTabelaDetalhe, pDetalhes);

            { Guarda o ID gerado para futuras edições }
            vIDField := pDetalhes.FindField('ID');

            if Assigned(vIDField) then
            begin
              vEraSomenteLeitura := vIDField.ReadOnly;

              try
                vIDField.ReadOnly := False;
                pDetalhes.Edit;
                vIDField.Value := vIDDetalhe;
                pDetalhes.Post;
              finally
                vIDField.ReadOnly := vEraSomenteLeitura;
              end;
            end;
          end;

        usModified:
          ExecutarAlteracao(
            pTabelaDetalhe, pDetalhes);
      end;

      pDetalhes.Next;
    end;

    { Exclusões }
    pDetalhes.StatusFilter := [usDeleted];
    pDetalhes.First;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text :=
        'DELETE FROM ' + pTabelaDetalhe +
        ' WHERE ID = :P_ID';

      while not pDetalhes.Eof do
      begin
        vIDField := pDetalhes.FindField('ID');

        if not Assigned(vIDField) or vIDField.IsNull then
          raise Exception.Create(
            'Não foi possível identificar o item excluído.');

        Q.ParamByName('P_ID').Value := vIDField.Value;
        Q.ExecSQL;

        pDetalhes.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    pDetalhes.StatusFilter := vStatusFilter;
  end;
end;

end.

