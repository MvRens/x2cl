{
  :: Contains the dialog presented for the Container's Graphics property
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLGraphicsEditor;

interface
uses
  ActnList,
  Classes,
  ComCtrls,
  Controls,
  Dialogs,
  ExtCtrls,
  ExtDlgs,
  Forms,
  ImgList,
  StdCtrls,
  ToolWin,

  X2CLGraphicList;

type
  TfrmGraphicsEditor = class(TForm)
    actAdd:                                     TAction;
    actClear:                                   TAction;
    actDelete:                                  TAction;
    actDown:                                    TAction;
    actOpen:                                    TAction;
    actSave:                                    TAction;
    actUp:                                      TAction;
    alGraphics:                                 TActionList;
    dlgOpen:                                    TOpenPictureDialog;
    dlgSave:                                    TSavePictureDialog;
    ilsIcons:                                   TImageList;
    imgPreview:                                 TImage;
    lblName:                                    TLabel;
    lstGraphics:                                TListBox;
    pnlGraphics:                                TPanel;
    pnlImage:                                   TPanel;
    pnlProperties:                              TPanel;
    sbImage:                                    TScrollBox;
    spltGraphics:                               TSplitter;
    tbClear:                                    TToolButton;
    tbDelete:                                   TToolButton;
    tbDown:                                     TToolButton;
    tbGraphics:                                 TToolBar;
    tbImage:                                    TToolBar;
    tbNew:                                      TToolButton;
    tbOpen:                                     TToolButton;
    tbSave:                                     TToolButton;
    tbSep1:                                     TToolButton;
    tbUp:                                       TToolButton;
    txtName:                                    TEdit;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstGraphicsClick(Sender: TObject);
    procedure txtNameChange(Sender: TObject);
    procedure actAddExecute(Sender: TObject);
    procedure actDeleteExecute(Sender: TObject);
    procedure actUpExecute(Sender: TObject);
    procedure actDownExecute(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure actClearExecute(Sender: TObject);
  private
    FComponent:         TX2GraphicContainer;

    procedure InternalExecute(const AComponent: TComponent);
    procedure Administrate();
    procedure UpdatePreview();

    function Active(out AIndex: Integer;
                    out AGraphic: TX2GraphicCollectionItem): Boolean;
  public
    class procedure Execute(const AComponent: TComponent);
  end;

implementation
uses
  Graphics,
  SysUtils;
  
var
  GEditor:        TfrmGraphicsEditor;


{$R *.dfm}


{===================== TfrmGraphicsEditor
  Initialization
========================================}
class procedure TfrmGraphicsEditor.Execute;
begin
  if not Assigned(GEditor) then
    GEditor := TfrmGraphicsEditor.Create(Application);

  GEditor.InternalExecute(AComponent);
end;

procedure TfrmGraphicsEditor.InternalExecute;
var
  iGraphic:         Integer;

begin
  FComponent  := TX2GraphicContainer(AComponent);
  Caption     := Format('%s.Graphics', [FComponent.Name]);

  // Fill graphics list
  with lstGraphics.Items do
  begin
    BeginUpdate();
    try
      Clear();

      for iGraphic  := 0 to FComponent.Graphics.Count - 1 do
        AddObject(FComponent.Graphics[iGraphic].DisplayName,
                  FComponent.Graphics[iGraphic]);
    finally
      EndUpdate();
    end;

    lstGraphics.ItemIndex := 0;
    UpdatePreview();
  end;

  Administrate();
  Show();
end;

procedure TfrmGraphicsEditor.FormClose;
begin
  Action  := caFree;
  GEditor := nil;
end;


procedure TfrmGraphicsEditor.Administrate;
var
  bEnabled:       Boolean;
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  bEnabled          := Active(iIndex, pGraphic);
  actDelete.Enabled := bEnabled;
  actOpen.Enabled   := bEnabled;

  if bEnabled then
    bEnabled          := Assigned(pGraphic.Picture.Graphic)
  else
    bEnabled          := False;
    
  actSave.Enabled   := bEnabled;
  actClear.Enabled  := bEnabled;

  actUp.Enabled     := bEnabled and (iIndex > 0);
  actDown.Enabled   := bEnabled and (iIndex < lstGraphics.Items.Count - 1);
end;

procedure TfrmGraphicsEditor.UpdatePreview;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    imgPreview.Picture.Assign(pGraphic.Picture);
    txtName.Text  := pGraphic.Name;
    Administrate();
  end;
end;



{===================== TfrmGraphicsEditor
  Graphic Management
========================================}
function TfrmGraphicsEditor.Active;
begin
  Result    := False;
  AIndex    := lstGraphics.ItemIndex;
  if AIndex = -1 then
    exit;

  AGraphic  := TX2GraphicCollectionItem(lstGraphics.Items.Objects[AIndex]);
  Result    := Assigned(AGraphic);
end;


procedure TfrmGraphicsEditor.lstGraphicsClick;
begin
  UpdatePreview();
end;

procedure TfrmGraphicsEditor.txtNameChange;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    pGraphic.Name             := txtName.Text;
    lstGraphics.Items[iIndex] := pGraphic.DisplayName;
  end;
end;


procedure TfrmGraphicsEditor.actAddExecute;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  pGraphic  := FComponent.Graphics.Add();
  iIndex    := lstGraphics.Items.AddObject(pGraphic.DisplayName,
                                           pGraphic);

  lstGraphics.ItemIndex := iIndex;
  UpdatePreview();
end;

procedure TfrmGraphicsEditor.actDeleteExecute;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    lstGraphics.Items.Delete(iIndex);
    FComponent.Graphics.Delete(pGraphic.Index);

    if iIndex > lstGraphics.Items.Count - 1 then
      iIndex  := lstGraphics.Items.Count - 1;

    lstGraphics.ItemIndex := iIndex;
    UpdatePreview();
  end;
end;

procedure TfrmGraphicsEditor.actUpExecute;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
    if iIndex > 0 then
    begin
      lstGraphics.Items.Move(iIndex, iIndex - 1);
      pGraphic.Index        := iIndex - 1;
      lstGraphics.ItemIndex := iIndex - 1;
      Administrate();
    end;
end;

procedure TfrmGraphicsEditor.actDownExecute;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
    if iIndex < lstGraphics.Items.Count - 1 then
    begin
      lstGraphics.Items.Move(iIndex, iIndex + 1);
      pGraphic.Index        := iIndex + 1;
      lstGraphics.ItemIndex := iIndex + 1;
      Administrate();
    end;
end;


procedure TfrmGraphicsEditor.actOpenExecute;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    dlgOpen.Filter  := GraphicFilter(TGraphic);
    if dlgOpen.Execute() then
    begin
      pGraphic.Picture.LoadFromFile(dlgOpen.FileName);
      if Length(pGraphic.Name) = 0 then
        pGraphic.Name := ChangeFileExt(ExtractFileName(dlgOpen.FileName), '');

      UpdatePreview();
    end;
  end;
end;

procedure TfrmGraphicsEditor.actSaveExecute;
var
  iIndex:         Integer;
  pClass:         TGraphicClass;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
    if Assigned(pGraphic.Picture.Graphic) then begin
      pClass            := TGraphicClass(pGraphic.Picture.Graphic.ClassType);
      dlgSave.Filter    := GraphicFilter(pClass);
      dlgSave.FileName  := ChangeFileExt(pGraphic.Name, '.' + GraphicExtension(pClass));
      
      if dlgSave.Execute() then
        pGraphic.Picture.SaveToFile(dlgSave.FileName);
    end;
end;

procedure TfrmGraphicsEditor.actClearExecute;
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicCollectionItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    pGraphic.Picture.Assign(nil);
    UpdatePreview();
  end;
end;

end.
