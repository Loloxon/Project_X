uses Utils, Utils_logs, SysUtils;

const
  OPERATION_TYPE = 0;
  ALTIUM_NAME = 1;     // pointers to   ComponentPAR  :  array[0..4] of string ;
  RS_PAR_NAME = 2;
  RS_PAR_VALUE = 3;
  RS_PAR_VISIBLE = 4;

// LOG file name start timestamp will be added
// consts for logs and reports (name of folders and files)
  LogFileName = 'LOG';
  NewCfgFileName = 'Missing';
  Log_file_folder = 'LP_LOG';
  Report_file_folder = 'LP_RPT';

var
  I: Integer;
  Doc: IDocument;
  CurrentSch: ISch_Document;
  SchDocument: IServerDocument;
  Project: IProject;

  ConfigPAR: IDocument;
  ParamFileName: String;
  WrkLogFile: TextFile;
  WrkRptFile: TextFile;
  TxTMessage: String;
  LastUsedDesignator: String;

{======================================================================================================================================================}
// The main work horse
{======================================================================================================================================================}
Procedure MTBF_AddUserDefinedParametersToComponentsByCategory(SchDoc: ISch_Document; New_Component);
var
  Component: ISch_Component;
  Component_Child: ISch_Component;
  Param: ISch_Parameter;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  Component_Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;

  ALTIUM_Lenght: Integer;
  ComponentDscriptNoSpaces: String;
  Parameter_Exist: Boolean;
  NewValue: String;
  NewValueIsHidden: Boolean;
  FirstDesignatorDigit: Integer;
  Boolean1: Boolean;
begin
  // init value - only one line for given parameters missing in one component
  LastUsedDesignator := '?';

  // Create a user defined parameter object and add it to all components.
  // Look for components only
  Iterator := SchDoc.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
  try
      SchServer.ProcessControl.PreProcess(SchDoc, '');
      try
        Component := Iterator.FirstSchObject;
        while Component <> Nil do
        begin
          Boolean1 := False;
          Component_Iterator := Component.SchIterator_Create;
          Component_Iterator.AddFilter_ObjectSet(MkSet(eParameter));
          Component_Child := Component_Iterator.FirstSchObject;
          while Component_Child <> Nil do
          begin
            if (Component_Child.Name = 'SN_CATEGORY') and (Component_Child.Text = New_Component[ALTIUM_NAME]) then
            begin
              Boolean1 := True;
              break;
            end;
            Component_Child := Component_Iterator.NextSchObject;
          end;
          if Boolean1 then
          begin
            // check if parameter already exist?
            Parameter_Exist := False;
            try
            PIterator := Component.SchIterator_Create;
            PIterator.AddFilter_ObjectSet(MkSet(eParameter));
            Parameter := PIterator.FirstSchObject;
            while (Parameter <> Nil) and (Parameter_Exist = False) do
            begin
              // Check for parameters that have the UserDefinedName Name.
              if Parameter.Name = New_Component[RS_PAR_NAME] then //UserDefinedName
              Parameter_Exist := True
              else
              Parameter := PIterator.NextSchObject;
              end;
            finally
              Component.SchIterator_Destroy(PIterator);
            end;
            if Parameter_Exist = False then
            begin
              // Add the parameter to the pin with undo stack also enabled
              Param := SchServer.SchObjectFactory (eParameter , eCreate_Default);
              Param.Name := New_Component[RS_PAR_NAME];
              Param.ShowName := False;
              Param.Text := ReplaceCharInString(New_Component[RS_PAR_VALUE], '*', ' ');

              if New_Component[RS_PAR_VISIBLE] = 'ON' then
                Param.IsHidden := False
              else
                Param.IsHidden := True;
              // Param object is placed 0.1 Dxp Units above the component.
              Param.Location := Point(Component.Location.X, Component.Location.Y + DxpsToCoord(0.1));
              Component.AddSchObject(Param);
              SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_PrimitiveRegistration, Param.I_ObjectAddress);
              end    //no coma since else
            else     // if exist modify value
              begin
              NewValue := ReplaceCharInString(New_Component[RS_PAR_VALUE], '*', ' ');
              if New_Component[RS_PAR_VISIBLE] = 'ON' then   // if exist modify visibility if required
                NewValueIsHidden := False
              else
                NewValueIsHidden := True;
                                      // check if something new
              if (Parameter.Text <> NewValue) or (Parameter.IsHidden xor NewValueIsHidden) then
                begin
                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                Parameter.Text := NewValue;
                Parameter.IsHidden := NewValueIsHidden;
                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
                end;
            end;
          end;
          Component := Iterator.NextSchObject;
        end;
    finally
      SchDoc.SchIterator_Destroy(Iterator);
    end;
  finally
    SchServer.ProcessControl.PostProcess(SchDoc, '');
  end;
