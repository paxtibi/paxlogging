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
    function format(data: TLogData): string;
  end;

  { ILogHandler }

  ILogHandler = interface(IFPObserved)
    ['{C997743F-CE50-4CB7-BC03-2B3BFDEDE60B}']
    function GetFormatter: ILogFormatter;
    procedure process(data: TLogData);
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
  end;

  { TAbstractLogger }

  TAbstractLogger = class(TPersistent, ILogInterface, IFPObserver)
  protected
    FThreshold: TLogLevel;
    FFormatter: ILogFormatter;
    procedure Log(data: TLogData); virtual; abstract;
    function getLogData(logLevel: TLogLevel; message: string): TLogData;
    procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
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
    constructor Create;
    destructor Destroy; override;
  end;

  { TNullLogger }

  TNullLogger = class(TAbstractLogger)
  protected
    procedure Log(data: TLogData); override;
  end;

  { TSimpleLogger }

  TSimpleLogger = class(TAbstractLogger)
  protected
    procedure Log(data: TLogData); override;
  end;

  { TAbstractFormatter }

  TAbstractFormatter = class(TPersistent, ILogFormatter)
  public
    destructor Destroy; override;
    function format(data: TLogData): string; virtual; abstract;
  end;

  { TAbstractHandler }

  TAbstractHandler = class(TPersistent, ILogHandler, IFPObserver)
  protected
    FFormatter: ILogFormatter;
  protected
    procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
  public
    destructor Destroy; override;
    procedure process(data: TLogData); virtual; abstract;
    function GetFormatter: ILogFormatter;
    procedure SetFormatter(AValue: ILogFormatter);
    property Formatter: ILogFormatter read GetFormatter write SetFormatter;
  end;

  { TConsoleHandler }

  TConsoleHandler = class(TAbstractHandler)
  public
    procedure process(data: TLogData); override;
  end;

  { TPlainFormatter }

  TPlainFormatter = class(TAbstractFormatter)
  public
    function format(data: TLogData): string; override;
  end;


procedure AddLogger(name: string; aLogger: ILogInterface; replace: boolean = False);
function getLogger(name: string): ILogInterface;
procedure RemoveLogger(name: string);
function HasLogger(Name: string): boolean;

function getLogLevelName(aLogLevel: TLogLevel): string;

var
  FailBackFormatter: ILogFormatter;
  FailBackHandler:   ILogHandler;

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
    procedure FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
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
  result := LogRegistry;
end;

procedure AddLogger(name: string; aLogger: ILogInterface; replace: boolean);
var
  lc: TLoggerContainer;
begin
  getLogRegistry;
  if HasLogger(name) then
  begin
    if replace then
    begin
      RemoveLogger(name);
    end;
    EnterCriticalsection(CS);
    lc := TLoggerContainer.Create;
    LogRegistry.Add(lc);
    lc.Logger := aLogger;
    lc.Name := name;
    LeaveCriticalsection(CS);
  end;
end;

function getLogger(name: string): ILogInterface;
var
  lc: TLoggerContainer;
begin
  result := nil;
  EnterCriticalsection(CS);
  for lc in getLogRegistry do
  begin
    if lc.Name = name then
    begin
      result := lc.Logger;
      break;
    end;
  end;
  LeaveCriticalsection(CS);
  if result = nil then
  begin
    result := TSimpleLogger.Create;
    AddLogger(name, Result);
  end;
end;

procedure RemoveLogger(name: string);
var
  lc: TLoggerContainer;
begin
  EnterCriticalsection(CS);
  for lc in getLogRegistry do
  begin
    if lc.Name = name then
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
  result := False;
  EnterCriticalsection(CS);
  for lc in getLogRegistry do
  begin
    if lc.Name = name then
    begin
      result := True;
      break;
    end;
  end;
  LeaveCriticalsection(CS);
end;

function getLogLevelName(aLogLevel: TLogLevel): string;
begin
  result := '??';
  case aLogLevel of
    API:
    begin
      result := 'API';
    end;
    DEBUG:
    begin
      result := 'DEBUG';
    end;
    INFO:
    begin
      result := 'INFO';
    end;
    NOTICE:
    begin
      result := 'NOTICE';
    end;
    WARNING:
    begin
      result := 'WARNING';
    end;
    ERROR:
    begin
      result := 'ERROR';
    end;
    CRITICAL:
    begin
      result := 'CRITICAL';
    end;
    ALERT:
    begin
      result := 'ALERT';
    end;
    EMERGENCY:
    begin
      result := 'EMERGENCY';
    end;
  end;
