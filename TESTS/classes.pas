{* \file
 * classes and procedures
 }
unit classes;

type

  TCustomItemDrawText =
    function(): Boolean of object;

TNoInherit = class
public
end;

{*
 * TMemoryStream class derived from TCustomMemoryStream
 }
TMemoryStream = class(TCustomMemoryStream)
  private
    FCapacity: Longint;                            ///< Private field
    procedure SetCapacity(NewCapacity: Longint);   ///< Private method
  protected
    ///<summary>func com</summary>
   	///<param name="mode">func par</param>
    function Realloc(var NewCapacity: Longint): Pointer; virtual;

    /// Protected property
    property Capacity: Longint read FCapacity write SetCapacity;
  public
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromStream(Stream: TStream);

    procedure LoadFromFile(const FileName: string);
    procedure SetSize(NewSize: Longint); override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

  TMyType = integer;

  TMyClass = class
  end {TMyClass};


interface

implementation

procedure TMemoryStream.Write(const Buffer : Longint, ///< buffer line
  const Count : Longint ///< counter
);
begin
  // some comment
end;

procedure  LoadFromStream(Stream: TStream);
begin
end;


end.
