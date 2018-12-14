unit paxlog_appender;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils,
{$IFDEF LINUX}
  SyncObjs,
{$ELSE}
  Windows,
{$ENDIF}   paxlog;

type

  { Basic implementation of an appender for printing log statements.
    Subclasses should at least override DoAppend(string). }
  TLogCustomAppender = class(TLogOptionHandler, ILogDynamicCreate,
    ILogOptionHandler, ILogAppender)
  private
    FClosed: boolean;
    FErrorHandler: ILogErrorHandler;
    FFilters: TInterfaceList;
    FLayout: ILogLayout;
    FName: string;
    FThreshold: TLogLevel;
  protected
    FCriticalAppender: TRTLCriticalSection;
    function GetErrorHandler: ILogErrorHandler;
    function GetFilters: TInterfaceList;
    function GetLayout: ILogLayout;
    function GetName: string;
    procedure SetErrorHandler(const ErrorHandler: ILogErrorHandler);
    procedure SetLayout(const Layout: ILogLayout);
    procedure SetName(const Name: string);
    function CheckEntryConditions: boolean; virtual;
    function CheckFilters(const Event: TLogEvent): boolean; virtual;
    procedure DoAppend(const Event: TLogEvent); overload; virtual;
    procedure DoAppend(const Message: string); overload; virtual; abstract;
    procedure WriteFooter; virtual;
    procedure WriteHeader; virtual;
    procedure SetOption(const Name, Value: string); override;
    function isAsSevereAsThreshold(level: TLogLevel): boolean;
  public
    constructor Create(const Name: string; const Layout: ILogLayout = nil); reintroduce; virtual;
    destructor Destroy; override;
    property ErrorHandler: ILogErrorHandler read GetErrorHandler write SetErrorHandler;
    property Filters: TInterfaceList read GetFilters;
    property Layout: ILogLayout read GetLayout write SetLayout;
    property Name: string read GetName write SetName;
    procedure AddFilter(const Filter: ILogFilter); virtual;
    procedure Append(const Event: TLogEvent); virtual;
    procedure Close; virtual;
    procedure Initialize; override;
    procedure RemoveAllFilters; virtual;
    procedure RemoveFilter(const Filter: ILogFilter); virtual;
    function RequiresLayout: boolean; virtual;
    {$IFDEF UNICODE}
    property Encoding: TEncoding read GetEncoding write SetEncoding;
    {$ENDIF UNICODE}
  end;

  { Discard log messages. }
  TLogNullAppender = class(TLogCustomAppender)
  protected
    procedure DoAppend(const Message: string); override;
  end;

  { Send log messages to debugging output. }
  TLogODSAppender = class(TLogCustomAppender)
  protected
    procedure DoAppend(const Message: string); override;
  end;

  { Send log messages to a stream. }
  TLogStreamAppender = class(TLogCustomAppender)
  private
    FStream: TStream;
  protected
    procedure DoAppend(const Message: string); override;
  public
    constructor Create(const Name: string; const Stream: TStream; const Layout: ILogLayout = nil); reintroduce; virtual;
    destructor Destroy; override;
  end;

  { Send log messages to a file.

    Accepts the following options:

    # Class identification
    log4d.appender.<name>=TLogFileAppender
    # Name of the file to write to, string, mandatory
    log4d.appender.<name>.fileName=C:\Logs\App.log
    # Whether to append to file, Boolean, optional, defaults to true
    log4d.appender.<name>.append=false
  }
  TLogFileAppender = class(TLogStreamAppender)
  private
    FAppend: boolean;
    FFileName: TFileName;
  protected
    procedure SetOption(const Name, Value: string); override;
    procedure SetLogFile(const Name: string); virtual;
    procedure CloseLogFile; virtual;
  public
    constructor Create(const Name, FileName: string; const Layout: ILogLayout = nil; const Append: boolean = True); reintroduce; virtual;
    property FileName: TFileName read FFileName;
    property OpenAppend: boolean read FAppend;
  end;

  { Send log messages to a file which uses logfile rotation

    Accepts the following options:

    # Class identification
    log4d.appender.<name>=TLogRollingFileAppender
    # Name of the file to write to, string, mandatory
    log4d.appender.<name>.fileName=C:\Logs\App.log
    # Whether to append to file, Boolean, optional, defaults to true
    log4d.appender.<name>.append=false
    # Max. file size accepts suffix "KB", "MB" and "GB", optional, default 10MB
    log4d.appender.<name>.maxFileSize=10MB
    # Max number of backup files, optional, default is 1
    log4d.appender.<name>.maxBackupIndex=3
  }
  TLogRollingFileAppender = class(TLogFileAppender, ILogRollingFileAppender)
  private
    FMaxFileSize: integer;
    FMaxBackupIndex: integer;
    FCurrentSize: integer;
  protected
    procedure SetOption(const Name, Value: string); override;
    procedure DoAppend(const msg: string); override;
  public
    procedure Initialize; override;
    procedure RollOver; virtual;        // just in case someone wants to override it...
    property MaxFileSize: integer read FMaxFileSize;
    property MaxBackupIndex: integer read FMaxBackupIndex;
  end;


