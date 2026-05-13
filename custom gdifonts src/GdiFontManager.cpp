#include "GdiFontManager.h"
#include <algorithm> // Include this header for std::max
#include <cmath>     // Include this header for std::ceil
#include <string>
#include <cwctype> // for std::iswspace
#include <filesystem>
#include <locale>
#include <cctype>
#include <unordered_map> // for g_familyCache (Tier-1 perf: cache pFontFamily by name)



int GetEncoderClsid(const WCHAR* format, CLSID* pClsid)
{
    UINT num  = 0; // number of image encoders
    UINT size = 0; // size of the image encoder array in bytes

    Gdiplus::ImageCodecInfo* pImageCodecInfo = NULL;

    Gdiplus::GetImageEncodersSize(&num, &size);
    if (size == 0)
        return -1; // Failure

    pImageCodecInfo = (Gdiplus::ImageCodecInfo*)(malloc(size));
    if (pImageCodecInfo == NULL)
        return -1; // Failure

    Gdiplus::GetImageEncoders(num, size, pImageCodecInfo);

    for (UINT j = 0; j < num; ++j)
    {
        if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0)
        {
            *pClsid = pImageCodecInfo[j].Clsid;
            free(pImageCodecInfo);
            return j; // Success
        }
    }

    free(pImageCodecInfo);
    return -1; // Failure
}

GdiFontManager::GdiFontManager(IDirect3DDevice8* pDevice)
    : m_Device(pDevice)
    , m_CanvasWidth(2048)
    , m_CanvasHeight(2048)
    , m_SaveToHardDrive(false)
{
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    Gdiplus::GdiplusStartup(&m_GDIToken, &gdiplusStartupInput, NULL);

    // Create bitmap in memory..
    m_Size     = m_CanvasWidth * m_CanvasHeight * 4;
    m_RawImage = malloc(m_Size + 108);
    m_Pixels   = (uint8_t*)m_RawImage + 108;
    memset(m_RawImage, 0, m_Size + 108);
    auto p_Header              = (BITMAPV4HEADER*)m_RawImage;
    p_Header->bV4Size          = sizeof(BITMAPV4HEADER);
    p_Header->bV4Width         = m_CanvasWidth;
    p_Header->bV4Height        = m_CanvasHeight;
    p_Header->bV4Planes        = 1;
    p_Header->bV4BitCount      = 32;
    p_Header->bV4V4Compression = BI_BITFIELDS;
    p_Header->bV4RedMask       = 0x00FF0000;
    p_Header->bV4GreenMask     = 0x0000FF00;
    p_Header->bV4BlueMask      = 0x000000FF;
    p_Header->bV4AlphaMask     = 0xFF000000;

    // Create gdiplus objects using bitmap in memory..
    this->m_CanvasStride = m_CanvasWidth * 4;
    this->m_Bitmap       = new Gdiplus::Bitmap(m_CanvasWidth, m_CanvasHeight, m_CanvasStride, PixelFormat32bppARGB, (BYTE*)m_Pixels);
    this->m_Graphics     = new Gdiplus::Graphics(this->m_Bitmap);
    m_Graphics->SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
    m_Graphics->SetCompositingMode(Gdiplus::CompositingModeSourceOver);
    m_Graphics->SetCompositingQuality(Gdiplus::CompositingQualityHighQuality);
    m_Graphics->SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    m_Graphics->SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
    m_Graphics->SetTextRenderingHint(Gdiplus::TextRenderingHintClearTypeGridFit);
    setlocale(LC_ALL, "");
}

Gdiplus::PrivateFontCollection g_fontCollection;
Gdiplus::FontFamily* g_customFont = nullptr;

// Process-wide singletons for the two fallback fonts the codepoint
// loop in CreateFontTextureColor uses for non-BMP / non-PUA glyphs.
// Gdiplus::FontFamily(name) enumerates the installed-font registry to
// resolve the family - non-trivial, and the family name never changes,
// so we build once and reuse for the DLL's lifetime.
Gdiplus::FontFamily* g_emojiFont  = nullptr;
Gdiplus::FontFamily* g_symbolFont = nullptr;

// Cache for the per-call "main" font family (data.FontFamily, which is
// almost always the same string across calls in normal use).  Avoids
// the FontFamily ctor + heap churn on every CreateFontTextureColor.
// Entries live for the DLL's lifetime; cleaned up in the dtor below.
std::unordered_map<std::wstring, Gdiplus::FontFamily*> g_familyCache;

GdiFontManager::~GdiFontManager()
{
    if (g_customFont)
    {
        delete g_customFont;
        g_customFont = nullptr;
    }
    if (g_emojiFont)
    {
        delete g_emojiFont;
        g_emojiFont = nullptr;
    }
    if (g_symbolFont)
    {
        delete g_symbolFont;
        g_symbolFont = nullptr;
    }
    for (auto& kv : g_familyCache)
    {
        delete kv.second;
    }
    g_familyCache.clear();

    g_fontCollection.~PrivateFontCollection();
    delete this->m_Graphics;
    delete this->m_Bitmap;
    free(m_RawImage);
    Gdiplus::GdiplusShutdown(m_GDIToken);
}

