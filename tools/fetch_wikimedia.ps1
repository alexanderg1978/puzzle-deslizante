# Descarga candidatos de dominio público de Wikimedia Commons, con pausas
# largas entre peticiones para respetar sus límites. Revisa a mano el resultado.
# Uso: powershell -File tools\fetch_wikimedia.ps1 -Out <carpeta>
param([string]$Out, [int]$PauseSeconds = 6)
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $Out | Out-Null
$ua = 'puzzle-deslizante/1.0 (hobby app; https://github.com/alexanderg1978/puzzle-deslizante)'
$queries = @(
 'Dürer Young Hare 1502', 'Rousseau Tiger in a Tropical Storm Surprised', 'Seurat A Sunday on La Grande Jatte',
 'Bruegel Hunters in the Snow', 'Vermeer The Milkmaid', 'Van Gogh Cafe Terrace at Night',
 'Van Gogh Almond blossom', 'Monet Woman with a Parasol', 'Klimt The Kiss', 'Waterhouse The Lady of Shalott',
 'Turner The Fighting Temeraire', 'Hiroshige Sudden shower over Shin-Ohashi bridge', 'Hokusai Red Fuji southern wind clear morning',
 'Van Eyck Arnolfini Portrait', 'Leonardo Lady with an Ermine', 'Rembrandt The Night Watch',
 'Cole The Oxbow', 'Homer The Gulf Stream', 'Monet Impression Sunrise', 'Van Gogh Bedroom in Arles',
 'Caravaggio Boy with a Basket of Fruit', 'Gauguin Tahitian Women on the Beach', 'Hiroshige Plum Park in Kameido',
 'Bierstadt Rocky Mountains Lander Peak', 'Millet The Gleaners', 'Degas The Ballet Class',
 'Magritte', 'Franz Marc Blue Horse', 'Stubbs Whistlejacket', 'Rousseau The Sleeping Gypsy',
 'Hokusai Kirifuri Waterfall', 'Van Gogh Wheatfield with Crows', 'Cezanne Still Life with Apples', 'Whistler Nocturne in Black and Gold'
)
function Md5Hex([string]$s) { ([System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-', '').ToLower() }
function Get-Retry([scriptblock]$f) {
  $wait = $PauseSeconds
  foreach ($i in 1..5) { try { return & $f } catch { Start-Sleep ($wait *= 2) } }
  throw 'agotados los reintentos'
}
$meta = @()
foreach ($q in $queries) {
  try {
    Start-Sleep $PauseSeconds
    $api = 'https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=1&gsrsearch=' + [uri]::EscapeDataString($q + ' filetype:bitmap') + '&prop=imageinfo&iiprop=url|size|extmetadata&iiextmetadatafilter=LicenseShortName|Artist|DateTimeOriginal|ObjectName'
    $r = Get-Retry { Invoke-RestMethod -UserAgent $ua -Uri $api }
    $p = $r.query.pages.PSObject.Properties.Value | Select-Object -First 1
    if (-not $p) { "$q -> sin resultado"; continue }
    $lic = $p.imageinfo[0].extmetadata.LicenseShortName.value
    if ($lic -notmatch 'Public domain|CC0|^PD') { "$q -> $($p.title) licencia $lic (descartada)"; continue }
    $name = ($p.title -replace '^File:', '') -replace ' ', '_'
    $h = Md5Hex $name
    $url = "https://upload.wikimedia.org/wikipedia/commons/thumb/$($h[0])/$($h[0])$($h[1])/$([uri]::EscapeDataString($name))/1280px-$([uri]::EscapeDataString($name))"
    if ($p.imageinfo[0].width -lt 1280) { $url = $p.imageinfo[0].url }
    $id = 'wm-' + (Md5Hex $name).Substring(0, 8)
    Start-Sleep $PauseSeconds
    Get-Retry { Invoke-WebRequest -UserAgent $ua -Uri $url -OutFile "$Out\$id.src" -UseBasicParsing -TimeoutSec 120 } | Out-Null
    $img = [System.Drawing.Image]::FromFile("$Out\$id.src")
    $side = [Math]::Min($img.Width, $img.Height)
    $bmp = New-Object System.Drawing.Bitmap 1024, 1024
    $g = [System.Drawing.Graphics]::FromImage($bmp); $g.InterpolationMode = 'HighQualityBicubic'
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0,0,1024,1024), (New-Object System.Drawing.Rectangle ([int](($img.Width-$side)/2)),([int](($img.Height-$side)/2)),$side,$side), 'Pixel')
    $g.Dispose(); $img.Dispose()
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | ? { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters 1
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]80)
    $bmp.Save("$Out\$id.jpg", $enc, $ep); $bmp.Dispose(); Remove-Item "$Out\$id.src"
    $meta += [pscustomobject]@{ id = $id; query = $q; file = $name; license = $lic }
    "$q -> $id ($name)"
  } catch { "$q -> ERROR $($_.Exception.Message)" }
}
$meta | ConvertTo-Json | Set-Content -Encoding utf8 "$Out\candidates.json"
'listo'
