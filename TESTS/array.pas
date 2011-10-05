{* \file
 * Arrays
 }
unit arrays;

interface

type

TArrayOfArray = array of array of Integer;

TArray = array of Integer;

TArrayOfArray2 = array of array of array of Integer;

/// The enumeration
TEnum = (E1, E2, E3);

TArrayOfSet = array of set of TEnum;

TArrayOfInPlaceSet = array of set of(E4, E5, E6);

TArrayOfInPlaceEnum = array of (E7, E8, E9);

/// The set of in-place enumeration.
TSet = set of (A, B);

implementation

end.