end;

{ TSimpleLogger }

procedure TSimpleLogger.Log(data: TLogData);
begin
  if FThreshold <= data.level then
  begin
    if FailBackHandler <> nil then
    begin
      FailBackHandler.process(data);
    end;
  end;
end;

{ TPlainFormatter }

function TPlainFormatter.format(data: TLogData): string;
var
  dateString: string;
begin
  DateTimeToString(dateString, 'yyyy:mm:dd hh:nn:ss.zzz', data.dateTime);
  result := SysUtils.Format('[%-16s]|[%-9s]|[%d.%d]|%s', [dateString, getLogLevelName(data.level), data.process, data.thread, data.message]);
end;

{ TConsoleHandler }

procedure TConsoleHandler.process(data: TLogData);
begin
  if Formatter = nil then
  begin
    Formatter := FailBackFormatter;
  end;
  if IsConsole then
  begin
    Writeln(self.Formatter.format(data));
  end;
end;

{ TAbstractHandler }

procedure TAbstractHandler.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
begin
  if Supports(ASender, ILogFormatter) and ((ASender as ILogFormatter) = FFormatter) and (Operation in [ooFree, ooDeleteItem]) then
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
  result.dateTime := now;
  result.message := message;
  result.level := logLevel;
  result.thread := GetCurrentThreadId;
  result.process := GetProcessID;
end;

procedure TAbstractLogger.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
begin
  if Supports(ASender, ILogFormatter) and ((ASender as ILogFormatter) = FFormatter) and (Operation in [ooFree, ooDeleteItem]) then
  begin
    FFormatter := nil;
  end;
end;

function TAbstractLogger.emergency(message: string; const parameters: array of const): ILogInterface;
begin
  result := emergency(Format(message, parameters));
end;

function TAbstractLogger.alert(message: string; const parameters: array of const): ILogInterface;
begin
  result := alert(Format(message, parameters));
end;

function TAbstractLogger.critical(message: string; const parameters: array of const): ILogInterface;
begin
  result := critical(Format(message, parameters));
end;

function TAbstractLogger.error(message: string; const parameters: array of const): ILogInterface;
begin
  result := error(Format(message, parameters));
end;

function TAbstractLogger.warning(message: string; const parameters: array of const): ILogInterface;
begin
  result := error(Format(message, parameters));
end;

function TAbstractLogger.notice(message: string; const parameters: array of const): ILogInterface;
begin
  result := notice(Format(message, parameters));
end;

function TAbstractLogger.info(message: string; const parameters: array of const): ILogInterface;
begin
  result := info(Format(message, parameters));
end;

function TAbstractLogger.debug(message: string; const parameters: array of const): ILogInterface;
begin
  result := debug(Format(message, parameters));
end;

function TAbstractLogger.emergency(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.EMERGENCY, message));
  result := self;
end;

function TAbstractLogger.alert(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.ALERT, message));
  result := self;
end;

function TAbstractLogger.critical(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.CRITICAL, message));
  result := self;
end;

function TAbstractLogger.error(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.ERROR, message));
  result := self;
end;

function TAbstractLogger.warning(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.WARNING, message));
  result := self;
end;

function TAbstractLogger.notice(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.NOTICE, message));
  result := self;
end;

function TAbstractLogger.info(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.INFO, message));
  result := self;
end;

function TAbstractLogger.debug(message: string): ILogInterface;
begin
  log(getLogData(TLogLevel.DEBUG, message));
  result := self;
end;

procedure TAbstractLogger.setThreshold(threshold: TLogLevel);
begin
  FThreshold := threshold;
end;

function TAbstractLogger.getThreshold: TLogLevel;
begin
  result := FThreshold;
end;

function TAbstractLogger.getFormatter: ILogFormatter;
begin
  result := FFormatter;
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

procedure TLoggerContainer.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
begin
  if Supports(ASender, ILogInterface) and ((ASender as ILogInterface) = FLogger) and (Operation in [ooFree, ooDeleteItem]) then
  begin
    FLogger := nil;
  end;
end;

{ TNullLogger }

procedure TNullLogger.Log(data: TLogData);
begin

end;


initialization

  LogRegistry := nil;
  InitCriticalSection(CS);
  FailBackHandler := TConsoleHandler.Create;
  FailBackFormatter := TPlainFormatter.Create;

finalization

  FreeAndNil(LogRegistry);
  DoneCriticalsection(CS);

end.
