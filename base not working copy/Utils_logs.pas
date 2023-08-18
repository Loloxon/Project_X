unit Utils_logs;

interface

    // Get file path
    // start to browse (with filter) from current project
    Function GetFile(InitFlag): String; end;

    Function OpenMyFile(FileName: String; FileType: String; FileFolder: String): TextFile; end;

    Procedure WriteLogFileMessage(TextMessage: String; WrkLogFile: TextFile); end;

    // Write LOG  procedures
    Procedure LogUnrecognisedComponent(SCH_CMP_CMMNT: String; ComponentDesignator: String; RptParameterName: String; Comment: String; WrkRepFile: TextFile); end;

    Procedure CloseMyFile(WrkFile: TextFile); end;

implementation

    Function GetFile(InitFlag): String;
    var
         OpenDialog: TOpenDialog;
         DirName: String;
    begin
         DirName := GetWorkspace.DM_WorkspaceFullPath;
         OpenDialog := TOpenDialog.Create(nil);
         OpenDialog.InitialDir := DirName;
         OpenDialog.Filter := 'Config files (*.txt)|*.TXT';
         // Display the OpenDialog component
         OpenDialog.Execute;

         // Obtain the file name of the selected file.
         Result := OpenDialog.Filename;
         OpenDialog.Free;
    end;


    Function OpenMyFile(FileName: String; FileType: String; FileFolder: String): TextFile;
    var
         Project: IProject;
         ProjectName: String;
         ProjectNamePos: Integer;
         ProjectFullPath: String;
         ProjectDirPath: String;
         DateStr: String;
         TimeStr: String;
         VarFilename: String;
         WrkFile: TextFile;
         TxTMessage: String;

    begin
         Project := GetWorkspace.DM_FocusedProject;

         if(Project = Nil) then Exit;
         ProjectName := Project.DM_ProjectFileName;
         ProjectFullPath := Project.DM_ProjectFullPath;

         DateStr := GetCurrentDateString;
         TimeStr := GetCurrentTimeString;

         ProjectNamePos := AnsiPos(ProjectName, ProjectFullPath);
         ProjectDirPath := copy(ProjectFullPath, 1, ProjectNamePos - 1) + FileFolder;
         TimeStr := ReplaceCharInString(TimeStr,':','_');
         VarFilename := FileName + TimeStr + '.txt';

         if(not directoryexists(ProjectDirPath)) then
            CreateDir(ProjectDirPath);
         if(not directoryexists(ProjectDirPath)) then
            begin
               ShowInfo ('Can not create folder' + ProjectDirPath);
               Exit;
            end;

         AssignFile(WrkFile, ProjectDirPath + '\' + VarFilename);
         Rewrite(WrkFile);

         TxTMessage := '############################################################################' + sLineBreak +
                       '##' + sLineBreak;

         if(FileType = 'LOG') then
            TxTMessage := TxTMessage + '## Processing LOG' + sLineBreak
         else
            TxTMessage := TxTMessage + '## Missing parameters report' + sLineBreak;

         Writeln(WrkFile, TxTMessage + '##' + sLineBreak +
                                       '## Project : ' + ProjectFullPath + sLineBreak +
                                       '## Date    : ' + DateStr + ' ' + TimeStr + sLineBreak +
                                       '##' + sLineBreak +
                                       '############################################################################');
         Result := WrkFile;
    end;

    Procedure WriteLogFileMessage(TextMessage: String, WrkLogFile: TextFile);
    begin
         Append(WrkLogFile);
         Writeln(WrkLogFile, TextMessage);
         CloseFile(WrkLogFile);
    end;

    Procedure LogUnrecognisedComponent(SCH_CMP_CMMNT: String; ComponentDesignator: String; RptParameterName: String; Comment: String, WrkRepFile: TextFile);
    begin
         Append(WrkRepFile);
         TxTMessage:='#   ' + SCH_CMP_CMMNT + '  ' + '#_  ' + '''' + ComponentDesignator + '''' + ' ' + '''' + RptParameterName + ''' ''' + Comment + '''' + ' ''OFF''';
         Writeln(WrkRepFile,TxTMessage);
    end;

    Procedure CloseMyFile(WrkFile: TextFile);
    begin
         Append(WrkFile);
         Writeln(WrkFile, sLineBreak + sLineBreak +
                             '## LOG end' + sLineBreak +
                             '############################################################################');
         CloseFile(WrkFile);
    end;