end;

Procedure MTBF_AddUserDefinedParametersToComponentsByName(SchDoc: ISch_Document; New_Component);
var
  Component: ISch_Component;
  Param: ISch_Parameter;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;

  ALTIUM_Lenght: Integer;
  ComponentDscriptNoSpaces: String;
  Parameter_Exist: Boolean;
  NewValue: String;
  NewValueIsHidden: Boolean;
  FirstDesignatorDigit: Integer;
  Boolean1: Boolean;
  Boolean2: Boolean;
  Boolean3: Boolean;
  Boolean4: Boolean;
  Boolean5: Boolean;
begin
  // init value - only one line for given parameters missing in one component
  LastUsedDesignator := '?';

  // Create a user defined parameter object and add it to all components.
  // Look for components only
  Iterator := SchDoc.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

  try
      SchServer.ProcessControl.PreProcess(SchDoc, '');
      try
        Component := Iterator.FirstSchObject;
        while Component <> Nil do
        begin
          // Check if got proper componenet
          ComponentDscriptNoSpaces := RemoveCharFromString(Component.ComponentDescription, ' ');
          ALTIUM_Lenght := GetStringLenght(New_Component[ALTIUM_NAME]);
          FirstDesignatorDigit := GetFirstDigitInString(Component.Designator.Text); // find first digit

          Boolean1 := AnsiStartsStr(UpperCase(New_Component[ALTIUM_NAME]), UpperCase(Component.Designator.Text));

          if Boolean1 then
          begin
            // check if parameter already exist?
            Parameter_Exist := False;
            try
            PIterator := Component.SchIterator_Create;
            PIterator.AddFilter_ObjectSet(MkSet(eParameter));
            Parameter := PIterator.FirstSchObject;
            while (Parameter <> Nil) and (Parameter_Exist = False) do
              begin
              // Check for parameters that have the UserDefinedName Name.
              if Parameter.Name = New_Component[RS_PAR_NAME] then //UserDefinedName
              Parameter_Exist := True
              else
              Parameter := PIterator.NextSchObject;
              end;
            finally
              Component.SchIterator_Destroy(PIterator);
            end;
            if Parameter_Exist = False then
              begin
              // Add the parameter to the pin with undo stack also enabled
              Param := SchServer.SchObjectFactory (eParameter , eCreate_Default);
              Param.Name := New_Component[RS_PAR_NAME];
              Param.ShowName := False;
              Param.Text := ReplaceCharInString(New_Component[RS_PAR_VALUE], '*', ' ');

              if New_Component[RS_PAR_VISIBLE] = 'ON' then
                Param.IsHidden := False
              else
                Param.IsHidden := True;
              // Param object is placed 0.1 Dxp Units above the component.
              Param.Location := Point(Component.Location.X, Component.Location.Y + DxpsToCoord(0.1));
              Component.AddSchObject(Param);
              SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_PrimitiveRegistration, Param.I_ObjectAddress);
              end    //no coma since else
            else     // if exist modify value
              begin
              NewValue := ReplaceCharInString(New_Component[RS_PAR_VALUE], '*', ' ');
              if New_Component[RS_PAR_VISIBLE] = 'ON' then   // if exist modify visibility if required
                NewValueIsHidden := False
              else
                NewValueIsHidden := True;
                                      // check if something new
              if (Parameter.Text <> NewValue) or (Parameter.IsHidden xor NewValueIsHidden) then
                begin
                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                Parameter.Text := NewValue;
                Parameter.IsHidden := NewValueIsHidden;
                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
                end;
            end;
          end;
          Component := Iterator.NextSchObject;
        end;
    finally
      SchDoc.SchIterator_Destroy(Iterator);
    end;
  finally
    SchServer.ProcessControl.PostProcess(SchDoc, '');
  end;
