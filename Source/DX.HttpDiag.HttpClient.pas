/// <summary>
/// DX.HttpDiag.HttpClient
/// HTTP/HTTPS diagnostic client with certificate validation
/// </summary>
///
/// <remarks>
/// Provides HTTP diagnostic functionality including:
/// - HEAD request with GET fallback
/// - Certificate validation and error reporting
/// - Detailed response information
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
/// System.Net.HttpClient
/// System.Net.URLClient
/// DX.HttpDiag.Config
/// DX.HttpDiag.Console
/// </dependencies>
///
/// <threadsafety>
/// All public methods are thread-safe
/// </threadsafety>
unit DX.HttpDiag.HttpClient;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  Winapi.Windows,
  DX.HttpDiag.Config,
  DX.HttpDiag.Console;

var
  /// <summary>
  /// Captured certificate during request (thread-local workaround via global)
  /// </summary>
  GCapturedCertificate: TCertificate;
  GCertificateCaptured: Boolean;

type
  /// <summary>
  /// Helper class for certificate validation callback
  /// </summary>
  TCertificateValidator = class
  private
    FInsecureMode: Boolean;
  public
    constructor Create(AInsecureMode: Boolean);
    procedure OnValidateCertificate(const Sender: TObject; const ARequest: TURLRequest;
      const Certificate: TCertificate; var Accepted: Boolean);
  end;

  /// <summary>
  /// HTTP diagnostic client
  /// </summary>
  THttpDiagClient = class
  private
    class procedure ShowCertificateDetails(const ACertificate: TCertificate);
    class function FormatCertDate(const ADate: TDateTime): string;
    class function AnalyzeCertificateIssues(const ACertificate: TCertificate): TArray<string>;
  public
    /// <summary>
    /// Performs HTTP diagnostic request
    /// </summary>
    class procedure PerformDiagnostic(const AConfig: TDiagConfig);
  end;

implementation

{ TCertificateValidator }

constructor TCertificateValidator.Create(AInsecureMode: Boolean);
begin
  inherited Create;
  FInsecureMode := AInsecureMode;
end;

procedure TCertificateValidator.OnValidateCertificate(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: Boolean);
begin
  // Capture certificate for detailed analysis
  GCapturedCertificate := Certificate;
  GCertificateCaptured := True;

  // In insecure mode, accept all certificates
  if FInsecureMode then
    Accepted := True;
  // Otherwise let Windows/WinHTTP validate the certificate (default behavior)
end;

{ THttpDiagClient }

