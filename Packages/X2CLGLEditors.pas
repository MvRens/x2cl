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
  TX2GraphicsProperty       = class(TClassProperty)
  public
    function AllEqual(): Boolean; override;
    procedure Edit(); override;
    function GetAttributes(): TPropertyAttributes; override;
  end;

  TX2GraphicContainerEditor = class(TComponentEditor)
  private
    procedure FindGraphics(const Prop: IProperty);
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


{==================== TX2GraphicsProperty
  Editor
========================================}
function TX2GraphicsProperty.AllEqual;
begin
  Result  := (PropCount = 1);
end;

procedure TX2GraphicsProperty.Edit;
begin
  TfrmGraphicsEditor.Execute(TComponent(GetComponent(0)));
end;

function TX2GraphicsProperty.GetAttributes;
begin
  Result  := [paDialog, paReadOnly];
end;


{============== TX2GraphicContainerEditor
  Editor
========================================}
procedure TX2GraphicContainerEditor.FindGraphics;
begin
  if SameText(Prop.GetName(), 'Graphics') then
    Prop.Edit();
end;

procedure TX2GraphicContainerEditor.Edit;
var
  dsComponents:       TDesignerSelections;

begin
  dsComponents  := TDesignerSelections.Create();
  try
    IDesignerSelections(dsComponents).Add(Component);
    GetComponentProperties(dsComponents, tkProperties, Designer, FindGraphics);
  finally
    FreeAndNil(dsComponents);
  end;
end;

procedure TX2GraphicContainerEditor.ExecuteVerb;
begin
  Edit();
end;

function TX2GraphicContainerEditor.GetVerb;
begin
  Result  := 'Graphics Editor...';
end;

function TX2GraphicContainerEditor.GetVerbCount;
begin
  Result  := 1;
end;


{=================== TX2GraphicListEditor
  Editor
========================================}
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
 