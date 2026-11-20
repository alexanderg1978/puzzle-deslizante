#!/usr/bin/env python3
"""Descarga imágenes candidatas de dominio público para el catálogo.

Deja en la carpeta de salida un JPG cuadrado de 1024x1024 por imagen y un
`candidates.json` con sus datos. Nada entra al catálogo solo: revisa el
resultado a mano, copia los JPG elegidos a `catalog/images/` y añade su
entrada en `catalog/catalog.json`.

Uso:
  python3 tools/fetch_images.py wikimedia SALIDA "Vermeer The Milkmaid" "Klimt The Kiss"
  python3 tools/fetch_images.py met SALIDA cat ship "still life" --per-query 4

Requiere Pillow (`pip install pillow`).
"""

import argparse
import hashlib
import io
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

from PIL import Image

USER_AGENT = os.environ.get("FETCH_USER_AGENT", "catalog-fetcher/1.0 (hobby app)")
SIZE = 1024


def get(url, timeout=120, retries=4, pause=6):
    """GET con reintentos y espera creciente, para respetar los límites."""
    for attempt in range(retries):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.read()
        except (urllib.error.URLError, TimeoutError) as error:
            # Un 404 no mejora por reintentar.
            if getattr(error, "code", None) == 404 or attempt == retries - 1:
                raise
            time.sleep(pause * 2 ** (attempt + 1))


def get_json(url, **kwargs):
    return json.loads(get(url, **kwargs))


def save_square(data, path):
    """Recorta el centro a un cuadrado y lo guarda como JPG de 1024x1024."""
    image = Image.open(io.BytesIO(data)).convert("RGB")
    side = min(image.size)
    left, top = (image.width - side) // 2, (image.height - side) // 2
    image = image.crop((left, top, left + side, top + side))
    image.resize((SIZE, SIZE), Image.LANCZOS).save(path, "JPEG", quality=80)


def strip_html(text):
    return re.sub(r"<[^>]+>", "", text or "").strip()


def fetch_wikimedia(out, queries, pause):
    """Primer resultado de Wikimedia Commons por búsqueda, si su licencia es libre."""
    found = []
    for query in queries:
        try:
            time.sleep(pause)
            api = "https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
                "action": "query", "format": "json", "generator": "search",
                "gsrnamespace": 6, "gsrlimit": 1, "gsrsearch": query + " filetype:bitmap",
                "prop": "imageinfo", "iiprop": "url|size|extmetadata", "iiurlwidth": 1280,
                "iiextmetadatafilter": "LicenseShortName|Artist|DateTimeOriginal|ObjectName",
            })
            pages = get_json(api, pause=pause).get("query", {}).get("pages", {})
            if not pages:
                print(f"{query} -> sin resultado")
                continue
            page = next(iter(pages.values()))
            info = page["imageinfo"][0]
            meta = info.get("extmetadata", {})
            license_name = meta.get("LicenseShortName", {}).get("value", "")
            if not re.search(r"Public domain|CC0|^PD", license_name):
                print(f"{query} -> {page['title']} licencia {license_name or 'desconocida'} (descartada)")
                continue
            name = re.sub(r"^File:", "", page["title"]).replace(" ", "_")
            image_id = "wm-" + hashlib.md5(name.encode()).hexdigest()[:8]
            # Miniatura de 1280 px que genera Commons; el original si es menor.
            url = info.get("thumburl") if info.get("width", 0) >= 1280 else info["url"]
            time.sleep(pause)
            save_square(get(url or info["url"], pause=pause), os.path.join(out, image_id + ".jpg"))
            found.append({
                "id": image_id, "query": query, "file": name, "license": license_name,
                "artist": strip_html(meta.get("Artist", {}).get("value")),
                "date": strip_html(meta.get("DateTimeOriginal", {}).get("value")),
            })
            print(f"{query} -> {image_id} ({name})")
        except Exception as error:  # una búsqueda fallida no detiene las demás
            print(f"{query} -> ERROR {error}")
    return found


def fetch_met(out, queries, per_query):
    """Pinturas y grabados destacados del Met marcados como dominio público (CC0)."""
    found, seen = [], set()
    base = "https://collectionapi.metmuseum.org/public/collection/v1"
    for query in queries:
        count = 0
        try:
            # La búsqueda vive en v1.1 (la de v1 se retiró); los objetos, en v1.
            search = get_json(base + ".1/search?" + urllib.parse.urlencode({
                "hasImages": "true", "isPublicDomain": "true", "isHighlight": "true",
                "q": query, "limit": 40,
            }))
        except Exception as error:
            print(f"{query} -> ERROR {error}")
            continue
        for object_id in (search.get("objectIDs") or [])[:40]:
            if count >= per_query:
                break
            if object_id in seen:
                continue
            try:
                item = get_json(f"{base}/objects/{object_id}", retries=2)
                if not item.get("isPublicDomain") or not item.get("primaryImageSmall"):
                    continue
                if not re.search(r"Paintings|Prints", item.get("classification", "")):
                    continue
                seen.add(object_id)
                image_id = f"met-{object_id}"
                save_square(get(item["primaryImageSmall"], timeout=60), os.path.join(out, image_id + ".jpg"))
            except Exception:
                continue
            found.append({
                "id": image_id, "query": query, "title": item.get("title"),
                "artist": item.get("artistDisplayName"), "date": item.get("objectDate"),
            })
            count += 1
        print(f"{query} -> {count}")
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sources = parser.add_subparsers(dest="source", required=True)
    wikimedia = sources.add_parser("wikimedia", help="Wikimedia Commons: una imagen por búsqueda")
    wikimedia.add_argument("out")
    wikimedia.add_argument("queries", nargs="+", help='p. ej. "Vermeer The Milkmaid"')
    wikimedia.add_argument("--pause", type=int, default=6, help="segundos entre peticiones")
    met = sources.add_parser("met", help="The Met: varias imágenes por tema")
    met.add_argument("out")
    met.add_argument("queries", nargs="+", help="temas en inglés, p. ej. cat ship")
    met.add_argument("--per-query", type=int, default=8)
    args = parser.parse_args()

    os.makedirs(args.out, exist_ok=True)
    if args.source == "wikimedia":
        found = fetch_wikimedia(args.out, args.queries, args.pause)
    else:
        found = fetch_met(args.out, args.queries, args.per_query)
    with open(os.path.join(args.out, "candidates.json"), "w", encoding="utf-8") as file:
        json.dump(found, file, ensure_ascii=False, indent=2)
    print(f"listo: {len(found)} imágenes en {args.out}")
    return 0 if found else 1


if __name__ == "__main__":
    sys.exit(main())
