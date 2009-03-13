{
  :: Contains the design-time editor for the MenuBar
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLMBEditors;

interface
uses
  DesignEditors;
  

type
  TX2MenuBarComponentEditor = class(TComponentEditor)
  public
    procedure Edit(); override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount(): Integer; override;
  end;


implementation
uses
  X2CLMenuBar,
  X2CLMenuBarEditor;



{ TX2MenuBarComponentEditor }
procedure TX2MenuBarComponentEditor.Edit();
begin
  if Assigned(Component) and (Component is TX2CustomMenuBar) then
    TfrmMenuBarEditor.Execute(TX2CustomMenuBar(Component), Designer);
end;


procedure TX2MenuBarComponentEditor.ExecuteVerb(Index: Integer);
begin
  Edit();
end;


function TX2MenuBarComponentEditor.GetVerb(Index: Integer): string;
begin
  Result  := 'Edit...';
end;


function TX2MenuBarComponentEditor.GetVerbCount(): Integer;
begin
  Result  := 1;
end;

end.