{ TAppender -------------------------------------------------------------------}

type
  { Holder for an appender reference. }
  TAppender = class(TObject)
  public
    Appender: ILogAppender;
    constructor Create(Appender: ILogAppender);
  end;


implementation

uses
  paxlog_resources;


{ TLogCustomAppender ----------------------------------------------------------}

constructor TLogCustomAppender.Create(const Name: string; const Layout: ILogLayout);
begin
  inherited Create;
  FName := Name;
  if Layout <> nil then
    FLayout := Layout
  else
    FLayout := TLogSimpleLayout.Create;
end;

destructor TLogCustomAppender.Destroy;
begin
  Close;
  FFilters.Free;
  DeleteCriticalSection(FCriticalAppender);
  inherited Destroy;
end;

{ Add a filter to the end of the filter list. }
procedure TLogCustomAppender.AddFilter(const Filter: ILogFilter);
begin
  if FFilters.IndexOf(Filter) = -1 then
    FFilters.Add(Filter);
end;

{ Log in appender-specific way. }
procedure TLogCustomAppender.Append(const Event: TLogEvent);
begin
  EnterCriticalSection(FCriticalAppender);
  try
    if isAsSevereAsThreshold(Event.Level) then
      if CheckEntryConditions then
        if CheckFilters(Event) then
          DoAppend(Event);
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

{ Only log if not closed and a layout is available. }
function TLogCustomAppender.CheckEntryConditions: boolean;
begin
  Result := False;
  if FClosed then
  begin
    LogLog.Warn(ClosedAppenderMsg);
    Exit;
  end;
  if (Layout = nil) and RequiresLayout then
  begin
    ErrorHandler.Error(Format(NoLayoutMsg, [Name]));
    Exit;
  end;
  Result := True;
end;

{ Only log if any/all filters allow it. }
function TLogCustomAppender.CheckFilters(const Event: TLogEvent): boolean;
var
  Index: integer;
begin
  for Index := 0 to FFilters.Count - 1 do
    case ILogFilter(FFilters[Index]).Decide(Event) of
      fdAccept:
      begin
        Result := True;
        Exit;
      end;
      fdDeny:
      begin
        Result := False;
        Exit;
      end;
      fdNeutral: { Try next one }
    end;
  Result := True;
end;

{ Release any resources allocated within the appender such as file
  handles, network connections, etc.
  It is a programming error to append to a closed appender. }
procedure TLogCustomAppender.Close;
begin
  EnterCriticalSection(FCriticalAppender);
  try
    if FClosed then
      Exit;
    WriteFooter;
    FClosed := True;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

procedure TLogCustomAppender.DoAppend(const Event: TLogEvent);
begin
  DoAppend(Layout.Format(Event));
end;

{ Returns the error handler for this appender. }
function TLogCustomAppender.GetErrorHandler: ILogErrorHandler;
begin
  Result := FErrorHandler;
end;

{ Returns the filters for this appender. }
function TLogCustomAppender.GetFilters: TInterfaceList;
begin
  Result := FFilters;
end;