end;
{======================================================================================================================================================}
Procedure MTBF_CopyDefinedParametersValue(SchDoc: ISch_Document; New_Component);
var
  Component: ISch_Component;
  Param: ISch_Parameter;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;

  ALTIUM_Lenght: Integer;
  ComponentDscriptNoSpaces: String;
  SrcParameter_Exist: Boolean;
  DstParameter_Exist: Boolean;
  ValueToCopy: String;
  VisibilityToCopy: Boolean;
  FirstDesignatorDigit: Integer;
  Boolean1: Boolean;
  Boolean2: Boolean;
  Boolean3: Boolean;
  Boolean4: Boolean;
  Boolean5: Boolean;
begin
  // Create a user defined parameter object and add it to all components.
  // Look for components only
  Iterator := SchDoc.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

  try
     SchServer.ProcessControl.PreProcess(SchDoc, '');
    try
       Component := Iterator.FirstSchObject;
       while Component <> Nil do
       begin
       // Check if got proper componenet
       ComponentDscriptNoSpaces := RemoveCharFromString(Component.ComponentDescription, ' ');
       ALTIUM_Lenght := GetStringLenght(New_Component[ALTIUM_NAME]);
       FirstDesignatorDigit := GetFirstDigitInString(Component.Designator.Text); // find first digit
        // check designator
        Boolean1 := UpperCase(New_Component[ALTIUM_NAME]) = UpperCase(Component.Designator.Text);
        // check description
        Boolean2 := (AnsiPos(UpperCase(New_Component[ALTIUM_NAME]),UpperCase(ComponentDscriptNoSpaces)) <> 0) and
                    (ALTIUM_Lenght<>1);
        // check group
        Boolean3 := (AnsiPos(UpperCase(New_Component[ALTIUM_NAME]),UpperCase(Component.Designator.Text)) = 1) and
                    (ALTIUM_Lenght = (FirstDesignatorDigit-1));
        // ALL components?
        Boolean4 := New_Component[ALTIUM_NAME]='All';
        //component selected ?
        Boolean5 := Component.Selection = True;

        if Boolean1 or Boolean2 or Boolean3 or Boolean4 or Boolean5 then
        begin
          // check if source parameter already exist?
          SrcParameter_Exist := False;
          try
          PIterator := Component.SchIterator_Create;
          PIterator.AddFilter_ObjectSet(MkSet(eParameter));
          Parameter := PIterator.FirstSchObject;
          while (Parameter <> Nil) and (SrcParameter_Exist = False) do
            begin
             // Check for parameters that have the source data.
            if Parameter.Name = New_Component[2] then
              begin
              SrcParameter_Exist := True;
              ValueToCopy := Parameter.Text;
              VisibilityToCopy := Parameter.IsHidden ;
              end
            else
              Parameter := PIterator.NextSchObject;
          end;
          finally
             Component.SchIterator_Destroy(PIterator);
          end;
          if SrcParameter_Exist = True then
            // find destination parametr
            begin
            DstParameter_Exist := False;
            try
            PIterator := Component.SchIterator_Create;
            PIterator.AddFilter_ObjectSet(MkSet(eParameter));
            Parameter := PIterator.FirstSchObject;
            while (Parameter <> Nil) and (DstParameter_Exist = False) do
              begin
              // Check for parameters that have the destination data.
              if Parameter.Name = New_Component[RS_PAR_VISIBLE] then
                DstParameter_Exist := True
              else
                Parameter := PIterator.NextSchObject;
            end;
            finally
              Component.SchIterator_Destroy(PIterator);
            end;
            if DstParameter_Exist = False then
              begin
              // Add the parameter to the pin with undo stack also enabled
              Param := SchServer.SchObjectFactory (eParameter , eCreate_Default);
              Param.Name := New_Component[RS_PAR_VISIBLE];
              Param.ShowName := False;
              Param.Text := ValueToCopy;
              Param.IsHidden := VisibilityToCopy;
              // Param object is placed 0.1 Dxp Units above the component.
              Param.Location := Point(Component.Location.X, Component.Location.Y + DxpsToCoord(0.1));
              Component.AddSchObject(Param);
              SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_PrimitiveRegistration, Param.I_ObjectAddress);
              end    //no coma since else
            else     // if exist modify value
              begin
              // check if something new
              if (Parameter.Text <> ValueToCopy) or (Parameter.IsHidden xor VisibilityToCopy) then
                begin
                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                Parameter.Text := ValueToCopy;
                Parameter.IsHidden := VisibilityToCopy;
                SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
                end;
              end;
        end;
      end;
      Component := Iterator.NextSchObject;
    end;

    finally
       SchDoc.SchIterator_Destroy(Iterator);
    end;
  finally
    SchServer.ProcessControl.PostProcess(SchDoc, '');
  end;
