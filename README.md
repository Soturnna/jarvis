# Jarvis

App pessoal para iPhone que reúne, num só lugar, finanças, treino, nutrição, saúde,
agenda, e-mail e um resumo do dia com IA. Substitui o Fluxo (finanças) e o Forja
(treino e nutrição). Feito em SwiftUI e compilado sem Mac, pelo GitHub Actions.

O andamento das fases fica em [`PROGRESSO.md`](PROGRESSO.md).

## Compilar e instalar

Cada push na `main` gera um `.ipa` sem assinatura na página **Releases**
(com o SHA-256 do arquivo). Instale pelo iOSGods App+.

Link fixo da versão mais recente:
https://github.com/Soturnna/jarvis/releases/latest/download/Jarvis.ipa

Para atualizar, instale a versão nova **por cima** da antiga, sem apagar o app:
apagar o app remove os dados dele.

## Estrutura

```
project.yml                      XcodeGen (o .xcodeproj é gerado na compilação)
.github/workflows/build-ipa.yml  Gitleaks + compilação → .ipa em Releases
PROGRESSO.md                     Estado das fases
App/                             Ciclo de vida, bloqueio e as 5 abas
Core/
  Security/                      Do Fluxo: AppLock, LockWindow, PrivacyShield, KeychainStore, Vault
  Design/                        Tokens visuais (cores, raios, componentes básicos)
  WidgetBridge/                  Grava o resumo no App Group E em Documents (Scriptable)
Features/                        Telas próprias: Hoje, Ajustes e Diagnóstico, abas ainda vazias
Resources/                       Catálogo de imagens e o Jarvis.js (script do Scriptable)
JarvisWidgets/                   Extensão: widgets nativos
design/icon.svg                  Ícone (convertido em PNG na compilação)
```

As pastas `Core/AI`, `Core/Summary` e `Modules/` entram nas fases seguintes.

## Widgets: dois caminhos

O iOSGods App+ não entrega o App Group, e sem ele o iOS não mostra os widgets nativos.
Por isso o app grava o mesmo resumo em dois lugares a cada atualização:

| Caminho | Quando funciona | De onde lê |
| --- | --- | --- |
| Scriptable | Sempre | `jarvis-widget.json` em Arquivos › No Meu iPhone › Jarvis |
| Nativo (WidgetKit) | Só se o App Group existir | Mesmo arquivo, na pasta do App Group |

A tela **Ajustes › Diagnóstico** informa qual caminho está ativo neste aparelho.

### Configurar o Scriptable (uma vez)

1. Instale o Scriptable pela App Store.
2. No Jarvis: Ajustes › **Exportar script do Scriptable** › escolha Scriptable.
   Se ele não aparecer na lista, use **Copiar código**, crie um script novo no Scriptable (+),
   cole e dê o nome `Jarvis`.
3. No Scriptable: engrenagem › File Bookmarks › + › Pick Folder › No Meu iPhone › Jarvis ›
   nome: `Jarvis` (exatamente assim).
4. Na tela de início: segure › + › Scriptable › escolha o tamanho. Toque no widget › Script: `Jarvis`.

Se o app for apagado e reinstalado, refaça o passo 3: a pasta muda.

## Modelo de segurança

O modelo do Fluxo (os 18 itens do README dele) vale para o app inteiro. Na fundação já estão ativos:

1. **Nenhum segredo no código.** As chaves serão digitadas no app e guardadas no Keychain
   (`WhenUnlockedThisDeviceOnly`).
2. **Varredura de segredos.** Todo push passa pelo Gitleaks antes de compilar.
3. **Bloqueio do app.** Face ID (ou código do iPhone) ao abrir e ao voltar do segundo plano,
   numa janela própria acima de tudo. O tempo é medido por relógio monotônico.
4. **Afrouxar exige identidade.** Desligar qualquer proteção pede Face ID.
5. **Alternador de apps.** Uma janela acima de tudo cobre a tela quando o app sai do primeiro plano.
6. **Só HTTPS.** Nenhuma exceção ao App Transport Security.
7. **Sessão com prazo.** Depois de 5 minutos em segundo plano, a sessão é descartada e as telas
   são recriadas do zero.
8. **Cofre local cifrado.** AES-GCM de 256 bits, chave no Keychain, Proteção de Dados completa,
   gravação atômica e fora do backup. (Pronto; os módulos passam a usá-lo na fase 1.)
9. **Ações fixadas por hash.** As GitHub Actions de terceiros usam o hash do commit, não a tag.
10. **Widgets sem valores.** Os arquivos de widget não têm valores em reais nem nomes.
    Mostrá-los será uma opção que exige Face ID, com o arquivo sob proteção de dados completa.

## Decisões registradas

Decisões tomadas durante a construção, quando o documento de especificação deixava a escolha em aberto.

### Fase 0

- **Tokens em `Core/Design`.** O arquivo `Theme.swift` é compilado no app e na extensão de widgets,
  por isso fica em `Core` e não depende do catálogo de imagens.
- **Cores dos módulos pelas cores do sistema.** Os valores da especificação (`#30D158`, `#FF9F0A`,
  `#FFD60A`, `#FF375F`, `#FF453A`) são exatamente as variantes escuras de `systemGreen`,
  `systemOrange`, `systemYellow`, `systemPink` e `systemRed`. Usar as cores do sistema entrega
  os mesmos valores no modo escuro e as variantes claras de graça.
- **Entitlements e assinatura ad-hoc (do Forja).** O workflow parte do Fluxo (Gitleaks, Actions por
  hash) e recebe do Forja a etapa que grava os entitlements no binário. Hoje só o App Group é
  pedido; o HealthKit entra na fase 2.
- **App Group em tempo de execução.** A busca junta a técnica do Fluxo (`group.<identificador
  instalado>`) com a do Forja (grupos do perfil de assinatura e `ALTAppGroups`). Vence o primeiro
  que o iOS realmente liberar.
- **Arquivo de widget da fase 0.** `jarvis-widget.json` tem `schemaVersion`, `updatedAt`,
  `showValues` e `note` (texto de teste). O `DailySummary` completo entra na fase 5, no mesmo arquivo.
- **Barra de abas nativa.** `TabView` com `tabItem`, que funciona do iOS 17 em diante e recebe o
  Liquid Glass automaticamente quando compilado com o SDK do iOS 26.
- **Bloqueio sempre escuro.** A tela de bloqueio e a proteção do alternador usam fundo preto fixo,
  em qualquer modo do sistema.
- **Sem workflow de testes ainda.** Ele entra na fase 1, junto com os testes do Fluxo.
- **`PROGRESSO.md` não dispara compilação.** Alterar só esse arquivo não gera um `.ipa` novo.

### Ponto a verificar na fase 1

A chave do cofre fica no Keychain. Não foi verificado se o Keychain continua legível quando o
iOSGods App+ troca o certificado de assinatura e o app é reinstalado por cima. Se não continuar,
o cofre fica ilegível e os dados precisam voltar por sincronização (Pluggy) e por backup exportado.
Isso será testado antes de o app guardar dados que só existem nele.

## Fora do escopo

Push de qualquer tipo, leitura de mensagens do WhatsApp ou do Instagram, bibliotecas não oficiais
dessas redes, engenharia reversa de apps de terceiros, publicação na App Store e versão Android.
