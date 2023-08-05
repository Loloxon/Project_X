{ Main concept and core functions Jerzy Kasperek kasperek@agh.edu.pl
{ Auxiliary functions £ukasz Smolarek (lukasz.smolarek@e-vertigo.com)
{======================================================================================================================================================}
{
Version 7.1
Date 20.11.2018

Change log
1. New functions MTBF_LogUSerDefinedParametersOfComponents - logs all...
2. New functions MTBF_CopyDefinedParametersValue - OK
3. LP_LOG directory is required in Project folder
4. Missing raport correction
5. Added selection criteria to add components for actions...
6. New function - replace header
7. All supported usage examples
8. Missing part raport formatting changed - each component data in one line to easy sorting + no duplicates
}
{======================================================================================================================================================}
{ Based on Altium scripts ( as below) for MTBF evaluation with Reliasoft Lambda Predict Software
{ Main function:
( MTBF_AddComponentUserParameters opens FileOpen dialog. User should open dedicated format config txt file.
{
# Syntax:
# Line starting with # - its a comment line
# Each line introduce one  parameter and should have exact four words (string type)
# First ASCII string is the Altium component type selector. 'All' denotes global ( for each component) parameter.
# Second ASCII string is the LambdaPredict given methodology Parameter Name
# Third ASCII string is the Parameter Value assigned
# Fourth - (last one) ASCII string is the Visibility atribute (ON/OFF)
#
# Note that spaces are not allowed in "Altium component type" field! In "Parameter Value" field spaces are allowed but
# should be coded by '*'  Scipt will recover spaces
# Also note that EXACT one space is required between strings!

Main functionality:
The main MTBF_AddComponentUserParameters procedure reads config file line by line and than
for each parameter found scans current design for SchDoc document.
Then calls the main engine: procedure MTBF_AddUserDefinedParametersToComponents with two parameters:
current SchDoc and parameter. Then each SchDoc component is checked if there is a match with given parameter.
If so, the parameter is attached to the component with its new value and given visibility aspect.
So for, there are four match criteria defined.
1. Config line example:
  'All' 'RS_CATT' '?' 'ON'
   First string = 'All' will define an attachment with given parameter ('RS_CAT' in this example) to every component and will set its value to
   the second string ('?' in this example). Also the visibility for this parameter will be set to 'ON'.
   Category 'RS_CAT' defines component category. This is the most important categorisation - and must be set for each component.
2. Config line example:
   'Capacitor' 'RS_CATT' 'Capacitor' 'OFF'
   First string = 'Capacitor' will define an attachment with given parameter ('RS_CATT' in this example) to every component with the word 'Capacitor'
   in his ALTIUM decription field. Also will sets its value to secong string ('Capacitor' in this example).
   Also visibility for this parameter is set to 'OFF'.
3. Config lines example:
   'U21' 'RS_CATT' 'Microprocessor,*Digital' 'OFF'
   'U21' 'RS_NMBR_BITS' '16' 'OFF'
   After these two lines as above processing,  component U21 (if found) with will receive parameter RS_CATT = 'Microprocessor, Digital',
   and  RS_NMBR_BITS = 16
   ( '*' symbols are coverted into spaces).Also visibility for this parameter is set to 'OFF'.
4. Config line example:
   'R' 'RS_RTD_PWR' '0.1' 'OFF'
   First string = 'R' (one letter) will define an attachment with given parameter group ('RS_RTD_PWR' - rated power in this example) to every component with
   his ALTIUM designator field starting with 'R' letter. So, R1,R3,R41 in this example will receive parameter RS_RTD_PWR = 0.1 (Watt).
   Also visibility for this parameter is set to 'OFF'.

Special raport utility
5. Config line example:
   '???' 'RS_CATT' 'any' 'any' generates report for any component checking if given parameter name is set and/or contain '?'.
   So this config line shall be used at the end...

Special raport utility     (version 4.0 +)
6. Config line example:
   '???' '???' 'any' 'any' generates report for an every parameter used in every ny component
   So this config line shall be used as the last one...

The log file records the work in text file named with the current time stamp.
}

// Copyright notice from ALTIUM
{======================================================================================================================================================}
{ Summary                                                                      }
{ Demo how to add, modify and delete the user parameters for components        }
{                                                                              }
{ Version 1.0                                                                  }
{ Copyright (c) 2008 by Altium Limited                                         }
{======================================================================================================================================================}

Const
    ALTIUM_NAME = 0;       // pointers to   ComponentPAR  :  array[0..3] of string ;
    RS_PAR_NAME = 1;
    RS_PAR_VALUE = 2;
    RS_PAR_VISIBLE = 3;

// LOG file name start timestamp will be added
    LogFileName     = 'LOG_';
    NewCfgFileName  = 'Missing_';
    Report_file_folder = 'LP_RPT';
    Log_file_folder = 'LP_LOG';

Var
    I           : Integer;
    Doc         : IDocument;
    CurrentSch  : ISch_Document;
    SchDocument : IServerDocument;
    Project     : IProject;

    ConfigPAR   : IDocument;
    ParamFileName : String;
    WrkLogFile : TextFile;
    WrkRepFile : TextFile;
    TxTMessage : String;
    LastUsedDesignator :string;


{======================================================================================================================================================}
{ Auxiliary function, used in component maching - C1A, D23 returns 1 REL2XXX returns 3 etc... }
{======================================================================================================================================================}
Function GetDesignatorFirstDigit(InString:string):integer ;
var
DigPosition : Integer;
LastPosition : Integer;
Digit_char  : Integer;
Search_char : Character;
Begin
LastPosition := 9999; // stupid big value
For  Digit_char := 49 to 57 do                    // '1' ....'9'
     begin
     Search_char := Chr(Digit_char);
     DigPosition:=AnsiPos(Search_char,InString);
     if((DigPosition <> 0) and (DigPosition < LastPosition)) then
        LastPosition := DigPosition;
     end;
Result:=LastPosition;
end;
{======================================================================================================================================================}
{ Auxiliary function, DELPHI LENGHT unfortunately not implemented in ALTIUM DELPHI            }
{======================================================================================================================================================}
Function GetStringLenght(InString:string):integer ;
var
Counter : integer;
DoCount : boolean;
begin
Counter:= 1;
DoCount:= true;
while (DoCount) do begin
  if( InString[Counter] = '') then
    DoCount:=false
  else
    inc(Counter);
end;
Result := Counter-1;
end ;
{======================================================================================================================================================}
{ Auxiliary function - removes spaces from input string            }
{======================================================================================================================================================}
Function RemoveSpaces(StringToFormat:string):string ;
var
Space_position : integer;
begin

Space_position := pos(' ', StringToFormat);
while Space_position > 0 do begin
  Delete(StringToFormat,Space_position,1);
  Space_position := pos(' ', StringToFormat);
end;
Result := StringToFormat;
end ;
{======================================================================================================================================================}
{ Auxiliary function - removes single quotes from input string            }
{======================================================================================================================================================}
Function RemoveQuotes(StringToFormat:string):string ;
var
Space_position : integer;
begin

Space_position := pos('''', StringToFormat);
while Space_position > 0 do begin
  Delete(StringToFormat,Space_position,1);
  Space_position := pos('''', StringToFormat);
end;
Result := StringToFormat;
end ;
{======================================================================================================================================================}
{ Log file takes current time to its filename . Char : is converted with this function to '_'
{======================================================================================================================================================}
Function ReplaceCharString(StringToFormat:string;OldChar:char;NewChar:char):string ;
var
Char_position : integer;
begin

Char_position := pos(OldChar, StringToFormat);
while Char_position > 0 do begin
  StringToFormat[Char_position]:=NewChar;
  Char_position := pos(OldChar, StringToFormat);
end;
Result := StringToFormat;
end ;

{=====================================================================================================================================================}
{  Script uses config script with spaces as the fields separator.Hence no space is allowed in Altium parameter value field. So spaces are coded with *
{  and need to be recovered
{   Function to be removed - use  ReplaceCharString !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
{======================================================================================================================================================}
Function RestoreSpaces(StringToFormat:string):string ;
var
Star_position : integer;
begin

Star_position := pos('*', StringToFormat);
while Star_position > 0 do begin
  Delete(StringToFormat,Star_position,1);
  Insert(' ',StringToFormat,Star_position);
  Star_position := pos('*', StringToFormat);
end;
Result := StringToFormat;
end ;
{======================================================================================================================================================}
// Get file path
//  start to browse (with filter) from current project
{======================================================================================================================================================}
Function GetFile(InitFlag) : string;
var
  OpenDialog : TOpenDialog;
  DirName: String;
begin
     Result := '';
     DirName:= GetWorkspace.DM_WorkspaceFullPath;
     OpenDialog := TOpenDialog.Create(nil);
     OpenDialog.InitialDir :=   DirName;
     OpenDialog.Filter := 'Config files (*.txt)|*.TXT';
     // Display the OpenDialog component
     OpenDialog.Execute;

     // Obtain the file name of the selected file.
     Result := OpenDialog.Filename;
     OpenDialog.Free;
end;
{======================================================================================================================================================}
// Open LOG file
Procedure OpenLogFile(FileName : String);
var
     Project         : IProject;
     ProjectName     : String;
     ProjectNamePos  : Integer;
     ProjectFullPath : String;
     ProjectDirPath  : String;
     DateStr         : String;
     TimeStr         : String;
     VarFilename     : String;

begin
     Project := GetWorkspace.DM_FocusedProject;

     If Project = Nil Then Exit;
     ProjectName     := Project.DM_ProjectFileName;
     ProjectFullPath := Project.DM_ProjectFullPath;

     DateStr := GetCurrentDateString;
     TimeStr := GetCurrentTimeString;

     ProjectNamePos := AnsiPos(ProjectName, ProjectFullPath);
     ProjectDirPath := copy(ProjectFullPath, 1, ProjectNamePos - 1);
     TimeStr        := ReplaceCharString(TimeStr,':','_');
     VarFilename    := FileName + TimeStr + '.txt';

     ProjectDirPath := ProjectDirPath  +  Log_file_folder ;
     If(not directoryexists(ProjectDirPath)) then
        CreateDir(ProjectDirPath);
     If(not directoryexists(ProjectDirPath)) then
        begin
        ShowInfo ('Can not create folder' + ProjectDirPath);
        Exit;
        end;

     AssignFile(WrkLogFile, ProjectDirPath + '\' + VarFilename);
     Rewrite(WrkLogFile);

     Writeln(WrkLogFile, '############################################################################');
     Writeln(WrkLogFile, '##');
     Writeln(WrkLogFile, '## Processing LOG');
     Writeln(WrkLogFile, '##');
     Writeln(WrkLogFile, '## Project : ' + ProjectFullPath);
     Writeln(WrkLogFile, '## Date    : ' + DateStr + ' ' + TimeStr);
     Writeln(WrkLogFile, '##');
     Writeln(WrkLogFile, '############################################################################');

end;
{======================================================================================================================================================}
// Close LOG file
Procedure CloseLogFile();
begin
     Writeln(WrkLogFile, '');
     Writeln(WrkLogFile, '');
     Writeln(WrkLogFile, '## LOG end');
     Writeln(WrkLogFile, '############################################################################');

     CloseFile(WrkLogFile);
end;
{======================================================================================================================================================}
Procedure WriteLogFileMessage(TextMessage : String);
begin
     Writeln(WrkLogFile,TextMessage);
end;
{======================================================================================================================================================}
// Open Report file
Procedure OpenRaportFile(FileName : String);
var
     Project         : IProject;
     ProjectName     : String;
     ProjectNamePos  : Integer;
     ProjectFullPath : String;
     ProjectDirPath  : String;
     DateStr         : String;
     TimeStr         : String;
     VarFilename     : String;

begin
     Project := GetWorkspace.DM_FocusedProject;

     If Project = Nil Then Exit;
     ProjectName     := Project.DM_ProjectFileName;
     ProjectFullPath := Project.DM_ProjectFullPath;

     DateStr := GetCurrentDateString;
     TimeStr := GetCurrentTimeString;

     ProjectNamePos := AnsiPos(ProjectName, ProjectFullPath);
     ProjectDirPath := copy(ProjectFullPath, 1, ProjectNamePos - 1);
     TimeStr        := ReplaceCharString(TimeStr,':','_');
     VarFilename    := FileName + TimeStr + '.txt';
     ProjectDirPath := ProjectDirPath  +  Report_file_folder ;
     If(not directoryexists(ProjectDirPath)) then
        CreateDir(ProjectDirPath);
     If(not directoryexists(ProjectDirPath)) then
        begin
        ShowInfo ('Can not create folder' + ProjectDirPath);
        Exit;
        end;

     AssignFile(WrkRepFile, ProjectDirPath + '\' + VarFilename);
     Rewrite(WrkRepFile);

     Writeln(WrkRepFile, '############################################################################');
     Writeln(WrkRepFile, '##');
     Writeln(WrkRepFile, '## Missing parameters report');
     Writeln(WrkRepFile, '##');
     Writeln(WrkRepFile, '## Project : ' + ProjectFullPath);
     Writeln(WrkRepFile, '## Date    : ' + DateStr + ' ' + TimeStr);
     Writeln(WrkRepFile, '##');
     Writeln(WrkRepFile, '############################################################################');

end;
{======================================================================================================================================================}
// Close Report file
Procedure CloseReportFile();
begin
     Writeln(WrkRepFile, '');
     Writeln(WrkRepFile, '');
     Writeln(WrkRepFile, '## Report end');
     Writeln(WrkRepFile, '############################################################################');

     CloseFile(WrkRepFile);
end;

{======================================================================================================================================================}
// Write LOG  procedures
Procedure LogUnrecognisedComponent(SCH_CMP_CMMNT : String; ComponentDesignator : String; RptParameterName :String ; Comment :String);
begin
     TxTMessage:='#   ' + SCH_CMP_CMMNT +'  ' ;
     TxTMessage:= TxTMessage + '#_  ' + '''' + ComponentDesignator + '''' + ' ';
     TxTMessage:= TxTMessage + '''' + RptParameterName + ''' ''' + Comment + '''' + ' ''OFF''';
     Writeln(WrkRepFile,TxTMessage);
end;
{======================================================================================================================================================}
// The main work horse
{======================================================================================================================================================}
Procedure MTBF_AddUserDefinedParametersToComponents(SchDoc : ISch_Document; New_Component);
Var
    Component       : ISch_Component;
    Param           : ISch_Parameter;
    Parameter       : ISch_Parameter;
    Iterator        : ISch_Iterator;
    PIterator       : ISch_Iterator;

    ALTIUM_Lenght            : Integer;
    ComponentDscriptNoSpaces : String;
    Parameter_Exist          : Boolean;
    NewValue                 : String;
    NewValueIsHidden         : Boolean;
    FirstDesignatorDigit     : Integer;
Begin
    // init value - only one line for given parameters missing in one component
    LastUsedDesignator :='?';

    // Create a user defined parameter object and add it to all components.
    // Look for components only
    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    Try
       SchServer.ProcessControl.PreProcess(SchDoc, '');
       Try
           Component := Iterator.FirstSchObject;
           While Component <> Nil Do
           Begin
             // Check if got proper componenet
             ComponentDscriptNoSpaces := RemoveSpaces(Component.ComponentDescription);
             ALTIUM_Lenght := GetStringLenght(New_Component[ALTIUM_NAME]);
             FirstDesignatorDigit := GetDesignatorFirstDigit(Component.Designator.Text); // find first digit
              if(
                 // check designator
                 (UpperCase(New_Component[ALTIUM_NAME]) = UpperCase(Component.Designator.Text)) or
                 // check description
                 ((AnsiPos(UpperCase(New_Component[ALTIUM_NAME]),UpperCase(ComponentDscriptNoSpaces)) <> 0) and (ALTIUM_Lenght<>1)) or
                 // check group
                 ((AnsiPos(UpperCase(New_Component[ALTIUM_NAME]),UpperCase(Component.Designator.Text)) = 1) and (ALTIUM_Lenght = (FirstDesignatorDigit-1))) or
                 // ALL components?
                 (New_Component[ALTIUM_NAME]='All')  or
                 //component selected ?
                 (Component.Selection = true)
              )then
               begin
                    // check if parameter already exist?
                    Parameter_Exist := False;
                    Try
                     PIterator := Component.SchIterator_Create;
                     PIterator.AddFilter_ObjectSet(MkSet(eParameter));
                     Parameter := PIterator.FirstSchObject;
                     While(( Parameter <> Nil) and (Parameter_Exist = False)) Do
                       Begin
                         // Check for parameters that have the UserDefinedName Name.
                       If Parameter.Name = New_Component[RS_PAR_NAME] then //UserDefinedName
                         Parameter_Exist := True
                       else
                         Parameter := PIterator.NextSchObject;
                       End;
                     Finally
                       Component.SchIterator_Destroy(PIterator);
                     End;
                     if (Parameter_Exist = False ) then
                        begin
                        // Add the parameter to the pin with undo stack also enabled
                        Param     := SchServer.SchObjectFactory (eParameter , eCreate_Default);
                        Param.Name     := New_Component[RS_PAR_NAME];
                        Param.ShowName := False;
                        Param.Text     := RestoreSpaces(New_Component[RS_PAR_VALUE]);
                        if( New_Component[RS_PAR_VISIBLE] = 'ON') then
                            Param.IsHidden := False
                        else
                            Param.IsHidden := True;
                        // Param object is placed 0.1 Dxp Units above the component.
                        Param.Location := Point(Component.Location.X, Component.Location.Y + DxpsToCoord(0.1));
                        Component.AddSchObject(Param);
                        SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_PrimitiveRegistration, Param.I_ObjectAddress);
                        end        //no coma since else
                    else       // if exist modify value
                        begin
                        NewValue := RestoreSpaces(New_Component[RS_PAR_VALUE]);
                        if( New_Component[RS_PAR_VISIBLE] = 'ON') then   // if exist modify visibility if required
                            NewValueIsHidden := False
                        else
                            NewValueIsHidden := True;
                                                                         // check if something new
                        if( (Parameter.Text <> NewValue) or (Parameter.IsHidden xor NewValueIsHidden)) then
                            begin
                            SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                            Parameter.Text := NewValue;
                            Parameter.IsHidden := NewValueIsHidden;
                            SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
                            end;
                    End;
              end;
              Component := Iterator.NextSchObject;
           End;

        Finally
           SchDoc.SchIterator_Destroy(Iterator);
        End;
    Finally
        SchServer.ProcessControl.PostProcess(SchDoc, '');
    End;
End;
{======================================================================================================================================================}
Procedure MTBF_CopyDefinedParametersValue(SchDoc : ISch_Document; New_Component);
Var
    Component       : ISch_Component;
    Param           : ISch_Parameter;
    Parameter       : ISch_Parameter;
    Iterator        : ISch_Iterator;
    PIterator       : ISch_Iterator;

    ALTIUM_Lenght            : Integer;
    ComponentDscriptNoSpaces : String;
    SrcParameter_Exist       : Boolean;
    DstParameter_Exist       : Boolean;
    ValueToCopy              : String;
 VisibilityToCopy   : Boolean;
    FirstDesignatorDigit     : Integer;
Begin
    // Create a user defined parameter object and add it to all components.
    // Look for components only
    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    Try
       SchServer.ProcessControl.PreProcess(SchDoc, '');
        Try
           Component := Iterator.FirstSchObject;
           While Component <> Nil Do
           Begin
             // Check if got proper componenet
             ComponentDscriptNoSpaces := RemoveSpaces(Component.ComponentDescription);
             ALTIUM_Lenght := GetStringLenght(New_Component[ALTIUM_NAME]);
             FirstDesignatorDigit := GetDesignatorFirstDigit(Component.Designator.Text); // find first digit
             if(
                 // check designator
                 (UpperCase(New_Component[ALTIUM_NAME]) = UpperCase(Component.Designator.Text)) or
                 // check description
                 ((AnsiPos(UpperCase(New_Component[ALTIUM_NAME]),UpperCase(ComponentDscriptNoSpaces)) <> 0) and (ALTIUM_Lenght<>1)) or
                 // check group
                 ((AnsiPos(UpperCase(New_Component[ALTIUM_NAME]),UpperCase(Component.Designator.Text)) = 1) and (ALTIUM_Lenght = (FirstDesignatorDigit-1))) or
                 // ALL components?
                 (New_Component[ALTIUM_NAME]='All')  or
                 //component selected ?
                 (Component.Selection = true)
             )then
                Begin
                    // check if source parameter already exist?
                    SrcParameter_Exist := False;
                    Try
                    PIterator := Component.SchIterator_Create;
                    PIterator.AddFilter_ObjectSet(MkSet(eParameter));
                    Parameter := PIterator.FirstSchObject;
                    While(( Parameter <> Nil) and (SrcParameter_Exist = False)) Do
                        Begin
                         // Check for parameters that have the source data.
                        if Parameter.Name = New_Component[2] then
                            begin
                            SrcParameter_Exist := True;
                            ValueToCopy := Parameter.Text;
                            VisibilityToCopy := Parameter.IsHidden ;
                            end
                        else
                            Parameter := PIterator.NextSchObject;
                    End;
                    Finally
                       Component.SchIterator_Destroy(PIterator);
                    End;
                    if (SrcParameter_Exist = True ) then
                      // find destination parametr
                        Begin
                        DstParameter_Exist := False;
                        Try
                        PIterator := Component.SchIterator_Create;
                        PIterator.AddFilter_ObjectSet(MkSet(eParameter));
                        Parameter := PIterator.FirstSchObject;
                        While(( Parameter <> Nil) and (DstParameter_Exist = False)) Do
                            Begin
                            // Check for parameters that have the destination data.
                            If Parameter.Name = New_Component[RS_PAR_VISIBLE] then
                                DstParameter_Exist := True
                            else
                                Parameter := PIterator.NextSchObject;
                        End;
                        Finally
                            Component.SchIterator_Destroy(PIterator);
                        End;
                        if(DstParameter_Exist = False) then 
                            begin
                            // Add the parameter to the pin with undo stack also enabled
                            Param         := SchServer.SchObjectFactory (eParameter , eCreate_Default);
                            Param.Name     := New_Component[RS_PAR_VISIBLE];
                            Param.ShowName := False;
                            Param.Text     := ValueToCopy;
                            Param.IsHidden := VisibilityToCopy;
                            // Param object is placed 0.1 Dxp Units above the component.
                            Param.Location := Point(Component.Location.X, Component.Location.Y + DxpsToCoord(0.1));
                            Component.AddSchObject(Param);
                            SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_PrimitiveRegistration, Param.I_ObjectAddress);
                            end        //no coma since else
                        else       // if exist modify value
                            begin
                            // check if something new
                            if( (Parameter.Text <> ValueToCopy) or (Parameter.IsHidden xor VisibilityToCopy)) then
                                begin
                                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                                Parameter.Text := ValueToCopy;
                                Parameter.IsHidden := VisibilityToCopy;
                                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
                                end;
                            end;       
                End;
            end;
            Component := Iterator.NextSchObject;
        End;

        Finally
           SchDoc.SchIterator_Destroy(Iterator);
        End;
    Finally
        SchServer.ProcessControl.PostProcess(SchDoc, '');
    End;
End;
{======================================================================================================================================================}
{======================================================================================================================================================}
// Raport utility - logs not categorised components
{======================================================================================================================================================}
Procedure MTBF_VerifyUSerDefinedParametersOfComponents(Sheet : ISch_Document; UserDefined : String);
Var
    Component     : ISch_Component;
    Parameter     : ISch_Parameter;
    Iterator      : ISch_Iterator;
    PIterator     : ISch_Iterator;
    ParameterFound :boolean;

Begin
    If Sheet = Nil Then Exit;



    // Look for components only
    Iterator := Sheet.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    // Initialize the robots in Schematic editor.
    SchServer.ProcessControl.PreProcess(Sheet, '');
    Try
        Component := Iterator.FirstSchObject;

        While Component <> Nil Do
        Begin
            Try
                PIterator := Component.SchIterator_Create;
                PIterator.AddFilter_ObjectSet(MkSet(eParameter));

                Parameter := PIterator.FirstSchObject;
                ParameterFound := false;

                While ((Parameter <> Nil)  and (ParameterFound = false)) Do
                Begin
                    // Check for UserDefined parameter
                    if (Parameter.Name = UserDefined) then
                       begin
                       ParameterFound := true;
                       if (AnsiPos('?',Parameter.Text) <> 0) then
                           begin
                           if(LastUsedDesignator <> Component.Designator.Text) then
                              begin
                              TxTMessage := 'Component:' + Component.Designator.Text + ':' + Component.Comment.Text + ' not defined: ' + UserDefined + ' yet';
                              WriteLogFileMessage(TxTMessage);
                              LogUnrecognisedComponent(Component.Comment.Text,Component.Designator.Text,UserDefined,'Not defined');
                              LastUsedDesignator := Component.Designator.Text;
                              end;
                           end;
                       End;
                    Parameter := PIterator.NextSchObject;
                End;
                if(ParameterFound = false) then
                       begin
                           if(LastUsedDesignator <> Component.Designator.Text) then
                               begin
                               TxTMessage := 'Component:' + Component.Designator.Text + ' not assigned:' + UserDefined ;
                               WriteLogFileMessage(TxTMessage);
                               LogUnrecognisedComponent(Component.Comment.Text,Component.Designator.Text,UserDefined,'Not existed');
                               LastUsedDesignator := Component.Designator.Text;
                           end;
                       End;

            Finally
                Component.SchIterator_Destroy(PIterator);
            End;
            Component := Iterator.NextSchObject;
        End;
    Finally
        Sheet.SchIterator_Destroy(Iterator);
    End;

    // Clean up robots in Schematic editor.
    SchServer.ProcessControl.PostProcess(Sheet, '');
    // Refresh the screen
    Sheet.GraphicallyInvalidate;
End;

{======================================================================================================================================================}
// Raport utility - logs all  categories and thei values for all components
{======================================================================================================================================================}
Procedure MTBF_LogUSerDefinedParametersOfComponents(Sheet : ISch_Document);
Var
    Component       : ISch_Component;
    Parameter       : ISch_Parameter;
    Iterator        : ISch_Iterator;
    PIterator       : ISch_Iterator;
    Par_Visibility  : String;
    ComponentNameLogged :boolean;
Begin
    If Sheet = Nil Then Exit;

    // Look for components only
    Iterator := Sheet.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    // Initialize the robots in Schematic editor.
    SchServer.ProcessControl.PreProcess(Sheet, '');
    Try
        Component := Iterator.FirstSchObject;
        While Component <> Nil Do
        Begin
             ComponentNameLogged:=false;
             Try
                PIterator := Component.SchIterator_Create;
                PIterator.AddFilter_ObjectSet(MkSet(eParameter));
                Parameter := PIterator.FirstSchObject;
                While (Parameter <> Nil ) Do            // log reliability parameters
                Begin
                    if (ComponentNameLogged = false) then // mark new component
                       begin
                       TxTMessage := '# ' + Component.Designator.Text + ':' + Component.Comment.Text ;
                       WriteLogFileMessage(TxTMessage);
                       ComponentNameLogged := true;
                       end;
                    if (AnsiPos('_',Parameter.Name) <> 0) then
                       begin
                       if Parameter.IsHidden then
                          Par_Visibility:= 'OFF'
                       else
                          Par_Visibility:= 'ON';
                       TxTMessage := '''' + Component.Designator.Text + ''' ''' + Parameter.Name + ''' ''' + Parameter.Text + ''' ''' + Par_Visibility + '''';
                       WriteLogFileMessage(TxTMessage);
                    end;
                    Parameter := PIterator.NextSchObject;
                End;
            Finally
                Component.SchIterator_Destroy(PIterator);
            End;
            Component := Iterator.NextSchObject;
        End;
    Finally
        Sheet.SchIterator_Destroy(Iterator);
    End;

    // Clean up robots in Schematic editor.
    SchServer.ProcessControl.PostProcess(Sheet, '');
    // Refresh the screen
    Sheet.GraphicallyInvalidate;
End;


{======================================================================================================================================================}
// Utility engine for removing all parameters with names starts with given Prefix
{======================================================================================================================================================}

Procedure MTBF_DeleteUserDefinedParametersOfComponents(SchDoc : ISch_Document; Prefix:String);
Var
    Component     : ISch_Component;
    OldParameter  : ISch_Parameter;
    Parameter     : ISch_Parameter;
    Iterator      : ISch_Iterator;
    PIterator     : ISch_Iterator;
    I             : Integer;
    ParameterList : TInterfaceList;
Begin
    // Initialize the robots in Schematic editor.
    SchServer.ProcessControl.PreProcess(SchDoc, '');

    // Look for components only
    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    ParameterList := TInterfaceList.Create;
    Try
        Component := Iterator.FirstSchObject;
        While Component <> Nil Do
        Begin
            Try
                PIterator := Component.SchIterator_Create;
                PIterator.AddFilter_ObjectSet(MkSet(eParameter));

                Parameter := PIterator.FirstSchObject;
                While Parameter <> Nil Do
                Begin
                 //delete parameters starting with given prefix
                    If (Ansipos(Prefix,Parameter.Name) = 1) Then
                         ParameterList.Add(Parameter);
                    Parameter := PIterator.NextSChObject;
                End;
            Finally
               Component.SchIterator_Destroy(PIterator);
            End;
            Component := Iterator.NextSchObject;
        End;
    Finally
        SchDoc.SchIterator_Destroy(Iterator);
    End;

    // Remove Parameters from their components
    Try
        For I := 0 to ParameterList.Count - 1 Do
        Begin
            Parameter := ParameterList.items[i];

            // Obtain the parent object which is the component
            // that user defined param is part of.
            Component := Parameter.Container;
            Component.RemoveSchObject(Parameter);

            SchServer.RobotManager.SendMessage(Component.I_ObjectAddress,c_BroadCast,SCHM_PrimitiveRegistration,Parameter.I_ObjectAddress);
        End;
    Finally
        ParameterList.Free;
    End;

    // Clean up robots in Schematic editor.
    SchServer.ProcessControl.PostProcess(SchDoc, '');

    // Refresh the screen
    SchDoc.GraphicallyInvalidate;
End;

{======================================================================================================================================================}
// Utility engine for renaming all parameters Prefix with new Prefix
{======================================================================================================================================================}

Procedure MTBF_RenameParametersPrefixOfComponents(SchDoc : ISch_Document; OldPrefix:String;NewPrefix:String);
Var
    Component     : ISch_Component;
    OldParameter  : ISch_Parameter;
    Parameter     : ISch_Parameter;
    Iterator      : ISch_Iterator;
    PIterator     : ISch_Iterator;
    I             : Integer;
    ParameterList : TInterfaceList;
    Name2change   :string; 
Begin
    // Initialize the robots in Schematic editor.
    SchServer.ProcessControl.PreProcess(SchDoc, '');

    // Look for components only
    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

    Try
        Component := Iterator.FirstSchObject;
        While Component <> Nil Do
        Begin
            Try
                PIterator := Component.SchIterator_Create;
                PIterator.AddFilter_ObjectSet(MkSet(eParameter));

                Parameter := PIterator.FirstSchObject;
                While Parameter <> Nil Do
                Begin
                 //find parameters starting with given prefix
                    If (Ansipos(OldPrefix,Parameter.Name) = 1) Then
                        Begin

                           SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                            Name2change := copy(Parameter.Name,GetStringLenght(OldPrefix),(GetStringLenght(Parameter.Name)-GetStringLenght(OldPrefix)));
       Parameter.Name:=NewPrefix+Name2change;
                            SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
   end;
                    Parameter := PIterator.NextSChObject;
                End;
            Finally
               Component.SchIterator_Destroy(PIterator);
            End;
            Component := Iterator.NextSchObject;
        End;
    Finally
        SchDoc.SchIterator_Destroy(Iterator);
    End;


    // Clean up robots in Schematic editor.
    SchServer.ProcessControl.PostProcess(SchDoc, '');

    // Refresh the screen
    SchDoc.GraphicallyInvalidate;
End;

{*******************************************************************************************************************************************************}
{*******************************************************************************************************************************************************}
// Main FUNCTION
{*******************************************************************************************************************************************************}
{*******************************************************************************************************************************************************}
Procedure MTBF_AddComponentUserParameters;
var
    I             : Integer;
    Doc           : IDocument;
    CurrentSch    : ISch_Document;
    SchDocument   : IServerDocument;
    Project       : IProject;

    ProjectName   : String;
    ProjectFullPath :  String;
    ParamFilePath : String;

    ComponentPAR  :  array[0..3] of string ;
    cfgFile       : TextFile;

    Parameter_List       : TStringList;
    Parameter_Array      : TStringList;
    cfgFileline_nr       : integer;
    line_first_char      : character;
    Schematic_processed  : integer;

    RdResult             : boolean;
    NextComponent        : boolean;
    NextComponentName    : String;

Begin


Project := GetWorkspace.DM_FocusedProject;
ProjectName:=Project.DM_ProjectFileName;
//-------------------------------------------------------

  // Get user parameters file path
  ParamFilePath := GetFile(0);

    TxTMessage:=ParamFilePath;
    while (AnsiPos('\',TxTMessage)<> 0)do
    Begin
       I:= AnsiPos('\',TxTMessage)+1;
       TxTMessage := Copy(TxTMessage,I,100);
    End;
    ParamFileName := TxTMessage;

  if FileExists(ParamFilePath) then
    begin
    RdResult:=ConfirmNoYes('Proceed with file: ' + ParamFileName +' ?');
    if (RdResult = false) then
       Exit;
    end;
  if (FileExists(ParamFilePath)=false) then
    begin
    ShowMessage('Config file read error');
    Exit;
    end;


//-------------------------------------------------------

// Open log file
    OpenLogFile(LogFileName);
    TxTMessage := '#  Config:' + ParamFilePath;
    WriteLogFileMessage(TxTMessage);
    TxTMessage := '##';
    WriteLogFileMessage(TxTMessage);

//-------------------------------------------------------
// Open raport file
    OpenRaportFile(NewCfgFileName);
//-------------------------------------------------------
    If Project = Nil Then Exit;
    Project.DM_Compile;

    AssignFile(cfgFile, ParamFilePath);

    Schematic_processed:=0;

    Parameter_Array:= TStringList.Create  ;
    Parameter_List:= TStringList.Create  ;

    // selected or all documents within the project
    For I := 0 to Project.DM_LogicalDocumentCount - 1 Do
    Begin
        Doc := Project.DM_LogicalDocuments(I);
        If (Doc.DM_DocumentKind = 'SCH') Then
        Begin
           Inc(Schematic_processed);
           SchDocument := Client.OpenDocument('Sch', Doc.DM_FullPath);
           If (SchDocument <> Nil) Then
           Begin

               Client.ShowDocument(SchDocument);
               CurrentSch := SchServer.GetCurrentSchDocument;
               If CurrentSch = Nil Then Exit;

               TxTMessage := '# Processing:' + CurrentSch.DocumentName;
               WriteLogFileMessage(TxTMessage);

               // read config file line by line
               Reset(cfgFile);
               cfgFileline_nr := 1;

               RdResult:= true;
               while (not Eof(cfgFile) and RdResult) do
               Begin
                  Try
                      RdResult:=ReadLn(cfgFile, Parameter_List);
                  except
                      RdResult:=false;
                  end;

                  inc (cfgFileline_nr);
               // empty line read protection    DOES NOT WORK!!! Eoln not implemented
                  if ( RdResult ) then
                  begin
                    Try
                    line_first_char:=Parameter_List[1];
                    Except
                    RdResult:=false;
                    end;

                    if((Eof(cfgFile) <> True) and RdResult) then
                          begin

                          if(line_first_char <> '#') then            // check if no comment line
                               begin
                                   Parameter_Array.Clear;
                                   Parameter_Array.Delimiter       := ' ';
                                   Parameter_Array.StrictDelimiter := True; // Requires D2006 or newer.
                                   Parameter_Array.DelimitedText   := Parameter_list;
                                   // check if 4 fields read
                                   if (Parameter_Array.Count = 4 ) then
                                      begin
                                      NextComponent := false;
                                      NextComponentName := RemoveQuotes(Parameter_Array[0]);//AnsiExtractQuotedStr(Parameter_Array[0],'''');
                                      if(ComponentPAR[ALTIUM_NAME] <> NextComponentName) then
                                         begin
                                         ComponentPAR[ALTIUM_NAME] := NextComponentName;
                                         NextComponent := true;
                                         end;
                                      ComponentPAR[RS_PAR_NAME] := RemoveQuotes(Parameter_Array[1]);//AnsiExtractQuotedStr(Parameter_Array[1],'''');
                                      ComponentPAR[RS_PAR_VALUE] := RemoveQuotes(Parameter_Array[2]);//AnsiExtractQuotedStr(Parameter_Array[2],'''');
                                      ComponentPAR[RS_PAR_VISIBLE] := RemoveQuotes(Parameter_Array[3]);//AnsiExtractQuotedStr(Parameter_Array[3],'''');

                                      if(NextComponent = true) then
                                         begin
                                         TxTMessage := '#' + chr(9) + 'For:' + ComponentPAR[ALTIUM_NAME];
                                         WriteLogFileMessage(TxTMessage);
                                         TxTMessage := '#' + chr(9) + chr(9) + 'Parameter:' + ComponentPAR[RS_PAR_NAME];
                                         WriteLogFileMessage(TxTMessage);
                                         end
                                      else
                                         begin
                                         TxTMessage := chr(9) + chr(9) +  'Parameter:' + ComponentPAR[RS_PAR_NAME];
                                         WriteLogFileMessage(TxTMessage);
                                         end;
                                      // now, do the job
                                      if(ComponentPAR[ALTIUM_NAME]<> '???') then
                                          if(ComponentPAR[RS_PAR_NAME]<> '>>>') then
                                             MTBF_AddUserDefinedParametersToComponents(CurrentSch,ComponentPAR)
                                          else
                                             MTBF_CopyDefinedParametersValue(CurrentSch,ComponentPAR)
                                      else
                                          if(ComponentPAR[RS_PAR_NAME]<> '???') then
                                             MTBF_VerifyUSerDefinedParametersOfComponents(CurrentSch,ComponentPAR[RS_PAR_NAME])
                                          else
                                             MTBF_LogUSerDefinedParametersOfComponents(CurrentSch);
                                      end;
                                   // handle different than 4 fields read
                                   if (Parameter_Array.Count <> 4 ) then
                                      begin
                                      TxTMessage := 'Syntax error in config ' + ParamFileName + ' file in line nr:' + IntToStr(cfgFileline_nr);
                                      WriteLogFileMessage(TxTMessage);
                                      ShowInfo (TxTMessage);
                                      Reset(cfgFile);
                                      CloseFile(cfgFile);
                                      CloseLogFile();
                                      Exit;
                                      end;
                               end;
                          end;
                        end;
               end;
               Reset(cfgFile);
               CloseFile(cfgFile);
           end;
        end;
    end;

    Reset(cfgFile);
    CloseFile(cfgFile);
    CloseLogFile();
    CloseReportFile();
    TxTMessage := 'Processing ' + ProjectName + ' done. Processed ' + IntToStr(Schematic_processed) + ' sheets';
    ShowInfo (TxTMessage);
    Exit;

End;
{======================================================================================================================================================}
// Utility for removing all parameters with names starts with prefix
// Scans all SCH files with  MTBF_DeleteUserDefinedParametersOfComponents engine
{======================================================================================================================================================}

Procedure MTBF_DeleteComponentUserParameters;

Const
    ParamPrefix = 'SN_';
Var
    I           : Integer;
    Project     : IProject;
    Doc         : IDocument;
    CurrentSch  : ISch_Document;
    SchDocument : IServerDocument;
    ProjectName : String;
Begin
    Project := GetWorkspace.DM_FocusedProject;
    If Project = Nil Then Exit;
    Project.DM_Compile;

    ProjectName:=Project.DM_ProjectFileName;
    // selected or all documents within the project
    For I := 0 to Project.DM_LogicalDocumentCount - 1 Do
    Begin
        Doc := Project.DM_LogicalDocuments(I);
        If Doc.DM_DocumentKind = 'SCH' Then
           Begin
           SchDocument := Client.OpenDocument('Sch', Doc.DM_FullPath);
           If SchDocument <> Nil Then
           Begin
               Client.ShowDocument(SchDocument);
               CurrentSch := SchServer.GetCurrentSchDocument;
               If CurrentSch = Nil Then Exit;
               MTBF_DeleteUserDefinedParametersOfComponents(CurrentSch,ParamPrefix);
           End;
        End;
    End;
    ShowInfo ('Deleting parameters with name prefix:' + '''' + ParamPrefix + '''' + ' done');
    Exit;
End;
{======================================================================================================================================================}
{======================================================================================================================================================}
// Utility for renaming all parameters prefix
// Scans all SCH files with  MTBF_RenameUserDefinedParametersOfComponents engine
{======================================================================================================================================================}

Procedure MTBF_RenameComponentUserParameters;

Const
    OldPrefix = 'SN_';
    NewPrefix = 'ML_';
Var
    I           : Integer;
    Project     : IProject;
    Doc         : IDocument;
    CurrentSch  : ISch_Document;
    SchDocument : IServerDocument;
    ProjectName : String;
Begin
    Project := GetWorkspace.DM_FocusedProject;
    If Project = Nil Then Exit;
    Project.DM_Compile;

    ProjectName:=Project.DM_ProjectFileName;
    // selected or all documents within the project
    For I := 0 to Project.DM_LogicalDocumentCount - 1 Do
    Begin
        Doc := Project.DM_LogicalDocuments(I);
        If Doc.DM_DocumentKind = 'SCH' Then
           Begin
           SchDocument := Client.OpenDocument('Sch', Doc.DM_FullPath);
           If SchDocument <> Nil Then
           Begin
               Client.ShowDocument(SchDocument);
               CurrentSch := SchServer.GetCurrentSchDocument;
               If CurrentSch = Nil Then Exit;
               MTBF_RenameParametersPrefixOfComponents(CurrentSch,OldPrefix,NewPrefix);
           End;
        End;
    End;
    ShowInfo ('Renaming parameters with name prefix:' + '''' + OldPrefix + '''' + 'with' + '''' + NewPrefix + '''' + ' done');
    Exit;
End;
{======================================================================================================================================================}


