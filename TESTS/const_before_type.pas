{* \file
 * Constants before type section in implementation section
 }
unit constants_before_type;

interface

implementation


resourcestring

  Hello = 'Hello there';

type
  TClassAfterConst = class
    FClassAfterConstField: Integer;
    function ClassAfterConstMethod: Integer;
  end;

const
  Adios = 'Adios amigo!';

function FunctionAfterConstClause(nIndex: Integer): Integer;
begin end;

end.
