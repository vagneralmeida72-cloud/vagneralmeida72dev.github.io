unit LibFuncoes;

interface

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs, Vcl.Forms, Winapi.Windows,
  Vcl.StdCtrls, Vcl.DBCtrls;

type
  TTipoMensagem = (tmInformacao, tmAviso, tmErro, tmConfirmacao);

  function F_Mensagem(pMensagem: string;
    pTipo: TTipoMensagem = tmInformacao): Integer;
  function F_Confirmar(pMensagem: string): Boolean;
  procedure P_ContadorCaracteres(pMemo: TDBMemo; pLabel: TLabel; pLimite: Integer);

implementation

function F_Mensagem(pMensagem: string;
  pTipo: TTipoMensagem = tmInformacao): Integer;
var
  vTitulo: string;
  vFlags: UINT;
begin
  case pTipo of
    tmInformacao:
      begin
        vTitulo := 'Informação';
        vFlags := MB_OK or MB_ICONINFORMATION;
      end;
    tmAviso:
      begin
        vTitulo := 'Atenção';
        vFlags := MB_OK or MB_ICONWARNING;
      end;
    tmErro:
      begin
        vTitulo := 'Erro';
        vFlags := MB_OK or MB_ICONERROR;
      end;
    tmConfirmacao:
      begin
        vTitulo := 'Confirmação';
        vFlags := MB_OK or MB_ICONQUESTION;
      end;
  else
    begin
      vTitulo := 'Informação';
      vFlags := MB_OK or MB_ICONINFORMATION;
    end;
  end;

  Result := MessageBox(0, PChar(pMensagem), PChar(vTitulo), vFlags);
end;

function F_Confirmar(pMensagem: string): Boolean;
begin
  Result := MessageBox(0, PChar(pMensagem), PChar('Confirmação'),
    MB_YESNO or MB_ICONQUESTION) = IDYES;
end;

procedure P_ContadorCaracteres(pMemo: TDBMemo; pLabel: TLabel; pLimite: Integer);
var
  Restante: Integer;
begin
  Restante := pLimite - Length(pMemo.Text);

  if Restante < 0 then
    Restante := 0;

  pLabel.Caption := IntToStr(Restante) + ' caracteres restantes...';
end;

end.
