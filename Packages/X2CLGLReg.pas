{
  :: Registers the GraphicList components
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLGLReg;

interface
  procedure Register;

implementation
uses
  Classes,
  DesignIntf,
  X2CLGraphicList,
  X2CLGLEditors;

{$R ..\Resources\GraphicList.dcr}

procedure Register;
begin
  RegisterNoIcon([TX2GraphicContainerItem]);

  RegisterComponents('X2Software', [TX2GraphicContainer, TX2GraphicList]);

  RegisterComponentEditor(TX2GraphicContainer, TX2GraphicContainerEditor);
  RegisterComponentEditor(TX2GraphicList, TX2GraphicListEditor);
end;

end.
 
