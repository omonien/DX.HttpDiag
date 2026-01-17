/// <summary>
/// DX.HttpDiag
/// HTTPS URL diagnostic console tool for Windows
/// </summary>
///
/// <remarks>
/// This tool performs comprehensive diagnostics on HTTPS URLs including:
/// - System time and proxy configuration
/// - DNS resolution
/// - HTTP/HTTPS connectivity tests
/// - TLS certificate validation and detailed error reporting
/// - Support for HEAD requests with GET fallback
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
/// DX.HttpDiag.Core
/// </dependencies>
///
/// <threadsafety>
/// Main program is single-threaded
/// </threadsafety>
///
/// <example>
/// <![CDATA[
/// DX.HttpDiag.exe https://www.example.com
/// DX.HttpDiag.exe https://www.example.com --timeout=15000
/// DX.HttpDiag.exe https://badssl.com --insecure
/// ]]>
/// </example>
program DX.HttpDiag;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DX.HttpDiag.Core in 'DX.HttpDiag.Core.pas',
  DX.HttpDiag.Config in 'DX.HttpDiag.Config.pas',
  DX.HttpDiag.Console in 'DX.HttpDiag.Console.pas',
  DX.HttpDiag.SystemInfo in 'DX.HttpDiag.SystemInfo.pas',
  DX.HttpDiag.HttpClient in 'DX.HttpDiag.HttpClient.pas';

begin
  try
    THttpDiagnostic.Run;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('FATAL ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.

