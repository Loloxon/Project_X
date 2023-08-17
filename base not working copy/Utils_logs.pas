unit Utils_logs;

interface
    {======================================================================================================================================================}
    // Open LOG file
    {======================================================================================================================================================}
    Function OpenLogFile(FileName: String):TextFile; end;

    {======================================================================================================================================================}
    // Close LOG file
    {======================================================================================================================================================}
    Procedure CloseLogFile(WrkLogFile: TextFile);end;

    {======================================================================================================================================================}
    // Write log file
    {======================================================================================================================================================}
    Procedure WriteLogFileMessage(TextMessage : String, WrkLogFile: TextFile);end;

    {======================================================================================================================================================}
    // Open Report file
    {======================================================================================================================================================}
    Function OpenRaportFile(FileName : String):TextFile;end;

    {======================================================================================================================================================}
    // Close Report file
    {======================================================================================================================================================}
    Procedure CloseReportFile(WrkRepFile: TextFile);end;

    {======================================================================================================================================================}
    // Write LOG  procedures
    {======================================================================================================================================================}
    Procedure LogUnrecognisedComponent(SCH_CMP_CMMNT: String; ComponentDesignator: String; RptParameterName: String ;Comment: String, WrkRepFile: TextFile);end;

    {======================================================================================================================================================}
    // Get file path
    //  start to browse (with filter) from current project
    {======================================================================================================================================================}
    Function GetFile(InitFlag) : string;end;


implementation

    Function GetFile(InitFlag) : string;
    var
      OpenDialog : TOpenDialog;
      DirName: String;
    begin
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


    Function OpenLogFile(FileName : String):TextFile;
    var
         Project         : IProject;
         ProjectName     : String;
         ProjectNamePos  : Integer;
         ProjectFullPath : String;
         ProjectDirPath  : String;
         DateStr         : String;
         TimeStr         : String;
         VarFilename     : String;
         WrkLogFile      : TextFile;

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

         Writeln(WrkLogFile, '############################################################################'+sLineBreak+
                             '##'+sLineBreak+
                             '## Processing LOG'+sLineBreak+
                             '##'+sLineBreak+
                             '## Project : ' + ProjectFullPath+sLineBreak+
                             '## Date    : ' + DateStr + ' ' + TimeStr+sLineBreak+
                             '##'+sLineBreak+
                             '############################################################################');
         Result := WrkLogFile;
    end;


    Procedure CloseLogFile(WrkLogFile: TextFile);
    begin
         Append(WrkLogFile);
         Writeln(WrkLogFile, sLineBreak+sLineBreak+
                             '## LOG end'+sLineBreak+
                             '############################################################################');

         CloseFile(WrkLogFile);
    end;

    Procedure WriteLogFileMessage(TextMessage : String, WrkLogFile: TextFile);
    begin
         Append(WrkLogFile);
         Writeln(WrkLogFile, TextMessage);
         CloseFile(WrkLogFile);
    end;

    Function OpenRaportFile(FileName : String):TextFile;
    var
         Project         : IProject;
         ProjectName     : String;
         ProjectNamePos  : Integer;
         ProjectFullPath : String;
         ProjectDirPath  : String;
         DateStr         : String;
         TimeStr         : String;
         VarFilename     : String;
         WrkRepFile      : TextFile;

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

         Writeln(WrkRepFile, '############################################################################'+sLineBreak+
                             '##'+sLineBreak+
                             '## Missing parameters report'+sLineBreak+
                             '##'+sLineBreak+
                             '## Project : ' + ProjectFullPath+sLineBreak+
                             '## Date    : ' + DateStr + ' ' + TimeStr+sLineBreak+
                             '##'+sLineBreak+
                             '############################################################################');

         Result := WrkRepFile;
    end;

    Procedure CloseReportFile(WrkRepFile: TextFile);
    begin
         Writeln(WrkRepFile, sLineBreak+sLineBreak+
                             '## LOG end'+sLineBreak+
                             '############################################################################');
         CloseFile(WrkRepFile);
    end;


    Procedure LogUnrecognisedComponent(SCH_CMP_CMMNT : String; ComponentDesignator : String; RptParameterName :String ; Comment :String, WrkRepFile: TextFile);
    begin
         TxTMessage:='#   ' + SCH_CMP_CMMNT +'  ' + '#_  ' + '''' + ComponentDesignator + '''' + ' ' + '''' + RptParameterName + ''' ''' + Comment + '''' + ' ''OFF''';
         Writeln(WrkRepFile,TxTMessage);
    end;

