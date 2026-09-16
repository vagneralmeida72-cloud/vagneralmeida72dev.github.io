object frmIA: TfrmIA
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Assistente IA '
  ClientHeight = 322
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 466
    Height = 273
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitLeft = 280
    ExplicitTop = 152
    ExplicitWidth = 185
    ExplicitHeight = 41
    object lblPergunta: TLabel
      Left = 10
      Top = 16
      Width = 48
      Height = 15
      Caption = 'Pergunta'
    end
    object lblResposta: TLabel
      Left = 10
      Top = 160
      Width = 47
      Height = 15
      Caption = 'Resposta'
    end
    object memPergunta: TMemo
      Left = 10
      Top = 37
      Width = 451
      Height = 75
      Lines.Strings = (
        'memPergunta')
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object memResposta: TMemo
      Left = 10
      Top = 181
      Width = 451
      Height = 75
      Lines.Strings = (
        'memResposta')
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object btnPerguntar: TButton
      Left = 386
      Top = 117
      Width = 75
      Height = 44
      Caption = 'Perguntar'
      TabOrder = 2
      OnClick = btnPerguntarClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 273
    Width = 466
    Height = 49
    Align = alBottom
    BevelInner = bvLowered
    Color = clGray
    ParentBackground = False
    TabOrder = 1
    ExplicitTop = 392
    object btnSair: TButton
      AlignWithMargins = True
      Left = 386
      Top = 5
      Width = 75
      Height = 39
      Align = alRight
      Caption = 'Fechar'
      TabOrder = 0
      OnClick = btnSairClick
      ExplicitLeft = 360
      ExplicitTop = 8
      ExplicitHeight = 25
    end
  end
end
