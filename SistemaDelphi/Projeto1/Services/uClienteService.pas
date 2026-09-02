unit uClienteService;

interface

uses
  System.SysUtils;

type
  TClienteService = class
public
  class procedure P_Validar(pNome, pCPF, pEmail: string);
end;

implementation

class procedure TClienteService.P_Validar(pNome, pCPF, pEmail: string);
begin
  if Trim(pNome) = '' then
    raise Exception.Create('Informe o nome do cliente.');

  if Trim(pCPF) = '' then
    raise Exception.Create('Informe o CPF do cliente.');

  if Trim(pEmail) = '' then
    raise Exception.Create('Informe o e-mail do cliente.');
end;

end.

