<#
.SYNOPSIS
  Gera os logos dos canais e os pôsteres dos filmes da lista demo em ./docs/img (PNG).

.DESCRIPTION
  Só Windows (System.Drawing). Roda uma vez e os PNGs vão versionados — o workflow do GitHub
  só regenera o EPG (build.ps1), não precisa disto.
  Arte própria na paleta Brasa para não depender de imagem de terceiro.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot 'docs/img'
New-Item -ItemType Directory -Force $out | Out-Null

$bg     = [System.Drawing.ColorTranslator]::FromHtml('#14110E')
$bg2    = [System.Drawing.ColorTranslator]::FromHtml('#2A1C14')
$accent = [System.Drawing.ColorTranslator]::FromHtml('#FF5A1F')
$text   = [System.Drawing.ColorTranslator]::FromHtml('#F7F2EC')
$muted  = [System.Drawing.ColorTranslator]::FromHtml('#B8A99A')

function New-Art([string]$id, [int]$w, [int]$h, [string]$title, [string]$kicker) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'

    $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $bg2, $bg, 90
    $g.FillRectangle($grad, $rect)

    # Barra de acento fire no topo + "chama" (círculo) de marca.
    $g.FillRectangle((New-Object System.Drawing.SolidBrush $accent), 0, 0, $w, [int]($h * 0.025))
    $d = [int]($w * 0.22)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $accent), [int](($w - $d) / 2), [int]($h * 0.16), $d, $d)

    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'
    $fmt.LineAlignment = 'Near'

    $titleFont = New-Object System.Drawing.Font 'Segoe UI Semibold', ([single]($w * 0.085)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $kickerFont = New-Object System.Drawing.Font 'Segoe UI', ([single]($w * 0.05)), ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

    $pad = [single]($w * 0.08)
    $titleTop = [single]($h * 0.16 + $d + $h * 0.06)
    $g.DrawString($title, $titleFont, (New-Object System.Drawing.SolidBrush $text),
        (New-Object System.Drawing.RectangleF $pad, $titleTop, ($w - 2 * $pad), ($h * 0.4)), $fmt)

    $fmt.LineAlignment = 'Far'
    $g.DrawString($kicker, $kickerFont, (New-Object System.Drawing.SolidBrush $muted),
        (New-Object System.Drawing.RectangleF $pad, 0, ($w - 2 * $pad), ($h - $h * 0.06)), $fmt)

    $bmp.Save((Join-Path $out "$id.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# Canais: quadrado.
New-Art 'demo.live.clock'  400 400 'Live Clock 24/7'     'DEMO LIVE'
New-Art 'demo.live.scifi'  400 400 'Sci-Fi Shorts'       'DEMO LIVE'
New-Art 'demo.live.bbb'    400 400 'Open Movies Channel' 'DEMO LIVE'

# Filmes: pôster 2:3.
New-Art 'demo.movie.bbb' 400 600 'Big Buck Bunny' 'Blender Foundation - CC BY'
New-Art 'demo.movie.tos' 400 600 'Tears of Steel' 'Blender Foundation - CC BY'

Write-Host "OK: $out"