end;
{======================================================================================================================================================}
{======================================================================================================================================================}
// Raport utility - logs not categorised components
{======================================================================================================================================================}
Procedure MTBF_VerifyUserDefinedParametersOfComponents(Sheet: ISch_Document; UserDefined: String);
var
  Component: ISch_Component;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;
  ParameterFound: Boolean;

begin
  if Sheet = Nil then Exit;



  // Look for components only
  Iterator := Sheet.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

  // Initialize the robots in Schematic editor.
  SchServer.ProcessControl.PreProcess(Sheet, '');
  try
    Component := Iterator.FirstSchObject;

    while Component <> Nil do
    begin
      try
        PIterator := Component.SchIterator_Create;
        PIterator.AddFilter_ObjectSet(MkSet(eParameter));

        Parameter := PIterator.FirstSchObject;
        ParameterFound := False;

        while (Parameter <> Nil) and (ParameterFound = False) do
        begin
          // Check for UserDefined parameter
          if Parameter.Name = UserDefined then
          begin
            ParameterFound := True;
            if AnsiPos('?',Parameter.Text) <> 0 then
            begin
              if LastUsedDesignator <> Component.Designator.Text then
              begin
                TxTMessage := 'Component:' + Component.Designator.Text + ':' + Component.Comment.Text + ' not defined: ' + UserDefined + ' yet';
                WriteLogFileMessage(TxTMessage, WrkLogFile);
                LogUnrecognisedComponent(Component.Comment.Text,Component.Designator.Text,UserDefined,'Not defined');
                LastUsedDesignator := Component.Designator.Text;
              end;
            end;
          end;
          Parameter := PIterator.NextSchObject;
        end;
        if ParameterFound = False then
        begin
          if LastUsedDesignator <> Component.Designator.Text then
          begin
            TxTMessage := 'Component:' + Component.Designator.Text + ' not assigned:' + UserDefined ;
            WriteLogFileMessage(TxTMessage, WrkLogFile);
            LogUnrecognisedComponent(Component.Comment.Text,Component.Designator.Text,UserDefined,'Not existed');
            LastUsedDesignator := Component.Designator.Text;
          end;
        end;
      finally
        Component.SchIterator_Destroy(PIterator);
      end;
      Component := Iterator.NextSchObject;
    end;
  finally
    Sheet.SchIterator_Destroy(Iterator);
  end;

  // Clean up robots in Schematic editor.
  SchServer.ProcessControl.PostProcess(Sheet, '');
  // Refresh the screen
  Sheet.GraphicallyInvalidate;
end;

{======================================================================================================================================================}
// Raport utility - logs all  categories and thei values for all components
{======================================================================================================================================================}
Procedure MTBF_LogUserDefinedParametersOfComponents(Sheet: ISch_Document);
var
  Component: ISch_Component;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;
  Par_Visibility: String;
  ComponentNameLogged: Boolean;
