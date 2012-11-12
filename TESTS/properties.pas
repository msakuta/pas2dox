unit properties;
unit ouf;

interface

type
/// Short description of the class
TTest = class
public
Field1: int;
/// <summary>internal field</summary>
/// \sa Pr1
Field2: int;
/// Short description Pr1
{* Long description *}
property Pr1 : int read Field1;
/// <summary>Short description Pr2</summary>
{* Long description Pr2 *}
property Pr2 : int read Field2 write Field2;

end;

implementation

end.

