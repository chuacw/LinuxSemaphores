///<summary> Written by Chua Chee Wee, Singapore, 2017.
///</summary>
unit NamedEvent;

interface
uses System.SyncObjs, Posix.Semaphore;

type
  ///<summary> A named semaphore for Linux. Note that the semaphore that gets its SetEvent called should not
  /// be destroyed until the semaphore that calls WaitFor gets called. </summary>
  TEvent = class(TSynchroObject)
  protected
    FName: string;
    FHandle: Psem_t;
    FManualReset: Boolean;
  public
    ///<summary> Linux semaphores need to start with a slash character (/). If it doesn't,
    /// this class inserts it as a prefix. This is a rule on Linux and cannot be circumvented. </summary>
    ///<param name="AName">The name of the semaphore. Different processes can share the same semaphore by
    /// supplying the same name in this variable.</param>
    ///<param name="ManualReset">Whether the semaphore should be reset automatically after getting set.</param>
    ///<param name="InitialState">Whether the semaphore should be set initially.</param>
    constructor Create(const AName: string; ManualReset, InitialState: Boolean);
    destructor Destroy; override;
    ///<summary>To reset the semaphore, call ResetEvent. </summary>
    procedure ResetEvent;
    ///<summary>Call this to fire off the semaphore.</summary>
    procedure SetEvent;
    ///<summary>Once SetEvent is called, WaitFor will return wrSignalled.</summary>
    function WaitFor(Timeout: Cardinal = INFINITE): TWaitResult; override;
  end;

implementation
uses
  System.SysUtils, Posix.Unistd,
  Posix.Time,
  Posix.Errno;

constructor TEvent.Create(const AName: string; ManualReset, InitialState: Boolean);
const
  O_CREAT = 100;
var
  M: TMarshaller;
  LName: MarshaledAString;
begin
  if not AName.StartsWith('/') then
    FName := '/' + AName else
    FName := AName;
  FManualReset := ManualReset;
  LName := M.AsAnsi(FName).ToPointer;
  FHandle := sem_open(LName, O_CREAT, $644, 0);
  if InitialState then
    sem_post(FHandle^);
end;

destructor TEvent.Destroy;
var
  M: TMarshaller;
  LName: MarshaledAString;
begin
  sem_close(FHandle^);
  LName := M.AsAnsi(FName).ToPointer;
  sem_unlink(LName);
end;

procedure TEvent.ResetEvent;
var
  Result: Integer;
begin
  sem_getvalue(FHandle^, Result);
  if Result < 0 then
    repeat
      sem_post(FHandle^);
      sem_getvalue(FHandle^, Result);
    until Result = 0 else
  if Result > 0 then
    repeat
      sem_wait(FHandle^);
      sem_getvalue(FHandle^, Result);
    until Result = 0;
  Result := sem_trywait(FHandle^);
end;

procedure TEvent.SetEvent;
begin
  sem_post(FHandle^);
end;

function TEvent.WaitFor(Timeout: Cardinal = INFINITE): TWaitResult;
var
  Err: Integer;
  EndTime: timespec;
begin
  if (Timeout > 0) and (Timeout < INFINITE) then
  begin
    GetPosixEndTime(EndTime, Timeout);
    if sem_timedwait(FHandle^, EndTime) <> 0 then
    begin
      Err := GetLastError;
      if Err = ETIMEDOUT then
        Result := wrTimeout
      else
        Result := wrError;
    end else
      Result := wrSignaled;
  end else if Timeout = INFINITE then
  begin
    if sem_wait(FHandle^) = 0 then
      Result := wrSignaled
    else
      Result := wrError;
  end else
  begin
    if sem_trywait(FHandle^) <> 0 then
    begin
      Err := GetLastError;
      if Err = EAGAIN then
        Result := wrTimeout
      else
        Result := wrError;
    end else
      Result := wrSignaled;
  end;
  if (Result = wrSignaled) and FManualReset then
    sem_post(FHandle^);
end;

end.
