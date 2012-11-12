{* \file
 * \brief Sample source for funcions and function pointers.
 }
unit func;

interface

/// <summary>A normal function declaration.</summary>
/// <param name="Arg">A typical argument.</param>
/// <returns>A typical return value.</returns>
function NormalFunc(Arg: Integer): Integer;

/// <summary>A normal procedure declaration.</summary>
/// <param name="Arg">A typical argument.</param>
procedure NormalProc(Arg: Integer);

/// <summary>A type definition for a function pointer.</summary>
/// <param name="Arg">A typical argument.</param>
/// <returns>A typical return value.</returns>
type FuncPtrType = function(Arg: Integer): Integer;

var
/// <summary>An ordinary variable.</summary>
avalue: Integer;

/// <summary>A function pointer variable.</summary>
var FuncPtr: FuncPtrType;

/// <summary>A function pointer variable without typedef.</summary>
/// <param name="Arg">An in-place function pointer's argument.</param>
/// <returns>An in-place function pointer's return value.</returns>
var FuncPtrInPlace: function(Arg: Integer): Integer;

/// <summary>A normal function declaration.</summary>
/// <param name="Arg">A typical argument.</param>
/// <returns>A typical return value.</returns>
function AnotherNormalFunc(Arg: Integer): Integer;

/// <summary>A procedure pointer variable without typedef.</summary>
/// <param name="Arg">An in-place procedure pointer's argument.</param>
/// <returns>An in-place procedure pointer's return value.</returns>
var ProcPtrInPlace:procedure(Arg: Integer);

/// <summary>A function pointer variable without arguments and typedef.</summary>
/// <returns>An in-place function pointer's return value.</returns>
var FuncPtrInPlaceWithoutParam:function:Integer;

/// <summary>A procedure pointer variable without arguments and typedef.</summary>
/// <returns>An in-place procedure pointer's return value.</returns>
var ProcPtrInPlaceWithoutParam:procedure;

implementation


end.
