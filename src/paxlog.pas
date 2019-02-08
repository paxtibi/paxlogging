unit paxlog;

interface

uses
  Classes,
  Contnrs,
  SysUtils;

type
  TLogLevel = (
    API = 2,
    DEBUG = 100,
    INFO = 200,
    NOTICE = 250,
    WARNING = 300,
    ERROR = 400,
    CRITICAL = 500,
    ALERT = 550,
    EMERGENCY = 600
    );

  TLogData = record
    level: TLogLevel;
    dateTime: TDateTime;
    message: string;
    thread: TThreadID;
    process: THandle;
  end;

  { ILogFormatter }

  ILogFormatter = interface(IFPObserved)
    ['{4F873EA4-B0FC-4DD7-A6BD-A3A6565434B2}']
    function format(Data: TLogData): string;
  end;

  { ILogHandler }

  ILogHandler = interface(IFPObserved)
    ['{C997743F-CE50-4CB7-BC03-2B3BFDEDE60B}']
    function GetFormatter: ILogFormatter;
    procedure process(Data: TLogData);
    procedure SetFormatter(AValue: ILogFormatter);
    property Formatter: ILogFormatter read GetFormatter write SetFormatter;
  end;

  { ILogInterface }

  ILogInterface = interface(IFPObserved)
    ['{4BD696B9-C8A0-4AEB-BB02-BE9102C67C6B}']
    {** PSR-3 **}
    function emergency(message: string; const parameters: array of const): ILogInterface;
    function alert(message: string; const parameters: array of const): ILogInterface;
    function critical(message: string; const parameters: array of const): ILogInterface;
    function error(message: string; const parameters: array of const): ILogInterface;
    function warning(message: string; const parameters: array of const): ILogInterface;
    function notice(message: string; const parameters: array of const): ILogInterface;
    function info(message: string; const parameters: array of const): ILogInterface;
    function debug(message: string; const parameters: array of const): ILogInterface;

    function emergency(message: string): ILogInterface;
    function alert(message: string): ILogInterface;
    function critical(message: string): ILogInterface;
    function error(message: string): ILogInterface;
    function warning(message: string): ILogInterface;
    function notice(message: string): ILogInterface;
    function info(message: string): ILogInterface;
    function debug(message: string): ILogInterface;

    procedure setThreshold(threshold: TLogLevel);
    function getThreshold: TLogLevel;
    function getFormatter: ILogFormatter;
    procedure setFormatter(aFormatter: ILogFormatter);
    function getHandler: ILogHandler;
    procedure setHandler(aHandler: ILogHandler);
  end;

  { TAbstractLogger }

  TAbstractLogger = class(TPersistent, ILogInterface, IFPObserver)
  protected
    FThreshold: TLogLevel;
    FFormatter: ILogFormatter;
    FHandler: ILogHandler;
    procedure Log(Data: TLogData); virtual; abstract;
    function getLogData(logLevel: TLogLevel; message: string): TLogData;
    procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation;
      Data: Pointer);
  public
    function emergency(message: string; const parameters: array of const): ILogInterface;
    function alert(message: string; const parameters: array of const): ILogInterface;
    function critical(message: string; const parameters: array of const): ILogInterface;
    function error(message: string; const parameters: array of const): ILogInterface;
    function warning(message: string; const parameters: array of const): ILogInterface;
    function notice(message: string; const parameters: array of const): ILogInterface;
    function info(message: string; const parameters: array of const): ILogInterface;
    function debug(message: string; const parameters: array of const): ILogInterface;

    function emergency(message: string): ILogInterface;
    function alert(message: string): ILogInterface;
    function critical(message: string): ILogInterface;
    function error(message: string): ILogInterface;
    function warning(message: string): ILogInterface;
    function notice(message: string): ILogInterface;
    function info(message: string): ILogInterface;
    function debug(message: string): ILogInterface;

    procedure setThreshold(threshold: TLogLevel);
    function getThreshold: TLogLevel;

    function getFormatter: ILogFormatter;
    procedure setFormatter(aFormatter: ILogFormatter);

    function getHandler: ILogHandler;
    procedure setHandler(aHandler: ILogHandler);

    constructor Create;
    destructor Destroy; override;
  end;

  { TNullLogger }

  TNullLogger = class(TAbstractLogger)
  protected
    procedure Log(Data: TLogData); override;
  end;

  { TSimpleLogger }

  TSimpleLogger = class(TAbstractLogger)
  protected
    procedure Log(Data: TLogData); override;
  end;

  { TAbstractFormatter }

  TAbstractFormatter = class(TPersistent, ILogFormatter)
  public
    destructor Destroy; override;
    function format(Data: TLogData): string; virtual; abstract;
  end;

  { TAbstractHandler }

  TAbstractHandler = class(TPersistent, ILogHandler, IFPObserver)
  protected
    FFormatter: ILogFormatter;
  protected
    procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation;
      Data: Pointer);
  public
    destructor Destroy; override;
    procedure process(Data: TLogData); virtual; abstract;
    function GetFormatter: ILogFormatter;
    procedure SetFormatter(AValue: ILogFormatter);
    property Formatter: ILogFormatter read GetFormatter write SetFormatter;
  end;

  { TLogConsoleHandler }

  TLogConsoleHandler = class(TAbstractHandler)
  public
    procedure process(Data: TLogData); override;
  end;

  { TLogFileHandler }

  TLogFileHandler = class(TAbstractHandler)
  private
    FFileName: string;
    FCS: TRTLCriticalSection;
    procedure SetFileName(AValue: string);
  protected
    FText: Text;
  public
    constructor Create;
    destructor Destroy; override;
    procedure process(Data: TLogData); override;
    property FileName: string read FFileName write SetFileName;
  end;


  { TPlainFormatter }

  TPlainFormatter = class(TAbstractFormatter)
  public
    function format(Data: TLogData): string; override;
  end;