{ Returns this appender's layout. }
function TLogCustomAppender.GetLayout: ILogLayout;
begin
  Result := FLayout;
end;

{ Get the name of this appender. The name uniquely identifies the appender. }
function TLogCustomAppender.GetName: string;
begin
  Result := FName;
end;

{ Initialisation. }
procedure TLogCustomAppender.Initialize;
begin
  inherited Initialize;
  InitializeCriticalSection(FCriticalAppender);
  FClosed := False;
  FErrorHandler := TLogOnlyOnceErrorHandler.Create;
  FFilters := TInterfaceList.Create;
  FThreshold := All;
end;

{ Clear the list of filters by removing all the filters in it. }
procedure TLogCustomAppender.RemoveAllFilters;
begin
  FFilters.Clear;
end;

{ Delete a filter from the appender's list. }
procedure TLogCustomAppender.RemoveFilter(const Filter: ILogFilter);
begin
  FFilters.Remove(Filter);
end;

{ Configurators call this method to determine if the appender requires
  a layout. If this method returns True, meaning that a layout is required,
  then the configurator will configure a layout using the configuration
  information at its disposal.  If this method returns False, meaning that
  a layout is not required, then layout configuration will be used if available. }
function TLogCustomAppender.RequiresLayout: boolean;
begin
  Result := True;
end;

{ Set the error handler for this appender - it cannot be nil. }
procedure TLogCustomAppender.SetErrorHandler(const ErrorHandler: ILogErrorHandler);
begin
  EnterCriticalSection(FCriticalAppender);
  try
    if ErrorHandler = nil then
      LogLog.Warn(NilErrorHandlerMsg)
    else
      FErrorHandler := ErrorHandler;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

{ Set the layout for this appender. }
procedure TLogCustomAppender.SetLayout(const Layout: ILogLayout);
begin
  FLayout := Layout;
end;

{ Set the name of this appender. The name is used by other
  components to identify this appender. }
procedure TLogCustomAppender.SetName(const Name: string);
begin
  FName := Name;
end;

procedure TLogCustomAppender.WriteFooter;
begin
  if Layout <> nil then
    DoAppend(Layout.Footer);
end;

procedure TLogCustomAppender.WriteHeader;
begin
  if Layout <> nil then
    DoAppend(Layout.Header);
end;

procedure TLogCustomAppender.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  if (Name = ThresholdOpt) and (Value <> '') then
  begin
    FThreshold := TLogLevel.GetLevel(Value, All);
  end
  {$IFDEF UNICODE}
  else if (Name = EncodingOpt) then
  begin
    Encoding := FindEncodingFromName(Value);
  end;
  {$ENDIF}
end;

function TLogCustomAppender.isAsSevereAsThreshold(level: TLogLevel): boolean;
begin
  Result := not ((FThreshold <> nil) and (level.Level < FThreshold.Level));
end;

{ TLogNullAppender ------------------------------------------------------------}

{ Do nothing. }
procedure TLogNullAppender.DoAppend(const Message: string);
begin //FI:W519 - ignore FixInsight warning
end;

{ TLogODSAppender -------------------------------------------------------------}

{ Log to debugging output. }
procedure TLogODSAppender.DoAppend(const Message: string);
begin
  if IsConsole then
    Write(Output, Message);
end;

{ TLogStreamAppender ----------------------------------------------------------}

constructor TLogStreamAppender.Create(const Name: string; const Stream: TStream; const Layout: ILogLayout);
begin
  inherited Create(Name, Layout);
  FStream := Stream;
end;

destructor TLogStreamAppender.Destroy;
begin
  Close;
  FStream.Free;
  inherited Destroy;
end;

{ Log to the attached stream. }
procedure TLogStreamAppender.DoAppend(const Message: string);
begin
  if FStream <> nil then
  begin
    FStream.Write(Message[1], Message.Length);
  end;
end;

{ TLogFileAppender ------------------------------------------------------------}

{ Create a file stream and delegate to the parent class. }
constructor TLogFileAppender.Create(const Name, FileName: string; const Layout: ILogLayout; const Append: boolean);
begin
  inherited Create(Name, nil, Layout);
  FAppend := Append;
  SetOption(FileNameOpt, FileName);
end;

{ create file stream }
procedure TLogFileAppender.SetLogFile(const Name: string);
var
  strPath: string;
  f: TextFile;
begin
  CloseLogFile;
  FFileName := Name;
  if FAppend and FileExists(FFileName) then
  begin
    // append to existing file
    // note that we replace fmShareDenyWrite with fmShareDenyNone for concurrent logging possibility
    FStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyNone);
    FStream.Seek(0, soFromEnd);
  end
  else
  begin
    // Check if directory exists
    strPath := ExtractFileDir(FFileName);
    if (strPath <> '') and not DirectoryExists(strPath) then
      ForceDirectories(strPath);

    //FIX 04.10.2006 MHoenemann:
    //  SysUtils.FileCreate() ignores any sharing option (like our fmShareDenyWrite),
    // Creating new file
    AssignFile(f, FFileName);
    try
      ReWrite(f);
    finally
      CloseFile(f);
    end;
    // now use this file
    FStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyNone);
  end;
  WriteHeader;
