#ifndef __GdiFontManager_H_INCLUDED__
#define __GdiFontManager_H_INCLUDED__

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
#pragma once
#endif

#include "Defines.h"

class GdiFontManager
{
private:
    ULONG_PTR m_GDIToken;
    IDirect3DDevice8* m_Device;
    Gdiplus::Bitmap* m_Bitmap;
    Gdiplus::Graphics* m_Graphics;

    // Bitmap components
    int m_CanvasWidth;
    int m_CanvasHeight;
    int m_CanvasStride;
    int m_Size;
    void* m_RawImage;
    uint8_t* m_Pixels;
    bool m_SaveToHardDrive;
    char m_SavePath[1024];


public:
    GdiFontManager(IDirect3DDevice8* pDevice);
    ~GdiFontManager();
    GdiFontReturn_t CreateFontTexture(GdiFontData_t data);
    GdiFontReturn_t CreateFontTextureColor(GdiFontData_t data);
    GdiFontReturn_t CreateRectTexture(GdiRectData_t data);
    void EnableTextureDump(const char* Folder);
    void DisableTextureDump();
    
private:
    Gdiplus::Color UINT32_TO_COLOR(uint32_t color);
    void ClearCanvas(int width, int height);
    Gdiplus::Brush* GetBrush(GdiFontData_t data, int width, int height);
    Gdiplus::Brush* GetBrush(GdiRectData_t data, int width, int height);
};
#endif