#include "app_identity.h"
#include <shlobj.h>
#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>
#include <wrl/client.h>
#include <filesystem>
#include <vector>

using Microsoft::WRL::ComPtr;
namespace fs = std::filesystem;

std::wstring FusionExecutablePath() {
  wchar_t path[32768]{};
  const DWORD size = GetModuleFileNameW(nullptr, path, ARRAYSIZE(path));
  return size && size < ARRAYSIZE(path) ? std::wstring(path, size) : L"";
}

std::wstring FusionIconPath() {
  return (fs::path(FusionExecutablePath()).parent_path() / kFusionIconFile).wstring();
}

namespace {
bool SetText(IPropertyStore* store, REFPROPERTYKEY key, const std::wstring& value) {
  PROPVARIANT property{};
  if (FAILED(InitPropVariantFromString(value.c_str(), &property))) return false;
  const HRESULT result = store->SetValue(key, property);
  PropVariantClear(&property);
  return SUCCEEDED(result);
}

std::wstring KnownFolder(REFKNOWNFOLDERID folder) {
  PWSTR path = nullptr;
  if (FAILED(SHGetKnownFolderPath(folder, 0, nullptr, &path))) return L"";
  const std::wstring result(path);
  CoTaskMemFree(path);
  return result;
}

bool SamePath(const std::wstring& a, const std::wstring& b) {
  if (a.empty() || b.empty()) return false;
  return _wcsicmp(fs::path(a).lexically_normal().c_str(), fs::path(b).lexically_normal().c_str()) == 0;
}

bool OwnLink(IShellLinkW* link, IPropertyStore* store, const std::wstring& exe) {
  wchar_t target[32768]{};
  if (SUCCEEDED(link->GetPath(target, ARRAYSIZE(target), nullptr, SLGP_RAWPATH)) && SamePath(target, exe)) return true;
  PROPVARIANT property{};
  if (SUCCEEDED(store->GetValue(PKEY_Link_TargetParsingPath, &property))) {
    const bool own = property.vt == VT_LPWSTR && property.pwszVal && SamePath(property.pwszVal, exe);
    PropVariantClear(&property);
    if (own) return true;
  }
  PIDLIST_ABSOLUTE id = nullptr;
  if (SUCCEEDED(link->GetIDList(&id)) && id) {
    PWSTR name = nullptr;
    bool own = false;
    if (SUCCEEDED(SHGetNameFromIDList(id, SIGDN_DESKTOPABSOLUTEPARSING, &name))) {
      own = SamePath(name, exe);
      CoTaskMemFree(name);
    }
    CoTaskMemFree(id);
    return own;
  }
  return false;
}

bool RefreshLink(const fs::path& path, const std::wstring& exe, const std::wstring& icon) {
  ComPtr<IShellLinkW> link;
  if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&link)))) return false;
  ComPtr<IPersistFile> file;
  ComPtr<IPropertyStore> store;
  if (FAILED(link.As(&file)) || FAILED(link.As(&store)) || FAILED(file->Load(path.c_str(), STGM_READWRITE))) return false;
  if (!OwnLink(link.Get(), store.Get(), exe)) return true; // Never alter another application's shortcut.
  if (FAILED(link->SetPath(exe.c_str())) || FAILED(link->SetWorkingDirectory(fs::path(exe).parent_path().c_str())) ||
      FAILED(link->SetIconLocation(icon.c_str(), 0)) || !SetText(store.Get(), PKEY_AppUserModel_ID, kFusionAppId) ||
      FAILED(store->Commit()) || FAILED(file->Save(path.c_str(), TRUE))) return false;
  SHChangeNotify(SHCNE_UPDATEITEM, SHCNF_PATHW | SHCNF_FLUSHNOWAIT, path.c_str(), nullptr);
  return true;
}
}

void ConfigureFusionIdentity() {
  SetCurrentProcessExplicitAppUserModelID(kFusionAppId);
}

void ApplyFusionWindowIdentity(HWND window) {
  ComPtr<IPropertyStore> store;
  if (SUCCEEDED(SHGetPropertyStoreForWindow(window, IID_PPV_ARGS(&store)))) {
    SetText(store.Get(), PKEY_AppUserModel_ID, kFusionAppId);
    SetText(store.Get(), PKEY_AppUserModel_RelaunchIconResource, FusionIconPath() + L",0");
    SetText(store.Get(), PKEY_AppUserModel_RelaunchCommand, L"\"" + FusionExecutablePath() + L"\"");
    SetText(store.Get(), PKEY_AppUserModel_RelaunchDisplayNameResource, L"SMT Fusion");
    store->Commit();
  }
  if (GetFileAttributesW(FusionIconPath().c_str()) != INVALID_FILE_ATTRIBUTES) {
    // These two process-lifetime handles are released by Windows on exit.
    const auto big = LoadImageW(nullptr, FusionIconPath().c_str(), IMAGE_ICON, GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), LR_LOADFROMFILE);
    const auto small_icon = LoadImageW(nullptr, FusionIconPath().c_str(), IMAGE_ICON, GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), LR_LOADFROMFILE);
    if (big) SendMessageW(window, WM_SETICON, ICON_BIG, reinterpret_cast<LPARAM>(big));
    if (small_icon) SendMessageW(window, WM_SETICON, ICON_SMALL, reinterpret_cast<LPARAM>(small_icon));
  }
}

int RepairFusionShortcuts() {
  const auto exe = FusionExecutablePath(), icon = FusionIconPath();
  if (exe.empty() || GetFileAttributesW(icon.c_str()) == INVALID_FILE_ATTRIBUTES) return 1;
  const auto desktop = KnownFolder(FOLDERID_Desktop);
  const auto programs = KnownFolder(FOLDERID_Programs);
  const auto roaming = KnownFolder(FOLDERID_RoamingAppData);
  std::vector<fs::path> paths;
  std::vector<std::wstring> roots{desktop};
  if (!programs.empty()) {
    roots.push_back(programs + L"\\SMT Fusion");
    roots.push_back(programs + L"\\SMT-CHECK");
  }
  if (!roaming.empty()) roots.push_back(roaming + L"\\Microsoft\\Internet Explorer\\Quick Launch\\User Pinned\\TaskBar");
  for (const auto& root : roots) {
    if (root.empty()) continue;
    std::error_code error;
    for (fs::directory_iterator it(root, error), end; !error && it != end; it.increment(error)) {
      if (it->path().extension() == L".lnk") paths.push_back(it->path());
    }
  }
  bool ok = true;
  for (const auto& path : paths) {
    const auto name = path.stem().wstring();
    if (name.find(L"SMT") != 0) continue;
    if (!RefreshLink(path, exe, icon)) ok = false;
  }
  // Ask the Shell to refresh associations; do not delete global caches or restart Explorer.
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSHNOWAIT, nullptr, nullptr);
  return ok ? 0 : 2;
}