GdiFontReturn_t GdiFontManager::CreateFontTexture(GdiFontData_t data)
{
    if (data.BoxHeight == 0)
        data.BoxHeight = m_CanvasHeight;
    if (data.BoxWidth == 0)
        data.BoxWidth = m_CanvasWidth;

    // Attempt to set up font family..
    wchar_t wBuffer[4096];
    ::MultiByteToWideChar(CP_UTF8, 0, data.FontFamily, -1, wBuffer, 4096);
    Gdiplus::FontFamily* pFontFamily = new Gdiplus::FontFamily(wBuffer);
    if (pFontFamily->GetLastStatus() != Gdiplus::Ok)
    {
        delete pFontFamily;
        return GdiFontReturn_t();
    }

    // Attempt to create graphics path..
    ::MultiByteToWideChar(CP_UTF8, 0, data.FontText, -1, wBuffer, 4096);
    auto length = wcslen(wBuffer);
    Gdiplus::Rect pathRect(0, 0, data.BoxWidth, data.BoxHeight);
    Gdiplus::StringFormat fontFormat;
    fontFormat.SetAlignment(Gdiplus::StringAlignment::StringAlignmentNear);
    Gdiplus::GraphicsPath* pPath = new Gdiplus::GraphicsPath();
    pPath->AddString(wBuffer, length, pFontFamily, data.FontFlags, data.FontHeight, pathRect, &fontFormat);
    if (pPath->GetLastStatus() != Gdiplus::Ok)
    {
        delete pPath;
        delete pFontFamily;
        return GdiFontReturn_t();
    }

    // Prepare outline pen if applicable and get calculated path size from Gdiplus..
    Gdiplus::Pen* pen = nullptr;
    Gdiplus::RectF box{};
    if ((data.OutlineWidth > 0) && ((data.OutlineColor & 0xFF000000) != 0))
    {
        pen = new Gdiplus::Pen(UINT32_TO_COLOR(data.OutlineColor), data.OutlineWidth);
        pPath->GetBounds(&box, nullptr, pen);
    }
    else
    {
        Gdiplus::Pen genericPen(Gdiplus::Color(255, 255, 255, 255), 1.0);
        pPath->GetBounds(&box, nullptr, &genericPen);
    }

    // Clear necessary space using calculated path size.
    int32_t width  = (int32_t)ceil(box.Width);
    int32_t height = (int32_t)ceil(box.Height);
    this->ClearCanvas(width, height);

    // Draw outline if applicable..
    if (pen)
    {
        m_Graphics->DrawPath(pen, pPath);
        delete pen;
    }

    // Fill text if font color isn't fully transparent..
    if (((data.FontColor & 0xFF000000) != 0) || ((data.GradientStyle != 0) && ((data.GradientColor & 0xFF000000) != 0)))
    {
        auto pBrush = GetBrush(data, width, height);
        m_Graphics->FillPath(pBrush, pPath);
        delete pBrush;
    }

    // Clean up remaining gdiplus objects..
    delete pPath;
    delete pFontFamily;

    // Examine raw pixels to get exact texture size(gdiplus does not calculate pixel perfect size)..
    int32_t firstPx = width - 1;
    int32_t lastPx  = 0;
    uint32_t* px    = (uint32_t*)this->m_Pixels;
    int maxHeight   = height;
    for (auto y = 0; y < maxHeight; y++)
    {
        for (auto x = (width - 1); x >= lastPx; x--)
        {
            if (px[x])
            {
                height = y + 1;
                lastPx = x;
            }
        }

        for (auto x = 0; x < width; x++)
        {
            if (px[x])
            {
                height = y + 1;
                if (x < firstPx)
                {
                    firstPx = x;
                }
                break;
            }
        }

        px += this->m_CanvasWidth;
    }
    width = (lastPx - firstPx) + 1;

    // End early if width or height are 0..
    if ((width == 0) || (height == 0))
        return GdiFontReturn_t();

    // Attempt to create texture..
    IDirect3DTexture8* pTexture;
    if (FAILED(::D3DXCreateTexture(this->m_Device, width, height, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &pTexture)))
    {
        return GdiFontReturn_t();
    }
    D3DSURFACE_DESC surfaceDesc;
    if (FAILED(pTexture->GetLevelDesc(0, &surfaceDesc)))
    {
        if (pTexture != nullptr)
            pTexture->Release();

        return GdiFontReturn_t();
    }

    // Copy rendered font from bitmap to texture..
    D3DLOCKED_RECT rect{};
    auto copyStride = width * 4;
    pTexture->LockRect(0, &rect, 0, 0);
    {
        uint8_t* dest = (uint8_t*)rect.pBits;
        uint8_t* src  = this->m_Pixels + (firstPx * 4);
        for (int x = 0; x < height; x++)
        {
            memcpy(dest, src, copyStride);
            dest += copyStride;
            src += this->m_CanvasStride;
        }
    }
    pTexture->UnlockRect(0);

    // Save physical file if requested
    if (m_SaveToHardDrive)
    {
        BITMAPV4HEADER bmp   = {sizeof(BITMAPV4HEADER)};
        bmp.bV4Width         = width;
        bmp.bV4Height        = height;
        bmp.bV4Planes        = 1;
        bmp.bV4BitCount      = 32;
        bmp.bV4V4Compression = BI_BITFIELDS;
        bmp.bV4RedMask       = 0x00FF0000;
        bmp.bV4GreenMask     = 0x0000FF00;
        bmp.bV4BlueMask      = 0x000000FF;
        bmp.bV4AlphaMask     = 0xFF000000;

        uint8_t* pPixels      = nullptr;
        HBITMAP pBmp          = ::CreateDIBSection(nullptr, (BITMAPINFO*)&bmp, DIB_RGB_COLORS, (void**)&pPixels, nullptr, 0);
        Gdiplus::Bitmap* pRaw = new Gdiplus::Bitmap(width, height, width * 4, PixelFormat32bppARGB, (BYTE*)pPixels);

        uint8_t* src = this->m_Pixels + (firstPx * 4);
        for (int x = 0; x < height; x++)
        {
            memcpy(pPixels, src, copyStride);
            pPixels += copyStride;
            src += this->m_CanvasStride;
        }

        CLSID pngClsid;
        GetEncoderClsid(L"image/png", &pngClsid);
        auto index = 0;
        wchar_t nameBuffer[256];
        swprintf_s(nameBuffer, L"%S\\font_%u.png", m_SavePath, index);
        while (std::filesystem::exists(nameBuffer))
        {
            index++;
            swprintf_s(nameBuffer, L"%S\\font_%u.png", m_SavePath, index);
        }
        pRaw->Save(nameBuffer, &pngClsid, NULL);
        delete pRaw;
        DeleteObject(pBmp);
    }

    // Create return object..
    GdiFontReturn_t ret;
    ret.Width   = width;
    ret.Height  = height;
    ret.Texture = pTexture;
    return ret;
}
Gdiplus::GraphicsPath* CreateRoundedRectPath(Gdiplus::Rect rect, int radius)
{
    Gdiplus::GraphicsPath* pPath = new Gdiplus::GraphicsPath();
    if (radius == 0)
        pPath->AddRectangle(rect);
    else
    {
        int diameter = radius * 2;
        Gdiplus::Rect arc(rect.X, rect.Y, diameter, diameter);
        pPath->AddArc(arc, 180, 90);
        arc.X = (rect.X + rect.Width) - diameter;
        pPath->AddArc(arc, 270, 90);
        arc.Y = (rect.Y + rect.Height) - diameter;
        pPath->AddArc(arc, 0, 90);
        arc.X = rect.X;
        pPath->AddArc(arc, 90, 90);
        pPath->CloseFigure();
    }
    return pPath;
}

