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
  X2CLGraphicList;

procedure Register;
begin
  RegisterComponents('X�Software', [TX2GraphicContainer, TX2GraphicList]);
end;

end.
 