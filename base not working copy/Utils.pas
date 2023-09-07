unit Utils;

interface

  function GetFirstDigitInString(InString: String): Integer; end;
  function GetStringLength(InString: String): Integer; end;
  function RemoveCharFromString(StringToFormat: String; CharToDelete: Char): String; end;
  function ReplaceCharInString(StringToFormat: String; OldChar, NewChar: Char): String; end;

implementation

  function GetFirstDigitInString(InString: String): Integer;
  var
    DigPosition: Integer;
    LastPosition: Integer;
    DigitChar: Integer;
    SearchChar: Char;
  begin
    LastPosition := 9999; // A large value
    for DigitChar := 49 to 57 do // '1' ....'9'
    begin
      SearchChar := Chr(DigitChar);
      DigPosition := AnsiPos(SearchChar, InString);
      if (DigPosition <> 0) and (DigPosition < LastPosition) then
        LastPosition := DigPosition;
    end;
    Result := LastPosition;
  end;

  function GetStringLenght(InString: String): Integer;
  var
    Counter: Integer;
    DoCount: Boolean;
  begin
    Counter := 1;
    DoCount := True;
    while DoCount do
    begin
      if InString[Counter] = '' then
        DoCount := False
      else
        Inc(Counter);
    end;
    Result := Counter - 1;
  end;

  function RemoveCharFromString(StringToFormat: String; CharToDelete: Char): String;
  var
    CharPosition: Integer;
  begin
    CharPosition := Pos(CharToDelete, StringToFormat);
    while CharPosition > 0 do
    begin
      Delete(StringToFormat, CharPosition, 1);
      CharPosition := Pos(CharToDelete, StringToFormat);
    end;
    Result := StringToFormat;
  end;

  function ReplaceCharInString(StringToFormat: String; OldChar, NewChar: Char): String;
  var
    CharPosition: Integer;
  begin
    CharPosition := Pos(OldChar, StringToFormat);
    while CharPosition > 0 do
    begin
      StringToFormat[CharPosition] := NewChar;
      CharPosition := Pos(OldChar, StringToFormat);
    end;
    Result := StringToFormat;
  end;

