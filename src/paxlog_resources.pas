unit paxlog_resources;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring
  AddingLoggerMsg = 'Adding logger "%s" in error handler';
  AppenderDefinedMsg = 'Appender "%s" was already parsed';
  BadConfigFileMsg = 'Couldn''t read configuration file "%s" - %s';
  ClosedAppenderMsg = 'Not allowed to write to a closed appender';
  ConvertErrorMsg = 'Could not convert "%s" to level';
  EndAppenderMsg = 'Parsed "%s" options';
  EndErrorHandlerMsg = 'End of parsing for "%s" error handler';
  EndFiltersMsg = 'End of parsing for "%s" filter';
  EndLayoutMsg = 'End of parsing for "%s" layout';
  FallbackMsg = 'Fallback on error %s';
  FallbackReplaceMsg = 'Fallback replacing "%s" with "%s" in logger "%s"';
  FinishedConfigMsg = 'Finished configuring with %s';
  HandlingAdditivityMsg = 'Handling %s="%s"';
  IgnoreConfigMsg = 'Ignoring configuration file "%s"';
  InterfaceNotImplMsg = '%s doesn''t implement %s';
  LayoutRequiredMsg = 'Appender "%s" requires a layout';
  LevelHdr = 'Level';
  LevelTokenMsg = 'Level token is "%s"';
  LoggerFactoryMsg = 'Setting logger factory to "%s"';
  LoggerHdr = 'Logger';
  MessageHdr = 'Message';
  NDCHdr = 'NDC';
  NilErrorHandlerMsg = 'An appender cannot have a nil error handler';
  NilLevelMsg = 'The root can''t have a nil level';
  NoAppendersMsg = 'No appenders could be found for logger "%s"';
  NoAppenderCreatedMsg = 'Couldn''t create appender named "%s"';
  NoClassMsg = 'Couldn''t find class %s';
  NoLayoutMsg = 'No layout set for appender named "%s"';
  NoRenderedCreatedMsg = 'Couldn''t find rendered class "%s"';
  NoRendererMsg = 'No renderer found for class %s';
  NoRendererCreatedMsg = 'Couldn''t create renderer "%s"';
  NoRootLoggerMsg = 'Couldn''t find root logger information. Is this OK?';
  ParsingAppenderMsg = 'Parsing appender named "%s"';
  ParsingLoggerMsg = 'Parsing for logger "%s" with value="%s"';
  ParsingErrorHandlerMsg = 'Parsing error handler options for "%s"';
  ParsingFiltersMsg = 'Parsing filter options for "%s"';
  ParsingLayoutMsg = 'Parsing layout options for "%s"';
  PleaseInitMsg = 'Please initialise the Log4D system properly';
  RendererMsg = 'Rendering class: "%s", Rendered class: "%s"';
  SessionStartMsg = 'Log session start time';
  SettingAdditivityMsg = 'Setting additivity for "%s" to "%s"';
  SettingAppenderMsg = 'Setting appender "%s" in error handler';
  SettingBackupMsg = 'Setting backup appender "%s" in error handler';
  SettingLevelMsg = 'Logger "%s" set to level "%s"';
  SettingLoggerMsg = 'Setting logger "%s" in error handler';
  ThreadHdr = 'Thread';
  TimeHdr = 'Time';
  ValueUnknownMsg = 'Unknown';

implementation

end.