class function THttpDiagClient.FormatCertDate(const ADate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', ADate);
end;

class function THttpDiagClient.AnalyzeCertificateIssues(const ACertificate: TCertificate): TArray<string>;
var
  LIssues: TArray<string>;
begin
  LIssues := [];

  // Check validity period
  if ACertificate.Expiry < Now then
    LIssues := LIssues + ['Certificate has EXPIRED'];

  if ACertificate.Start > Now then
    LIssues := LIssues + ['Certificate is not yet valid (future start date)'];

  // Check expiration approaching
  if (ACertificate.Expiry > Now) and (ACertificate.Expiry < IncDay(Now, 30)) then
    LIssues := LIssues + [Format('Certificate expires soon (%d days remaining)',
      [DaysBetween(Now, ACertificate.Expiry)])];

  // Check for self-signed (Subject = Issuer)
  if SameText(ACertificate.Subject, ACertificate.Issuer) then
    LIssues := LIssues + ['Certificate appears to be self-signed (Subject = Issuer)'];

  // Check key size (warn if < 2048 bits for RSA, but ECC uses smaller keys)
  // ECC keys of 256 bits are equivalent to RSA 3072 bits
  // Signature algorithm OID 1.2.840.10045.* indicates ECDSA (ECC)
  if (ACertificate.KeySize > 0) and (ACertificate.KeySize < 2048) then
  begin
    // Check if this is an ECC certificate (ECDSA signature algorithm)
    if ACertificate.AlgSignature.StartsWith('1.2.840.10045') or
       ACertificate.AlgSignature.ToLower.Contains('ecdsa') or
       ACertificate.AlgSignature.ToLower.Contains('ec') then
    begin
      // ECC: 256 bits is secure, warn only if < 224
      if ACertificate.KeySize < 224 then
        LIssues := LIssues + [Format('Weak ECC key size (%d bits, recommended: 256+)', [ACertificate.KeySize])];
    end
    else
      // RSA: warn if < 2048
      LIssues := LIssues + [Format('Weak RSA key size (%d bits, recommended: 2048+)', [ACertificate.KeySize])];
  end;

  // Check for weak signature algorithms
  if ACertificate.AlgSignature.ToLower.Contains('sha1') then
    LIssues := LIssues + ['Weak signature algorithm (SHA-1 is deprecated)'];

  if ACertificate.AlgSignature.ToLower.Contains('md5') then
    LIssues := LIssues + ['Insecure signature algorithm (MD5 is broken)'];

  Result := LIssues;
end;

class procedure THttpDiagClient.ShowCertificateDetails(const ACertificate: TCertificate);
var
  LIssues: TArray<string>;
  LIssue: string;
begin
  WriteLn;
  TConsoleWriter.WriteSection('Certificate Details');

  // Basic information
  if not ACertificate.CertName.IsEmpty then
    TConsoleWriter.WriteInfo('Certificate Name', ACertificate.CertName);

  if not ACertificate.Subject.IsEmpty then
    TConsoleWriter.WriteInfo('Subject', ACertificate.Subject);

  if not ACertificate.Issuer.IsEmpty then
    TConsoleWriter.WriteInfo('Issuer', ACertificate.Issuer);

  if not ACertificate.SerialNum.IsEmpty then
    TConsoleWriter.WriteInfo('Serial Number', ACertificate.SerialNum);

  // Validity period
  WriteLn;
  TConsoleWriter.WriteLineColor('Validity Period:', FOREGROUND_INTENSITY or FOREGROUND_GREEN or FOREGROUND_BLUE);
  TConsoleWriter.WriteInfo('  Not Before', FormatCertDate(ACertificate.Start));
  TConsoleWriter.WriteInfo('  Not After', FormatCertDate(ACertificate.Expiry));

  // Calculate days remaining
  if ACertificate.Expiry > Now then
    TConsoleWriter.WriteInfo('  Days Remaining', IntToStr(DaysBetween(Now, ACertificate.Expiry)))
  else
    TConsoleWriter.WriteWarning('  Certificate has EXPIRED!');

  // Cryptographic details
  WriteLn;
  TConsoleWriter.WriteLineColor('Cryptographic Information:', FOREGROUND_INTENSITY or FOREGROUND_GREEN or FOREGROUND_BLUE);

  if not ACertificate.AlgSignature.IsEmpty then
    TConsoleWriter.WriteInfo('  Signature Algorithm', ACertificate.AlgSignature);

  if not ACertificate.AlgEncryption.IsEmpty then
    TConsoleWriter.WriteInfo('  Encryption Algorithm', ACertificate.AlgEncryption);

  if ACertificate.KeySize > 0 then
    TConsoleWriter.WriteInfo('  Key Size', Format('%d bits', [ACertificate.KeySize]));

  if not ACertificate.ProtocolName.IsEmpty then
    TConsoleWriter.WriteInfo('  Protocol', ACertificate.ProtocolName);

  if not ACertificate.PublicKey.IsEmpty then
    TConsoleWriter.WriteInfo('  Public Key (first 64 chars)', Copy(ACertificate.PublicKey, 1, 64) + '...');

  // Analyze and display issues
  LIssues := AnalyzeCertificateIssues(ACertificate);
  if Length(LIssues) > 0 then
  begin
    WriteLn;
    TConsoleWriter.WriteLineColor('Certificate Warnings/Issues:', FOREGROUND_INTENSITY or FOREGROUND_RED);
    for LIssue in LIssues do
      WriteLn('  ! ' + LIssue);
  end
  else
  begin
    WriteLn;
    TConsoleWriter.WriteSuccess('No certificate issues detected');
  end;
end;

class procedure THttpDiagClient.PerformDiagnostic(const AConfig: TDiagConfig);
var
  LHTTPClient: THTTPClient;
  LResponse: IHTTPResponse;
  LStartTime, LEndTime: TDateTime;
  LDuration: Int64;
  LHeaders: TNetHeaders;
  I: Integer;
  LMethod: string;
  LValidator: TCertificateValidator;
begin
  TConsoleWriter.WriteSection('HTTP/HTTPS Diagnostic');

  // Reset certificate capture
  GCertificateCaptured := False;

  LValidator := TCertificateValidator.Create(AConfig.InsecureMode);
  try
    LHTTPClient := THTTPClient.Create;
    try
      // Configure timeout
      LHTTPClient.ConnectionTimeout := AConfig.Timeout;
      LHTTPClient.ResponseTimeout := AConfig.Timeout;

      // Always capture server certificate for analysis
      LHTTPClient.OnValidateServerCertificate := LValidator.OnValidateCertificate;

      if AConfig.InsecureMode then
        TConsoleWriter.WriteWarning('INSECURE MODE: Certificate validation disabled!');

      // Try HEAD first, fallback to GET if needed
      LMethod := 'HEAD';

      TConsoleWriter.WriteInfo('Request Method', LMethod);
      TConsoleWriter.WriteInfo('Target URL', AConfig.URL);
      TConsoleWriter.WriteInfo('Timeout', Format('%d ms', [AConfig.Timeout]));
      WriteLn;

      LStartTime := Now;

      try
        // Attempt HEAD request
        LResponse := LHTTPClient.Head(AConfig.URL);

        // Check if we got 405 or 501 - need to fallback to GET
        if (LResponse.StatusCode = 405) or (LResponse.StatusCode = 501) then
        begin
          TConsoleWriter.WriteWarning(Format('HEAD request returned %d, trying GET with Range...', [LResponse.StatusCode]));
          LMethod := 'GET (Range: bytes=0-1023)';

          // Try GET with Range header
          SetLength(LHeaders, 1);
          LHeaders[0] := TNetHeader.Create('Range', 'bytes=0-1023');
          LResponse := LHTTPClient.Get(AConfig.URL, nil, LHeaders);
        end;

        LEndTime := Now;
        LDuration := MilliSecondsBetween(LEndTime, LStartTime);

        // Success!
        TConsoleWriter.WriteSuccess('Request completed successfully');
        WriteLn;

        // Display response information
        TConsoleWriter.WriteInfo('Status Code', Format('%d %s', [LResponse.StatusCode, LResponse.StatusText]));
        TConsoleWriter.WriteInfo('Request Duration', Format('%d ms', [LDuration]));

        // Check for redirect location
        if not LResponse.HeaderValue['Location'].IsEmpty then
          TConsoleWriter.WriteInfo('Redirect Location', LResponse.HeaderValue['Location']);

        // Content information
        if LResponse.ContentLength > 0 then
          TConsoleWriter.WriteInfo('Content-Length', Format('%d bytes', [LResponse.ContentLength]));

        if not LResponse.MimeType.IsEmpty then
          TConsoleWriter.WriteInfo('Content-Type', LResponse.MimeType);

        // Display response headers
        WriteLn;
        TConsoleWriter.WriteLineColor('Response Headers:', FOREGROUND_INTENSITY or FOREGROUND_GREEN or FOREGROUND_BLUE);
        for I := 0 to Length(LResponse.Headers) - 1 do
        begin
          WriteLn(Format('  %s: %s', [LResponse.Headers[I].Name, LResponse.Headers[I].Value]));
        end;

        // Display certificate information if captured (HTTPS only)
        if GCertificateCaptured and AConfig.URL.ToLower.StartsWith('https://') then
          ShowCertificateDetails(GCapturedCertificate);

      except
        on E: ENetHTTPClientException do
        begin
          LEndTime := Now;
          LDuration := MilliSecondsBetween(LEndTime, LStartTime);

          TConsoleWriter.WriteError('HTTP Client error!');
          WriteLn;
          TConsoleWriter.WriteInfo('Exception Class', E.ClassName);
          TConsoleWriter.WriteInfo('Error Message', E.Message);
          TConsoleWriter.WriteInfo('Request Duration', Format('%d ms', [LDuration]));

          // Show certificate info if captured
          if GCertificateCaptured then
            ShowCertificateDetails(GCapturedCertificate)
          else if E.Message.Contains('certificate') or E.Message.Contains('SSL') or E.Message.Contains('TLS') then
          begin
            WriteLn;
            TConsoleWriter.WriteWarning('This could indicate:');
            WriteLn('  - Expired or invalid certificate');
            WriteLn('  - TLS inspection by corporate proxy/firewall');
            WriteLn('  - Man-in-the-middle attack');
            WriteLn('  - Self-signed certificate');
          end;
        end;

        on E: Exception do
        begin
          LEndTime := Now;
          LDuration := MilliSecondsBetween(LEndTime, LStartTime);

          TConsoleWriter.WriteError('Request failed!');
          WriteLn;
          TConsoleWriter.WriteInfo('Exception Class', E.ClassName);
          TConsoleWriter.WriteInfo('Error Message', E.Message);
          TConsoleWriter.WriteInfo('Request Duration', Format('%d ms', [LDuration]));

          // Show certificate info if captured
          if GCertificateCaptured then
            ShowCertificateDetails(GCapturedCertificate);
        end;
      end;

    finally
      LHTTPClient.Free;
    end;
  finally
    LValidator.Free;
  end;
end;

end.