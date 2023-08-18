unit Utils;

interface

    // Function returns place of first digit in string (C1A, D23 returns 1 REL2XXX returns 3 etc.)
    Function GetFirstDigitInString(InString: String): Integer; end;

    Function GetStringLenght(InString: String): Integer; end;

    Function RemoveCharFromString(StringToFormat: String; CharToDelete: Char): String; end;

    Function ReplaceCharInString(StringToFormat: String; OldChar: Char; NewChar: Char): String; end;


implementation

    Function GetFirstDigitInString(InString: String): Integer;
    var
         DigPosition: Integer;
         LastPosition: Integer;
         Digit_char: Integer;
         Search_char: Character;
    begin
         LastPosition := 9999; // stupid big value
         for Digit_char := 49 to 57 do                    // '1' ....'9'
         begin
              Search_char := Chr(Digit_char);
              DigPosition := AnsiPos(Search_char, InString);
              if((DigPosition <> 0) and (DigPosition < LastPosition)) then
                   LastPosition := DigPosition;
         end;
         Result := LastPosition;
    end;

    Function GetStringLenght(InString: String): Integer;
    var
         Counter: Integer;
         DoCount: Boolean;
    begin
         Counter := 1;
         DoCount := true;
         while (DoCount) do
         begin
              if(InString[Counter] = '') then
                   DoCount := false
              else
                   inc(Counter);
         end;
         Result := Counter-1;
    end;

    Function RemoveCharFromString(StringToFormat: String; CharToDelete: Char): String ;
    var
         Char_position: Integer;
    begin
         Char_position := pos(CharToDelete, StringToFormat);
         while Char_position > 0 do
         begin
              Delete(StringToFormat, Char_position, 1);
              Char_position := pos(CharToDelete, StringToFormat);
         end;
         Result := StringToFormat;
    end;

    Function ReplaceCharInString(StringToFormat: String; OldChar: Char; NewChar: Char): String ;
    var
         Char_position: Integer;
    begin
         Char_position := pos(OldChar, StringToFormat);
         while Char_position > 0 do
         begin
              StringToFormat[Char_position] := NewChar;
              Char_position := pos(OldChar, StringToFormat);
         end;
         Result := StringToFormat;
    end;




