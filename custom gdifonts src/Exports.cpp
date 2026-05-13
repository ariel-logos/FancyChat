#include "GdiFontManager.h"

int CALLBACK EnumFontFamExProc(const LOGFONT* lpelfe, const TEXTMETRIC* lpntme, DWORD FontType, LPARAM lParam)
{
    *((LPARAM*)lParam) = 1;
    return 1;
}

extern "C"
{
    extern __declspec(dllexport) GdiFontManager* CreateFontManager(IDirect3DDevice8* pDirect3DDevice)
    {
        return new GdiFontManager(pDirect3DDevice);
    }
    extern __declspec(dllexport) void DestroyFontManager(GdiFontManager* pFontManager)
    {
        delete pFontManager;
    }
    extern __declspec(dllexport) GdiFontReturn_t CreateTexture(GdiFontManager* pFontManager, GdiFontData_t* data)
    {
        return pFontManager->CreateFontTexture(*data);
    }
    extern __declspec(dllexport) GdiFontReturn_t CreateTextureColor(GdiFontManager* pFontManager, GdiFontData_t* data)
    {
        return pFontManager->CreateFontTextureColor(*data);
    }
    extern __declspec(dllexport) GdiFontReturn_t CreateRectTexture(GdiFontManager* pFontManager, GdiRectData_t* data)
    {
        return pFontManager->CreateRectTexture(*data);
    }
    extern __declspec(dllexport) bool GetFontAvailable(const char* font)
    {
        LOGFONT lf = {0};
        lf.lfCharSet = DEFAULT_CHARSET;
        swprintf_s(lf.lfFaceName, 32, L"%S", font);
        LPARAM lParam = 0;
        ::EnumFontFamiliesEx(GetDC(nullptr), &lf, EnumFontFamExProc, (LPARAM)&lParam, 0);
        return lParam ? true : false;
    }
    extern __declspec(dllexport) void EnableTextureDump(GdiFontManager* pFontManager, const char* folder)
    {
        pFontManager->EnableTextureDump(folder);
    }
    extern __declspec(dllexport) void DisableTextureDump(GdiFontManager* pFontManager)
    {
        pFontManager->DisableTextureDump();
    }
}