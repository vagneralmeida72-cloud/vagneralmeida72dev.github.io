unit uCadastroService;


interface

uses
  System.SysUtils, System.Variants, Data.DB, uCadastroRepository;

type
  TCadastroService = class
  private
    FRepository: TCadastroRepository;
    FTabela: string;

  public
    constructor Create(pRepository: TCadastroRepository; pTabela: string);

    function F_Inserir(pDataSet: TDataSet): Boolean;
    function F_Alterar(pDataSet: TDataSet): Boolean;
    function F_Excluir(pID: Variant): Boolean;
  end;

implementation

{ TCadastroService }

constructor TCadastroService.Create(pRepository: TCadastroRepository;
  pTabela: string);
begin
  if not Assigned(pRepository) then
    raise Exception.Create('O Repository não foi informado.');

  if Trim(pTabela) = '' then
    raise Exception.Create('A tabela não foi informada.');

  FRepository := pRepository;
  FTabela := Trim(pTabela);
end;

function TCadastroService.F_Inserir(pDataSet: TDataSet): Boolean;
begin
  if not Assigned(pDataSet) then
    raise Exception.Create('O DataSet não foi informado.');

  if pDataSet.State <> dsInsert then
    raise Exception.Create('O DataSet não está em modo de inserção.');

  { Aqui futuramente entram regras de negócio }

  Result := FRepository.F_Inserir(FTabela, pDataSet);
end;

function TCadastroService.F_Alterar(pDataSet: TDataSet): Boolean;
begin
  if not Assigned(pDataSet) then
    raise Exception.Create('O DataSet não foi informado.');

  if pDataSet.State <> dsEdit then
    raise Exception.Create('O DataSet não está em modo de edição.');

  { Aqui futuramente entram regras de negócio }

  Result := FRepository.F_Alterar(FTabela, pDataSet);
end;

function TCadastroService.F_Excluir(pID: Variant): Boolean;
begin
  if VarIsNull(pID) or VarIsEmpty(pID) then
    raise Exception.Create('O ID do registro não foi informado.');

  { Aqui futuramente entram regras de negócio }

  Result := FRepository.F_Excluir(FTabela, pID);
end;

end.
