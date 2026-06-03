
# Compressor de mp3 ꕤ
Comprime arquivos `.mp3` em lote usando `ffmpeg`.

**Requisito:** `ffmpeg`.

## O que faz:

* Comprime todos os `.mp3` da pasta com três modos: bitrate, duração ou ambos.
* Reduz para 64kbps, pulando arquivos já otimizados.
* Permite cortar cada arquivo em N minutos.
* Salva em `compressed/` sem sobrescrever os originais.
* Mostra resumo total de espaço economizado ao final.

```bash
bash compress.sh
```

## Demo
![Demonstração](demo.png)