procedure AddLogger(Name: string; aLogger: ILogInterface; replace: boolean = False);
function getLogger(Name: string): ILogInterface;
procedure RemoveLogger(Name: string);
function HasLogger(Name: string): boolean;

function getLogLevelName(aLogLevel: TLogLevel): string;

var
  FailBackFormatter: ILogFormatter;
  FailBackHandler: ILogHandler;

implementation

uses
  fgl, typinfo;

type
  { TLoggerContainer }

  TLoggerContainer = class(TPersistent, IFPObserver)
  private
    FLogger: ILogInterface;
    FName: string;
    procedure SetLogger(AValue: ILogInterface);
    procedure SetName(AValue: string);
  protected
    procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation;
      Data: Pointer);
  public
    constructor Create;
    destructor Destroy; override;
    property Logger: ILogInterface read FLogger write SetLogger;
    property Name: string read FName write SetName;
  end;

type
  TLogRegistry = specialize TFPGObjectList<TLoggerContainer>;

var
  LogRegistry: TLogRegistry;
  CS: TRTLCriticalSection;

function getLogRegistry: TLogRegistry;
begin
  if LogRegistry = nil then
  begin
    LogRegistry := TLogRegistry.Create(True);
  end;
  Result := LogRegistry;
end;

procedure AddLogger(Name: string; aLogger: ILogInterface; replace: boolean);
var
  lc: TLoggerContainer;
begin
  getLogRegistry;
  if HasLogger(Name) then
  begin
    if replace then
    begin
      RemoveLogger(Name);
    end;
    EnterCriticalsection(CS);
    lc := TLoggerContainer.Create;
    LogRegistry.Add(lc);
    lc.Logger := aLogger;
    lc.Name := Name;
    LeaveCriticalsection(CS);
  end;
end;

function getLogger(Name: string): ILogInterface;
var
  lc: TLoggerContainer;
begin
  Result := nil;
  EnterCriticalsection(CS);
  for lc in getLogRegistry do
  begin
    if lc.Name = Name then
    begin
      Result := lc.Logger;
      break;
    end;
  end;
  LeaveCriticalsection(CS);
  if Result = nil then
  begin
    Result := TSimpleLogger.Create;
    AddLogger(Name, Result);
  end;
end;

procedure RemoveLogger(Name: string);
var
  lc: TLoggerContainer;
begin
  EnterCriticalsection(CS);
  for lc in getLogRegistry do
  begin
    if lc.Name = Name then
    begin
      LogRegistry.Remove(lc);
      break;
    end;
  end;
  LeaveCriticalsection(CS);
end;

function HasLogger(Name: string): boolean;
var
  lc: TLoggerContainer;
