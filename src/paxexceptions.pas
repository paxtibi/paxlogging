unit paxexceptions;

interface

uses
  SysUtils;

(*
  EException
    EClassNotFoundException
    ECloneNotSupportedException
    EIllegalAccessException
    EInstantiationException
    EInterruptedException
    ENoSuchFieldException
    ENoSuchMethodException
    ERuntimeException
      EArithmeticException
      EArrayStoreException
      EClassCastException
      EIllegalArgumentException
        EIllegalThreadStateException
        ENumberFormatException
      EIllegalMonitorStateException
      EIllegalStateException
      EIndexOutOfBoundsException
        EArrayIndexOutOfBoundsException
        EStringIndexOutOfBoundsException
      ENegativeArraySizeException
      ENullPointerException
      ESecurityException
      EUnsupportedOperationException
      EConcurrentModificationException
      EEmptyStackException
      EMissingResourceException
      ENoSuchElementException
      ETooManyListenersException
    EIOException
      ECharConversionException
      EEOFException
      EFileNotFoundException
      EInterruptedIOException
      EObjectStreamException
      EInvalidClassException
      EInvalidObjectException
      ENotActiveException
      ENotSerializableException
      EOptionalDataException
      EStreamCorruptedException
      EWriteAbortedException
      ESyncFailedException
      EUnsupportedEncodingException
      EUTFDataFormatException
*)

type
  EException = class(Exception)
  protected
    FCause: Exception;
  public
    constructor Create; overload;
    constructor Create(const aCause: Exception); overload;
    constructor Create(const msg: string); overload;
    property Cause: Exception read FCause write FCause;
  end;

  EClassNotFoundException = class(EException)
  end;

  ECloneNotSupportedException = class(EException)
  end;

  EIllegalAccessException = class(EException)
  end;

  EInstantiationException = class(EException)
  end;

  EInterruptedException = class(EException)
  end;

  ENoSuchFieldException = class(EException)
  end;

  ENoSuchMethodException = class(EException)
  end;

  ERuntimeException = class(EException)
  end;

  EArithmeticException = class(ERuntimeException)
  end;

  EArrayStoreException = class(ERuntimeException)
  end;

  EClassCastException = class(ERuntimeException)
  end;

  EIllegalArgumentException = class(ERuntimeException)
  end;

  EIllegalThreadStateException = class(EIllegalArgumentException)
  end;

  ENumberFormatException = class(EIllegalArgumentException)
  public
    class function forInputString(s: WideString): ENumberFormatException;
  end;

  EIllegalMonitorStateException = class(ERuntimeException)
  end;

  EIllegalStateException = class(ERuntimeException)
  end;

  EIndexOutOfBoundsException = class(ERuntimeException)
  public
    constructor Create; overload; virtual;
    constructor Create(index: longint); overload; virtual;
  end;

  EArrayIndexOutOfBoundsException = class(EIndexOutOfBoundsException)
  end;

  EStringIndexOutOfBoundsException = class(EIndexOutOfBoundsException)
  end;

  EThreadDeath = class(ERuntimeException)
  end;

  ENegativeArraySizeException = class(ERuntimeException)
  end;

  ENullPointerException = class(ERuntimeException)
  end;

  ESecurityException = class(ERuntimeException)
  end;

  EUnsupportedOperationException = class(ERuntimeException)
  end;

  EConcurrentModificationException = class(ERuntimeException)
  end;

  EEmptyStackException = class(ERuntimeException)
  end;

  EMissingResourceException = class(ERuntimeException)
  end;

  ENoSuchElementException = class(ERuntimeException)
  end;

  ETooManyListenersException = class(ERuntimeException)
  end;

  EIOException = class(EException)
    class function getOSException(code: longint): EIOException;
  end;

  ECharConversionException = class(EIOException)
  end;

  EEOFException = class(EIOException)
  end;

  EFileNotFoundException = class(EIOException)
  end;

  EInterruptedIOException = class(EIOException)
  end;

  EObjectStreamException = class(EIOException)
  end;

  EInvalidClassException = class(EIOException)
  end;

  EInvalidObjectException = class(EIOException)
  end;

  ENotActiveException = class(EIOException)
  end;

  ENotSerializableException = class(EIOException)
  end;

  EOptionalDataException = class(EIOException)
  end;

  EStreamCorruptedException = class(EIOException)
  end;

  EWriteAbortedException = class(EIOException)
  end;

  ESyncFailedException = class(EIOException)
  end;

  EUnsupportedEncodingException = class(EIOException)
  end;

  EUTFDataFormatException = class(EIOException)
  end;

implementation

uses
  Windows;

{ EException }

constructor EException.Create;
begin
  inherited Create('');
  FCause := nil;
end;

constructor EException.Create(const aCause: Exception);
begin
  inherited Create('');
  FCause := aCause;
end;

constructor EException.Create(const msg: string);
begin
  inherited Create(msg);
  FCause := nil;
end;

{ EIndexOutOfBoundsException }

constructor EIndexOutOfBoundsException.Create;
begin
  inherited Create('');
end;

constructor EIndexOutOfBoundsException.Create(index: longint);
begin
  inherited Create(IntToStr(index));
end;

{ ENumberFormatException }

class function ENumberFormatException.forInputString(s: WideString): ENumberFormatException;
begin
  Result := ENumberFormatException.Create('For input string: "' + s + '"');
end;

{ EIOException }

class function EIOException.getOSException(code: longint): EIOException;
begin
  Result := EIOException.Create(SysErrorMessage(code));
end;

end.
