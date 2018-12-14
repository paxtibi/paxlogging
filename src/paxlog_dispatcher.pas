unit paxlog_dispatcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, paxlog, paxlog_appender;

type

  { TPaxLoggerAppenderDispatcher }

  TPaxLoggerAppenderDispatcher = class{(TThread)}
  private
    FEvent: TLogEvent;
    FLog: TLogLogger;
    procedure SetEvent(AValue: TLogEvent);
    procedure SetLog(AValue: TLogLogger);
  public
    constructor Create(CreateSuspended: boolean = True; const StackSize: SizeUInt = DefaultStackSize);
    property Event: TLogEvent read FEvent write SetEvent;
    property Log: TLogLogger read FLog write SetLog;
    procedure Execute; {override;}
    procedure Run;
  end;

implementation

uses
  StrUtils;

type
  { TLog }
  TLog = class(TLogLog)
  protected
    procedure CallAppenders(const Event: TLogEvent); override;
  public
    property TraceLevel;
  end;

{ TLog }

procedure TLog.CallAppenders(const Event: TLogEvent);
begin
  inherited CallAppenders(Event);
end;

{ TPaxLoggerAppenderDispatcher }

procedure TPaxLoggerAppenderDispatcher.SetLog(AValue: TLogLogger);
begin
  if FLog = AValue then
    Exit;
  FLog := AValue;
end;

constructor TPaxLoggerAppenderDispatcher.Create(CreateSuspended: boolean; const StackSize: SizeUInt);
begin
  inherited Create{(CreateSuspended, StackSize)};
end;

procedure TPaxLoggerAppenderDispatcher.Execute;
begin
  TLog(FLog).CallAppenders(FEvent);
end;

procedure TPaxLoggerAppenderDispatcher.Run;
begin
  //FreeOnTerminate := True;
  //Suspended := False;
  Execute;
end;

procedure TPaxLoggerAppenderDispatcher.SetEvent(AValue: TLogEvent);
begin
  if FEvent = AValue then
    Exit;
  FEvent := AValue;
  if Trace.IsGreaterOrEqual(FEvent.Level) then
  begin
    FEvent.Message := DupeString(' ', FLog.TraceLevel) + FEvent.Message;
  end;
end;

end.