begin
  if Sheet = Nil then Exit;

  // Look for components only
  Iterator := Sheet.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

  // Initialize the robots in Schematic editor.
  SchServer.ProcessControl.PreProcess(Sheet, '');
  try
    Component := Iterator.FirstSchObject;
    while Component <> Nil do
    begin
       ComponentNameLogged:=False;
       try
        PIterator := Component.SchIterator_Create;
        PIterator.AddFilter_ObjectSet(MkSet(eParameter));
        Parameter := PIterator.FirstSchObject;
        while Parameter <> Nil do      // log reliability parameters
        begin
          if ComponentNameLogged = False then // mark new component
          begin
            TxTMessage := '# ' + Component.Designator.Text + ':' + Component.Comment.Text ;
            WriteLogFileMessage(TxTMessage, WrkLogFile);
            ComponentNameLogged := True;
          end;
          if AnsiPos('_',Parameter.Name) <> 0 then
          begin
            if Parameter.IsHidden then
              Par_Visibility:= 'OFF'
            else
              Par_Visibility:= 'ON';
            TxTMessage := '''' + Component.Designator.Text + ''' ''' + Parameter.Name + ''' ''' + Parameter.Text + ''' ''' + Par_Visibility + '''';
            WriteLogFileMessage(TxTMessage, WrkLogFile);
          end;
          Parameter := PIterator.NextSchObject;
        end;
      finally
        Component.SchIterator_Destroy(PIterator);
      end;
      Component := Iterator.NextSchObject;
    end;
  finally
    Sheet.SchIterator_Destroy(Iterator);
  end;

  // Clean up robots in Schematic editor.
  SchServer.ProcessControl.PostProcess(Sheet, '');
  // Refresh the screen
  Sheet.GraphicallyInvalidate;
end;


{======================================================================================================================================================}
// Utility engine for removing all parameters with names starts with given Prefix
{======================================================================================================================================================}

Procedure MTBF_DeleteUserDefinedParametersOfComponents(SchDoc : ISch_Document; Prefix:String);
var
  Component: ISch_Component;
  OldParameter: ISch_Parameter;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;
  I: Integer;
  ParameterList: TInterfaceList;
begin
  // Initialize the robots in Schematic editor.
  SchServer.ProcessControl.PreProcess(SchDoc, '');

  // Look for components only
  Iterator := SchDoc.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

  ParameterList := TInterfaceList.Create;
  try
    Component := Iterator.FirstSchObject;
    while Component <> Nil do
    begin
      try
        PIterator := Component.SchIterator_Create;
        PIterator.AddFilter_ObjectSet(MkSet(eParameter));
        Parameter := PIterator.FirstSchObject;
        while Parameter <> Nil do
        begin
         //delete parameters starting with given prefix
          if (Ansipos(Prefix,Parameter.Name) = 1) then
            ParameterList.Add(Parameter);
          Parameter := PIterator.NextSChObject;
        end;
      finally
        Component.SchIterator_Destroy(PIterator);
      end;
      Component := Iterator.NextSchObject;
    end;
  finally
    SchDoc.SchIterator_Destroy(Iterator);
  end;

  // Remove Parameters from their components
  try
    for I := 0 to ParameterList.Count - 1 do
    begin
      Parameter := ParameterList.items[i];

      // Obtain the parent object which is the component
      // that user defined param is part of.
      Component := Parameter.Container;
      Component.RemoveSchObject(Parameter);

      SchServer.RobotManager.SendMessage(Component.I_ObjectAddress,c_BroadCast,SCHM_PrimitiveRegistration,Parameter.I_ObjectAddress);
    end;
  finally
    ParameterList.Free;
  end;

  // Clean up robots in Schematic editor.
  SchServer.ProcessControl.PostProcess(SchDoc, '');

  // Refresh the screen
  SchDoc.GraphicallyInvalidate;
end;

{======================================================================================================================================================}
// Utility engine for renaming all parameters Prefix with new Prefix
{======================================================================================================================================================}

