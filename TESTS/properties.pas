unit DoxygenTest;

interface

type
/// Short description of the class
TTest = class(TObject)
public
/// Short description Pr1
{* Long description *}
property Pr1 : integer read Field1;
/// Short description Pr2
{* Long description Pr2 *}
property Pr2 : integer read Field2 write Field2;

end;

implementation

end.

