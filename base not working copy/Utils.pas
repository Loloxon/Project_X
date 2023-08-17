unit Utils;

interface
    {======================================================================================================================================================}
    { Auxiliary function, used in component maching - C1A, D23 returns 1 REL2XXX returns 3 etc... }
    {======================================================================================================================================================}
    Function GetDesignatorFirstDigit(InString: string): integer; end;

    {======================================================================================================================================================}
    { Auxiliary function, DELPHI LENGHT unfortunately not implemented in ALTIUM DELPHI            }
    {======================================================================================================================================================}
    Function GetStringLenght(InString: string): integer; end;

    {======================================================================================================================================================}
    { Auxiliary function - removes character from input string            }
    {======================================================================================================================================================}
    Function RemoveChar(StringToFormat: string;CharToDelete: char): string; end;

    {======================================================================================================================================================}
    { Log file takes current time to its filename . Char : is converted with this function to '_'
    {======================================================================================================================================================}
    Function ReplaceCharString(StringToFormat: string;OldChar: char;NewChar: char): string; end;


implementation

    Function GetDesignatorFirstDigit(InString: string): integer;
    var
    DigPosition: Integer;
    LastPosition: Integer;
    Digit_char: Integer;
    Search_char: Character;
    Begin
    LastPosition := 9999; // stupid big value
    For  Digit_char := 49 to 57 do                    // '1' ....'9'
         begin
         Search_char := Chr(Digit_char);
         DigPosition :=AnsiPos(Search_char, InString);
         if((DigPosition <> 0) and (DigPosition < LastPosition)) then
            LastPosition := DigPosition;
         end;
    Result :=LastPosition;
    end;

    Function GetStringLenght(InString: string): integer;
    var
    Counter: integer;
    DoCount: boolean;
    begin
    Counter := 1;
    DoCount := true;
    while (DoCount) do begin
      if( InString[Counter] = '') then
        DoCount := false
      else
        inc(Counter);
    end;
    Result := Counter-1;
    end;

    Function RemoveChar(StringToFormat: string; CharToDelete: char): string ;
    var
    Char_position: integer;
    begin

    Char_position := pos(CharToDelete, StringToFormat);
    while Char_position > 0 do begin
      Delete(StringToFormat,Char_position,1);
      Char_position := pos(CharToDelete, StringToFormat);
    end;
    Result := StringToFormat;
    end;

    Function ReplaceCharString(StringToFormat: string; OldChar: char; NewChar: char): string ;
    var
    Char_position: integer;
    begin

    Char_position := pos(OldChar, StringToFormat);
    while Char_position > 0 do begin
      StringToFormat[Char_position]:=NewChar;
      Char_position := pos(OldChar, StringToFormat);
    end;
    Result := StringToFormat;
    end;