begin
  Result := False;
  EnterCriticalsection(CS);
  for lc in getLogRegistry do
  begin
    if lc.Name = Name then
    begin
      Result := True;
      break;
    end;
  end;
  LeaveCriticalsection(CS);
end;

function getLogLevelName(aLogLevel: TLogLevel): string;
begin
  Result := '??';
  case aLogLevel of
    API:
    begin
      Result := 'API';
    end;
    DEBUG:
    begin
      Result := 'DEBUG';
    end;
    INFO:
    begin
      Result := 'INFO';
    end;
    NOTICE:
    begin
      Result := 'NOTICE';
    end;
    WARNING:
    begin
      Result := 'WARNING';
    end;
    ERROR:
    begin
      Result := 'ERROR';
    end;
    CRITICAL:
    begin
      Result := 'CRITICAL';
    end;
    ALERT:
    begin
      Result := 'ALERT';
    end;
    EMERGENCY:
    begin
      Result := 'EMERGENCY';
    end;
  end;
end;

{ TLogFileHandler }

procedure TLogFileHandler.SetFileName(AValue: string);
begin
  if FFileName = AValue then
    Exit;
  FFileName := AValue;
end;

constructor TLogFileHandler.Create;
begin
  InitCriticalSection(FCS);
end;

destructor TLogFileHandler.Destroy;
begin
  DoneCriticalSection(FCS);
  inherited Destroy;
end;

procedure TLogFileHandler.process(Data: TLogData);
begin
  EnterCriticalsection(FCS);
  AssignFile(FText, FFileName);
  if FileExists(FFileName) then
  begin
    Append(FText);
  end
  else
    Rewrite(FText);
  Writeln(FText, Formatter.format(Data));
  CloseFile(FText);
  LeaveCriticalsection(FCS);
end;

{ TSimpleLogger }

procedure TSimpleLogger.Log(Data: TLogData);
begin
  if FThreshold <= Data.level then
  begin
    if FailBackHandler <> nil then
    begin
      FailBackHandler.process(Data);
    end;
  end;
end;

{ TPlainFormatter }

function TPlainFormatter.format(Data: TLogData): string;
var
  dateString: string;
begin
  DateTimeToString(dateString, 'yyyy:mm:dd hh:nn:ss.zzz', Data.dateTime);
  Result := SysUtils.Format('[%-16s]|[%-9s]|[%d.%d]|%s',
    [dateString, getLogLevelName(Data.level), Data.process, Data.thread, Data.message]);
end;

{ TLogConsoleHandler }

procedure TLogConsoleHandler.process(Data: TLogData);
begin
  if Formatter = nil then
  begin
    Formatter := FailBackFormatter;
  end;
  if IsConsole then
  begin
    Writeln(self.Formatter.format(Data));
  end;
end;

{ TAbstractHandler }

procedure TAbstractHandler.FPOObservedChanged(ASender: TObject;
  Operation: TFPObservedOperation; Data: Pointer);
begin
  if Supports(ASender, ILogFormatter) and ((ASender as ILogFormatter) = FFormatter) and
    (Operation in [ooFree, ooDeleteItem]) then
  begin
    FFormatter := nil;
  end;
end;

destructor TAbstractHandler.Destroy;
begin
  inherited Destroy;
end;

function TAbstractHandler.GetFormatter: ILogFormatter;
begin
  Result := FFormatter;
end;

procedure TAbstractHandler.SetFormatter(AValue: ILogFormatter);
begin
  if FFormatter <> nil then
  begin
    FFormatter.FPODetachObserver(Self);
  end;
  FFormatter := AValue;
  if FFormatter <> nil then
  begin
    FFormatter.FPOAttachObserver(Self);
  end;
end;

{ TAbstractFormatter }

destructor TAbstractFormatter.Destroy;
begin
  FPONotifyObservers(self, ooFree, nil);
  inherited Destroy;
end;

{ TAbstractLogger }

function TAbstractLogger.getLogData(logLevel: TLogLevel; message: string): TLogData;
begin
  Result.dateTime := now;
  Result.message := message;
  Result.level := logLevel;
  Result.thread := GetCurrentThreadId;
  Result.process := GetProcessID;
end;

procedure TAbstractLogger.FPOObservedChanged(ASender: TObject;
  Operation: TFPObservedOperation; Data: Pointer);
