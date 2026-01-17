/// <summary>
/// DX.HttpDiag.Config
/// Configuration and command-line argument parsing
/// </summary>
///
/// <remarks>
/// Handles parsing of command-line arguments and stores diagnostic configuration
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
/// </dependencies>
///
/// <threadsafety>
/// All public methods are thread-safe
/// </threadsafety>
unit DX.HttpDiag.Config;

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Configuration for URL diagnostic operation
  /// </summary>
  TDiagConfig = record
    URL: string;
    Timeout: Integer;
    InsecureMode: Boolean;
  end;

  /// <summary>
  /// Command-line parser and configuration manager
  /// </summary>
  TConfigParser = class
  public
    /// <summary>
    /// Parses command-line arguments and returns configuration
    /// </summary>
    /// <param name="AConfig">Output configuration</param>
    /// <returns>True if parsing succeeded, False if help was shown or error occurred</returns>
    class function Parse(out AConfig: TDiagConfig): Boolean;

    /// <summary>
    /// Displays usage information
    /// </summary>
    class procedure ShowUsage;
  end;

implementation

{ TConfigParser }

class procedure TConfigParser.ShowUsage;
begin
  WriteLn('DX.HttpDiag - HTTPS URL Diagnostic Tool');
  WriteLn;
  WriteLn('Usage: DX.HttpDiag.exe <URL> [options]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  --timeout=<ms>    Request timeout in milliseconds (default: 30000)');
  WriteLn('  --insecure        Accept invalid certificates (for diagnostics only!)');
  WriteLn;
  WriteLn('Examples:');
  WriteLn('  DX.HttpDiag.exe https://www.example.com');
  WriteLn('  DX.HttpDiag.exe https://www.example.com --timeout=15000');
  WriteLn('  DX.HttpDiag.exe https://badssl.com --insecure');
end;

class function TConfigParser.Parse(out AConfig: TDiagConfig): Boolean;
var
  I: Integer;
  LParam: string;
begin
  Result := False;

  // Set defaults
  AConfig.Timeout := 30000; // Default 30 seconds
  AConfig.InsecureMode := False;
  AConfig.URL := '';

  if ParamCount = 0 then
  begin
    ShowUsage;
    Exit;
  end;

  for I := 1 to ParamCount do
  begin
    LParam := ParamStr(I);

    if SameText(LParam, '--help') or SameText(LParam, '-h') or SameText(LParam, '-?') then
    begin
      ShowUsage;
      Exit;
    end
    else if LParam.StartsWith('--timeout=', True) then
    begin
      if not TryStrToInt(LParam.Substring(10), AConfig.Timeout) then
      begin
        WriteLn('ERROR: Invalid timeout value: ' + LParam.Substring(10));
        Exit;
      end;
    end
    else if SameText(LParam, '--insecure') then
    begin
      AConfig.InsecureMode := True;
    end
    else if AConfig.URL.IsEmpty then
    begin
      AConfig.URL := LParam;
    end
    else
    begin
      WriteLn('ERROR: Unknown parameter: ' + LParam);
      Exit;
    end;
  end;

  if AConfig.URL.IsEmpty then
  begin
    WriteLn('ERROR: No URL specified');
    Exit;
  end;

  Result := True;
end;

end.

