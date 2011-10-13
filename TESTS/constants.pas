{* \file
 * Declared constants
 }
unit constants;

interface

const

  Min = 0;
  Max = 100;
  Center = (Max - Min) div 2;
  Beta = Chr(225);
  NumChars = Ord('Z') - Ord('A') + 1;
  Message = 'Out of memory';
  ErrStr = ' Error: ' + Message + '. ';
  ErrPos = 80 - Length(ErrStr) div 2;
  Ln10 = 2.302585092994045684;
  Ln10R = 1 / Ln10;
  Numeric = ['0'..'9'];
  Alpha = ['A'..'Z', 'a'..'z'];
  AlphaNum = Alpha + Numeric;
  THPTimerARRAY=array[1..4] of Longint;
  TVendor=array [0..11] of char;
  _HHwinHwnd : HWND = 0; {*< Help Window handle }


  // Typed constant
  // Typed constants handling broken with version 1.86 of pas2dox.l
  //   the following line should parse to 'const Integer Max = 100;'
  //   instead of 'Max: const Integer = 100;'
  //Max: Integer = 100;

  TMyType = integer;

resourcestring

  CreateError = 'Cannot create file %s';        {  for explanations of format specifiers, }
  OpenError = 'Cannot open file %s';            { see 'Format strings' in the online Help }
  LineTooLong = 'Line too long';
  ProductName = 'Borland Rocks\000\000';
  SomeResourceString = SomeTrueConstant;

implementation


const
  LINE_BEGIN    = 1;
  LINE_END      = 2;
  LINE_CONST    = 3;
  LINE_FUNCTION = 4;
  LINE_PROCEDURE = 5;
  LINE_USES     = 6;
  LINE_INTERFACE = 7;
  LINE_IMPLEMENTATION = 8;
  LINE_RESOURCESTRING = 9;

function FunctionAfterConstClause(nIndex: Integer): Integer;
begin end;

end.
