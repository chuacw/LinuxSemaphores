program FireSemaphores;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Hash, Posix.Unistd, System.SysUtils, System.SyncObjs,
  NamedEvent in 'NamedEvent.pas';

///<summary>
/// Demonstrates semaphores on Linux. Run this, then run the WaitSemaphore app.
/// Press enter in this app, and the WaitSemaphore app will show that it got signalled! </summary>
procedure Main;
var
  LHashName: string;
  LEvent1: TEvent;
  LFilename: string;
begin
  if ParamCount > 0 then
    LHashName := ParamStr(1) else
    LHashName := THashMD5.GetHashString('Delphi-1995-02-14');
  LEvent1 := TEvent.Create(LHashName, True, False);
  LFilename := ParamStr(0) + '.log';
  try
    Write('Press enter to fire the event...');
    ReadLn;
    LEvent1.SetEvent;
  finally
    LEvent1.Free;
  end;
end;

begin
  Main;
end.
