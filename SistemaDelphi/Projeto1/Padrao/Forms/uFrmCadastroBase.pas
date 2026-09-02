unit uFrmCadastroBase;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.ImageList, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ImgList,
  Vcl.Grids, Vcl.DBGrids, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Data.DB,
  Datasnap.DBClient, Datasnap.Provider, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async,
  FireDAC.DApt;

type
  TfrmCadastroBase = class(TForm)
    pnlBotoes: TPanel;
    pgcCadastro: TPageControl;
    tsPesquisa: TTabSheet;
    tsCadastro: TTabSheet;
    pnlCadastro: TPanel;
    dbgCadastro: TDBGrid;
    cdsCadastro: TClientDataSet;
    dsCadastro: TDataSource;
    qryCadastro: TFDQuery;
    dspCadastro: TDataSetProvider;
    btnNovo: TSpeedButton;
    imgIcon: TImageList;
    btnFechar: TSpeedButton;
    btnExcluir: TSpeedButton;
    btnAlterar: TSpeedButton;

    procedure FormCreate(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure dsCadastroStateChange(Sender: TObject);
    procedure dbgCadastroTitleClick(Column: TColumn);
    procedure FormShow(Sender: TObject);

  private
    FSQLOriginal, FTabela: string;
    FConfigurado: Boolean;
    procedure P_AtualizarBotoes;
    procedure P_AcaoBotoes(pEdicao: Boolean);
    procedure P_MostrarCadastro;
    procedure P_MostrarPesquisa;
    procedure P_RecarregarDados;
    procedure P_PesquisarColuna(pField: TField; pTexto: string);

    function F_MontarSQLPesquisa(pSQL, pCampo: string): string;
    function F_CriarQuery: TFDQuery;
    function F_InserirRegistro: Boolean;
    function F_AlterarRegistro: Boolean;
    function F_ExcluirRegistro: Boolean;
    function F_ValorCampo(pField: TField): Variant;
  public
    procedure P_ConfigurarCadastro(pSQL, pTabela: string);
  end;

var
  frmCadastroBase: TfrmCadastroBase;

implementation

{$R *.dfm}

uses
  uDM;

procedure TfrmCadastroBase.FormCreate(Sender: TObject);
begin
  inherited;
  if not Assigned(DM) then
    raise Exception.Create('DataModule DM não foi criado.');

  if not DM.FDConnection.Connected then
    DM.FDConnection.Connected := True;

  qryCadastro.Connection := DM.FDConnection;

  cdsCadastro.Close;
  qryCadastro.Close;

  tsPesquisa.TabVisible  := True;
  tsCadastro.TabVisible  := False;
  pgcCadastro.ActivePage := tsPesquisa;

  P_AcaoBotoes(False);
  P_AtualizarBotoes;
end;

procedure TfrmCadastroBase.FormShow(Sender: TObject);
var
  vTabela: string;
begin
  if FConfigurado then
    Exit;

  vTabela := Copy(ClassName, 5, Length(ClassName));

  vTabela := UpperCase(vTabela);

  FTabela := vTabela;

  FSQLOriginal := 'SELECT * FROM ' + FTabela + ' ORDER BY ID';

  P_ConfigurarCadastro(FSQLOriginal, FTabela);

  FConfigurado := True;
end;

procedure TfrmCadastroBase.P_ConfigurarCadastro(pSQL, pTabela: string);
begin
  if Trim(pSQL) = '' then
    raise Exception.Create('O SQL do cadastro não foi informado.');

  if Trim(pTabela) = '' then
    raise Exception.Create('A tabela do cadastro não foi informada.');

  FTabela      := Trim(pTabela);
  FSQLOriginal := Trim(pSQL);

  cdsCadastro.Close;
  qryCadastro.Close;

  qryCadastro.SQL.Clear;
  qryCadastro.SQL.Text := FSQLOriginal;
  qryCadastro.Open;
  cdsCadastro.Open;
end;

procedure TfrmCadastroBase.btnNovoClick(Sender: TObject);
var
  I: Integer;
  F: TField;
begin
  // NOVO
  if cdsCadastro.State = dsBrowse then
  begin
    try
      cdsCadastro.Append;

      for I := 0 to cdsCadastro.FieldCount - 1 do
      begin
        F := cdsCadastro.Fields[I];

        if SameText(F.FieldName, 'ID') then
          Continue;

        if F.FieldKind <> fkData then
          Continue;

        if not F.ReadOnly then
          F.Clear;
      end;
      P_MostrarCadastro;
      Exit;
    except
      on E: Exception do
      begin
        ShowMessage('Erro ao iniciar novo registro:' + sLineBreak +
          E.ClassName + sLineBreak + E.Message);
      end;
    end;
  end;

  // SALVAR
  if cdsCadastro.State in [dsInsert, dsEdit] then
  begin
    try
      cdsCadastro.UpdateRecord;
      if cdsCadastro.State = dsInsert then
      begin
        if F_InserirRegistro then
        begin
          cdsCadastro.Cancel;
          P_RecarregarDados;
          P_MostrarPesquisa;
          ShowMessage('Registro salvo com sucesso!');
        end;
      end
      else
      begin
        if F_AlterarRegistro then
        begin
          cdsCadastro.Cancel;
          P_RecarregarDados;
          P_MostrarPesquisa;
          ShowMessage('Registro alterado com sucesso!');
        end;
      end;
    except
      on E: Exception do
      begin
        ShowMessage('Erro ao salvar:' + sLineBreak + E.ClassName +
          sLineBreak + E.Message);
      end;
    end;
  end;
end;

procedure TfrmCadastroBase.btnAlterarClick(Sender: TObject);
var
  vID: Variant;
begin
  //ALTERAR
  if cdsCadastro.State = dsBrowse then
  begin
    if cdsCadastro.IsEmpty then
    begin
      ShowMessage('Selecione um registro para alterar.');
      Exit;
    end;

    vID := cdsCadastro.FieldByName('ID').Value;
    try
      cdsCadastro.Edit;
      if not VarSameValue(cdsCadastro.FieldByName('ID').Value, vID) then
      begin
        cdsCadastro.Cancel;
        ShowMessage('Não foi possível selecionar o registro.');
        Exit;
      end;
      P_MostrarCadastro;
    except
      on E: Exception do
      begin
        ShowMessage('Erro ao editar:' + sLineBreak + E.ClassName +
          sLineBreak + E.Message);
      end;
    end;
    Exit;
  end;

  // CANCELAR
  if cdsCadastro.State in [dsInsert, dsEdit] then
  begin
    try
      cdsCadastro.Cancel;
      P_MostrarPesquisa;
    except
      on E: Exception do
      begin
        ShowMessage('Erro ao cancelar:' + sLineBreak + E.ClassName +
          sLineBreak + E.Message);
      end;
    end;
  end;
end;

procedure TfrmCadastroBase.btnExcluirClick(Sender: TObject);
begin
  if cdsCadastro.State <> dsBrowse then
    Exit;

  if cdsCadastro.IsEmpty then
  begin
    ShowMessage('Selecione um registro para excluir.');
    Exit;
  end;

  if MessageDlg('Deseja realmente excluir este registro?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;
  try
    if F_ExcluirRegistro then
    begin
      P_RecarregarDados;
      ShowMessage('Registro excluído com sucesso!');
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao excluir:' + sLineBreak + E.ClassName +
        sLineBreak + E.Message);
    end;
  end;
end;

function TfrmCadastroBase.F_CriarQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := DM.FDConnection;
end;

function TfrmCadastroBase.F_ValorCampo(pField: TField): Variant;
begin
  if pField.IsNull then
    Result := Null
  else
    Result := pField.Value;
end;

function TfrmCadastroBase.F_InserirRegistro: Boolean;
var
  Q: TFDQuery;
  I: Integer;
  F: TField;
  vCampos, vParametros: string;
begin
  vCampos     := '';
  vParametros := '';

  for I := 0 to cdsCadastro.FieldCount - 1 do
  begin
    F := cdsCadastro.Fields[I];

    // NÃO grava ID
    if SameText(F.FieldName, 'ID') then
      Continue;

    // Ignora campos calculados
    if F.FieldKind <> fkData then
      Continue;

    if vCampos <> '' then
    begin
      vCampos     := vCampos + ', ';
      vParametros := vParametros + ', ';
    end;

    vCampos     := vCampos + F.FieldName;
    vParametros := vParametros + ':' + F.FieldName;
  end;

  if vCampos = '' then
    raise Exception.Create('Nenhum campo para inserir.');

  Q := F_CriarQuery;
  try
    Q.SQL.Text := 'INSERT INTO ' + FTabela +
      ' (' + vCampos + ') VALUES (' + vParametros +')';

    for I := 0 to cdsCadastro.FieldCount - 1 do
    begin
      F := cdsCadastro.Fields[I];
      if SameText(F.FieldName, 'ID') then
        Continue;

      if F.FieldKind <> fkData then
        Continue;

      Q.ParamByName(F.FieldName).Value := F_ValorCampo(F);
    end;

    Q.ExecSQL;
    Result := True;
  finally
    Q.Free;
  end;
end;

function TfrmCadastroBase.F_AlterarRegistro: Boolean;
var
  Q: TFDQuery;
  I: Integer;
  F: TField;
  vID: Variant;
  vSQL: string;
  vPrimeiro: Boolean;
begin
  cdsCadastro.UpdateRecord;

  vID := cdsCadastro.FieldByName('ID').Value;
  Q   := F_CriarQuery;
  try
    vSQL := 'UPDATE ' + FTabela + ' SET ';
    vPrimeiro := True;

    for I := 0 to cdsCadastro.FieldCount - 1 do
    begin
      F := cdsCadastro.Fields[I];
      if SameText(F.FieldName, 'ID') then
        Continue;

      if F.FieldKind <> fkData then
        Continue;

      if not vPrimeiro then
        vSQL := vSQL + ', ';

      vSQL := vSQL + F.FieldName + ' = :' + F.FieldName;
      vPrimeiro := False;
    end;

    vSQL := vSQL + ' WHERE ID = :ID';
    Q.SQL.Text := vSQL;

    for I := 0 to cdsCadastro.FieldCount - 1 do
    begin
      F := cdsCadastro.Fields[I];

      if SameText(F.FieldName, 'ID') then
        Continue;

      if F.FieldKind <> fkData then
        Continue;

      if F.IsNull then
        Q.ParamByName(F.FieldName).Clear
      else
        Q.ParamByName(F.FieldName).Value := F.Value;
    end;

    Q.ParamByName('ID').Value := vID;
    Q.ExecSQL;

    if Q.RowsAffected = 0 then
      raise Exception.Create('Nenhum registro foi alterado.' + sLineBreak +
        'ID: ' + VarToStr(vID));

    Result := True;
  finally
    Q.Free;
  end;
end;

function TfrmCadastroBase.F_ExcluirRegistro: Boolean;
var
  Q: TFDQuery;
  vID: Variant;
begin
  vID := cdsCadastro.FieldByName('ID').Value;
  Q   := F_CriarQuery;
  try
    Q.SQL.Text := 'DELETE FROM ' + FTabela + ' WHERE ID = :ID';
    Q.ParamByName('ID').Value := vID;
    Q.ExecSQL;
    Result := True;
  finally
    Q.Free;
  end;
end;

procedure TfrmCadastroBase.P_RecarregarDados;
begin
  cdsCadastro.Close;
  qryCadastro.Close;
  qryCadastro.SQL.Text := FSQLOriginal;
  qryCadastro.Open;
  cdsCadastro.Open;
end;

procedure TfrmCadastroBase.P_AtualizarBotoes;
begin
  if not Assigned(cdsCadastro) then
    Exit;

  btnExcluir.Enabled := (cdsCadastro.State = dsBrowse) and not cdsCadastro.IsEmpty;
  btnFechar.Enabled := cdsCadastro.State = dsBrowse;
end;

procedure TfrmCadastroBase.P_AcaoBotoes(pEdicao: Boolean);
begin
  if pEdicao then
  begin
    btnNovo.Caption       := 'Salvar';
    btnAlterar.Caption    := 'Cancelar';
    btnNovo.ImageIndex    := 3;
    btnAlterar.ImageIndex := 5;
  end
  else
  begin
    btnNovo.Caption       := 'Novo';
    btnAlterar.Caption    := 'Alterar';
    btnNovo.ImageIndex    := 0;
    btnAlterar.ImageIndex := 1;
  end;
end;

procedure TfrmCadastroBase.P_MostrarCadastro;
begin
  tsPesquisa.TabVisible  := False;
  tsCadastro.TabVisible  := True;
  pgcCadastro.ActivePage := tsCadastro;

  P_AcaoBotoes(True);
  P_AtualizarBotoes;
end;

procedure TfrmCadastroBase.P_MostrarPesquisa;
begin
  tsPesquisa.TabVisible  := True;
  tsCadastro.TabVisible  := False;
  pgcCadastro.ActivePage := tsPesquisa;

  P_AcaoBotoes(False);
  P_AtualizarBotoes;
end;

procedure TfrmCadastroBase.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCadastroBase.dsCadastroStateChange(Sender: TObject);
begin
  P_AtualizarBotoes;
end;

procedure TfrmCadastroBase.dbgCadastroTitleClick(Column: TColumn);
var
  vField: TField;
  vTexto: string;
begin
  vField := Column.Field;

  if not Assigned(vField) then
    Exit;

  if Trim(vField.FieldName) = '' then
    Exit;

  vTexto := InputBox('Pesquisar', 'Pesquisar em ' + vField.DisplayLabel, '');

  // Se deixar vazio, volta para o SELECT original
  if Trim(vTexto) = '' then
  begin
    cdsCadastro.Close;
    qryCadastro.Close;

    qryCadastro.SQL.Text := FSQLOriginal;

    qryCadastro.Open;
    cdsCadastro.Open;

    Exit;
  end;

  P_PesquisarColuna(vField, vTexto);
end;

procedure TfrmCadastroBase.P_PesquisarColuna(pField: TField;pTexto: string);
var
  vCampo: string;
begin
  if not Assigned(pField) then
    Exit;

  vCampo := Trim(pField.FieldName);

  if vCampo = '' then
    Exit;

  if Trim(pTexto) = '' then
  begin
    cdsCadastro.Close;
    qryCadastro.Close;

    qryCadastro.SQL.Text := FSQLOriginal;

    qryCadastro.Open;
    cdsCadastro.Open;

    Exit;
  end;

  cdsCadastro.Close;
  qryCadastro.Close;

  qryCadastro.SQL.Text := F_MontarSQLPesquisa(FSQLOriginal, vCampo);
  qryCadastro.ParamByName('PESQUISA').AsString := '%' + Trim(pTexto) + '%';

  qryCadastro.Open;
  cdsCadastro.Open;
end;

function TfrmCadastroBase.F_MontarSQLPesquisa(pSQL,pCampo: string): string;
var
  vSQL, vOrder: string;
  vPosOrder: Integer;
begin
  vSQL := Trim(pSQL);
  pCampo := Trim(pCampo);

  if pCampo = '' then
  begin
    Result := vSQL;
    Exit;
  end;

  // Remove ; do final
  if (vSQL <> '') and (vSQL[Length(vSQL)] = ';') then
    Delete(vSQL, Length(vSQL), 1);

  vSQL := Trim(vSQL);

  vPosOrder := Pos('ORDER BY', UpperCase(vSQL));

  if vPosOrder > 0 then
  begin
    vOrder := Trim(Copy(vSQL, vPosOrder, Length(vSQL)));
    vSQL   := Trim(Copy(vSQL, 1, vPosOrder - 1));
    Result := vSQL + ' WHERE ' + pCampo + ' LIKE :PESQUISA ' + vOrder;
  end
  else
    Result := vSQL + ' WHERE ' + pCampo + ' LIKE :PESQUISA';
end;

end.
