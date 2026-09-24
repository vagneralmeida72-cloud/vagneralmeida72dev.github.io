program ProjetoAPI;

{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  uServidorAPI in 'Forms\uServidorAPI.pas' {frmServidorAPI},
  uWebModuleAPI in 'Forms\uWebModuleAPI.pas' {WebModule1: TWebModule1};

{$R *.res}

begin
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;

  Application.Initialize;
  Application.CreateForm(TfrmServidorAPI, frmServidorAPI);
  Application.Run;
end.