Procedure MTBF_RenameParametersPrefixOfComponents(SchDoc: ISch_Document; OldPrefix: String; NewPrefix: String);
var
  Component: ISch_Component;
  OldParameter: ISch_Parameter;
  Parameter: ISch_Parameter;
  Iterator: ISch_Iterator;
  PIterator: ISch_Iterator;
  I: Integer;
  ParameterList: TInterfaceList;
  Name2change: String;
begin
  // Initialize the robots in Schematic editor.
  SchServer.ProcessControl.PreProcess(SchDoc, '');

  // Look for components only
  Iterator := SchDoc.SchIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));

  try
    Component := Iterator.FirstSchObject;
    while Component <> Nil do
    begin
      try
        PIterator := Component.SchIterator_Create;
        PIterator.AddFilter_ObjectSet(MkSet(eParameter));

        Parameter := PIterator.FirstSchObject;
        while Parameter <> Nil do
        begin
         //find parameters starting with given prefix
          if (Ansipos(OldPrefix,Parameter.Name) = 1) then
          begin
            SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
            Name2change := copy(Parameter.Name,GetStringLenght(OldPrefix),(GetStringLenght(Parameter.Name)-GetStringLenght(OldPrefix)));
            Parameter.Name:=NewPrefix+Name2change;
            SchServer.RobotManager.SendMessage(Parameter.I_ObjectAddress, c_BroadCast, SCHM_EndModify  , c_NoEventData);
          end;
          Parameter := PIterator.NextSChObject;
        end;
      finally
        Component.SchIterator_Destroy(PIterator);
      end;
      Component := Iterator.NextSchObject;
    end;
  finally
    SchDoc.SchIterator_Destroy(Iterator);
  end;


  // Clean up robots in Schematic editor.
  SchServer.ProcessControl.PostProcess(SchDoc, '');

  // Refresh the screen
  SchDoc.GraphicallyInvalidate;
end;

{*******************************************************************************************************************************************************}
{*******************************************************************************************************************************************************}
// Main FUNCTION
{*******************************************************************************************************************************************************}
{*******************************************************************************************************************************************************}
Procedure MTBF_AddComponentUserParameters;
var
  I: Integer;
  Doc: IDocument;
  CurrentSch: ISch_Document;
  SchDocument: IServerDocument;
  Project: IProject;

  ProjectName : String;
  ProjectFullPath: String;
  ParamFilePath: String;

  ComponentPAR: array[0..4] of String ;
  cfgFile: TextFile;

  Parameter_List: TStringList;
  Parameter_Array: TStringList;
  cfgFileline_nr: Integer;
  line_first_char: Char;
  Schematic_processed: Integer;

  RdResult: Boolean;
  NextComponent: Boolean;
  NextComponentName: String;

begin


