{
  :: Contains the design-time editor for the GraphicList
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLGLEditors;

interface
uses
  DesignEditors,
  DesignIntf;

type
  TX2GraphicContainerEditor = class(TComponentEditor)
  protected
    procedure Convert();
  public
    procedure Edit(); override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): String; override;
    function GetVerbCount(): Integer; override;
  end;

  TX2GraphicListEditor      = class(TComponentEditor)
  public
    procedure Edit(); override;
  end;

implementation
uses
  Classes,
  SysUtils,
  TypInfo,

  X2CLGraphicList,
  X2CLGraphicsEditor;

type
  TProtectedX2GraphicContainer = class(TX2GraphicContainer);


{ TX2GraphicContainerEditor }
procedure TX2GraphicContainerEditor.Edit();
begin
  TGraphicsEditorForm.Execute(Component, Self.Designer);
end;

procedure TX2GraphicContainerEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: Edit();
    1: Convert();
  end;
end;

function TX2GraphicContainerEditor.GetVerb(Index: Integer): String;
begin
  case Index of
    0: Result := 'Graphics Editor...';
    1: Result := 'Convert items';
  end;
end;

function TX2GraphicContainerEditor.GetVerbCount(): Integer;
begin
  Result  := 1;

  if TProtectedX2GraphicContainer(Component).ConversionRequired then
    Inc(Result);
end;


procedure TX2GraphicContainerEditor.Convert();
var
  container: TX2GraphicContainer;
  tempContainer: TX2GraphicContainer;
  graphicIndex: Integer;
  graphicItem: TX2GraphicContainerItem;

begin
  if not Assigned(Designer) then
    exit;

  container := TX2GraphicContainer(Component);
  tempContainer := TX2GraphicContainer.Create(nil);
  try
    tempContainer.Assign(container);

    container.Clear();

    for graphicIndex := 0 to Pred(tempContainer.GraphicCount) do
    begin
      graphicItem := TX2GraphicContainerItem(Designer.CreateComponent(TX2GraphicContainerItem, nil, 0, 0, 0, 0));
      if Assigned(graphicItem) then
      begin
        graphicItem.Assign(tempContainer.Graphics[graphicIndex]);
        graphicItem.Container := container;
      end;
    end;

    TProtectedX2GraphicContainer(container).ConversionRequired := False;
  finally
    FreeAndNil(tempContainer);
  end;
end;


{ TX2GraphicContainerEditor }
procedure TX2GraphicListEditor.Edit;
var
  ifEditor:       IComponentEditor;

begin
  // Instead of showing the default ImageList dialog, check if a Container
  // is available and execute it's default action...
  if Component is TX2GraphicList then
    with TX2GraphicList(Component) do
      if Assigned(Container) then
      begin
        ifEditor  := GetComponentEditor(Container, Designer);
        if Assigned(ifEditor) then
          ifEditor.Edit();
      end;
end;

end.
 
