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
    actAdd: TAction;
    actClear: TAction;
    actDelete: TAction;
    actDown: TAction;
    actOpen: TAction;
    actSave: TAction;
    actUp: TAction;
    alGraphics: TActionList;
    dlgOpen: TOpenPictureDialog;
    dlgSave: TSavePictureDialog;
    ilsIcons: TImageList;
    imgPreview: TImage;
    lblName: TLabel;
    lstGraphics: TListBox;
    pnlGraphics: TPanel;
    pnlImage: TPanel;
    pnlProperties: TPanel;
    sbImage: TScrollBox;
    spltGraphics: TSplitter;
    tbClear: TToolButton;
    tbDelete: TToolButton;
    tbDown: TToolButton;
    tbGraphics: TToolBar;
    tbImage: TToolBar;
    tbNew: TToolButton;
    tbOpen: TToolButton;
    tbSave: TToolButton;
    tbSep1: TToolButton;
    tbUp: TToolButton;
    txtName: TEdit;
    lblClassType: TLabel;
    tbExport: TToolButton;
    tbImport: TToolButton;
    actExport: TAction;
    actImport: TAction;
    tbSep2: TToolButton;
    dlgExport: TSaveDialog;
    dlgImport: TOpenDialog;

    function lstGraphicsDataFind(Control: TWinControl; FindString: String): Integer;
    procedure actAddExecute(Sender: TObject);
    procedure actClearExecute(Sender: TObject);
    procedure actDeleteExecute(Sender: TObject);
    procedure actDownExecute(Sender: TObject);
    procedure actExportExecute(Sender: TObject);
    procedure actImportExecute(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure actUpExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstGraphicsClick(Sender: TObject);
    procedure lstGraphicsData(Control: TWinControl; Index: Integer; var Data: String);
    procedure lstGraphicsKeyPress(Sender: TObject; var Key: Char);
    procedure txtNameChange(Sender: TObject);
  private
    FComponent: TX2GraphicContainer;
    FComponentDesigner: IDesigner;
    FUpdating: Boolean;

    procedure InternalExecute(const AComponent: TComponent; const ADesigner: IDesigner);

    procedure LoadGraphic(AGraphic: TX2GraphicContainerItem; const AFileName: string);
    
    procedure ItemChanged(AUpdatePreview: Boolean = True);
    procedure UpdateUI;
    procedure UpdatePreview;

    function Active(out AIndex: Integer; out AGraphic: TX2GraphicContainerItem): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    class procedure Execute(const AComponent: TComponent; const ADesigner: IDesigner);
  end;

implementation
uses
  Graphics,
  IniFiles,
  SysUtils,
  Windows;


var
  EditorInstance: TGraphicsEditorForm;


{$R *.dfm}


{ TGraphicsEditorForm }
class procedure TGraphicsEditorForm.Execute(const AComponent: TComponent; const ADesigner: IDesigner);
begin
  if not Assigned(EditorInstance) then
    EditorInstance := TGraphicsEditorForm.Create(Application);

  EditorInstance.InternalExecute(AComponent, ADesigner);
end;


procedure TGraphicsEditorForm.InternalExecute(const AComponent: TComponent; const ADesigner: IDesigner);
begin
  FComponent          := TX2GraphicContainer(AComponent);
  FComponent.FreeNotification(Self);

  FComponentDesigner  := ADesigner;
  Caption             := Format('%s Graphics', [FComponent.Name]);

  lstGraphics.Count := FComponent.GraphicCount;
  lstGraphics.ItemIndex := 0;

  UpdateUI;
  UpdatePreview;
  Show;
end;


procedure TGraphicsEditorForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action  := caFree;

  if Self = EditorInstance then
    EditorInstance := nil;

  if Assigned(FComponent) then
    FComponent.RemoveFreeNotification(Self);
end;


procedure TGraphicsEditorForm.LoadGraphic(AGraphic: TX2GraphicContainerItem; const AFileName: string);
begin
  AGraphic.Picture.LoadFromFile(AFileName);

  if Length(AGraphic.PictureName) = 0 then
  begin
    AGraphic.PictureName  := ChangeFileExt(ExtractFileName(AFileName), '');
    lstGraphics.Invalidate;
  end;
end;


procedure TGraphicsEditorForm.ItemChanged(AUpdatePreview: Boolean);
begin
  if Assigned(FComponentDesigner) then
    FComponentDesigner.Modified;

  UpdateUI;

  if AUpdatePreview then
    UpdatePreview;
end;


procedure TGraphicsEditorForm.UpdateUI;
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
  actExport.Enabled := (FComponent.GraphicCount > 0);

  actUp.Enabled     := enabled and (index > 0);
  actDown.Enabled   := enabled and (index < Pred(FComponent.GraphicCount));
end;


procedure TGraphicsEditorForm.UpdatePreview;
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  FUpdating := True;
  try
    if Active(index, graphic) then
    begin
      imgPreview.Picture.Assign(graphic.Picture);

      if Assigned(graphic.Picture.Graphic) then
        lblClassType.Caption  := graphic.Picture.Graphic.ClassName
      else
        lblClassType.Caption  := '';
        
      txtName.Text          := graphic.PictureName;
      lstGraphics.Invalidate;
    end else
    begin
      imgPreview.Picture.Assign(nil);
      lblClassType.Caption      := '';
      txtName.Text              := '';
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

  AGraphic  := FComponent.Graphics[AIndex];
  Result    := Assigned(AGraphic);
end;


procedure TGraphicsEditorForm.lstGraphicsClick(Sender: TObject);
begin
  UpdateUI;
  UpdatePreview;
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
    graphic.PictureName := txtName.Text;
    lstGraphics.Invalidate;

    ItemChanged(False);
  end;
end;


procedure TGraphicsEditorForm.actAddExecute(Sender: TObject);
var
  graphic:      TX2GraphicContainerItem;
  fileIndex:    Integer;

begin
  if Assigned(FComponentDesigner) then
  begin
    dlgOpen.Filter  := GraphicFilter(TGraphic);
    dlgOpen.Options := dlgOpen.Options + [ofAllowMultiSelect];

    if dlgOpen.Execute then
    begin
      for fileIndex := 0 to Pred(dlgOpen.Files.Count) do
      begin
        graphic := TX2GraphicContainerItem(FComponentDesigner.CreateComponent(TX2GraphicContainerItem, nil, 0, 0, 0, 0));

        if Assigned(graphic) then
        begin
          graphic.Container := FComponent;
          lstGraphics.Count := FComponent.GraphicCount;

          LoadGraphic(graphic, dlgOpen.Files[fileIndex]);
        end else
          raise Exception.Create('Failed to create TX2GraphicContainerItem!');
      end;

      ItemChanged;
    end;
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
    graphic.Free;
    lstGraphics.Count := FComponent.GraphicCount;

    if index > Pred(FComponent.GraphicCount) then
      index  := Pred(FComponent.GraphicCount);

    lstGraphics.ItemIndex := index;

    ItemChanged;
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
      graphic.Index         := Pred(index);
      lstGraphics.ItemIndex := Pred(index);
      lstGraphics.Invalidate;

      ItemChanged(False);
    end;
end;


procedure TGraphicsEditorForm.actDownExecute(Sender: TObject);
var
  index:        Integer;
  graphic:      TX2GraphicContainerItem;

begin
  if Active(index, graphic) then
    if index < Pred(FComponent.GraphicCount) then
    begin
      graphic.Index         := Succ(index);
      lstGraphics.ItemIndex := Succ(index);
      lstGraphics.Invalidate;

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
    dlgOpen.Options := dlgOpen.Options - [ofAllowMultiSelect];

    if dlgOpen.Execute then
    begin
      LoadGraphic(graphic, dlgOpen.FileName);
      ItemChanged;
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

      if dlgSave.Execute then
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
    ItemChanged;
  end;
end;


procedure TGraphicsEditorForm.actExportExecute(Sender: TObject);
var
  exportFile: TIniFile;
  exportBaseFileName: string;
  exportPath: string;
  index: Integer;
  graphic: TX2GraphicContainerItem;
  fileName: string;

begin
  if dlgExport.Execute then
  begin
    exportPath := ExtractFilePath(dlgExport.FileName);
    exportBaseFileName := ChangeFileExt(ExtractFileName(dlgExport.FileName), '');

    exportFile := TIniFile.Create(dlgExport.FileName);
    try
      for index := 0 to Pred(FComponent.GraphicCount) do
      begin
        graphic := FComponent.Graphics[index];
        exportFile.WriteString('PictureName', IntToStr(index), graphic.PictureName);

        if Assigned(graphic.Picture.Graphic) then
        begin
          fileName := exportBaseFileName + '.' + IntToStr(index) + '.' + GraphicExtension(TGraphicClass(graphic.Picture.Graphic.ClassType));

          graphic.Picture.Graphic.SaveToFile(exportPath + fileName);
          exportFile.WriteString('FileName', IntToStr(index), fileName);
        end;
      end;

      ShowMessage('Graphics have been exported');
    finally
      FreeAndNil(exportFile);
    end;
  end;
end;


procedure TGraphicsEditorForm.actImportExecute(Sender: TObject);
var
  importFile: TIniFile;
  importPath: string;
  index: Integer;
  graphic: TX2GraphicContainerItem;
  fileName: string;
  startIndex: Integer;

begin
  if dlgImport.Execute then
  begin
    if FComponent.GraphicCount > 0 then
    begin
      if MessageBox(Self.Handle, 'All graphics will be replaced. Do you want to continue?', 'Import', MB_YESNO or MB_ICONQUESTION) <> ID_YES then
        exit;
    end;

    { Items inherited from the ancestor through visual inheritance can not
      be deleted. Start at the first one introduced at this level. }
    startIndex := 0;
    while (startIndex < FComponent.GraphicCount) and (csAncestor in FComponent.Graphics[startIndex].ComponentState) do
      Inc(startIndex);

    lstGraphics.Clear;

    if startIndex = 0 then
      FComponent.Clear
    else
    begin
      for index := Pred(FComponent.GraphicCount) downto startIndex do
        FComponent.Graphics[index].Free;
    end;

    importPath := ExtractFilePath(dlgImport.FileName);
    importFile := TIniFile.Create(dlgImport.FileName);
    try
      index := 0;

      while importFile.ValueExists('PictureName', IntToStr(index)) do
      begin
        if index >= startIndex then
        begin
          graphic := TX2GraphicContainerItem(FComponentDesigner.CreateComponent(TX2GraphicContainerItem, nil, 0, 0, 0, 0));

          if Assigned(graphic) then
          begin
            graphic.Container := FComponent;
            graphic.PictureName := importFile.ReadString('PictureName', IntToStr(index), IntToStr(index));

            fileName := importFile.ReadString('FileName', IntToStr(index), '');
            if (Length(fileName) > 0) and FileExists(importPath + fileName) then
              graphic.Picture.LoadFromFile(importPath + fileName);
          end;
        end;

        Inc(index);
      end;
    finally
      FreeAndNil(importFile);

      lstGraphics.Count := FComponent.GraphicCount;
      ItemChanged(True);
    end;
  end;
end;


procedure TGraphicsEditorForm.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (AComponent = FComponent) then
  begin
    FComponent := nil;
    Close;
  end;
end;


procedure TGraphicsEditorForm.lstGraphicsData(Control: TWinControl; Index: Integer; var Data: String);
begin
  Data  := Format('%d - %s', [Index, FComponent.Graphics[Index].PictureName]);
end;


function TGraphicsEditorForm.lstGraphicsDataFind(Control: TWinControl; FindString: String): Integer;
var
  graphicIndex: Integer;

begin
  Result := -1;

  for graphicIndex := 0 to Pred(FComponent.GraphicCount) do
    if SameText(Copy(FComponent.Graphics[graphicIndex].PictureName, 1, Length(FindString)), FindString) then
    begin
      Result := graphicIndex;
      Break;
    end;
end;


procedure TGraphicsEditorForm.lstGraphicsKeyPress(Sender: TObject; var Key: Char);
begin
  { Because the listbox is virtual, Return causes the ItemIndex to reset to 0 }
  if Ord(Key) = VK_RETURN then
    Key := #0;
end;

end.
