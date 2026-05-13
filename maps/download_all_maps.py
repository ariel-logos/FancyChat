"""
Bulk-download FFXIclopedia zone maps for every zone in boussole's zones.lua.

Layout produced under maps/:
    <Zone_Name>/Maps/                  base zone maps
    <Zone_Name>/Fishing/               fishing maps
    <Zone_Name>/Weather/               elemental spawn maps
    <Zone_Name>/Treasure/       coffer drop-zone maps
    <Zone_Name>/Notorious_Monsters/    per-NM spawn maps

Zones that have no recognisable maps on the wiki get an empty Maps/ folder.
"""
import os, re, sys, json, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
try:
    from PIL import Image
    PIL_OK = True
except ImportError:
    PIL_OK = False

ROOT = Path(__file__).parent  # /addons/fancychat/maps/ relative to this script
ZONES_FILE = ROOT / "zones_en.txt"
API = "https://ffxiclopedia.fandom.com/api.php"

S = requests.Session()
S.headers["User-Agent"] = "Mozilla/5.0 (FancyChat-MapDownloader)"

# ---------------------------------------------------------------------------
# Classification: given a filename and the zone we're processing, decide which
# "section" subfolder the file belongs in (or None to skip).
# ---------------------------------------------------------------------------

def normalize(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())

# Generic decoration images that appear on most zone pages and are NOT maps.
# These are filtered out before zone-name matching even runs.
DECORATION = {normalize(x) for x in [
    "information", "warning", "rare", "exclusive", "unknown", "rareexclusive",
    "escapeicon", "tractoricon", "adventuringfellowicon",
    "translightning", "transwater", "transfire", "transwind",
    "transearth", "transice", "translight", "transdark",
    "ffxihby08", "ffxigld01",
    "check", "exclamation", "keyitem", "augmented",
]}


def zone_variants(zone: str) -> set:
    """Normalised string forms a filename's zone-prefix might take."""
    out = {normalize(zone)}
    # [S] / (S) Campaign zone forms are interchangeable across wiki pages.
    if "[S]" in zone:
        out.add(normalize(zone.replace("[S]", "(S)")))
        out.add(normalize(zone.replace("[S]", "")))
    if "(S)" in zone:
        out.add(normalize(zone.replace("(S)", "[S]")))
        out.add(normalize(zone.replace("(S)", "")))
    if zone.lower().startswith("the "):
        out.add(normalize(zone[4:]))
    else:
        out.add(normalize("the " + zone))
    return {v for v in out if v}


def classify(filename: str, zone: str):
    stem, ext = os.path.splitext(filename)
    ext_lower = ext.lower()
    if ext_lower not in (".png", ".gif", ".jpg", ".jpeg"):
        return None
    norm = normalize(stem)
    if not norm or norm in DECORATION:
        return None

    # Banner / preview pictures: <zone>-pic.jpg, <zone>pic.png, etc.
    if norm.endswith("pic") or norm.endswith("picture"):
        return None

    variants = zone_variants(zone)
    matched_pos = None
    for v in variants:
        idx = norm.find(v)
        # Tolerate up to 3 leading characters (e.g. "the" prefix slipping past
        # the variant stripping on some weird filenames).
        if 0 <= idx <= 3:
            matched_pos = idx + len(v)
            break
    if matched_pos is None:
        # Numeric-named maps: Abyssea zones use 5-digit in-game map IDs as
        # filenames (03230.png ... 03244.png) instead of zone-prefixed names.
        # 4-6 digits is the safe range; 1-3 would catch too many decorations.
        if re.fullmatch(r"\d{4,6}", norm) and ext_lower == ".png":
            return "Maps"
        return None

    suffix = norm[matched_pos:]
    fl = filename.lower()

    # NM: every variant the wiki uses — `_NM`, `_NM_<n>`, the plural
    # `NMs`, and the plural with a digit.  The single regex matches a
    # suffix that ends in `nm` or `nms` followed by optional digits.
    if (re.search(r"nms?\d*$", suffix)
            or re.search(r"_nm(\b|_|\d|\.)", fl)):
        return "Notorious_Monsters"
    if "fish" in suffix:
        return "Fishing"
    if "element" in suffix:
        return "Weather"
    # Treasure-spawn maps come down under three different words depending
    # on the zone: `Coffers*` (artifact-armor coffer drops), `Chests*`
    # (treasure-chest drops), or just `Treasure*`.  All three belong in
    # the same section.
    if "coffer" in suffix or "chest" in suffix or "treasure" in suffix:
        return "Treasure"

    # Suffix is just digits / hyphen / underscore -> base zone map.
    if re.fullmatch(r"[-_]?\d*", suffix.replace("-", "")) or re.fullmatch(r"\d*", suffix):
        return "Maps"

    # Has other text (e.g. "Aqueducts", "Tower", named subarea); still a map
    # but bucket it under Maps for now.
    return "Maps"


