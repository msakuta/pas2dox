{* \file
 * comments_in_function_args
 }
unit comments_in_function_args;

type

function BlockCommentsInFunctionArgs(a: TList { of Integer};
	b: TList {of String} {and another annotation};
	c: Integer {The end}): Integer;

function LineCommentsInFunctionArgs(a: TList ///of Integer
/// and another comment
; b: TVector // and the second param
): Integer;

interface

implementation

end.
