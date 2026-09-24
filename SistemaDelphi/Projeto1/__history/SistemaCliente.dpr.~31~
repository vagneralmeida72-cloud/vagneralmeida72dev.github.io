program SistemaCliente;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  uFrmCadastroBase in 'Padrao\Forms\uFrmCadastroBase.pas' {frmCadastroBase},
  uClientes in 'Cadastros\uClientes.pas' {frmCliente},
  uDM in 'Padrao\Data\uDM.pas' {DM: TDataModule},
  uClienteService in 'Service\uClienteService.pas',
  uUpdate in 'Padrao\Update\uUpdate.pas',
  uLibFuncoesUpdate in 'Padrao\Update\uLibFuncoesUpdate.pas',
  uCadastroRepository in 'Repository\uCadastroRepository.pas',
  uCadastroService in 'Service\uCadastroService.pas',
  LibFuncoes in 'Padrao\Lib\LibFuncoes.pas',
  uFrmIA in 'Padrao\Forms\uFrmIA.pas' {frmIA},
  uIA in 'Service\uIA.pas',
  uProdutoService in 'Service\uProdutoService.pas',
  uProduto in 'Cadastros\uProduto.pas' {frmProduto};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDM, DM);
  DM.P_Conectar;
  //crie os forms
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmCadastroBase, frmCadastroBase);
  Application.CreateForm(TfrmCliente, frmCliente);
  Application.CreateForm(TfrmIA, frmIA);
  Application.CreateForm(TfrmProduto, frmProduto);
  Application.Run;
end.
