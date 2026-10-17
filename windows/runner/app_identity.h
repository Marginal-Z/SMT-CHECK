#pragma once
#include <windows.h>
#include <string>

inline constexpr wchar_t kFusionAppId[] = L"MarginalZ.SMTFusion.Desktop";
inline constexpr wchar_t kFusionIconFile[] = L"smt-fusion-20261017.ico";
std::wstring FusionExecutablePath();
std::wstring FusionIconPath();
void ConfigureFusionIdentity();
void ApplyFusionWindowIdentity(HWND window);
int RepairFusionShortcuts();
