<#
.SYNOPSIS
  Gera a lista demo do FireIPTV (M3U + EPG XMLTV + wrappers HLS dos filmes) em ./docs.

.DESCRIPTION
  Fonte de teste para a certificação da Microsoft Store (política 10.3.3 "App Is Testable"):
  só streams de teste públicos e filmes abertos da Blender Foundation (CC BY), nada de canal
  de terceiro sem direito de distribuição.

  O EPG é gerado relativo à data de HOJE (de ontem até +DaysAhead). Grade estática envelhece e o
  testador veria "sem programação" — por isso o workflow do GitHub roda este script toda semana.

  Compatível com Windows PowerShell 5.1 e pwsh 7 (o runner Linux do GitHub usa pwsh).

.PARAMETER BaseUrl
  URL pública onde ./docs é servido (GitHub Pages), sem barra no fim.
#>
param(
    [string]$BaseUrl = 'https://igorpaixaodev.github.io/fireiptv-demo',
    [int]$DaysAhead = 30
)

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'docs'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-Text([string]$path, [string]$text) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $text.Replace("`r`n", "`n"), $utf8)
}

function Esc([string]$s) { [System.Security.SecurityElement]::Escape($s) }

# ---------------------------------------------------------------------------------------------
# Catálogo
# O FireIPTV classifica entradas M3U pela forma da URL/nome (M3uContentSource.Classify):
#   - URL com "/movie/"      -> Filme   (por isso os filmes passam por um wrapper HLS em /movie/)
#   - nome com SxxEyy        -> Série
#   - o resto                -> Ao vivo
# ---------------------------------------------------------------------------------------------

