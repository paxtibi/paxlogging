{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit paxlogging_package;

{$warn 5023 off : no warning about unused units}
interface

uses
  paxlog, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('paxlogging_package', @Register);
end.
