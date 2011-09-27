{* \file
 * enums
 }
unit enum;

type

{*
 * A Simple enum
 }

{* Types of messages scan should emit }
TMsgScan = (
MSG_ERROR = 1, {*< An error was found during scan }
MSG_INFO = 2, {*< Information about the process 
that is split over more than 1 
line.}
MSG_DIRECTORY = 3 {*< Scan entered a directory }
);

{*
 * Set of Enum
 }
TSetOfEnum = set of (
AConst,
BConst,
CConst
);

interface

implementation

end.
