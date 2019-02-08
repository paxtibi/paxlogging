unit paxlog;

interface

uses
  Classes,
  Contnrs,
  SysUtils;

type
  TLogLevel = (
    EMERGENCY = 7,
    ALERT = 6,
    CRITICAL = 5,
    ERROR = 4,
    WARNING = 3,
    NOTICE = 2,
    INFO = 1,
    DEBUG = 0
    );


  ILogInterface = interface
    ['{4BD696B9-C8A0-4AEB-BB02-BE9102C67C6B}']
    function emergency(message: string; const parameters): ILogInterface;
    function alert(message: string; const parameters): ILogInterface;
    function critical(message: string; const parameters): ILogInterface;
    function error(message: string; const parameters): ILogInterface;
    function warning(message: string; const parameters): ILogInterface;
    function notice(message: string; const parameters): ILogInterface;
    function info(message: string; const parameters): ILogInterface;
    function debug(message: string; const parameters): ILogInterface;
  end;

  { TAbstractLogger }

  TAbstractLogger = class(TInterfacedObject, ILogInterface)
  protected
    procedure Log(LogLevel: TLogLevel; message: string; const parameters); virtual; abstract;
  public
    function emergency(message: string; const parameters): ILogInterface;
    function alert(message: string; const parameters): ILogInterface;
    function critical(message: string; const parameters): ILogInterface;
    function error(message: string; const parameters): ILogInterface;
    function warning(message: string; const parameters): ILogInterface;
    function notice(message: string; const parameters): ILogInterface;
    function info(message: string; const parameters): ILogInterface;
    function debug(message: string; const parameters): ILogInterface;
  end;

  { TNullLogger }

  TNullLogger = class(TAbstractLogger)
  protected
    procedure Log(LogLevel: TLogLevel; message: string; const parameters); override;
  end;

implementation

{ TNullLogger }

procedure TNullLogger.Log(LogLevel: TLogLevel; message: string; const parameters);
begin

end;

{ TAbstractLogger }

function TAbstractLogger.emergency(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.EMERGENCY, message, parameters);
  result := self;
end;

function TAbstractLogger.alert(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.ALERT, message, parameters);
  result := self;
end;

function TAbstractLogger.critical(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.CRITICAL, message, parameters);
  result := self;
end;

function TAbstractLogger.error(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.ERROR, message, parameters);
  result := self;
end;

function TAbstractLogger.warning(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.WARNING, message, parameters);
  result := self;
end;

function TAbstractLogger.notice(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.NOTICE, message, parameters);
  result := self;
end;

function TAbstractLogger.info(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.INFO, message, parameters);
  result := self;
end;

function TAbstractLogger.debug(message: string; const parameters): ILogInterface;
begin
  log(TLogLevel.DEBUG, message, parameters);
  result := self;
end;

end.
