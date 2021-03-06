unit X2CLMenuBarEditor;

interface
uses
  ActnList,
  Classes,
  ComCtrls,
  Controls,
  DesignIntf,
  DesignWindows,
  Forms,
  ImgList,
  ToolWin,

  X2CLMenuBar;
  

type
  TfrmMenuBarEditor = class(TDesignWindow, IX2MenuBarDesigner)
    actAddGroup:                                TAction;
    actAddItem:                                 TAction;
    actDelete:                                  TAction;
    actMoveDown:                                TAction;
    actMoveUp:                                  TAction;
    alMenu:                                     TActionList;
    ilsActions:                                 TImageList;
    sbStatus:                                   TStatusBar;
    tbAddGroup:                                 TToolButton;
    tbAddItem:                                  TToolButton;
    tbDelete:                                   TToolButton;
    tbMenu:                                     TToolBar;
    tbMoveDown:                                 TToolButton;
    tbMoveUp:                                   TToolButton;
    tbSep1:                                     TToolButton;
    tvMenu:                                     TTreeView;

    procedure actDeleteExecute(Sender: TObject);
    procedure actAddItemExecute(Sender: TObject);
    procedure actAddGroupExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure tvMenuChange(Sender: TObject; Node: TTreeNode);
    procedure FormActivate(Sender: TObject);
    procedure actMoveUpExecute(Sender: TObject);
    procedure actMoveDownExecute(Sender: TObject);
    procedure tvMenuKeyPress(Sender: TObject; var Key: Char);
  private
    FMenuBar:             TX2CustomMenuBar;
    FDesignerAttached:    Boolean;
    FMoving:              Boolean;

    procedure SetMenuBar(const Value: TX2CustomMenuBar);

    procedure AttachDesigner();
    procedure DetachDesigner();

    function GetSelectedItem(): TX2CustomMenuBarItem;
    function GetItemNode(AItem: TX2CustomMenuBarItem): TTreeNode;
    procedure MoveSelectedItem(ADown: Boolean);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ItemAdded(AItem: TX2CustomMenuBarItem);
    procedure ItemModified(AItem: TX2CustomMenuBarItem);
    procedure ItemDeleting(AItem: TX2CustomMenuBarItem);
  protected
    procedure RefreshMenu();
    function AddGroup(AGroup: TX2MenuBarGroup): TTreeNode;
    function AddItem(ANode: TTreeNode; AItem: TX2MenuBarItem): TTreeNode;

    procedure UpdateNode(ANode: TTreeNode);
    procedure UpdateUI();
    procedure Modified();

    property MenuBar:     TX2CustomMenuBar  read FMenuBar   write SetMenuBar;
  public
    class procedure Execute(AMenuBar: TX2CustomMenuBar; ADesigner: IDesigner);
  end;
  

implementation
uses
  Contnrs,
  SysUtils, Dialogs;


var
  GEditors:     TObjectBucketList;



{$R *.dfm}


{ TfrmMenuBarEditor }
class procedure TfrmMenuBarEditor.Execute(AMenuBar: TX2CustomMenuBar; ADesigner: IDesigner);
var
  editorForm:     TfrmMenuBarEditor;

begin
  if not Assigned(GEditors) then
    GEditors  := TObjectBucketList.Create();

  editorForm  := nil;
  if GEditors.Exists(AMenuBar) then
    editorForm  := TfrmMenuBarEditor(GEditors.Data[AMenuBar]);

  if not Assigned(editorForm) then
  begin
    editorForm          := TfrmMenuBarEditor.Create(Application);
    editorForm.MenuBar  := AMenuBar;
    editorForm.Designer := ADesigner;
    GEditors.Add(AMenuBar, editorForm);
  end;

  editorForm.Show();
end;


procedure TfrmMenuBarEditor.FormCreate(Sender: TObject);
begin
  {$IF CompilerVersion >= 18}
  // Delphi (BDS) 2006
  tbMenu.EdgeBorders  := [];
  tbMenu.DrawingStyle := dsGradient;
  {$ELSE}
  tbMenu.Flat         := True;
  {$IFEND}
end;


procedure TfrmMenuBarEditor.FormActivate(Sender: TObject);
var
  item:     TX2CustomMenuBarItem;

begin
  if Assigned(tvMenu.Selected) then
  begin
    item  := TX2CustomMenuBarItem(tvMenu.Selected.Data);

    if Assigned(Designer) then
      Designer.SelectComponent(item);
  end;

  UpdateUI();
end;


