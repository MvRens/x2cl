{
  :: Registers the MenuBar components
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLMBReg;

interface
  procedure Register;

implementation
uses
  Classes,
  DesignIntf,
  X2CLMenuBar,
  X2CLmusikCubeMenuBarPainter,
  X2CLunaMenuBarPainter;

{.$R ..\Resources\MenuBar.dcr}

procedure Register;
begin
  RegisterComponents('X2Software', [TX2MenuBar,
                                    TX2MenuBarmusikCubePainter,
                                    TX2MenuBarunaPainter]);
end;

end.

