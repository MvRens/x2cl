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
  private
    procedure FindGraphics(const Prop: IProperty);
  public
    procedure Edit(); override;
  end;

  TX2GraphicListEditor      = class(TComponentEditor)
  public
    procedure Edit(); override;
  end;

implementation
uses
  SysUtils,
  TypInfo,
  Dialogs,
  X2CLGraphicList;


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
 