{* \file
 * \brief funcions and function pointers
 }
unit classes;

interface

function NormalFunc(Arg: Integer): Integer;

type FuncPtrType = function(Arg: Integer): Integer;

var
avalue: Integer;

var FuncPtr: FuncPtrType;

var FuncPtrInPlace: function(Arg: Integer): Integer;

var ProcPtrInPlace:procedure(Arg: Integer);

var FuncPtrInPlaceWithoutParam:function:Integer;

var ProcPtrInPlaceWithoutParam:procedure;

implementation


end.
