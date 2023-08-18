uses Utils, Utils_logs;

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
             ComponentDscriptNoSpaces := RemoveChar(Component.ComponentDescription, ' ');
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
                        Param.Text     := ReplaceCharString(New_Component[RS_PAR_VALUE], '*', ' ');
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
                        NewValue := ReplaceCharString(New_Component[RS_PAR_VALUE], '*', ' ');
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
             ComponentDscriptNoSpaces := RemoveChar(Component.ComponentDescription, ' ');
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
                              WriteLogFileMessage(TxTMessage, WrkLogFile);
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
                               WriteLogFileMessage(TxTMessage, WrkLogFile);
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
                       WriteLogFileMessage(TxTMessage, WrkLogFile);
                       ComponentNameLogged := true;
                       end;
                    if (AnsiPos('_',Parameter.Name) <> 0) then
                       begin
                       if Parameter.IsHidden then
                          Par_Visibility:= 'OFF'
                       else
                          Par_Visibility:= 'ON';
                       TxTMessage := '''' + Component.Designator.Text + ''' ''' + Parameter.Name + ''' ''' + Parameter.Text + ''' ''' + Par_Visibility + '''';
                       WriteLogFileMessage(TxTMessage, WrkLogFile);
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
    WrkLogFile := OpenMyFile(LogFileName, 'LOG');
    TxTMessage := '#  Config:' + ParamFilePath;
    WriteLogFileMessage(TxTMessage, WrkLogFile);
    TxTMessage := '##';
    WriteLogFileMessage(TxTMessage, WrkLogFile);

//-------------------------------------------------------
// Open raport file
    WrkRepFile := OpenMyFile(NewCfgFileName, 'REP');
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
               WriteLogFileMessage(TxTMessage, WrkLogFile);

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
                                      NextComponentName := RemoveChar(Parameter_Array[0], '''');//AnsiExtractQuotedStr(Parameter_Array[0],'''');
                                      if(ComponentPAR[ALTIUM_NAME] <> NextComponentName) then
                                         begin
                                         ComponentPAR[ALTIUM_NAME] := NextComponentName;
                                         NextComponent := true;
                                         end;
                                      ComponentPAR[RS_PAR_NAME] := RemoveChar(Parameter_Array[1], '''');//AnsiExtractQuotedStr(Parameter_Array[1],'''');
                                      ComponentPAR[RS_PAR_VALUE] := RemoveChar(Parameter_Array[2], '''');//AnsiExtractQuotedStr(Parameter_Array[2],'''');
                                      ComponentPAR[RS_PAR_VISIBLE] := RemoveChar(Parameter_Array[3], '''');//AnsiExtractQuotedStr(Parameter_Array[3],'''');

                                      if(NextComponent = true) then
                                         begin
                                         TxTMessage := '#' + chr(9) + 'For:' + ComponentPAR[ALTIUM_NAME];
                                         WriteLogFileMessage(TxTMessage, WrkLogFile);
                                         TxTMessage := '#' + chr(9) + chr(9) + 'Parameter:' + ComponentPAR[RS_PAR_NAME];
                                         WriteLogFileMessage(TxTMessage, WrkLogFile);
                                         end
                                      else
                                         begin
                                         TxTMessage := chr(9) + chr(9) +  'Parameter:' + ComponentPAR[RS_PAR_NAME];
                                         WriteLogFileMessage(TxTMessage, WrkLogFile);
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
                                      WriteLogFileMessage(TxTMessage, WrkLogFile);
                                      ShowInfo (TxTMessage);
                                      Reset(cfgFile);
                                      CloseFile(cfgFile);
                                      CloseMyFile(WrkLogFile);
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
    CloseMyFile(WrkLogFile);
    CloseMyFile(WrkRepFile);
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