GdiFontReturn_t GdiFontManager::CreateRectTexture(GdiRectData_t data)
{
    int width  = data.Width;
    int height = data.Height;

    Gdiplus::Rect drawRect(0, 0, width, height);
    if (data.OutlineWidth != 0)
    {
        auto inset  = data.OutlineWidth / 2;
        auto shrink = data.OutlineWidth;
        if (data.OutlineWidth % 2)
        {
            inset += 1;
            shrink++;
        }
        drawRect = Gdiplus::Rect(inset, inset, width - shrink, height - shrink);
    }
    Gdiplus::GraphicsPath* pPath = CreateRoundedRectPath(drawRect, data.Diameter);

    // Clear necessary space
    this->ClearCanvas(width, height);

    // Fill text if font color isn't fully transparent..
    if (((data.FillColor & 0xFF000000) != 0) || ((data.GradientStyle != 0) && ((data.GradientColor & 0xFF000000) != 0)))
    {
        auto pBrush = GetBrush(data, width, height);
        m_Graphics->FillPath(pBrush, pPath);
        delete pBrush;
    }

    // Draw outline if applicable..
    if ((data.OutlineWidth > 0) && ((data.OutlineColor & 0xFF000000) != 0))
    {
        Gdiplus::GraphicsPath* pOutline = CreateRoundedRectPath(drawRect, data.Diameter);
        Gdiplus::Pen pen(UINT32_TO_COLOR(data.OutlineColor), data.OutlineWidth);
        m_Graphics->DrawPath(&pen, pOutline);
        delete pOutline;
    }

    // Clean up remaining gdiplus objects..
    delete pPath;

    // Attempt to create texture..
    IDirect3DTexture8* pTexture;
    if (FAILED(::D3DXCreateTexture(this->m_Device, width, height, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &pTexture)))
    {
        return GdiFontReturn_t();
    }
    D3DSURFACE_DESC surfaceDesc;
    if (FAILED(pTexture->GetLevelDesc(0, &surfaceDesc)))
    {
        if (pTexture != nullptr)
            pTexture->Release();

        return GdiFontReturn_t();
    }

    // Copy rendered font from bitmap to texture..
    D3DLOCKED_RECT rect{};
    auto copyStride = width * 4;
    pTexture->LockRect(0, &rect, 0, 0);
    {
        uint8_t* dest = (uint8_t*)rect.pBits;
        uint8_t* src  = this->m_Pixels;
        for (int x = 0; x < height; x++)
        {
            memcpy(dest, src, copyStride);
            dest += copyStride;
            src += this->m_CanvasStride;
        }
    }
    pTexture->UnlockRect(0);

    // Save physical file if requested
    if (m_SaveToHardDrive)
    {
        BITMAPV4HEADER bmp   = {sizeof(BITMAPV4HEADER)};
        bmp.bV4Width         = width;
        bmp.bV4Height        = height;
        bmp.bV4Planes        = 1;
        bmp.bV4BitCount      = 32;
        bmp.bV4V4Compression = BI_BITFIELDS;
        bmp.bV4RedMask       = 0x00FF0000;
        bmp.bV4GreenMask     = 0x0000FF00;
        bmp.bV4BlueMask      = 0x000000FF;
        bmp.bV4AlphaMask     = 0xFF000000;

        uint8_t* pPixels      = nullptr;
        HBITMAP pBmp          = ::CreateDIBSection(nullptr, (BITMAPINFO*)&bmp, DIB_RGB_COLORS, (void**)&pPixels, nullptr, 0);
        Gdiplus::Bitmap* pRaw = new Gdiplus::Bitmap(width, height, width * 4, PixelFormat32bppARGB, (BYTE*)pPixels);

        uint8_t* src = this->m_Pixels;
        for (int x = 0; x < height; x++)
        {
            memcpy(pPixels, src, copyStride);
            pPixels += copyStride;
            src += this->m_CanvasStride;
        }

        CLSID pngClsid;
        GetEncoderClsid(L"image/png", &pngClsid);
        auto index = 0;
        wchar_t nameBuffer[256];
        swprintf_s(nameBuffer, L"%S\\rect_%u.png", m_SavePath, index);
        while (std::filesystem::exists(nameBuffer))
        {
            index++;
            swprintf_s(nameBuffer, L"%S\\rect_%u.png", m_SavePath, index);
        }
        pRaw->Save(nameBuffer, &pngClsid, NULL);
        delete pRaw;
        DeleteObject(pBmp);
    }

    // Create return object..
    GdiFontReturn_t ret;
    ret.Width   = width;
    ret.Height  = height;
    ret.Texture = pTexture;
    return ret;
}

