/// <summary>
/// DX.HttpDiag.Core
/// Main diagnostic orchestration
/// </summary>
///
/// <remarks>
/// Coordinates all diagnostic operations and provides the main entry point
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
/// System.Net.URLClient
/// DX.HttpDiag.Config
/// DX.HttpDiag.Console
/// DX.HttpDiag.SystemInfo
/// DX.HttpDiag.HttpClient
/// </dependencies>
///
/// <threadsafety>
/// All public methods are thread-safe
/// </threadsafety>
unit DX.HttpDiag.Core;

interface

uses
  System.SysUtils,
  System.Net.URLClient,
  Winapi.Windows,
  DX.HttpDiag.Config,
  DX.HttpDiag.Console,
  DX.HttpDiag.SystemInfo,
  DX.HttpDiag.HttpClient;

type
  /// <summary>
  /// Main diagnostic coordinator
  /// </summary>
  THttpDiagnostic = class
  private
    class function ExtractHostname(const AURL: string): string;
  public
    /// <summary>
    /// Main entry point for diagnostic execution
    /// </summary>
    class procedure Run;
  end;

implementation

{ THttpDiagnostic }

class function THttpDiagnostic.ExtractHostname(const AURL: string): string;
var
  LURI: TURI;
begin
  LURI := TURI.Create(AURL);
  Result := LURI.Host;
end;

class procedure THttpDiagnostic.Run;
var
  LConfig: TDiagConfig;
  LHostname: string;
begin
  // Parse command-line arguments
  if not TConfigParser.Parse(LConfig) then
    Exit;

  // Display header
  WriteLn('DX.HttpDiag - HTTPS URL Diagnostic Tool');
  WriteLn('========================================');
  WriteLn;
  TConsoleWriter.WriteInfo('Target URL', LConfig.URL);
  TConsoleWriter.WriteInfo('Timeout', Format('%d ms', [LConfig.Timeout]));

  if LConfig.InsecureMode then
    TConsoleWriter.WriteWarning('Insecure mode enabled - certificate errors will be ignored!');

  // System diagnostics
  TSystemInfo.ShowSystemTime;
  TSystemInfo.ShowProxyEnvironment;
  TSystemInfo.ShowWinHTTPProxy;

  // DNS resolution
  LHostname := ExtractHostname(LConfig.URL);
  if not LHostname.IsEmpty then
    TSystemInfo.ShowDNSResolution(LHostname);

  // HTTP diagnostic
  THttpDiagClient.PerformDiagnostic(LConfig);

  // Footer
  WriteLn;
  TConsoleWriter.WriteLineColor('=== Diagnostic Complete ===', FOREGROUND_INTENSITY or FOREGROUND_GREEN or FOREGROUND_BLUE);
end;

end.

