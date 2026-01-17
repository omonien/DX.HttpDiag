/// <summary>
/// DX.HttpDiag.SystemInfo
/// System information and diagnostics
/// </summary>
///
/// <remarks>
/// Provides system-level diagnostic information including:
/// - System time and timezone
/// - Proxy configuration (environment and WinHTTP)
/// - DNS resolution
/// </remarks>
///
/// <author>Olaf Monien</author>
/// <version>1.0.0</version>
///
/// <copyright>
/// Copyright © 2025 Olaf Monien
/// Licensed under MIT
/// </copyright>
///
/// <dependencies>
/// System.SysUtils
/// System.DateUtils
/// Winapi.Windows
/// Winapi.WinSock
/// Winapi.WinHttp
/// DX.HttpDiag.Console
/// </dependencies>
///
/// <threadsafety>
/// All public methods are thread-safe
/// </threadsafety>
unit DX.HttpDiag.SystemInfo;

interface

uses
  System.SysUtils,
  System.DateUtils,
  Winapi.Windows,
  Winapi.WinSock,
  Winapi.WinHttp,
  DX.HttpDiag.Console;

type
  /// <summary>
  /// System information provider
  /// </summary>
  TSystemInfo = class
  public
    /// <summary>
    /// Displays system time information
    /// </summary>
    class procedure ShowSystemTime;

    /// <summary>
    /// Displays proxy configuration from environment variables
    /// </summary>
    class procedure ShowProxyEnvironment;

    /// <summary>
    /// Displays WinHTTP proxy configuration
    /// </summary>
    class procedure ShowWinHTTPProxy;

    /// <summary>
    /// Resolves DNS for the given hostname and displays results
    /// </summary>
    class procedure ShowDNSResolution(const AHostname: string);
  end;

implementation

{ TSystemInfo }

class procedure TSystemInfo.ShowSystemTime;
var
  LNow: TDateTime;
  LLocalTime, LUTCTime: TSystemTime;
  LTimeZoneInfo: TTimeZoneInformation;
  LBias: Integer;
begin
  TConsoleWriter.WriteSection('System Time');

  LNow := Now;
  DateTimeToSystemTime(LNow, LLocalTime);
  DateTimeToSystemTime(TTimeZone.Local.ToUniversalTime(LNow), LUTCTime);

  GetTimeZoneInformation(LTimeZoneInfo);
  LBias := LTimeZoneInfo.Bias;

  TConsoleWriter.WriteInfo('Local Time', FormatDateTime('yyyy-mm-dd hh:nn:ss', LNow));
  TConsoleWriter.WriteInfo('UTC Time', FormatDateTime('yyyy-mm-dd hh:nn:ss', TTimeZone.Local.ToUniversalTime(LNow)));
  TConsoleWriter.WriteInfo('UTC Offset', Format('%d minutes (%d hours)', [LBias, LBias div 60]));
end;

class procedure TSystemInfo.ShowProxyEnvironment;
var
  LHttpProxy, LHttpsProxy, LNoProxy: string;
begin
  TConsoleWriter.WriteSection('Proxy Configuration (Environment)');

  LHttpProxy := GetEnvironmentVariable('HTTP_PROXY');
  LHttpsProxy := GetEnvironmentVariable('HTTPS_PROXY');
  LNoProxy := GetEnvironmentVariable('NO_PROXY');

  if LHttpProxy.IsEmpty and LHttpsProxy.IsEmpty and LNoProxy.IsEmpty then
  begin
    WriteLn('  No proxy environment variables set');
  end
  else
  begin
    if not LHttpProxy.IsEmpty then
      TConsoleWriter.WriteInfo('HTTP_PROXY', LHttpProxy);
    if not LHttpsProxy.IsEmpty then
      TConsoleWriter.WriteInfo('HTTPS_PROXY', LHttpsProxy);
    if not LNoProxy.IsEmpty then
      TConsoleWriter.WriteInfo('NO_PROXY', LNoProxy);
  end;
end;

class procedure TSystemInfo.ShowWinHTTPProxy;
var
  LProxyInfo: WINHTTP_CURRENT_USER_IE_PROXY_CONFIG;
begin
  TConsoleWriter.WriteSection('Proxy Configuration (WinHTTP/IE)');

  FillChar(LProxyInfo, SizeOf(LProxyInfo), 0);

  if WinHttpGetIEProxyConfigForCurrentUser(LProxyInfo) then
  begin
    try
      if LProxyInfo.fAutoDetect then
        WriteLn('  Auto-detect: Enabled');

      if LProxyInfo.lpszAutoConfigUrl <> nil then
        TConsoleWriter.WriteInfo('Auto-config URL', string(LProxyInfo.lpszAutoConfigUrl));

      if LProxyInfo.lpszProxy <> nil then
        TConsoleWriter.WriteInfo('Proxy', string(LProxyInfo.lpszProxy))
      else if not LProxyInfo.fAutoDetect and (LProxyInfo.lpszAutoConfigUrl = nil) then
        WriteLn('  Direct connection (no proxy)');

      if LProxyInfo.lpszProxyBypass <> nil then
        TConsoleWriter.WriteInfo('Proxy Bypass', string(LProxyInfo.lpszProxyBypass));
    finally
      if LProxyInfo.lpszAutoConfigUrl <> nil then
        GlobalFree(HGLOBAL(LProxyInfo.lpszAutoConfigUrl));
      if LProxyInfo.lpszProxy <> nil then
        GlobalFree(HGLOBAL(LProxyInfo.lpszProxy));
      if LProxyInfo.lpszProxyBypass <> nil then
        GlobalFree(HGLOBAL(LProxyInfo.lpszProxyBypass));
    end;
  end
  else
  begin
    WriteLn('  Could not retrieve WinHTTP proxy configuration');
  end;
end;

class procedure TSystemInfo.ShowDNSResolution(const AHostname: string);
var
  LWSAData: TWSAData;
  LHostEnt: PHostEnt;
  LAddr: PInAddr;
  I: Integer;
  LAnsiHostname: AnsiString;
begin
  TConsoleWriter.WriteSection('DNS Resolution');
  TConsoleWriter.WriteInfo('Hostname', AHostname);

  // Initialize Winsock
  if WSAStartup(MAKEWORD(2, 2), LWSAData) <> 0 then
  begin
    TConsoleWriter.WriteError('Failed to initialize Winsock');
    Exit;
  end;

  try
    LAnsiHostname := AnsiString(AHostname);
    LHostEnt := gethostbyname(PAnsiChar(LAnsiHostname));

    if LHostEnt = nil then
    begin
      TConsoleWriter.WriteError(Format('DNS resolution failed: %d', [WSAGetLastError]));
      Exit;
    end;

    I := 0;
    while LHostEnt^.h_addr_list[I] <> nil do
    begin
      LAddr := PInAddr(LHostEnt^.h_addr_list[I]);
      TConsoleWriter.WriteInfo(Format('  IPv4 [%d]', [I + 1]), string(inet_ntoa(LAddr^)));
      Inc(I);
    end;

    if I = 0 then
      WriteLn('  No addresses found');

  finally
    WSACleanup;
  end;
end;

end.