Project := GetWorkspace.DM_FocusedProject;
ProjectName:=Project.DM_ProjectFileName;
//-------------------------------------------------------

  // Get user parameters file path
  ParamFilePath := GetFile(0);

  TxTMessage:=ParamFilePath;
  while AnsiPos('\',TxTMessage)<> 0 do
  begin
    I := AnsiPos('\',TxTMessage)+1;
    TxTMessage := Copy(TxTMessage,I,100);
  end;
  ParamFileName := TxTMessage;

  if FileExists(ParamFilePath) then
  begin
    RdResult:=ConfirmNoYes('Proceed with file: ' + ParamFileName +' ?');
    if RdResult = False then
      Exit;
  end;
  if FileExists(ParamFilePath)=False then
  begin
    ShowMessage('Config file read error');
    Exit;
  end;


//-------------------------------------------------------

// Open log file

  WrkLogFile := OpenMyFile(LogFileName, 'LOG', Log_file_folder);

  TxTMessage := '#  Config:' + ParamFilePath;
  WriteLogFileMessage(TxTMessage, WrkLogFile);
  TxTMessage := '##';
  WriteLogFileMessage(TxTMessage, WrkLogFile);

//-------------------------------------------------------
// Open raport file
  WrkRptFile := OpenMyFile(NewCfgFileName, 'RPT', Report_file_folder);

//-------------------------------------------------------
  if Project = Nil then
    Exit;
  Project.DM_Compile;

  AssignFile(cfgFile, ParamFilePath);

  Schematic_processed:=0;

  Parameter_Array:= TStringList.Create;
  Parameter_List:= TStringList.Create;

  // selected or all documents within the project
  for I := 0 to Project.DM_LogicalDocumentCount - 1 do
  begin
    Doc := Project.DM_LogicalDocuments(I);
    if Doc.DM_DocumentKind = 'SCH' then
    begin
      Inc(Schematic_processed);
      SchDocument := Client.OpenDocument('Sch', Doc.DM_FullPath);
      if (SchDocument <> Nil) then
      begin
        Client.ShowDocument(SchDocument);
        CurrentSch := SchServer.GetCurrentSchDocument;
        if CurrentSch = Nil then
          Exit;
        TxTMessage := '# Processing:' + CurrentSch.DocumentName;
        WriteLogFileMessage(TxTMessage, WrkLogFile);

        // read config file line by line
        Reset(cfgFile);
        cfgFileline_nr := 1;

        RdResult:= True;
        while (not Eof(cfgFile) and RdResult) do
        begin
          try
            RdResult:=ReadLn(cfgFile, Parameter_List);
          except
            RdResult:=False;
          end;

          inc (cfgFileline_nr);
          // empty line read protection  DOES NOT WORK!!! Eoln not implemented
          if ( RdResult ) then
          begin
            try
              line_first_char:=Parameter_List[1];
            except
              RdResult:=False;
            end;
            if (Eof(cfgFile) <> True) and RdResult then
            begin
              if line_first_char <> '#' then      // check if no comment line
              begin
                Parameter_Array.Clear;
                Parameter_Array.Delimiter := ' ';
                Parameter_Array.StrictDelimiter := True; // Requires D2006 or newer.
                Parameter_Array.DelimitedText := Parameter_list;
                // check if 4 fields read
                if Parameter_Array.Count = 5 then
                begin
                  NextComponent := False;
                  NextComponentName := RemoveCharFromString(Parameter_Array[1], '''');//AnsiExtractQuotedStr(Parameter_Array[0],'''');
                  if ComponentPAR[ALTIUM_NAME] <> NextComponentName then
                  begin
                    ComponentPAR[ALTIUM_NAME] := NextComponentName;
                    NextComponent := True;
                  end;
                  ComponentPAR[OPERATION_TYPE] := RemoveCharFromString(Parameter_Array[0], '''');//AnsiExtractQuotedStr(Parameter_Array[1],'''');
                  ComponentPAR[RS_PAR_NAME] := RemoveCharFromString(Parameter_Array[2], '''');//AnsiExtractQuotedStr(Parameter_Array[1],'''');
                  ComponentPAR[RS_PAR_VALUE] := RemoveCharFromString(Parameter_Array[3], '''');//AnsiExtractQuotedStr(Parameter_Array[2],'''');
                  ComponentPAR[RS_PAR_VISIBLE] := RemoveCharFromString(Parameter_Array[4], '''');//AnsiExtractQuotedStr(Parameter_Array[3],'''');

                  if NextComponent = True then
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
                  if ComponentPAR[ALTIUM_NAME] <> '???' then
                    if ComponentPAR[RS_PAR_NAME] <> '>>>' then
                      if ComponentPAR[OPERATION_TYPE] = 'CATEGORY' then
                        MTBF_AddUserDefinedParametersToComponentsByName(CurrentSch,ComponentPAR)
                      else
                        if ComponentPAR[OPERATION_TYPE] = 'VALUE' then
                          MTBF_AddUserDefinedParametersToComponentsByCategory(CurrentSch,ComponentPAR)
                    else
                      MTBF_CopyDefinedParametersValue(CurrentSch,ComponentPAR)
                  else
                    if ComponentPAR[RS_PAR_NAME] <> '???' then
                        MTBF_VerifyUserDefinedParametersOfComponents(CurrentSch,ComponentPAR[RS_PAR_NAME])
                    else
                      MTBF_LogUserDefinedParametersOfComponents(CurrentSch);
                end;
                // handle different than 4 fields read
                if Parameter_Array.Count <> 5 then
                begin
                  TxTMessage := 'Syntax error in config ' + ParamFileName + ' file in line nr:' + IntToStr(cfgFileline_nr);
                  WriteLogFileMessage(TxTMessage, WrkLogFile);
                  ShowInfo(TxTMessage);
                  Reset(cfgFile);
                  CloseFile(cfgFile);
                  CloseMyFile(WrkLogFile, 'LOG');
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
  CloseMyFile(WrkLogFile, 'LOG');
  CloseMyFile(WrkRptFile, 'RPT');
  TxTMessage := 'Processing ' + ProjectName + ' done. Processed ' + IntToStr(Schematic_processed) + ' sheets';
  ShowInfo(TxTMessage);
  Exit;

end;
{======================================================================================================================================================}
// Utility for removing all parameters with names starts with prefix
// Scans all SCH files with  MTBF_DeleteUserDefinedParametersOfComponents engine
{======================================================================================================================================================}

Procedure MTBF_DeleteComponentUserParameters;

const
  ParamPrefix = 'SN_';
var
  I: Integer;
  Project: IProject;
  Doc: IDocument;
  CurrentSch: ISch_Document;
  SchDocument: IServerDocument;
  ProjectName: String;
begin
  Project := GetWorkspace.DM_FocusedProject;
  if Project = Nil then Exit;
  Project.DM_Compile;

  ProjectName:=Project.DM_ProjectFileName;
  // selected or all documents within the project
  for I := 0 to Project.DM_LogicalDocumentCount - 1 do
  begin
    Doc := Project.DM_LogicalDocuments(I);
    if Doc.DM_DocumentKind = 'SCH' then
    begin
      SchDocument := Client.OpenDocument('Sch', Doc.DM_FullPath);
      if SchDocument <> Nil then
      begin
        Client.ShowDocument(SchDocument);
        CurrentSch := SchServer.GetCurrentSchDocument;
        if CurrentSch = Nil then Exit;
        MTBF_DeleteUserDefinedParametersOfComponents(CurrentSch,ParamPrefix);
      end;
    end;
  end;
  ShowInfo ('Deleting parameters with name prefix:' + '''' + ParamPrefix + '''' + ' done');
  Exit;
end;
{======================================================================================================================================================}
{======================================================================================================================================================}
// Utility for renaming all parameters prefix
// Scans all SCH files with  MTBF_RenameUserDefinedParametersOfComponents engine
{======================================================================================================================================================}

Procedure MTBF_RenameComponentUserParameters;

const
  OldPrefix = 'SN_';
  NewPrefix = 'ML_';
var
  I: Integer;
  Project: IProject;
  Doc: IDocument;
  CurrentSch: ISch_Document;
  SchDocument: IServerDocument;
  ProjectName: String;
begin
  Project := GetWorkspace.DM_FocusedProject;
  if Project = Nil then Exit;
  Project.DM_Compile;

  ProjectName:=Project.DM_ProjectFileName;
  // selected or all documents within the project
  for I := 0 to Project.DM_LogicalDocumentCount - 1 do
  begin
    Doc := Project.DM_LogicalDocuments(I);
    if Doc.DM_DocumentKind = 'SCH' then
    begin
      SchDocument := Client.OpenDocument('Sch', Doc.DM_FullPath);
      if SchDocument <> Nil then
      begin
        Client.ShowDocument(SchDocument);
        CurrentSch := SchServer.GetCurrentSchDocument;
        if CurrentSch = Nil then Exit;
        MTBF_RenameParametersPrefixOfComponents(CurrentSch,OldPrefix,NewPrefix);
      end;
    end;
  end;
  ShowInfo('Renaming parameters with name prefix:' + '''' + OldPrefix + '''' + 'with' + '''' + NewPrefix + '''' + ' done');
  Exit;
end;
{======================================================================================================================================================}


