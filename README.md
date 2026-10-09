# FireIPTV — lista demo

Fonte de teste para a certificação da Microsoft Store (10.3.3 "App Is Testable"). Só streams de
teste públicos (Mux, Unified Streaming) e filmes abertos da Blender Foundation (CC BY).

Esta pasta é o conteúdo do repositório **público** `igorpaixaodev/fireiptv-demo`, servido pelo
GitHub Pages a partir de `main` / `docs`.

| Arquivo | O que é |
|---|---|
| `build.ps1` | Gera `docs/playlist.m3u`, `docs/epg.xml` e os wrappers `docs/movie/*.m3u8` |
| `make-images.ps1` | Gera logos/pôsteres em `docs/img` (só Windows; rodar uma vez) |
| `.github/workflows/refresh-epg.yml` | Regenera o EPG toda segunda (a grade é relativa a hoje) |

URLs publicadas:

- M3U: `https://igorpaixaodev.github.io/fireiptv-demo/playlist.m3u`
- EPG: `https://igorpaixaodev.github.io/fireiptv-demo/epg.xml`

Por que os filmes passam por wrapper: o FireIPTV classifica entradas M3U pela URL — só vira
**Filme** quem tem `/movie/` no caminho. O wrapper é um master HLS hospedado em `/movie/` que
aponta (URI absoluta) para os variants na origem. Séries são reconhecidas pelo `SxxEyy` no nome.

## Lista de diagnóstico (`docs/diag.m3u`)

Fora da lista da certificação; serve à issue `igorpaixaodev/fire-iptv#25`. Cada canal isola um
formato de master HLS para descobrir qual derruba o FFmpegInteropX 1.1.0-pre42. O DIAG 5 é o
controle (formato que sempre tocou).