procedure TfrmMenuBarEditor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(Designer) and Assigned(MenuBar) then
    Designer.SelectComponent(MenuBar);

  Action  := caFree;
end;


procedure TfrmMenuBarEditor.FormDestroy(Sender: TObject);
begin
  if Assigned(MenuBar) then
  begin
    DetachDesigner();

    if GEditors.Exists(MenuBar) then
      GEditors.Remove(MenuBar);
  end;
end;


procedure TfrmMenuBarEditor.tvMenuChange(Sender: TObject; Node: TTreeNode);
var
  item:     TX2CustomMenuBarItem;

begin
  if Assigned(Node) then
  begin
    item  := TX2CustomMenuBarItem(Node.Data);

    if Assigned(Designer) then
      Designer.SelectComponent(item);
  end;

  UpdateUI();
end;


procedure TfrmMenuBarEditor.tvMenuKeyPress(Sender: TObject; var Key: Char);
begin
  ActivateInspector(Key);
end;


procedure TfrmMenuBarEditor.RefreshMenu();
var
  groupIndex:     Integer;

begin
  tvMenu.Items.BeginUpdate();
  try
    tvMenu.Items.Clear();

    if Assigned(MenuBar) then
      for groupIndex := 0 to Pred(MenuBar.Groups.Count) do
        AddGroup(MenuBar.Groups[groupIndex]);
  finally
    tvMenu.Items.EndUpdate();
    UpdateUI();
  end;
end;


procedure TfrmMenuBarEditor.actAddGroupExecute(Sender: TObject);
begin
  MenuBar.Groups.Add();
  Modified();
end;


procedure TfrmMenuBarEditor.actAddItemExecute(Sender: TObject);
var
  menuItem:       TX2CustomMenuBarItem;
  group:          TX2MenuBarGroup;

begin
  menuItem  := GetSelectedItem();
  if Assigned(menuItem) then
  begin
    group := nil;

    if menuItem is TX2MenuBarGroup then
      group := TX2MenuBarGroup(menuItem)
    else if menuItem is TX2MenuBarItem then
      group := TX2MenuBarItem(menuItem).Group;

    if Assigned(group) then
    begin
      group.Items.Add();
      if group.Items.Count = 1 then
        group.Expanded  := True;

      Modified();
    end;
  end;
end;


procedure TfrmMenuBarEditor.actDeleteExecute(Sender: TObject);
var
  menuItem:   TX2CustomMenuBarItem;

begin
  menuItem  := GetSelectedItem();
  if Assigned(menuItem) and Assigned(menuItem.Collection) then
  begin
    menuItem.Collection.Delete(menuItem.Index);
    Modified();
  end;
end;


procedure TfrmMenuBarEditor.actMoveUpExecute(Sender: TObject);
begin
  MoveSelectedItem(False);
end;


procedure TfrmMenuBarEditor.actMoveDownExecute(Sender: TObject);
begin
  MoveSelectedItem(True);
end;


function TfrmMenuBarEditor.AddGroup(AGroup: TX2MenuBarGroup): TTreeNode;
var
  itemIndex:      Integer;
  siblingGroup:   TX2MenuBarGroup;
  siblingNode:    TTreeNode;
  groupNode:      TTreeNode;

begin
  tvMenu.Items.BeginUpdate();
  try
    siblingGroup  := nil;
    siblingNode   := nil;

    { Make sure the group is inserted in the correct position by searching
      for it's sibling group. Note: do NOT use Items[x] in a loop; TTreeView
      emulates this by using GetFirst/GetNext. }
    if AGroup.Index < Pred(AGroup.Collection.Count) then
      siblingGroup  := TX2MenuBarGroup(AGroup.Collection.Items[Succ(AGroup.Index)]);

    if Assigned(siblingGroup) then
    begin
      siblingNode := tvMenu.Items.GetFirstNode();
      while Assigned(siblingNode) do
      begin
        if siblingNode.Data = siblingGroup then
          break;

        siblingNode := siblingNode.GetNextSibling();
      end;
    end;

    if Assigned(siblingNode) then
      groupNode  := tvMenu.Items.AddNode(nil, siblingNode, '', nil, naInsert)
    else
      groupNode := tvMenu.Items.Add(nil, '');

    groupNode.Data  := AGroup;
    UpdateNode(groupNode);

    { Add items }
    for itemIndex := 0 to Pred(AGroup.Items.Count) do
      AddItem(groupNode, AGroup.Items[itemIndex]);

    groupNode.Expand(False);
    Result  := groupNode;
  finally
    tvMenu.Items.EndUpdate();
  end;
