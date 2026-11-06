# Descarga candidatos de dominio público (CC0) del Met a una carpeta para revisarlos.
# Uso: powershell -File tools\fetch_candidates.ps1 -Out <carpeta>
param([string]$Out, [int]$PerQuery = 8)
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $Out | Out-Null
$ua = 'puzzle-deslizante/1.0 (hobby app)'
$queries = 'cat','dog','horse','bird','flowers','tiger','ship','fish','mountain','garden','sea','tree','sunset','city','fruit','winter','boat','lion','peacock','butterfly','bridge','river','farm','portrait of a woman','still life'
$meta = @()
$seen = @{}
foreach ($q in $queries) {
  $s = Invoke-RestMethod -UserAgent $ua -Uri "https://collectionapi.metmuseum.org/public/collection/v1.1/search?hasImages=true&isPublicDomain=true&isHighlight=true&q=$([uri]::EscapeDataString($q))&limit=40"
  $n = 0
  foreach ($id in $s.objectIDs) {
    if ($n -ge $PerQuery) { break }
    if ($seen.ContainsKey($id)) { continue }
    try { $o = Invoke-RestMethod -UserAgent $ua -Uri "https://collectionapi.metmuseum.org/public/collection/v1/objects/$id" } catch { continue }
    if (-not $o.isPublicDomain -or -not $o.primaryImageSmall) { continue }
    if ($o.classification -notmatch 'Paintings|Prints') { continue }
    $seen[$id] = 1
    try { Invoke-WebRequest -UserAgent $ua -Uri $o.primaryImageSmall -OutFile "$Out\$id.src" -UseBasicParsing -TimeoutSec 60 } catch { continue }
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
    $meta += [pscustomobject]@{ id = $id; query = $q; title = $o.title; artist = $o.artistDisplayName; date = $o.objectDate }
    $n++
  }
  "$q -> $n"
}
$meta | ConvertTo-Json | Set-Content -Encoding utf8 "$Out\candidates.json"
