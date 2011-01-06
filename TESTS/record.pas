{* \file
 * records
 }
unit enum;

type

{*
 * A Simple record
 }

cvsroot_t = record
original: PChar; {*< the complete source CVSroot
string }
method: PChar; {*< protocol name }
end;

interface

implementation

end.
