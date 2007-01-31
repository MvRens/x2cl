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
  TGraphicsEditorForm = class(TForm)
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
    FComponent:           TX2GraphicContainer;
    FComponentDesigner:   IDesigner;
    FUpdating:            Boolean;

    procedure InternalExecute(const AComponent: TComponent; const ADesigner: IDesigner);
    
    procedure ItemChanged(AUpdatePreview: Boolean = True);
    procedure UpdateUI();
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
  EditorInstance:     TGraphicsEditorForm;


{$R *.dfm}


{ TGraphicsEditorForm }
class procedure TGraphicsEditorForm.Execute(const AComponent: TComponent; const ADesigner: IDesigner);
begin
  if not Assigned(EditorInstance) then
    EditorInstance := TGraphicsEditorForm.Create(Application);

  EditorInstance.InternalExecute(AComponent, ADesigner);
end;

procedure TGraphicsEditorForm.InternalExecute(const AComponent: TComponent; const ADesigner: IDesigner);
var
  graphicIndex:   Integer;

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

      for graphicIndex := 0 to FComponent.GraphicCount - 1 do
        AddObject(FComponent.Graphics[graphicIndex].PictureName,
                  FComponent.Graphics[graphicIndex]);
    finally
      EndUpdate();
    end;

    lstGraphics.ItemIndex := 0;
  end;

  UpdateUI();
  UpdatePreview();
  Show();
end;


procedure TGraphicsEditorForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action  := caFree;

  if Self = EditorInstance then
    EditorInstance := nil;

  if Assigned(FComponent) then
    FComponent.RemoveFreeNotification(Self);
end;


procedure TGraphicsEditorForm.ItemChanged(AUpdatePreview: Boolean);
begin
  if Assigned(FComponentDesigner) then
    FComponentDesigner.Modified();

  UpdateUI();

  if AUpdatePreview then
    UpdatePreview();
end;


procedure TGraphicsEditorForm.UpdateUI();
var
  enabled:      Boolean;
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  enabled           := Active(index, graphic);
  actDelete.Enabled := enabled;
  actOpen.Enabled   := enabled;

  if enabled then
    enabled         := Assigned(graphic.Picture.Graphic)
  else
    enabled         := False;

  actSave.Enabled   := enabled;
  actClear.Enabled  := enabled;

  actUp.Enabled     := enabled and (index > 0);
  actDown.Enabled   := enabled and (index < Pred(lstGraphics.Items.Count));
end;


procedure TGraphicsEditorForm.UpdatePreview();
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  FUpdating := True;
  try
    if Active(index, graphic) then
    begin
      imgPreview.Picture.Assign(graphic.Picture);
      txtName.Text  := graphic.PictureName;
    end;
  finally
    FUpdating := False;
  end;
end;



function TGraphicsEditorForm.Active(out AIndex: Integer; out AGraphic: TX2GraphicContainerItem): Boolean;
begin
  Result    := False;
  AIndex    := lstGraphics.ItemIndex;
  if AIndex = -1 then
    exit;

  AGraphic  := TX2GraphicContainerItem(lstGraphics.Items.Objects[AIndex]);
  Result    := Assigned(AGraphic);
end;


procedure TGraphicsEditorForm.lstGraphicsClick(Sender: TObject);
begin
  UpdateUI();
  UpdatePreview();
end;


procedure TGraphicsEditorForm.txtNameChange(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if FUpdating then
    Exit;

  if Active(index, graphic) then
  begin
    graphic.PictureName       := txtName.Text;
    lstGraphics.Items[index]  := graphic.PictureName;

    ItemChanged(False);
  end;
end;


procedure TGraphicsEditorForm.actAddExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Assigned(FComponentDesigner) then
  begin
    graphic := TX2GraphicContainerItem(FComponentDesigner.CreateComponent(TX2GraphicContainerItem, nil, 0, 0, 0, 0));

    if Assigned(graphic) then
    begin
      graphic.Container := FComponent;
      index             := lstGraphics.Items.AddObject(graphic.PictureName,
                                                       graphic);

      lstGraphics.ItemIndex := index;
      ItemChanged();

      actOpen.Execute();
    end else
      raise Exception.Create('Failed to create TX2GraphicContainerItem!');
  end else
    raise Exception.Create('Designer not found!');
end;


procedure TGraphicsEditorForm.actDeleteExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Active(index, graphic) then
  begin
    { First attempt to remove the component; this will raise an exception
      if it's not allowed, for example due to it being introduced in
      an ancestor. }
    graphic.Free();
    lstGraphics.Items.Delete(index);

    if index > Pred(lstGraphics.Items.Count) then
      index  := Pred(lstGraphics.Items.Count);

    lstGraphics.ItemIndex := index;

    ItemChanged();
  end;
end;


procedure TGraphicsEditorForm.actUpExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Active(index, graphic) then
    if index > 0 then
    begin
      lstGraphics.Items.Move(index, Pred(index));
      graphic.Index         := Pred(index);
      lstGraphics.ItemIndex := Pred(index);

      ItemChanged(False);
    end;
end;


procedure TGraphicsEditorForm.actDownExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Active(index, graphic) then
    if index < Pred(lstGraphics.Items.Count) then
    begin
      lstGraphics.Items.Move(index, index + 1);
      graphic.Index         := Succ(index);
      lstGraphics.ItemIndex := Succ(index);

      ItemChanged(False);
    end;
end;


procedure TGraphicsEditorForm.actOpenExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Active(index, graphic) then
  begin
    dlgOpen.Filter  := GraphicFilter(TGraphic);
    if dlgOpen.Execute() then
    begin
      graphic.Picture.LoadFromFile(dlgOpen.FileName);
      if Length(graphic.PictureName) = 0 then
        graphic.PictureName := ChangeFileExt(ExtractFileName(dlgOpen.FileName), '');

      ItemChanged();
    end;
  end;
end;

procedure TGraphicsEditorForm.actSaveExecute(Sender: TObject);
var
  index:          Integer;
  graphic:        TX2GraphicContainerItem;
  graphicClass:   TGraphicClass;

begin
  if Active(index, graphic) then
    if Assigned(graphic.Picture.Graphic) then begin
      graphicClass      := TGraphicClass(graphic.Picture.Graphic.ClassType);
      dlgSave.Filter    := GraphicFilter(graphicClass);
      dlgSave.FileName  := ChangeFileExt(graphic.PictureName, '.' + GraphicExtension(graphicClass));

      if dlgSave.Execute() then
        graphic.Picture.SaveToFile(dlgSave.FileName);
    end;
end;

procedure TGraphicsEditorForm.actClearExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Active(index, graphic) then
  begin
    graphic.Picture.Assign(nil);
    ItemChanged();
  end;
end;


procedure TGraphicsEditorForm.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (AComponent = FComponent) then
  begin
    FComponent := nil;
    Close();
  end;
end;

end.
