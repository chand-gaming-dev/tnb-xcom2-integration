using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;

namespace TheNameBeneath.Companion;

internal interface ISecretStore
{
    string? Read(string journey);
    void Write(string journey, string secret);
    void Remove(string journey);
}

internal sealed class WindowsSecrets(Uri api) : ISecretStore
{
    // Preserve the existing vault key so a branding update does not orphan credentials.
    private string Target(string journey) => "Threadline/TheNameBeneath/" + Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(api.AbsoluteUri)))[..16] + "/" + journey;
    public string? Read(string journey)
    {
        if (!CredRead(Target(journey), 1, 0, out var pointer))
        {
            if (Marshal.GetLastWin32Error() == 1168) return null;
            throw new BridgeError("credential_store_unavailable");
        }
        try
        {
            var credential = Marshal.PtrToStructure<Credential>(pointer);
            if (credential.Size == 0 || credential.Size > 2560 || credential.Size % 2 != 0) throw new BridgeError("credential_store_invalid");
            return Marshal.PtrToStringUni(credential.Blob, checked((int)credential.Size / 2));
        }
        finally { CredFree(pointer); }
    }
    public void Write(string journey, string secret)
    {
        var bytes = Encoding.Unicode.GetBytes(secret);
        if (bytes.Length > 2560) throw new BridgeError("credential_too_long");
        var blob = Marshal.AllocHGlobal(bytes.Length);
        try
        {
            Marshal.Copy(bytes, 0, blob, bytes.Length);
            var value = new Credential { Type = 1, Target = Target(journey), Size = (uint)bytes.Length, Blob = blob, Persist = 2, UserName = "The Name Beneath Journey" };
            if (!CredWrite(ref value, 0)) throw new BridgeError("credential_store_unavailable");
        }
        finally
        {
            CryptographicOperations.ZeroMemory(bytes);
            for (int i = 0; i < secret.Length * 2; i++) Marshal.WriteByte(blob, i, 0);
            Marshal.FreeHGlobal(blob);
        }
    }
    public void Remove(string journey)
    {
        if (!CredDelete(Target(journey), 1, 0) && Marshal.GetLastWin32Error() != 1168) throw new BridgeError("credential_store_unavailable");
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct Credential
    {
        public uint Flags, Type;
        [MarshalAs(UnmanagedType.LPWStr)] public string? Target;
        [MarshalAs(UnmanagedType.LPWStr)] public string? Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint Size;
        public IntPtr Blob;
        public uint Persist, AttributeCount;
        public IntPtr Attributes;
        [MarshalAs(UnmanagedType.LPWStr)] public string? Alias;
        [MarshalAs(UnmanagedType.LPWStr)] public string? UserName;
    }
    [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(string target, uint type, uint flags, out IntPtr credential);
    [DllImport("advapi32.dll", EntryPoint = "CredWriteW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredWrite(ref Credential credential, uint flags);
    [DllImport("advapi32.dll", EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredDelete(string target, uint type, uint flags);
    [DllImport("advapi32.dll")] private static extern void CredFree(IntPtr pointer);
}