end;


function TfrmMenuBarEditor.AddItem(ANode: TTreeNode; AItem: TX2MenuBarItem): TTreeNode;
var
  siblingItem:    TX2MenuBarItem;
  siblingNode:    TTreeNode;
  itemNode:       TTreeNode;

begin
  tvMenu.Items.BeginUpdate();
  try
    siblingItem   := nil;
    siblingNode   := nil;

    { See AddGroup }
    if AItem.Index < Pred(AItem.Collection.Count) then
      siblingItem := TX2MenuBarItem(AItem.Collection.Items[Succ(AItem.Index)]);

    if Assigned(siblingItem) then
    begin
      siblingNode := ANode.GetFirstChild();
      while Assigned(siblingNode) do
      begin
        if siblingNode.Data = siblingItem then
          break;

        siblingNode := siblingNode.GetNextSibling();
      end;
    end;

    if Assigned(siblingNode) then
      itemNode  := tvMenu.Items.AddNode(nil, siblingNode, '', nil, naInsert)
    else
      itemNode  := tvMenu.Items.AddChild(ANode, '');

    itemNode.Data := AItem;
    UpdateNode(itemNode);

    Result        := itemNode;
  finally
    tvMenu.Items.EndUpdate();
  end;
end;


procedure TfrmMenuBarEditor.UpdateNode(ANode: TTreeNode);
var
  menuItem:     TX2CustomMenuBarItem;

begin
  menuItem            := TX2CustomMenuBarItem(ANode.Data);
  ANode.Text          := menuItem.Caption;
  ANode.ImageIndex    := menuItem.ImageIndex;
  ANode.SelectedIndex := ANode.ImageIndex;
end;


procedure TfrmMenuBarEditor.UpdateUI();
var
  canMoveDown:      Boolean;
  canMoveUp:        Boolean;
  itemSelected:     Boolean;
  menuItem:         TX2CustomMenuBarItem;
  group:            TX2MenuBarGroup;

begin
  itemSelected        := Assigned(tvMenu.Selected);
  actAddGroup.Enabled := Assigned(MenuBar);
  actAddItem.Enabled  := itemSelected;
  actDelete.Enabled   := itemSelected;

  canMoveUp           := False;
  canMoveDown         := False;

  if itemSelected then
  begin
    menuItem    := GetSelectedItem();

    if Assigned(menuItem.Collection) then
    begin
      canMoveUp   := (menuItem.Index > 0);
      canMoveDown := (menuItem.Index < Pred(menuItem.Collection.Count));

      if menuItem is TX2MenuBarItem then
      begin
        group       := TX2MenuBarItem(menuItem).Group;

        if Assigned(group) then
        begin
          canMoveUp   := canMoveUp or (group.Index > 0);
          canMoveDown := canMoveDown or (group.Index < Pred(MenuBar.Groups.Count));
        end;
      end;
    end;
  end;

  actMoveUp.Enabled   := canMoveUp;
  actMoveDown.Enabled := canMoveDown;
end;


procedure TfrmMenuBarEditor.Modified();
begin
  if Assigned(Designer) then
    Designer.Modified();

  UpdateUI();
end;


procedure TfrmMenuBarEditor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = MenuBar) then
  begin
    DetachDesigner();
    Release();
  end;

  inherited;
end;


procedure TfrmMenuBarEditor.ItemAdded(AItem: TX2CustomMenuBarItem);
var
  group:        TX2MenuBarGroup;
  groupNode:    TTreeNode;
  treeNode:     TTreeNode;

begin
  if FMoving then
    Exit;

  treeNode  := nil;

  if AItem is TX2MenuBarGroup then
    treeNode  := AddGroup(TX2MenuBarGroup(AItem))
  else if AItem is TX2MenuBarItem then
  begin
    group     := TX2MenuBarItem(AItem).Group;
    groupNode := nil;

    if Assigned(group) then
      groupNode := GetItemNode(group);

    if Assigned(groupNode) then
      treeNode  := AddItem(groupNode, TX2MenuBarItem(AItem));
  end;

  if Assigned(treeNode) then
    tvMenu.Selected := treeNode;
end;


procedure TfrmMenuBarEditor.ItemModified(AItem: TX2CustomMenuBarItem);
var
  treeNode:     TTreeNode;

begin
  if FMoving then
    Exit;

  tvMenu.Items.BeginUpdate();
  try
    treeNode  := tvMenu.Items.GetFirstNode();
    while Assigned(treeNode) do
    begin
      UpdateNode(treeNode);
      treeNode  := treeNode.GetNext();
    end;
  finally
    tvMenu.Items.EndUpdate();
  end;
