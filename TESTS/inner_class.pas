{* \file
 * Inner class test
 }
unit classes;

type

{*
 * A part of TEditButton ripped from ExtCtrls.pas
 }
  TEditButton = class(TPersistent)
  strict private
    type
      TButtonState = (bsNormal, bsHot, bsPushed);
      TGlyph = class(TCustomControl)
      private
        FButton: TEditButton;
        FState: TButtonState;
      protected
        procedure Click; override;
        procedure CreateWnd; override;
        procedure Paint; override;
        procedure WndProc(var Message: TMessage); override;
      public
        constructor Create(AButton: TEditButton); reintroduce; virtual;
      end;
  end;

implementation

end.