Gdiplus::Color GdiFontManager::UINT32_TO_COLOR(uint32_t color)
{
    auto alpha = (color & 0xFF000000) >> 24;
    auto red   = (color & 0x00FF0000) >> 16;
    auto green = (color & 0x0000FF00) >> 8;
    auto blue  = (color & 0x000000FF);
    return Gdiplus::Color(alpha, red, green, blue);
}

void GdiFontManager::ClearCanvas(int width, int height)
{
    auto clearStride = width * 4;
    auto pixels      = this->m_Pixels;
    for (int x = 0; x < height; x++)
    {
        memset(pixels, 0, clearStride);
        pixels += this->m_CanvasStride;
    }
}

Gdiplus::Brush* GdiFontManager::GetBrush(GdiFontData_t data, int width, int height)
{
    if (data.GradientStyle == 0)
    {
        auto color = UINT32_TO_COLOR(data.FontColor);
        return new Gdiplus::SolidBrush(color);
    }

    Gdiplus::Point start(0, 0);
    Gdiplus::Point end(0, 0);
    switch (data.GradientStyle)
    {
        //Left to right
        case 1:
            end.X = width;
            break;

        //Top-Left to Bottom Right
        case 2:
            end.X = width;
            end.Y = height;
            break;

        //Top to bottom
        case 3:
            end.Y = height;
            break;

        //Top-Right to Bottom Left
        case 4:
            start.X = width;
            end.Y   = height;
            break;

        //Right to Left
        case 5:
            start.X = width;
            break;

        //Bottom-Right to Top Left
        case 6:
            start.X = width;
            start.Y = height;
            break;

        //Bottom to Top
        case 7:
            start.Y = height;
            break;

        //Bottom-Left to Top Right
        case 8:
            start.Y = height;
            end.X   = width;
            break;

        default:
            end.X = width;
            break;
    }

    return new Gdiplus::LinearGradientBrush(start, end, UINT32_TO_COLOR(data.FontColor), UINT32_TO_COLOR(data.GradientColor));
}

Gdiplus::Brush* GdiFontManager::GetBrush(GdiRectData_t data, int width, int height)
{
    if (data.GradientStyle == 0)
    {
        auto color = UINT32_TO_COLOR(data.FillColor);
        return new Gdiplus::SolidBrush(color);
    }

    Gdiplus::Point start(0, 0);
    Gdiplus::Point end(0, 0);

    switch (data.GradientStyle)
    {
        //Left to right
        case 1:
            end.X = width;
            break;

        //Top-Left to Bottom Right
        case 2:
            end.X = width;
            end.Y = height;
            break;

        //Top to bottom
        case 3:
            end.Y = height;
            break;

        //Top-Right to Bottom Left
        case 4:
            start.X = width;
            end.Y   = height;
            break;

        //Right to Left
        case 5:
            start.X = width;
            break;

        //Bottom-Right to Top Left
        case 6:
            start.X = width;
            start.Y = height;
            break;

        //Bottom to Top
        case 7:
            start.Y = height;
            break;

        //Bottom-Left to Top Right
        case 8:
            start.Y = height;
            end.X   = width;
            break;

        default:
            end.X = width;
            break;
    }

    return new Gdiplus::LinearGradientBrush(start, end, UINT32_TO_COLOR(data.FillColor), UINT32_TO_COLOR(data.GradientColor));
}

void GdiFontManager::EnableTextureDump(const char* folder)
{
    strcpy_s(m_SavePath, 1024, folder);
    m_SaveToHardDrive = true;
}
void GdiFontManager::DisableTextureDump()
{
    m_SaveToHardDrive = false;
}

std::wstring trim(const std::wstring& str)
{
    size_t first = 0;
    while (first < str.size() && std::iswspace(str[first])) {
        ++first;
    }

    size_t last = str.size();
    while (last > first && std::iswspace(str[last - 1])) {
        --last;
    }

    return str.substr(first, last - first);
}

std::vector<uint32_t> Utf16ToUtf32(const wchar_t* src)
{
    std::vector<uint32_t> out;
    size_t i = 0, len = wcslen(src);

    while (i < len)
    {
        wchar_t wc = src[i];
        if (i + 1 < len && wc >= 0xD800 && wc <= 0xDBFF)
        {
            wchar_t wc2 = src[i + 1];
            if (wc2 >= 0xDC00 && wc2 <= 0xDFFF)
            {
                uint32_t cp = (((wc - 0xD800) << 10) | (wc2 - 0xDC00)) + 0x10000;
                out.push_back(cp);
                i += 2;
                continue;
            }
        }
        out.push_back(static_cast<uint32_t>(wc));
        i++;
    }
    return out;
}

