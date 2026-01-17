/// <summary>
/// DX.HttpDiag.Console
/// Console output utilities with color support
/// </summary>
///
/// <remarks>
/// Provides colored console output functions for diagnostic messages
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
/// Winapi.Windows
/// </dependencies>
///
/// <threadsafety>
/// All public methods are thread-safe
/// </threadsafety>
unit DX.HttpDiag.Console;

interface

uses
  System.SysUtils,
  Winapi.Windows;

type
  /// <summary>
  /// Console output helper with color support
  /// </summary>
  TConsoleWriter = class
  public
    /// <summary>
    /// Writes colored text to console
    /// </summary>
    class procedure WriteColor(const AText: string; AColor: Word);

    /// <summary>
    /// Writes colored text with newline to console
    /// </summary>
    class procedure WriteLineColor(const AText: string; AColor: Word);

    /// <summary>
    /// Writes section header
    /// </summary>
    class procedure WriteSection(const ATitle: string);

    /// <summary>
    /// Writes info line (label: value)
    /// </summary>
    class procedure WriteInfo(const ALabel, AValue: string);

    /// <summary>
    /// Writes error message
    /// </summary>
    class procedure WriteError(const AMessage: string);

    /// <summary>
    /// Writes warning message
    /// </summary>
    class procedure WriteWarning(const AMessage: string);

    /// <summary>
    /// Writes success message
    /// </summary>
    class procedure WriteSuccess(const AMessage: string);
  end;

implementation

{ TConsoleWriter }

class procedure TConsoleWriter.WriteColor(const AText: string; AColor: Word);
var
  LConsoleHandle: THandle;
  LConsoleInfo: TConsoleScreenBufferInfo;
begin
  LConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  if GetConsoleScreenBufferInfo(LConsoleHandle, LConsoleInfo) then
  begin
    SetConsoleTextAttribute(LConsoleHandle, AColor);
    Write(AText);
    SetConsoleTextAttribute(LConsoleHandle, LConsoleInfo.wAttributes);
  end
  else
    Write(AText);
end;

class procedure TConsoleWriter.WriteLineColor(const AText: string; AColor: Word);
begin
  WriteColor(AText + sLineBreak, AColor);
end;

class procedure TConsoleWriter.WriteSection(const ATitle: string);
begin
  WriteLn;
  WriteLineColor('=== ' + ATitle + ' ===', FOREGROUND_INTENSITY or FOREGROUND_GREEN or FOREGROUND_BLUE);
end;

class procedure TConsoleWriter.WriteInfo(const ALabel, AValue: string);
begin
  WriteColor(ALabel + ': ', FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
  WriteLn(AValue);
end;

class procedure TConsoleWriter.WriteError(const AMessage: string);
begin
  WriteLineColor('ERROR: ' + AMessage, FOREGROUND_INTENSITY or FOREGROUND_RED);
end;

class procedure TConsoleWriter.WriteWarning(const AMessage: string);
begin
  WriteLineColor('WARNING: ' + AMessage, FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN);
end;

class procedure TConsoleWriter.WriteSuccess(const AMessage: string);
begin
  WriteLineColor('SUCCESS: ' + AMessage, FOREGROUND_INTENSITY or FOREGROUND_GREEN);
end;

end.

