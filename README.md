# Painel Tab

Painel de mesa e porta-retratos **editável** para tablet Android (feito para um Samsung Tab A com Android 11).

## O que faz

- **Cenas** feitas de camadas: texto, relógio, data, contagem regressiva, fotos (slideshow), vídeo em loop, formas, anéis e barras de progresso.
- **Animações leves** por camada: pulsar, piscar, girar, flutuar, zoom, deslizar, tremular, glitch e digitar.
- **Efeitos de fundo**: grade, linhas de varredura, faixa de luz, chuva de dados e neve.
- **Editor no próprio tablet**: toque na tela, depois no lápis. Arraste as camadas, redimensione pela alça amarela e ajuste tudo no painel lateral.
- **Datas comemorativas**: uma cena pode aparecer sozinha num período (ex.: Natal de 1/12 a 26/12).
- **Modo noturno** que escurece a tela em um horário e nível de efeitos (alto, baixo, desligado) para poupar o aparelho.
- Tela sempre ligada e em tela cheia.

## Como instalar

1. Abra **Releases** neste repositório pelo navegador do tablet.
2. Baixe `painel-tab.apk` da versão mais recente e instale (permita "instalar apps desconhecidos").

Cada push na branch `main` gera um APK novo pelo GitHub Actions. A assinatura é fixa (`tool/debug.keystore`, chave de depuração padrão), então dá para atualizar por cima sem perder as cenas.

## Compilar no PC

```
flutter create --platforms=android --org br.com.painel --project-name painel_tab .
python3 tool/patch_android.py
flutter pub get
flutter build apk --release
```

(O `flutter create` só gera a pasta `android/`; guarde uma cópia de `lib/` e `pubspec.yaml` antes, como faz o workflow.)

## Observações

- As fontes (Orbitron, Share Tech Mono etc.) são baixadas na primeira vez que aparecem, então o tablet precisa de internet nesse momento. Sem internet, o texto usa a fonte do sistema.
- Fotos e vídeos escolhidos são copiados para a pasta do app.