bool fontLoaded = false;

GdiFontReturn_t GdiFontManager::CreateFontTextureColor(GdiFontData_t data)
{
	Gdiplus::Status status;
	if (!fontLoaded) {
        
        wchar_t exePath[MAX_PATH];
        GetModuleFileNameW(nullptr, exePath, MAX_PATH);

        wchar_t* lastSlash = wcsrchr(exePath, L'\\');
        if (lastSlash)
            *lastSlash = 0;

        std::wstring fontPath = std::wstring(exePath) + L"\\../addons/fancychat/gdifonts/gameicons.ttf";
        status = g_fontCollection.AddFontFile(fontPath.c_str());
		
		if (status == Gdiplus::Ok) {
            
            int count = g_fontCollection.GetFamilyCount();
            if (count > 0)
            {
                Gdiplus::FontFamily families[1];
                int found = 0;
                g_fontCollection.GetFamilies(1, families, &found);
                if (found > 0)
                {
                    WCHAR familyName[LF_FACESIZE];
                    families[0].GetFamilyName(familyName);
                    g_customFont = new Gdiplus::FontFamily(familyName, &g_fontCollection);

                    fontLoaded = true;
                }
            }
		}
	}

    // One-shot init of the two system fallback fonts.  Separate latch
    // from `fontLoaded` above so that even if gameicons.ttf can't be
    // loaded (path issue), we still pay this cost exactly once instead
    // of every call.
    static bool s_sysFontsLoaded = false;
    if (!s_sysFontsLoaded)
    {
        g_emojiFont    = new Gdiplus::FontFamily(L"Segoe UI Emoji");
        g_symbolFont   = new Gdiplus::FontFamily(L"Segoe UI Symbol");
        s_sysFontsLoaded = true;
    }

    if (data.BoxHeight == 0)
        data.BoxHeight = m_CanvasHeight;
    if (data.BoxWidth == 0)
        data.BoxWidth = m_CanvasWidth;

    // Attempt to set up font family..  Cached by name: most calls use
    // the same chat font, so we skip the FontFamily ctor + heap alloc
    // on every call after the first for any given family.  Cache
    // entries are owned by g_familyCache and freed in the destructor;
    // do NOT delete pFontFamily at the end of the function.
    wchar_t wBuffer[4096];
    ::MultiByteToWideChar(CP_UTF8, 0, data.FontFamily, -1, wBuffer, 4096);
    Gdiplus::FontFamily* pFontFamily = nullptr;
    {
        auto it = g_familyCache.find(wBuffer);
        if (it != g_familyCache.end())
        {
            pFontFamily = it->second;
        }
        else
        {
            pFontFamily = new Gdiplus::FontFamily(wBuffer);
            if (pFontFamily->GetLastStatus() != Gdiplus::Ok)
            {
                delete pFontFamily;
                return GdiFontReturn_t();
            }
            g_familyCache.emplace(std::wstring(wBuffer), pFontFamily);
        }
    }

    // Loop-invariant within this call AND across calls: hoist out of
    // the per-codepoint inner loop below so we replace N virtual
    // IsAvailable() calls with one boolean read.
    const bool hasCustomFont = g_customFont && g_customFont->IsAvailable();

    // Convert text to wide string
    ::MultiByteToWideChar(CP_UTF8, 0, data.FontText, -1, wBuffer, 4096);
    auto length = wcslen(wBuffer);
    // Default-constructed StringFormat uses StringAlignmentNear (which
    // is what the previous per-call code explicitly set), so a single
    // process-wide instance is fine here.  C++11+ guarantees thread-
    // safe static init on first entry.
    static Gdiplus::StringFormat fontFormat;

    // Clear canvas before drawing
    this->ClearCanvas(data.BoxWidth, data.BoxHeight);

    // Parse runs with color changes
    std::vector<std::pair<Gdiplus::Color, std::wstring>> runs;
    Gdiplus::Color currentColor = UINT32_TO_COLOR(data.FontColor);
	Gdiplus::Color originalColor = currentColor; // Store the original color
 
    size_t i = 0;

    while (i < length)
    {
        //
        if (wBuffer[i] == L'\\' && i + 1 < length)
        {
            if (wBuffer[i + 1] == L'\u00A7' && i + 9 < length)
            {
            
                if (wBuffer[i + 10] == L'\u00E7' && wBuffer[i + 11] == L'\\')
                {
                    if (wBuffer[i + 2] == L'-')
                    {
						currentColor = originalColor; // Reset to original color
                        i += 12;
                        continue;
                    }
                    else
                    {
                        // Inline 2-char hex parse - replaces 4 std::wcstol
                        // calls per escape (each doing locale-aware string
                        // parsing on a tiny buffer) with a 4-character
                        // lookup.  Invalid digits return 0, matching the
                        // prior wcstol fallthrough behavior.
                        auto hex1 = [](wchar_t c) -> int {
                            if (c >= L'0' && c <= L'9') return c - L'0';
                            if (c >= L'a' && c <= L'f') return c - L'a' + 10;
                            if (c >= L'A' && c <= L'F') return c - L'A' + 10;
                            return 0;
                        };
                        // AA: alpha is taken from the global FontColor
                        // (the AA bytes in the escape are intentionally
                        // ignored - see the commented-out original code).
                        int a = (data.FontColor >> 24) & 0xFF;
                        int r = (hex1(wBuffer[i + 4]) << 4) | hex1(wBuffer[i + 5]);
                        int g = (hex1(wBuffer[i + 6]) << 4) | hex1(wBuffer[i + 7]);
                        int b = (hex1(wBuffer[i + 8]) << 4) | hex1(wBuffer[i + 9]);

                        currentColor = Gdiplus::Color(a, r, g, b);
                        i += 12;
                        continue;
                    }
                }
                
            }
        }
        // Start a new run
        size_t runStart = i;
        while (i < length)
        {
            if (wBuffer[i] == L'\\' && i + 1 < length &&
                (wBuffer[i + 1] == L'\u00A7'))
            {
                break;
            }
            i++;
        }
        if (runStart < i)
            runs.emplace_back(currentColor, std::wstring(&wBuffer[runStart], i - runStart));
    }

    // Compose the full path and draw/fill each run
    Gdiplus::Rect pathRect(0, 0, data.BoxWidth, data.BoxHeight);
    Gdiplus::Font baseFont(pFontFamily, data.FontHeight, data.FontFlags, Gdiplus::UnitPixel);

    

    // ------------------------------------------------------
    // Iterate through runs
    // ------------------------------------------------------
    int runCount = 0;
    float xOffset = 0.0f;
    float maxRight = 0.0f;
    int height = 0;
    int32_t width = 0;

    // Fallback fonts (emoji / symbol) are now process-wide singletons
    // initialized once at the top of the function - see g_emojiFont
    // and g_symbolFont.  Each is a single FontFamily allocation that
    // lives for the DLL's lifetime; the codepoint loop below reads
    // them directly instead of constructing a per-call instance.

    Gdiplus::RectF spaceBox;
    m_Graphics->MeasureString(L" ", 1, &baseFont, Gdiplus::PointF(0, 0), &spaceBox);
    float spaceWidth = spaceBox.Width;

    for (const auto& run : runs)
    {
        runCount++;
        const std::wstring& text = run.second;
        if (text.empty()) continue;

        // ------------------------------------------------------
        // Use text exactly as extracted  don't trim
        // ------------------------------------------------------
        const std::wstring& drawText = text;
        if (std::all_of(drawText.begin(), drawText.end(), [](wchar_t c) { return c == L' '; }))
        {
            xOffset += drawText.length() * spaceWidth * 1.58f;
            continue;
        }

        // ------------------------------------------------------
        // Origin and path
        // ------------------------------------------------------
        Gdiplus::PointF origin(static_cast<Gdiplus::REAL>(xOffset), 0.0f);
        Gdiplus::GraphicsPath* pPath = new Gdiplus::GraphicsPath();


        auto codepoints = Utf16ToUtf32(drawText.c_str());
        std::wstring bmpText;
        bmpText.reserve(drawText.size());

        float xAdvance = 0.0f;
        float arrow_offset = 0.0f;
        float space_offset = 0.0f;
        bool arrow_nextspace = false;

        for (size_t ci = 0; ci < codepoints.size(); ++ci)
        {
            uint32_t cp = codepoints[ci];

            if ((cp == 0x1F81E || cp == 0x1F81C))
            {
                arrow_offset = data.FontHeight * 0.1f;
            }
            
            if ((cp > 0xE000 && cp < 0xEF02) && hasCustomFont)
            {

                if (ci > 0 && codepoints[ci - 1] == 0x20)
                {
                    space_offset = spaceWidth;
                }

                // Flush any buffered text before the special glyph
                if (!bmpText.empty())
                {
                    Gdiplus::PointF pos(origin.X + xAdvance, origin.Y);
                    pPath->AddString(bmpText.c_str(), (INT)bmpText.length(),
                        pFontFamily, data.FontFlags, data.FontHeight,
                        pos, &fontFormat);

                    Gdiplus::RectF bounds;
                    m_Graphics->MeasureString(bmpText.c_str(), (INT)bmpText.length(),
                        &baseFont, pos, &bounds);
                    xAdvance += bounds.Width;
                    bmpText.clear();
                }

				xAdvance += space_offset;
                
                const wchar_t ch = static_cast<wchar_t>(cp);

                // Draw using your custom font
                Gdiplus::GraphicsPath glyphPath;
                Gdiplus::PointF pos(origin.X + xAdvance - (data.FontHeight * 0.1f), origin.Y + (data.FontHeight*0.12f));
                glyphPath.AddString(&ch, 1, g_customFont,
                    data.FontFlags, data.FontHeight-1,
                    pos, &fontFormat);

                // Add to main path
                pPath->AddPath(&glyphPath, FALSE);

                // Measure advance (so next glyph starts after this one)
                Gdiplus::RectF bounds;
                m_Graphics->MeasureString(&ch, 1, &baseFont, pos, &bounds);
                xAdvance += bounds.Width + space_offset - (data.FontHeight * 0.1f);

                continue; // Skip to next codepoint � don't process this one again
            }

            else
                if (cp < 0x10000)
            {
                bmpText.push_back(static_cast<wchar_t>(cp));
            }
            else
            {
                if (!bmpText.empty())
                {
					
                    Gdiplus::PointF pos(origin.X + xAdvance, origin.Y);
                    
                    pPath->AddString(bmpText.c_str(), static_cast<INT>(bmpText.length()), pFontFamily, data.FontFlags, data.FontHeight, pos, &fontFormat);
                    Gdiplus::RectF bounds;
                    m_Graphics->MeasureString(bmpText.c_str(), bmpText.length(), &baseFont, pos, &bounds);
                    xAdvance += bounds.Width;
                    bmpText.clear();
                }

                // Keep the original codepoint before subtracting 0x10000
                uint32_t cpOrig = codepoints[ci];

                wchar_t surrogate[3] = { 0 };
                uint32_t cpTmp = cpOrig - 0x10000;
                surrogate[0] = static_cast<wchar_t>(0xD800 + (cpTmp >> 10));
                surrogate[1] = static_cast<wchar_t>(0xDC00 + (cpTmp & 0x3FF));

				float emojioffset = 0.0f;
               
                if (ci == codepoints.size() - 1)
                {
					emojioffset = data.FontHeight * 0.15;
                }
				
                Gdiplus::PointF emojiPos(origin.X + xAdvance + arrow_offset - emojioffset, origin.Y);

				float_t newFontHeight = data.FontHeight -3;
                const Gdiplus::FontFamily* chosenFont = g_emojiFont;

                // Supplemental Arrows-C, Geometric Symbols, etc.
                if ((cp >= 0x1F780 && cp <= 0x1F8FF) ||     // arrows
                    (cp >= 0x1FA70 && cp <= 0x1FAFF) ||     // symbols extended
                    (cp >= 0x2300 && cp <= 0x23FF) ||       // technical symbols
                    (cp >= 0x2600 && cp <= 0x26FF) ||       // miscellaneous symbols
                    (cp >= 0x2700 && cp <= 0x27BF))         // dingbats
                {
                    chosenFont = g_symbolFont;
                    newFontHeight = data.FontHeight - 2;
                }

                // Build the emoji as its own path
                Gdiplus::GraphicsPath emojiPath;
                emojiPath.AddString(
                    surrogate,
                    2,
                    chosenFont,
                    data.FontFlags,
                    newFontHeight,
                    emojiPos,
                    &fontFormat
                );

                // Flip the dagger U+1F5E1 by transforming the path itself
                if (cpOrig == 0x1F5E1)
                {
                    Gdiplus::RectF eb;
                    // Use a simple pen to get accurate bounds (or your outline pen if you prefer)
                    Gdiplus::Pen tmpPen(Gdiplus::Color(255, 255, 255, 255), 1.0f);
                    emojiPath.GetBounds(&eb, nullptr, &tmpPen);

                    // Mirror around the glyph's center
                    const float cx = eb.X + eb.Width * 0.5f;
                    const float cy = eb.Y + eb.Height * 0.5f;

                    Gdiplus::Matrix m;
                    m.Translate(cx, cy);
                    m.Scale(-1.0f, -1.0f);   // flip X and Y; use (-1,1) for horizontal-only, (1,-1) for vertical-only
                    m.Translate(-cx, -cy);

                    emojiPath.Transform(&m);
                }

                // Add the emoji to your main run path
                pPath->AddPath(&emojiPath, FALSE);

                // Measure advance using the unflipped text (width doesn�t change with flip)
                Gdiplus::RectF emojiBounds;
                m_Graphics->MeasureString(surrogate, 2, &baseFont, emojiPos, &emojiBounds);
                xAdvance += emojiBounds.Width;
            }
        }

        if (!bmpText.empty())
        {
            Gdiplus::PointF pos(origin.X + xAdvance, origin.Y);
            pPath->AddString(bmpText.c_str(), static_cast<INT>(bmpText.length()), pFontFamily, data.FontFlags, data.FontHeight, pos, &fontFormat);
            Gdiplus::RectF bounds;
            m_Graphics->MeasureString(bmpText.c_str(), bmpText.length(), &baseFont, pos, &bounds);
            xAdvance += bounds.Width;
        }

        // Draw outline and fill
        Gdiplus::Pen* pen = nullptr;
        Gdiplus::RectF box{};
        if ((data.OutlineWidth > 0) && ((data.OutlineColor & 0xFF000000) != 0))
        {
            pen = new Gdiplus::Pen(UINT32_TO_COLOR(data.OutlineColor), static_cast<Gdiplus::REAL>(data.OutlineWidth));
            pPath->GetBounds(&box, nullptr, pen);
        }
        else
        {
            // Constant 1px white pen used only for path-bounds estimation
            // when there's no outline.  Same instance every call, every
            // run - life on the static (process-wide) once-init path.
            static const Gdiplus::Pen s_genericPen(Gdiplus::Color(255, 255, 255, 255), 1.0f);
            pPath->GetBounds(&box, nullptr, &s_genericPen);
        }

        if (pen)
        {
            m_Graphics->DrawPath(pen, pPath);
            delete pen;
        }

        Gdiplus::SolidBrush brush(run.first);
        m_Graphics->FillPath(&brush, pPath);

        // ------------------------------------------------------
        // Measure final run width and update layout bounds
        // ------------------------------------------------------
        Gdiplus::RectF runBounds;
        pPath->GetBounds(&runBounds);

        if (runBounds.Width > 0.0f)
        {
            float rightEdge = runBounds.GetRight();

            wchar_t lastChar = drawText.back();
            wchar_t nextFirst = 0;
            if (runCount < runs.size())
            {
                // Look ahead at the first glyph of the next run
                const std::wstring& nextText = runs[runCount].second;
                if (!nextText.empty())
                    nextFirst = nextText.front();
            }

            // If current run ends with >, remove empty pixels after it
            if (lastChar == 0x276E)
            {
                rightEdge -= data.FontHeight * 0.15f;
            }
            // If next run starts with <, also remove empty pixels before it
            else if (nextFirst == 0x276F)
            {
                rightEdge -= data.FontHeight * 0.15f;
            }
			else if (codepoints.back() == 0x20 && nextFirst == 0x276E)
			{
				rightEdge += data.FontHeight * 0.15f;
			}
           

            // Handle trailing spaces visually
            size_t trailingSpaces = 0;
			bool betweenascii = false;
            for (int j = static_cast<int>(drawText.size()) - 1; j >= 0; --j)
            {
                if (drawText[j] == L' ')
                    trailingSpaces++;
                else
                {
					if (drawText[j] <= 0x7F && nextFirst <= 0x7F)
					{
						betweenascii = true;
					}
                    break;
                }
            }
            float trailingSpacesWidth = trailingSpaces * spaceWidth * (betweenascii ? 1.35f : 1.0f);
            if (codepoints[0] == 0x276F && nextFirst == 0x20)
            {
                trailingSpacesWidth -= spaceWidth*0.30f;
            }
            if (lastChar == 0xECA4 && nextFirst == 0x20)
            {
                trailingSpacesWidth -= spaceWidth * 0.9f;
            }

            float adjustedRight = rightEdge + (trailingSpacesWidth)
                + space_offset +(arrow_offset > 0 && nextFirst == 0x20 ? -(arrow_offset*1.5) : 0.0f);
            maxRight = (std::max)(maxRight, adjustedRight);
            height = (std::max)(height, static_cast<int>(std::ceil(runBounds.GetBottom())));
            xOffset = adjustedRight;
        }

        delete pPath;

    }

    width = static_cast<int32_t>(std::ceil(maxRight + 1.0f));

    // pFontFamily intentionally NOT deleted - it lives in g_familyCache
    // and is owned by the cache (cleaned up in the destructor along
    // with the other process-wide singletons).

    int32_t firstPx = width - 1;
    int32_t lastPx = 0;
    uint32_t* px = (uint32_t*)this->m_Pixels;
    int maxHeight = height+1;
    for (auto y = 0; y < maxHeight; y++)
    {
        for (auto x = (width - 1); x >= lastPx; x--)
        {
            if (px[x])
            {
                height = y + 1;
                lastPx = x;
            }
        }

        for (auto x = 0; x < width; x++)
        {
            if (px[x])
            {
                height = y + 1;
                if (x < firstPx)
                {
                    firstPx = x;
                }
                break;
            }
        }

        px += this->m_CanvasWidth;
    }
    width = (lastPx - firstPx) + 1;

    // End early if width or height are 0..
    if ((width == 0) || (height == 0))
        return GdiFontReturn_t();
   

    // Attempt to create texture..
    IDirect3DTexture8* pTexture;
    if (FAILED(::D3DXCreateTexture(this->m_Device, width, height, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &pTexture)))
    {
        return GdiFontReturn_t();
    }
    D3DSURFACE_DESC surfaceDesc;
    if (FAILED(pTexture->GetLevelDesc(0, &surfaceDesc)))
    {
        if (pTexture != nullptr)
            pTexture->Release();

        return GdiFontReturn_t();
    }

    // Copy rendered font from bitmap to texture..
    D3DLOCKED_RECT rect{};
    auto copyStride = width * 4;
    pTexture->LockRect(0, &rect, 0, 0);
    {
        uint8_t* dest = (uint8_t*)rect.pBits;
        uint8_t* src = this->m_Pixels + (firstPx * 4);
        for (int x = 0; x < height; x++)
        {
            memcpy(dest, src, copyStride);
            dest += copyStride;
            src += this->m_CanvasStride;
        }
    }
    pTexture->UnlockRect(0);

    // Save physical file if requested
    if (m_SaveToHardDrive)
    {
        BITMAPV4HEADER bmp = { sizeof(BITMAPV4HEADER) };
        bmp.bV4Width = width;
        bmp.bV4Height = height;
        bmp.bV4Planes = 1;
        bmp.bV4BitCount = 32;
        bmp.bV4V4Compression = BI_BITFIELDS;
        bmp.bV4RedMask = 0x00FF0000;
        bmp.bV4GreenMask = 0x0000FF00;
        bmp.bV4BlueMask = 0x000000FF;
        bmp.bV4AlphaMask = 0xFF000000;

        uint8_t* pPixels = nullptr;
        HBITMAP pBmp = ::CreateDIBSection(nullptr, (BITMAPINFO*)&bmp, DIB_RGB_COLORS, (void**)&pPixels, nullptr, 0);
        Gdiplus::Bitmap* pRaw = new Gdiplus::Bitmap(width, height, width * 4, PixelFormat32bppARGB, (BYTE*)pPixels);

        uint8_t* src = this->m_Pixels + (firstPx * 4);
        for (int x = 0; x < height; x++)
        {
            memcpy(pPixels, src, copyStride);
            pPixels += copyStride;
            src += this->m_CanvasStride;
        }

        CLSID pngClsid;
        GetEncoderClsid(L"image/png", &pngClsid);
        auto index = 0;
        wchar_t nameBuffer[256];
        swprintf_s(nameBuffer, L"%S\\font_%u.png", m_SavePath, index);
        while (std::filesystem::exists(nameBuffer))
        {
            index++;
            swprintf_s(nameBuffer, L"%S\\font_%u.png", m_SavePath, index);
        }
        pRaw->Save(nameBuffer, &pngClsid, NULL);
        delete pRaw;
        DeleteObject(pBmp);
    }

	this->ClearCanvas(width, height);
    // Create return object..
    GdiFontReturn_t ret;
    ret.Width = width;
    ret.Height = height;
    ret.Texture = pTexture;
    return ret;
}