# Canais ao vivo apontam para a playlist de MIDIA (um variant TS com audio junto), nao para o
# master: o Live Clock pelo master (renditions de audio separadas + variants so de audio + I-frame)
# derrubou o FFmpegInteropX com access violation. So o formato simples e comprovado entra aqui.
$live = @(
    @{ Id = 'demo.live.clock';   Name = 'Live Clock 24/7';      Group = 'Live - Test Channels'
       Url = 'https://demo.unified-streaming.com/k8s/live/stable/live.isml/live-audio_eng=128000-video=1000000.m3u8' }
    @{ Id = 'demo.live.scifi';   Name = 'Sci-Fi Shorts';        Group = 'Live - Open Movies'
       Url = 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/tears-of-steel-audio_eng=128002-video_eng=1501000.m3u8' }
    @{ Id = 'demo.live.bbb';     Name = 'Open Movies Channel';  Group = 'Live - Open Movies'
       Url = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8' }
)

# Variants com URI ABSOLUTA: o wrapper mora no Pages (para ter "/movie/" no caminho) e aponta
# para os segmentos na origem. Mesmos CODECS/RESOLUTION dos masters originais.
$movies = @(
    @{ Id = 'demo.movie.bbb'; Slug = 'big-buck-bunny'; Name = 'Big Buck Bunny (2008)'; Group = 'Open Movies'
       Variants = @(
         @{ Inf = 'BANDWIDTH=836280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=848x480'
            Uri = 'https://test-streams.mux.dev/x36xhzz/url_6/193039199_mp4_h264_aac_hq_7.m3u8' }
         @{ Inf = 'BANDWIDTH=2149280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=1280x720'
            Uri = 'https://test-streams.mux.dev/x36xhzz/url_0/193039199_mp4_h264_aac_hd_7.m3u8' }
         @{ Inf = 'BANDWIDTH=6221600,CODECS="mp4a.40.2,avc1.640028",RESOLUTION=1920x1080'
            Uri = 'https://test-streams.mux.dev/x36xhzz/url_8/193039199_mp4_h264_aac_fhd_7.m3u8' }
       ) }
    @{ Id = 'demo.movie.tos'; Slug = 'tears-of-steel'; Name = 'Tears of Steel (2012)'; Group = 'Open Movies'
       Variants = @(
         @{ Inf = 'BANDWIDTH=932000,CODECS="mp4a.40.2,avc1.66.30",RESOLUTION=448x200'
            Uri = 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/tears-of-steel-audio_eng=128002-video_eng=751000.m3u8' }
         @{ Inf = 'BANDWIDTH=1727000,CODECS="mp4a.40.2,avc1.100.40",RESOLUTION=1680x750'
            Uri = 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/tears-of-steel-audio_eng=128002-video_eng=1501000.m3u8' }
         @{ Inf = 'BANDWIDTH=2468000,CODECS="mp4a.40.2,avc1.100.40",RESOLUTION=1680x750'
            Uri = 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/tears-of-steel-audio_eng=128002-video_eng=2200000.m3u8' }
       ) }
)

# Episódios apontam direto para a origem: o SxxEyy do nome já basta para virar série.
$episodes = @(
    @{ Id = 'demo.ep.s01e01'; Name = 'Open Movie Shorts S01E01 - Big Buck Bunny'
       Url = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8' }
    @{ Id = 'demo.ep.s01e02'; Name = 'Open Movie Shorts S01E02 - Tears of Steel'
       Url = 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/tears-of-steel-audio_eng=128002-video_eng=1501000.m3u8' }
    @{ Id = 'demo.ep.s01e03'; Name = 'Open Movie Shorts S01E03 - Elephants Dream'
       Url = 'https://download.blender.org/ED/elephantsdream-480-h264-st-aac.mov' }
)

# ---------------------------------------------------------------------------------------------
# 1. Wrappers HLS dos filmes
# ---------------------------------------------------------------------------------------------
foreach ($m in $movies) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('#EXTM3U')
    [void]$sb.AppendLine('#EXT-X-VERSION:3')
    foreach ($v in $m.Variants) {
        [void]$sb.AppendLine("#EXT-X-STREAM-INF:$($v.Inf)")
        [void]$sb.AppendLine($v.Uri)
    }
    Write-Text (Join-Path $root "movie/$($m.Slug).m3u8") $sb.ToString()
}

# ---------------------------------------------------------------------------------------------
# 2. Playlist M3U
# ---------------------------------------------------------------------------------------------
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("#EXTM3U x-tvg-url=`"$BaseUrl/epg.xml`"")
foreach ($c in $live) {
    [void]$sb.AppendLine("#EXTINF:-1 tvg-id=`"$($c.Id)`" tvg-name=`"$($c.Name)`" tvg-logo=`"$BaseUrl/img/$($c.Id).png`" group-title=`"$($c.Group)`",$($c.Name)")
    [void]$sb.AppendLine($c.Url)
}
foreach ($m in $movies) {
    [void]$sb.AppendLine("#EXTINF:-1 tvg-id=`"$($m.Id)`" tvg-name=`"$($m.Name)`" tvg-logo=`"$BaseUrl/img/$($m.Id).png`" group-title=`"$($m.Group)`",$($m.Name)")
    [void]$sb.AppendLine("$BaseUrl/movie/$($m.Slug).m3u8")
}
foreach ($e in $episodes) {
    [void]$sb.AppendLine("#EXTINF:-1 tvg-id=`"$($e.Id)`" tvg-name=`"$($e.Name)`" group-title=`"Open Movie Shorts`",$($e.Name)")
    [void]$sb.AppendLine($e.Url)
}
Write-Text (Join-Path $root 'playlist.m3u') $sb.ToString()

# ---------------------------------------------------------------------------------------------
# 3. EPG XMLTV (de ontem 00:00 UTC até +DaysAhead, blocos de 1h)
# ---------------------------------------------------------------------------------------------
$shows = @{
    'demo.live.clock'  = @(
        @('Live Clock', 'A continuous live feed with a running clock, ideal for testing live playback.'),
        @('Signal Check', 'Live signal verification segment.'),
        @('Timecode Live', 'Live stream with burned-in timecode.'))
    'demo.live.scifi' = @(
        @('Tears of Steel', 'Warriors and scientists fight to save the world from destructive robots. Blender Foundation, CC BY 3.0.'),
        @('Sci-Fi Shorts', 'Open-licensed science fiction short films.'),
        @('Future Worlds', 'Visual effects showcase from open productions.'))
    'demo.live.bbb'    = @(
        @('Big Buck Bunny', 'A giant rabbit takes revenge on three bullying rodents. Blender Foundation, CC BY 3.0.'),
        @('Open Movies Hour', 'Short films released under open licenses.'),
        @('Animation Showcase', 'Highlights from open animated productions.'))
}

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$start = [DateTime]::UtcNow.Date.AddDays(-1)
$hours = ($DaysAhead + 1) * 24

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<tv generator-info-name="FireIPTV demo">')
foreach ($c in $live) {
    [void]$sb.AppendLine("  <channel id=`"$($c.Id)`"><display-name>$(Esc $c.Name)</display-name><icon src=`"$BaseUrl/img/$($c.Id).png`"/></channel>")
}
foreach ($c in $live) {
    $list = $shows[$c.Id]
    for ($h = 0; $h -lt $hours; $h++) {
        $s = $start.AddHours($h)
        $show = $list[$h % $list.Count]
        $a = $s.ToString('yyyyMMddHHmmss', $culture)
        $b = $s.AddHours(1).ToString('yyyyMMddHHmmss', $culture)
        [void]$sb.AppendLine("  <programme start=`"$a +0000`" stop=`"$b +0000`" channel=`"$($c.Id)`"><title>$(Esc $show[0])</title><desc>$(Esc $show[1])</desc></programme>")
    }
}
[void]$sb.AppendLine('</tv>')
Write-Text (Join-Path $root 'epg.xml') $sb.ToString()

Write-Text (Join-Path $root '.nojekyll') ''

Write-Host "OK: $root"
Write-Host "  playlist: $BaseUrl/playlist.m3u"
Write-Host "  epg:      $BaseUrl/epg.xml"
