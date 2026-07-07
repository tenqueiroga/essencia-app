# Mapa de Logos — Olfato (v2)

Referência rápida de onde cada variante de logo deve ser usada no projeto.

---

## 📁 Estrutura

```
branding/nova logo/
├── masters/          → Arquivos originais em alta resolução (não usar diretamente)
├── horizontal/       → Logo horizontal (com e sem assinatura)
├── vertical/         → Logo vertical (com e sem assinatura)
├── simbolo/          → Apenas o símbolo (nariz estilizado)
├── icones/           → Ícone de app com fundo transparente (vários tamanhos)
└── monocromaticas/   → Versões monocromáticas (ameixa, branco, dourado)
```

---

## 🗺️ Onde usar cada logo

### App Icon (launcher)
| Plataforma | Arquivo fonte | Destino no projeto |
|---|---|---|
| Android | `icones/olfato_icone_transparente_*.png` | `frontend/android/app/src/main/res/mipmap-*/ic_launcher.png` |
| iOS | `icones/olfato_icone_transparente_1024.png` | `frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| Web (PWA) | `icones/olfato_icone_transparente_192.png` e `512.png` | `frontend/web/icons/` e `backend/public/app/icons/` |
| Play Store | `icones/olfato_icone_transparente_512.png` | `frontend/android/app/src/main/res/playstore-icon.png` |

### Favicon
| Contexto | Arquivo fonte | Destino |
|---|---|---|
| Web favicon (PNG) | `icones/olfato_icone_transparente_32.png` | `frontend/web/favicon.png` e `backend/public/app/favicon.png` |
| Web favicon (ICO) | gerado a partir do 32px | `backend/public/favicon.ico` |

### Dentro do App (Flutter assets)
| Uso | Arquivo fonte | Destino |
|---|---|---|
| Símbolo (avatar, nav, ícones inline) | `simbolo/olfato_simbolo_512.png` | `frontend/assets/images/olfato_simbolo.png` |
| Logo horizontal (headers, splash) | `horizontal/olfato_horizontal_800.png` | `frontend/assets/images/olfato_logo_horizontal.png` |
| Logo vertical (onboarding, about) | `vertical/olfato_vertical_768.png` | `frontend/assets/images/olfato_logo_vertical.png` |

### Monocromáticas (situações especiais)
| Variante | Quando usar |
|---|---|
| `*_branco.png` | Fundos escuros, dark mode, overlays |
| `*_ameixa.png` | Fundos claros, documentos, materiais impressos com cor da marca |
| `*_dourado.png` | Materiais premium, certificados, convites |

### Com Assinatura ("Seu gosto, traduzido em perfume.")
| Variante | Quando usar |
|---|---|
| `horizontal_com_assinatura_*` | Banners, headers de email, landing pages |
| `vertical_com_assinatura_*` | Posters, cards de redes sociais, stories |

---

## 🎨 Referência de Cores da Marca

| Nome | Hex | Uso |
|---|---|---|
| Ameixa (Plum) | `#4A1942` | Cor primária da marca |
| Dourado (Gold) | `#B8956A` | Acentos premium |
| Branco | `#FFFFFF` | Para fundos escuros |

---

## 🔧 Regeneração de Ícones

Para regenerar todos os ícones do app a partir da fonte:

```bash
cd frontend
python generate_icon.py
```

Isso regenera Android, iOS e Web icons automaticamente a partir de `novas logos/05_Icones/olfato_icone_transparente_1024.png`.

---

## ⚠️ Regras

1. **Não distorcer** — manter proporção original sempre
2. **Não alterar cores** — usar apenas as variantes fornecidas
3. **Espaço de respiro** — manter margem mínima de 20% do tamanho do símbolo ao redor
4. **AURA mantém identidade própria** — a logo do Aura (chatbot) não usa essas assets
