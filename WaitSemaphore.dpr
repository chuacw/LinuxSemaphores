program WaitSemaphore;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Hash, Posix.Unistd, System.SysUtils, System.SyncObjs,
  NamedEvent in 'NamedEvent.pas';

procedure Main;
var
  LHashName: string;
  LEvent1: TEvent;
  LFilename: string;
begin
  if ParamCount > 0 then
    LHashName := ParamStr(1) else
    LHashName := THashMD5.GetHashString('Delphi-1995-02-14');
  Write('Waiting for semaphore from the other app, and press Enter to continue');
  LEvent1 := TEvent.Create(LHashName, True, False);
  LFilename := ParamStr(0) + '.log';
  try
    case LEvent1.WaitFor(INFINITE) of
      wrSignaled: WriteLn('Signalled!');
      wrTimeout: WriteLn('Timed out!');
      wrAbandoned: WriteLn('Abandoned!');
    end;
  finally
    LEvent1.Free;
  end;
end;

begin
  Main;
end.