end;


procedure TfrmMenuBarEditor.ItemDeleting(AItem: TX2CustomMenuBarItem);
var
  treeNode:     TTreeNode;

begin
  if FMoving then
    Exit;

  treeNode  := GetItemNode(AItem);
  if Assigned(treeNode) then
    tvMenu.Items.Delete(treeNode);
end;


procedure TfrmMenuBarEditor.AttachDesigner();
begin
  if FDesignerAttached or (not Assigned(MenuBar)) then
    exit;

  MenuBar.Designer  := Self;
  FDesignerAttached := True;
end;


procedure TfrmMenuBarEditor.DetachDesigner();
begin
  if not FDesignerAttached then
    exit;

  FDesignerAttached := False;
  if Assigned(MenuBar) then
    MenuBar.Designer := nil;
end;



procedure TfrmMenuBarEditor.MoveSelectedItem(ADown: Boolean);
var
  selectedItem:   TX2CustomMenuBarItem;
  group:          TX2MenuBarGroup;
  refresh:        Boolean;

begin
  if not Assigned(MenuBar) then
    Exit;

  selectedItem  := GetSelectedItem();
  if not Assigned(selectedItem) then
    Exit;

  refresh := False;
  group   := nil;

  if selectedItem is TX2MenuBarItem then
    group := TX2MenuBarItem(selectedItem).Group;

  FMoving := True;
  try
    if ADown then
    begin
      if selectedItem.Index < Pred(selectedItem.Collection.Count) then
      begin
        selectedItem.Index  := Succ(selectedItem.Index);
        refresh             := True;
      end else if Assigned(group) then
      begin
        { Move down to another group
            The AddItem is triggered by moving between groups, no need
            to add here. }
        if group.Index < Pred(MenuBar.Groups.Count) then
        begin
          selectedItem.Collection := MenuBar.Groups[Succ(group.Index)].Items;
          selectedItem.Index      := 0;
          refresh                 := True;
        end;
      end;
    end else
    begin
      if selectedItem.Index > 0 then
      begin
        selectedItem.Index  := Pred(selectedItem.Index);
        refresh             := True;
      end else if Assigned(group) then
      begin
        { Move up to another group }
        if group.Index > 0 then
        begin
          selectedItem.Collection := MenuBar.Groups[Pred(group.Index)].Items;
          refresh                 := True;
        end;
      end;
    end;
  finally
    FMoving := False;

    if refresh then
    begin
      ItemDeleting(selectedItem);
      ItemAdded(selectedItem);
    end;
  end;
end;


function TfrmMenuBarEditor.GetSelectedItem(): TX2CustomMenuBarItem;
begin
  Result  := nil;
  if Assigned(tvMenu.Selected) then
    Result  := TX2CustomMenuBarItem(tvMenu.Selected.Data);
end;


function TfrmMenuBarEditor.GetItemNode(AItem: TX2CustomMenuBarItem): TTreeNode;
var
  treeNode:     TTreeNode;

begin
  Result    := nil;
  treeNode  := tvMenu.Items.GetFirstNode();
  while Assigned(treeNode) do
  begin
    if treeNode.Data = AItem then
    begin
      Result  := treeNode;
      break;
    end;

    treeNode  := treeNode.GetNext();
  end;
end;


procedure TfrmMenuBarEditor.SetMenuBar(const Value: TX2CustomMenuBar);
begin
  if Value <> FMenuBar then
  begin
    if Assigned(FMenuBar) then
    begin
      DetachDesigner();
      FMenuBar.RemoveFreeNotification(Self);
    end;

    FMenuBar := Value;

    if Assigned(FMenuBar) then
    begin
      tvMenu.Images := FMenuBar.Images;
      Self.Caption  := 'Editing ' + FMenuBar.Name;

      AttachDesigner();
      FMenuBar.FreeNotification(Self);
    end else
    begin
      Self.Caption  := '';
      tvMenu.Images := nil;
    end;

    RefreshMenu();
  end;
end;


procedure FreeEditor(AInfo, AItem, AData: Pointer; out AContinue: Boolean);
begin
  with (TObject(AData) as TfrmMenuBarEditor) do
  begin
    MenuBar := nil;
    Free();
  end;
end;


initialization
finalization
  if Assigned(GEditors) then
    GEditors.ForEach(FreeEditor);

  FreeAndNil(GEditors);

end.
