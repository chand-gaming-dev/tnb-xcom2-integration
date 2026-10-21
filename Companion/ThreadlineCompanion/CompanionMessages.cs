namespace ThreadlineCompanion;

internal static class CompanionMessages
{
    internal static string Error(Exception error) => error switch
    {
        BridgeError bridge => bridge.Code switch
        {
            "invalid_credential_format" => "Enter a Journey credential beginning with tlj_.",
            "invalid_credential" or "journey_credential_invalid" => "The service rejected the credential. Check it or issue a replacement.",
            "scope_missing" => "This credential is missing required permissions: roster read, instance create/read, and event write are required.",
            "credential_missing" => "No credential is stored. Enter one and select Validate and save.",
            "credential_store_unavailable" => "Windows Credential Manager is unavailable. No successful save is confirmed.",
            "journey_mismatch" => "The credential does not match the expected Journey. Existing links have not been changed.",
            "api_context_invalid" or "api_response_invalid" => "The API returned an unexpected Journey response.",
            "api_redirect_rejected" => "The development server redirected the request. Refresh its external-access token if needed, then restart the companion.",
            "rate_limited" or "journey_credential_throttled" => "The service is limiting requests. Wait before trying again; any stored credential is retained.",
            _ => "The connection could not be verified. Check the API address, development access, and credential permissions."
        },
        System.Net.Sockets.SocketException => "The local companion port is unavailable. Close any other copy or check the port configuration.",
        HttpRequestException => "The service could not be reached. Any previously stored credential is retained.",
        OperationCanceledException => "The request was cancelled or timed out. Check the current stored-credential status before retrying.",
        IOException or UnauthorizedAccessException => "Local companion storage is unavailable. Check the current stored-credential status.",
        _ => "The companion could not complete this operation. No secret or raw server error is displayed."
    };

    internal static string Connection(string state) => state switch
    {
        "connected" => "Connected",
        "unverified" => "Stored, not yet verified this session",
        "unable_to_verify" => "Unable to verify",
        "invalid_credential" => "Invalid or revoked credential",
        "scope_missing" => "Credential permissions incomplete",
        "not_configured" => "Not configured",
        _ => "Status unavailable"
    };
}