begin
  if Supports(ASender, ILogFormatter) and ((ASender as ILogFormatter) = FFormatter) and
    (Operation in [ooFree, ooDeleteItem]) then
  begin
    FFormatter := nil;
  end;
end;

function TAbstractLogger.emergency(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := emergency(Format(message, parameters));
end;

function TAbstractLogger.alert(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := alert(Format(message, parameters));
end;

function TAbstractLogger.critical(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := critical(Format(message, parameters));
end;

function TAbstractLogger.error(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := error(Format(message, parameters));
end;

function TAbstractLogger.warning(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := error(Format(message, parameters));
end;

function TAbstractLogger.notice(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := notice(Format(message, parameters));
end;

function TAbstractLogger.info(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := info(Format(message, parameters));
end;

function TAbstractLogger.debug(message: string;
  const parameters: array of const): ILogInterface;
begin
  Result := debug(Format(message, parameters));
end;

function TAbstractLogger.emergency(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.EMERGENCY, message));
  Result := self;
end;

function TAbstractLogger.alert(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.ALERT, message));
  Result := self;
end;

function TAbstractLogger.critical(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.CRITICAL, message));
  Result := self;
end;

function TAbstractLogger.error(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.ERROR, message));
  Result := self;
end;

function TAbstractLogger.warning(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.WARNING, message));
  Result := self;
end;

function TAbstractLogger.notice(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.NOTICE, message));
  Result := self;
end;

function TAbstractLogger.info(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.INFO, message));
  Result := self;
end;

function TAbstractLogger.debug(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.DEBUG, message));
  Result := self;
end;

procedure TAbstractLogger.setThreshold(threshold: TLogLevel);
begin
  FThreshold := threshold;
end;

function TAbstractLogger.getThreshold: TLogLevel;
begin
  Result := FThreshold;
end;

function TAbstractLogger.getFormatter: ILogFormatter;
begin
  Result := FFormatter;
end;

procedure TAbstractLogger.setFormatter(aFormatter: ILogFormatter);
begin
  if FFormatter <> nil then
  begin
    FFormatter.FPODetachObserver(Self);
  end;
  FFormatter := aFormatter;
  if FFormatter <> nil then
  begin
    FFormatter.FPOAttachObserver(Self);
  end;
end;

function TAbstractLogger.getHandler: ILogHandler;
begin
  Result := FHandler;
end;

procedure TAbstractLogger.setHandler(aHandler: ILogHandler);
begin
  if FHandler <> nil then
    FHandler.FPODetachObserver(Self);
  FHandler := aHandler;
  if FHandler <> nil then
    FHandler.FPOAttachObserver(Self);
end;

constructor TAbstractLogger.Create;
begin
  FThreshold := api;
end;

destructor TAbstractLogger.Destroy;
begin
  setFormatter(nil);
  FPONotifyObservers(Self, ooFree, nil);
  inherited Destroy;
end;

{ TLoggerContainer }

procedure TLoggerContainer.SetLogger(AValue: ILogInterface);
begin
  if FLogger = AValue then
  begin
    Exit;
  end;
  FLogger := AValue;
  if FLogger <> nil then
  begin
    FLogger.FPOAttachObserver(self);
  end;
end;

procedure TLoggerContainer.SetName(AValue: string);
begin
  if FName = AValue then
  begin
    Exit;
  end;
  FName := AValue;
end;

constructor TLoggerContainer.Create;
begin
  FLogger := nil;
end;

destructor TLoggerContainer.Destroy;
begin
  FLogger := nil;
  inherited Destroy;
end;

procedure TLoggerContainer.FPOObservedChanged(ASender: TObject;
  Operation: TFPObservedOperation; Data: Pointer);
begin
  if Supports(ASender, ILogInterface) and ((ASender as ILogInterface) = FLogger) and
    (Operation in [ooFree, ooDeleteItem]) then
  begin
    FLogger := nil;
  end;
end;

{ TNullLogger }

procedure TNullLogger.Log(Data: TLogData);
begin

end;


initialization

  LogRegistry := nil;
  InitCriticalSection(CS);
  FailBackHandler := TLogConsoleHandler.Create;
  FailBackFormatter := TPlainFormatter.Create;

finalization

  FreeAndNil(LogRegistry);
  DoneCriticalsection(CS);

end.