end;

{ close file stream }
procedure TLogFileAppender.CloseLogFile;
begin
  if FStream <> nil then
    FreeAndNil(FStream);
end;

procedure TLogFileAppender.SetOption(const Name, Value: string);
begin
  inherited SetOption(Name, Value);
  EnterCriticalSection(FCriticalAppender);
  try
    if (Name = AppendOpt) and (Value <> '') then
    begin
      FAppend := StrToBool(Value, FAppend);
    end
    else if (Name = FileNameOpt) and (Value <> '') then
    begin
      SetLogFile(Value);    // changed by adasen
    end;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;

{ TLogRollingFileAppender }

procedure TLogRollingFileAppender.DoAppend(const msg: string);
begin
  if assigned(FStream) and (FCurrentSize = 0) then
    FCurrentSize := FStream.Size;
  FCurrentSize := FCurrentSize + Length(msg);   // should be faster than TFileStream.Size
  if (FStream <> nil) and (FCurrentSize > FMaxFileSize) then
  begin
    FCurrentSize := 0;
    RollOver;
  end;
  inherited;
end;

{ set defaults }
procedure TLogRollingFileAppender.Initialize;
begin
  inherited;
  FMaxFileSize := DEFAULT_MAX_FILE_SIZE;
  FMaxBackupIndex := DEFAULT_MAX_BACKUP_INDEX;
end;

{ log file rotation }
procedure TLogRollingFileAppender.RollOver;
var
  i: integer;
  filename: string;
begin
  // If maxBackups <= 0, then there is no file renaming to be done.
  if FMaxBackupIndex > 0 then
  begin
    // Delete the oldest file, to keep Windows happy.
    SysUtils.DeleteFile(FFileName + '.' + FMaxBackupIndex.ToString);
    // Map (maxBackupIndex - 1), ..., 2, 1 to maxBackupIndex, ..., 3, 2
    for i := FMaxBackupIndex - 1 downto 1 do
    begin
      filename := FFileName + '.' + IntToStr(i);
      if FileExists(filename) then
        RenameFile(filename, FFileName + '.' + IntToStr(i + 1));
    end;
    // close file
    CloseLogFile;
    // Rename fileName to fileName.1
    RenameFile(FFileName, FFileName + '.1');
    // open new file
    SetLogFile(FFileName);
  end;
end;

procedure TLogRollingFileAppender.SetOption(const Name, Value: string);
var
  suffix: string;
begin
  inherited SetOption(Name, Value);
  EnterCriticalSection(FCriticalAppender);
  try
    if (Name = MaxFileSizeOpt) and (Value <> '') then
    begin
      // check suffix
      suffix := Copy(Value, Length(Value) - 1, 2);
      if suffix = 'KB' then
        FMaxFileSize := StrToIntDef(Copy(Value, 1, Length(Value) - 2), 0) * 1024
      else if suffix = 'MB' then
        FMaxFileSize := StrToIntDef(Copy(Value, 1, Length(Value) - 2), 0) * 1024 * 1024
      else if suffix = 'GB' then
        FMaxFileSize := StrToIntDef(Copy(Value, 1, Length(Value) - 2), 0) * 1024 * 1024 * 1024
      else
        FMaxFileSize := StrToIntDef(Value, 0);
      if FMaxFileSize = 0 then
        FMaxFileSize := DEFAULT_MAX_FILE_SIZE;
    end
    else if (Name = MaxBackupIndexOpt) and (Value <> '') then
    begin
      FMaxBackupIndex := StrToIntDef(Value, DEFAULT_MAX_BACKUP_INDEX);
    end;
  finally
    LeaveCriticalSection(FCriticalAppender);
  end;
end;


constructor TAppender.Create(Appender: ILogAppender);
begin
  inherited Create;
  Self.Appender := Appender;
end;

end.
