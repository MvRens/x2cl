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
  DesignIntf,
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
    FComponentDesigner: IDesigner;

    procedure InternalExecute(const AComponent: TComponent; const ADesigner: IDesigner);
    procedure Administrate();
    procedure UpdatePreview();

    function Active(out AIndex: Integer; out AGraphic: TX2GraphicContainerItem): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    class procedure Execute(const AComponent: TComponent; const ADesigner: IDesigner);
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
class procedure TfrmGraphicsEditor.Execute(const AComponent: TComponent; const ADesigner: IDesigner);
begin
  if not Assigned(GEditor) then
    GEditor := TfrmGraphicsEditor.Create(Application);

  GEditor.InternalExecute(AComponent, ADesigner);
end;

procedure TfrmGraphicsEditor.InternalExecute(const AComponent: TComponent; const ADesigner: IDesigner);
var
  iGraphic:         Integer;

begin
  FComponent          := TX2GraphicContainer(AComponent);
  FComponent.FreeNotification(Self);
  
  FComponentDesigner  := ADesigner;
  Caption             := Format('%s Graphics', [FComponent.Name]);

  // Fill graphics list
  with lstGraphics.Items do
  begin
    BeginUpdate();
    try
      Clear();

      for iGraphic  := 0 to FComponent.GraphicCount - 1 do
        AddObject(FComponent.Graphics[iGraphic].PictureName,
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

procedure TfrmGraphicsEditor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action  := caFree;
  GEditor := nil;

  if Assigned(FComponent) then
    FComponent.RemoveFreeNotification(Self);
end;


procedure TfrmGraphicsEditor.Administrate();
var
  bEnabled:       Boolean;
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

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

procedure TfrmGraphicsEditor.UpdatePreview();
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    imgPreview.Picture.Assign(pGraphic.Picture);
    txtName.Text  := pGraphic.PictureName;
    Administrate();

    if Assigned(FComponentDesigner) then
      FComponentDesigner.SelectComponent(pGraphic);
  end else
    if Assigned(FComponentDesigner) then
      FComponentDesigner.SelectComponent(FComponent);
end;



{===================== TfrmGraphicsEditor
  Graphic Management
========================================}
function TfrmGraphicsEditor.Active(out AIndex: Integer; out AGraphic: TX2GraphicContainerItem): Boolean;
begin
  Result    := False;
  AIndex    := lstGraphics.ItemIndex;
  if AIndex = -1 then
    exit;

  AGraphic  := TX2GraphicContainerItem(lstGraphics.Items.Objects[AIndex]);
  Result    := Assigned(AGraphic);
end;


procedure TfrmGraphicsEditor.lstGraphicsClick(Sender: TObject);
begin
  UpdatePreview();
end;

procedure TfrmGraphicsEditor.txtNameChange(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    pGraphic.PictureName      := txtName.Text;
    lstGraphics.Items[iIndex] := pGraphic.PictureName;
  end;
end;


procedure TfrmGraphicsEditor.actAddExecute(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Assigned(FComponentDesigner) then
  begin
    pGraphic            := TX2GraphicContainerItem(FComponentDesigner.CreateComponent(TX2GraphicContainerItem, nil, 0, 0, 0, 0));

    if Assigned(pGraphic) then
    begin
      pGraphic.Container  := FComponent;
      iIndex              := lstGraphics.Items.AddObject(pGraphic.PictureName,
                                                         pGraphic);

      lstGraphics.ItemIndex := iIndex;
      UpdatePreview();

      actOpen.Execute();
    end else
      raise Exception.Create('Failed to create TX2GraphicContainerItem!');
  end else
    raise Exception.Create('Designer not found!');
end;

procedure TfrmGraphicsEditor.actDeleteExecute(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    { First attempt to remove the component; this will raise an exception
      if it's not allowed, for example due to it being introduced in
      an ancestor. }
    pGraphic.Free();
    lstGraphics.Items.Delete(iIndex);

    if iIndex > lstGraphics.Items.Count - 1 then
      iIndex  := lstGraphics.Items.Count - 1;

    lstGraphics.ItemIndex := iIndex;
    UpdatePreview();
  end;
end;

procedure TfrmGraphicsEditor.actUpExecute(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

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

procedure TfrmGraphicsEditor.actDownExecute(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

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


procedure TfrmGraphicsEditor.actOpenExecute(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    dlgOpen.Filter  := GraphicFilter(TGraphic);
    if dlgOpen.Execute() then
    begin
      pGraphic.Picture.LoadFromFile(dlgOpen.FileName);
      if Length(pGraphic.PictureName) = 0 then
        pGraphic.PictureName := ChangeFileExt(ExtractFileName(dlgOpen.FileName), '');

      UpdatePreview();
    end;
  end;
end;

procedure TfrmGraphicsEditor.actSaveExecute(Sender: TObject);
var
  iIndex:         Integer;
  pClass:         TGraphicClass;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Active(iIndex, pGraphic) then
    if Assigned(pGraphic.Picture.Graphic) then begin
      pClass            := TGraphicClass(pGraphic.Picture.Graphic.ClassType);
      dlgSave.Filter    := GraphicFilter(pClass);
      dlgSave.FileName  := ChangeFileExt(pGraphic.PictureName, '.' + GraphicExtension(pClass));
      
      if dlgSave.Execute() then
        pGraphic.Picture.SaveToFile(dlgSave.FileName);
    end;
end;

procedure TfrmGraphicsEditor.actClearExecute(Sender: TObject);
var
  iIndex:         Integer;
  pGraphic:       TX2GraphicContainerItem;

begin
  if Active(iIndex, pGraphic) then
  begin
    pGraphic.Picture.Assign(nil);
    UpdatePreview();
  end;
end;


procedure TfrmGraphicsEditor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (AComponent = FComponent) then
  begin
    FComponent := nil;
    Close();
  end;
end;

end.