def folder_safe(zone: str) -> str:
    # Windows-safe folder name. Apostrophes are legal; `/` is not.
    return zone.replace("/", "_")


def chunked(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


# ---------------------------------------------------------------------------
# Wiki API helpers
# ---------------------------------------------------------------------------

def to_wiki_title(zone: str) -> str:
    """Translate a boussole-style zone name into the title FFXIclopedia uses."""
    # Campaign-era zones: boussole writes "Foo [S]", the wiki uses "Foo (S)".
    if "[S]" in zone:
        return zone.replace("[S]", "(S)")
    return zone


def fetch_zone_images(zones):
    """For a batch of zones, return {zone: {section: [filenames]}}.
    Zones missing from the wiki get an empty dict."""
    # Map wiki-side title -> boussole zone name so we can route the response
    # back to the original key the caller knows about.
    wiki_titles = {to_wiki_title(z): z for z in zones}
    titles = "|".join(wiki_titles.keys())
    r = S.get(API, params={
        "action": "query", "prop": "images", "imlimit": "500",
        "titles": titles, "format": "json", "redirects": 1,
    }, timeout=60)
    r.raise_for_status()
    data = r.json()

    pages = data.get("query", {}).get("pages", {})
    redirects = {x["from"]: x["to"] for x in data.get("query", {}).get("redirects", [])}
    normalized = {x["from"]: x["to"] for x in data.get("query", {}).get("normalized", [])}

    title_to_zone = {}
    for wt, z in wiki_titles.items():
        t = normalized.get(wt, wt)
        t = redirects.get(t, t)
        title_to_zone[t] = z

    result = {z: {} for z in zones}
    for page in pages.values():
        title = page.get("title", "")
        zone = title_to_zone.get(title)
        if zone is None or "missing" in page:
            continue
        for img in page.get("images", []):
            filename = img["title"].replace("File:", "").replace(" ", "_")
            section = classify(filename, zone)
            if section:
                result[zone].setdefault(section, []).append(filename)
    return result


NM_TEMPLATE_RE = re.compile(r"\{\{Tooltip-NMMap\s*\|([^}]+)\}\}", re.IGNORECASE)


def fetch_wikitext(zone: str):
    """Fetch the raw wikitext for a single zone page via action=parse.
    Returns the wikitext string or None if the page is missing/errored."""
    r = S.get(API, params={
        "action": "parse", "page": to_wiki_title(zone), "prop": "wikitext",
        "format": "json", "redirects": 1,
    }, timeout=60)
    if r.status_code != 200:
        return None
    data = r.json()
    if "error" in data:
        return None
    return data.get("parse", {}).get("wikitext", {}).get("*")


def parse_nm_index(wikitext: str):
    """Pull {{Tooltip-NMMap|map=…|NM=…}} entries out of zone wikitext.
    Returns {filename_with_underscores: [NM names in insertion order]}.
    Filenames are normalised so they match the on-disk layout."""
    out = {}
    if not wikitext:
        return out
    for args in NM_TEMPLATE_RE.findall(wikitext):
        kv = {}
        for part in args.split("|"):
            if "=" not in part:
                continue
            k, v = part.split("=", 1)
            kv[k.strip().lower()] = v.strip()
        m, nm = kv.get("map", ""), kv.get("nm", "")
        if not m or not nm:
            continue
        m = m.replace(" ", "_")
        lst = out.setdefault(m, [])
        if nm not in lst:                                # dedupe, keep order
            lst.append(nm)
    return out


def lua_quote(s: str) -> str:
    """Render s as a Lua double-quoted string literal, escaping the
    characters Lua's tokenizer cares about."""
    return ('"'
            + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
            + '"')


def write_nm_index(zone: str, nm_index) -> bool:
    """Emit maps/<zone>/Notorious_Monsters/_nm_index.lua.  Skips zones
    whose Notorious_Monsters/ folder doesn't exist on disk (i.e. zones
    we never downloaded NM maps for)."""
    if not nm_index:
        return False
    folder = ROOT / folder_safe(zone) / "Notorious_Monsters"
    if not folder.exists():
        return False
    path = folder / "_nm_index.lua"
    with open(path, "w", encoding="utf-8") as f:
        f.write("-- Auto-generated by maps/download_all_maps.py.\n")
        f.write("-- Map filename -> list of Notorious Monsters using it.\n")
        f.write("-- Hand-edit to fix wiki typos (e.g. Leshonki / Voluptuous Vivian).\n")
        f.write("return {\n")
        for fname in sorted(nm_index):
            nms = ", ".join(lua_quote(n) for n in nm_index[fname])
            f.write(f"    [{lua_quote(fname)}] = {{ {nms} }},\n")
        f.write("}\n")
    return True


def fetch_image_urls(filenames):
    """Return {filename: (url_with_format_original, width, height)}.
    Width/height let the caller drop tiny item-icons from the queue."""
    titles = "|".join("File:" + f for f in filenames)
    r = S.get(API, params={
        "action": "query", "prop": "imageinfo", "iiprop": "url|size",
        "titles": titles, "format": "json",
    }, timeout=60)
    r.raise_for_status()
    data = r.json()
    out = {}
    for page in data.get("query", {}).get("pages", {}).values():
        title = page.get("title", "")
        fn = title.replace("File:", "").replace(" ", "_")
        info = page.get("imageinfo")
        if info:
            ii = info[0]
            url = ii["url"]
            url += ("&" if "?" in url else "?") + "format=original"
            out[fn] = (url, ii.get("width", 0), ii.get("height", 0))
    return out


# ---------------------------------------------------------------------------
# Downloader
# ---------------------------------------------------------------------------

def download_one(url: str, dest: Path):
    try:
        with S.get(url, timeout=120, stream=True) as r:
            r.raise_for_status()
            dest.parent.mkdir(parents=True, exist_ok=True)
            with open(dest, "wb") as f:
                for c in r.iter_content(64 * 1024):
                    f.write(c)
        with open(dest, "rb") as f:
            magic = f.read(4)
        ok = magic[:4] in (b"\x89PNG", b"GIF8") or magic[:3] == b"\xff\xd8\xff"
        return (dest, ok, dest.stat().st_size if ok else f"bad magic {magic.hex()}")
    except Exception as e:
        return (dest, False, str(e))


def main():
    zones = [l.strip() for l in ZONES_FILE.read_text().splitlines() if l.strip()]
    print(f"[1/4] Loaded {len(zones)} zones")

    # ---- query images per zone in small batches -------------------------
    # imlimit caps the TOTAL image count returned across all pages in one
    # query (Fandom's docs say it's per-page but the practical behaviour is
    # global).  20 zones * up to ~25 images each = under the 500 cap.
    zone_images = {}
    for i, batch in enumerate(chunked(zones, 20)):
        try:
            res = fetch_zone_images(batch)
            zone_images.update(res)
        except Exception as e:
            print(f"   batch {i} ERROR: {e}")
        time.sleep(0.2)
    have_maps = sum(1 for v in zone_images.values() if v)
    print(f"[2/4] Image lists fetched: {len(zone_images)} zones, {have_maps} with maps")

    # ---- resolve all unique filenames to CDN URLs -----------------------
    all_files = sorted({fn for sects in zone_images.values() for files in sects.values() for fn in files})
    print(f"[3/4] {len(all_files)} unique image files; resolving URLs...")
    file_urls = {}
    for batch in chunked(all_files, 50):
        try:
            file_urls.update(fetch_image_urls(batch))
        except Exception as e:
            print(f"   url batch ERROR: {e}")
        time.sleep(0.3)
    print(f"      Resolved {len(file_urls)}/{len(all_files)} URLs")

    # ---- create folders + queue downloads -------------------------------
    # Map images on FFXIclopedia are virtually all 512x512 (some 1024x1024
    # for newer zones).  Reject anything that's:
    #   * smaller than 256 px on either side (item-drop / NPC-portrait
    #     icons that pollute zone pages — 32x32 .. 64x64);
    #   * aspect ratio more than 1.2 or less than 0.83 (real maps are
    #     square or close to it; widescreen 16:9 / 16:10 images are
    #     in-game screenshots posing as zone "maps" on the wiki);
    #   * filename containing "interior", "cover", or a "ship"-suffix
    #     pattern (named-as-screenshot uploads — e.g.
    #     `Manaclippership.jpg`, `Castle_Oztroja_S_cover.jpg`,
    #     `Silver_Knife_interior.jpg`).  No actual zone has any of
    #     these substrings in its name, so the keyword filter is safe.
    MIN_DIM       = 256
    AR_HI, AR_LO  = 1.2, 0.83
    NAME_KEYS     = ("interior", "cover")
    def is_screenshot_name(stem):
        s = stem.lower()
        if any(k in s for k in NAME_KEYS):
            return True
        return (s.endswith("ship") or "_ship" in s or "-ship" in s
                or "ship_" in s or "ship-" in s)
    download_tasks = []
    skipped_small, skipped_aspect, skipped_name = 0, 0, 0
    for zone in zones:
        sects = zone_images.get(zone, {})
        zfolder = ROOT / folder_safe(zone)
        # Filter out tiny non-map images per section.
        filtered = {}
        for section, files in sects.items():
            keep = []
            for fn in files:
                meta = file_urls.get(fn)
                if not meta:
                    continue
                url, w, h = meta
                if w and h and (w < MIN_DIM or h < MIN_DIM):
                    skipped_small += 1
                    continue
                if w and h:
                    ar = w / h
                    if ar > AR_HI or ar < AR_LO:
                        skipped_aspect += 1
                        continue
                stem = fn.rsplit(".", 1)[0]
                if is_screenshot_name(stem):
                    skipped_name += 1
                    continue
                keep.append((fn, url))
            if keep:
                filtered[section] = keep
        if not filtered:
            (zfolder / "Maps").mkdir(parents=True, exist_ok=True)
            continue
        for section, items in filtered.items():
            (zfolder / section).mkdir(parents=True, exist_ok=True)
            for fn, url in items:
                dest = zfolder / section / fn
                if dest.exists() and dest.stat().st_size > 0:
                    continue
                download_tasks.append((url, dest))
    print(f"      Filtered out {skipped_small} files smaller than {MIN_DIM}px,"
          f" {skipped_aspect} non-square (aspect outside {AR_LO}..{AR_HI}),"
          f" {skipped_name} screenshot-named")

    print(f"[4/4] Download queue: {len(download_tasks)} files")
    ok = fail = 0
    failures = []
    with ThreadPoolExecutor(max_workers=12) as ex:
        futs = [ex.submit(download_one, u, d) for u, d in download_tasks]
        for i, fut in enumerate(as_completed(futs)):
            dest, success, info = fut.result()
            if success:
                ok += 1
            else:
                fail += 1
                failures.append((str(dest), info))
            if (i + 1) % 200 == 0:
                print(f"      ...{i+1}/{len(download_tasks)}  ok={ok} fail={fail}")
    print(f"\nDONE  ok={ok}  fail={fail}")
    if failures:
        rep = ROOT / "_download_failures.txt"
        with open(rep, "w", encoding="utf-8") as f:
            for d, e in failures:
                f.write(f"{d}\t{e}\n")
        print(f"Failures logged to {rep}")

    # ---- Step 4b: GIF -> PNG conversion ---------------------------------
    # FFXI's DX8 build of D3DXCreateTextureFromFileInMemoryEx is unreliable
    # with palette-mode GIFs (it fails the palette -> A8R8G8B8 conversion).
    # All Fishing-section maps and a few stragglers come down as palette
    # GIFs from the wiki.  Convert each to RGBA PNG in place so the addon
    # can load them through the same texture path it uses for everything
    # else.  Lossless; the rendered map is identical.
    if PIL_OK:
        gifs = list(ROOT.rglob("*.gif"))
        if gifs:
            print(f"\n[4b] Converting {len(gifs)} GIF map(s) to PNG...")
            cv_ok, cv_fail = 0, 0
            for gif in gifs:
                png = gif.with_suffix(".png")
                try:
                    with Image.open(gif) as im:
                        im.convert("RGBA").save(png, format="PNG", optimize=True)
                    gif.unlink()
                    cv_ok += 1
                except Exception as e:
                    cv_fail += 1
                    print(f"     FAIL {gif}: {e}")
                    if png.exists():
                        png.unlink()
            print(f"     converted {cv_ok}/{len(gifs)}")
    else:
        print("\n[4b] Pillow not installed; skipping GIF->PNG conversion.")
        print("     `pip install pillow` if you want palette GIFs auto-converted.")

    # ---- Step 4c: PNG -> JPEG recompression (real-alpha only kept) -----
    # Cartographic content compresses extremely well as JPEG.  q88 is
    # visually indistinguishable from the wiki source PNGs at typical
    # viewing scale while ~50% smaller on disk.  RGBA-mode PNGs whose
    # alpha channel is in fact all-255 (very common on the wiki) get
    # the same treatment - "phantom alpha" doesn't need PNG.  Real-
    # alpha files (5 known overlays) stay as PNG.
    def _has_real_alpha(im):
        if im.mode in ('RGBA', 'LA'):
            return im.getchannel('A').getextrema()[0] < 255
        if im.mode == 'P' and 'transparency' in im.info:
            return im.convert('RGBA').getchannel('A').getextrema()[0] < 255
        return False

    if PIL_OK:
        pngs = list(ROOT.rglob("*.png"))
        if pngs:
            print(f"\n[4c] Recompressing {len(pngs)} PNG map(s) to JPEG q88 (real-alpha kept)...")
            cv_ok, cv_skip, cv_fail = 0, 0, 0
            for png in pngs:
                try:
                    with Image.open(png) as im:
                        if _has_real_alpha(im):
                            cv_skip += 1
                            continue
                        jpg = png.with_suffix(".jpg")
                        if jpg.exists() and jpg != png:
                            # Existing .jpg with same stem (wiki-original
                            # JPG that lives next to a same-name PNG, or
                            # a leftover from a prior run).  Skip to
                            # avoid clobbering.
                            cv_skip += 1
                            continue
                        im.convert("RGB").save(jpg, format="JPEG",
                                               quality=88, optimize=True,
                                               progressive=False)
                    png.unlink()
                    cv_ok += 1
                except Exception as e:
                    cv_fail += 1
                    print(f"     FAIL {png}: {e}")
            print(f"     converted {cv_ok}/{len(pngs)} (real-alpha kept: {cv_skip}, fail: {cv_fail})")
    else:
        print("\n[4c] Pillow not installed; skipping PNG->JPEG recompression.")

    # ---- Step 4d: lossless mozjpeg pass on every JPEG ------------------
    try:
        import mozjpeg_lossless_optimization
        jpgs = list(ROOT.rglob("*.jpg"))
        if jpgs:
            print(f"\n[4d] Running mozjpeg lossless pass on {len(jpgs)} JPEG(s)...")
            ok = 0
            for jp in jpgs:
                try:
                    with open(jp, 'rb') as f:
                        d = f.read()
                    opt = mozjpeg_lossless_optimization.optimize(d)
                    if len(opt) < len(d):
                        with open(jp, 'wb') as f:
                            f.write(opt)
                        ok += 1
                except Exception:
                    pass
            print(f"     shrunk {ok}/{len(jpgs)}")
    except ImportError:
        print("\n[4d] mozjpeg-lossless-optimization not installed; skipping.")
        print("     `pip install mozjpeg-lossless-optimization` for the extra trim.")

    # ---- Step 5: NM-index manifests ------------------------------------
    # For every zone whose Notorious_Monsters/ folder exists on disk,
    # parse the page's wikitext for {{Tooltip-NMMap|map=…|NM=…}} entries
    # and write a sidecar _nm_index.lua so the addon can label each map
    # by NM name instead of raw filename.
    print("\n[5/5] Generating _nm_index.lua manifests...")
    zones_with_nm = [z for z in zones
                     if (ROOT / folder_safe(z) / "Notorious_Monsters").exists()]
    print(f"      zones with Notorious_Monsters/: {len(zones_with_nm)}")
    written, total_pairs = 0, 0
    for z in zones_with_nm:
        try:
            wt = fetch_wikitext(z)
        except Exception as e:
            print(f"      [{z}] fetch error: {e}")
            continue
        idx = parse_nm_index(wt or "")
        if write_nm_index(z, idx):
            written += 1
            total_pairs += sum(len(v) for v in idx.values())
        time.sleep(0.1)                                  # be polite to the API
    print(f"      wrote {written} _nm_index.lua files,"
          f" {total_pairs} (file, NM) pairs total")

    # Summary report
    rep = ROOT / "_summary.txt"
    with open(rep, "w", encoding="utf-8") as f:
        f.write(f"Total zones        : {len(zones)}\n")
        f.write(f"Zones with maps    : {have_maps}\n")
        f.write(f"Zones empty (Maps/): {len(zones) - have_maps}\n")
        f.write(f"Files attempted    : {len(download_tasks)}\n")
        f.write(f"Downloaded ok      : {ok}\n")
        f.write(f"Failed             : {fail}\n\n")
        for zone in zones:
            sects = zone_images.get(zone, {})
            n = sum(len(v) for v in sects.values())
            f.write(f"{zone}\t{n}\t{','.join(sorted(sects.keys()))}\n")
    print(f"Summary in {rep}")


if __name__ == "__main__":
    main()
