# π RuView

<p align="center">
  <a href="https://cognitum.one/seed">
    <img src="assets/ruview-seed.png" alt="RuView - WiFi DensePose" width="100%">
  </a>
</p>
<p align="center">
  <a href="https://cognitum.one/seed">
    <img src="assets/seed.png" alt="Cognitum Seed" width="100%">
  </a>
</p>

## **Voir à travers les murs avec le WiFi**

**Transformez un WiFi ordinaire en système d'intelligence spatiale.** Détectez les personnes, mesurez la respiration et le rythme cardiaque, suivez les mouvements et surveillez les pièces — à travers les murs, dans l'obscurité, sans caméra ni wearable. Juste de la physique.

Fonctionne nativement avec les quatre principaux écosystèmes domotiques : **[Home Assistant](docs/integrations/home-assistant.md)** via le publisher MQTT HA-DISCO, **[Apple Home & HomePod](docs/user-guide-apple-homepod.md)** en tant que pont HAP-1.1, **[Google Home](docs/integrations/home-assistant.md)** et **[Amazon Alexa](docs/integrations/home-assistant.md)** via le même pont HA ou un endpoint [Matter](docs/adr/ADR-122-bfld-ruview-ha-matter-exposure.md). Siri, Google Assistant et Alexa peuvent vocaliser la présence et les signes vitaux par pièce sans compétence personnalisée.

[![Works with Home Assistant](https://img.shields.io/badge/Fonctionne%20avec-Home%20Assistant-blue?logo=home-assistant&logoColor=white&labelColor=41BDF5)](docs/integrations/home-assistant.md) [![Works with Matter](https://img.shields.io/badge/Fonctionne%20avec-Matter-blue?labelColor=4285F4)](docs/adr/ADR-122-bfld-ruview-ha-matter-exposure.md) [![Works with Apple Home](https://img.shields.io/badge/Fonctionne%20avec-Apple%20Home-black?logo=apple)](docs/user-guide-apple-homepod.md) [![Works with Google Home](https://img.shields.io/badge/Fonctionne%20avec-Google%20Home-blue?logo=googlehome)](docs/integrations/home-assistant.md) [![Works with Alexa](https://img.shields.io/badge/Fonctionne%20avec-Alexa-blue?logo=amazon&logoColor=white&labelColor=00CAFF)](docs/integrations/home-assistant.md)

> Intégrez-vous dans n'importe quelle installation **Home Assistant** avec un simple flag `--mqtt`. Ou appariez-vous dans **Apple Home / Google Home / Alexa / SmartThings** en tant que Matter Bridge. Livre 21 entités par nœud (11 signaux bruts + 10 états sémantiques inférés : quelqu'un-dort, détresse-possible, pièce-active, anomalie-inactivité-personne-âgée, réunion-en-cours, salle-de-bains-occupée, risque-de-chute-élevé, sortie-de-lit, aucun-mouvement, transition-multi-pièces) plus 3 Blueprints HA de démarrage. Voir [`docs/integrations/home-assistant.md`](docs/integrations/home-assistant.md) · [ADR-115](docs/adr/ADR-115-home-assistant-integration.md).

### π RuView est une plateforme de détection WiFi qui transforme les signaux radio en intelligence spatiale.

Chaque routeur WiFi remplit déjà votre espace d'ondes radio. Quand une personne bouge, respire, ou même reste immobile, elle perturbe ces ondes de manière mesurable. RuView capture ces perturbations en utilisant les « Channel State Information » (CSI) de capteurs ESP32 à faible coût et les transforme en données exploitables : qui est là, ce qu'il fait, et si tout va bien.

**Ce qu'il détecte :**
- **Présence et occupation** — détecte les personnes à travers les murs, les compte, suit les entrées et sorties
- **Signes vitaux** — fréquence respiratoire et cardiaque, sans contact, pendant le sommeil ou en position assise
- **Reconnaissance d'activité** — marche, position assise, gestes, chutes — à partir de motifs CSI temporels
- **Cartographie de l'environnement** — l'empreinte RF identifie les pièces, détecte les meubles déplacés, repère les nouveaux objets
- **Qualité du sommeil** — surveillance nocturne avec classification des stades de sommeil et dépistage de l'apnée

Construit sur [RuVector](https://github.com/ruvnet/ruvector/) et [Cognitum Seed](https://cognitum.one), RuView fonctionne entièrement sur du matériel Edge — un maillage ESP32 (à partir de 9 € par nœud) associé à un Cognitum Seed pour la mémoire persistante, l'attestation cryptographique et l'intégration IA. Pas de cloud, pas de caméra, pas d'accès Internet requis.

Le système apprend chaque environnement localement en utilisant des réseaux de neurones impulsionnels qui s'adaptent en moins de 30 secondes, avec un balayage multi-fréquences sur 6 canaux WiFi qui utilise les routeurs de vos voisins comme illuminateurs radar gratuits. Chaque mesure est cryptographiquement attestée via une chaîne de témoins Ed25519.

RuView transforme le WiFi ordinaire en capteur sans contact. Une carte ESP32 à 9 € lit les réflexions radio sur les personnes dans une pièce, et un petit modèle pré-entraîné — publié sur Hugging Face à [`ruvnet/wifi-densepose-pretrained`](https://huggingface.co/ruvnet/wifi-densepose-pretrained) — vous dit qui est là, comment ils respirent et comment évolue leur rythme cardiaque. Le modèle tient dans 8 Ko (quantifié en 4 bits) et s'exécute en microsecondes sur un Raspberry Pi. Pas de caméra, pas de wearable, pas d'application sur le téléphone.

### Conçu pour les applications Edge à faible consommation

Les [modules Edge](#intelligence-edge-adr-041) sont de petits programmes qui s'exécutent directement sur le capteur ESP32 — pas d'accès Internet, pas de frais de cloud, réponse instantanée.

[![Rust 1.85+](https://img.shields.io/badge/rust-1.85+-orange.svg)](https://www.rust-lang.org/)
[![License: MIT](https://img.shields.io/badge/Licence-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests: 1463](https://img.shields.io/badge/tests-1463%20réussis-brightgreen.svg)](https://github.com/ruvnet/RuView)
[![Docker: multi-arch](https://img.shields.io/badge/docker-amd64%20%2B%20arm64-blue.svg)](https://hub.docker.com/r/ruvnet/wifi-densepose)
[![Signes Vitaux](https://img.shields.io/badge/signes%20vitaux-respiration%20%2B%20rythme%20cardiaque-red.svg)](#détection-des-signes-vitaux)
[![Prêt ESP32](https://img.shields.io/badge/ESP32--S3-Flux%20CSI-purple.svg)](#pipeline-matériel-esp32-s3)
[![crates.io](https://img.shields.io/crates/v/wifi-densepose-ruvector.svg)](https://crates.io/crates/wifi-densepose-ruvector)
[![Téléchargements](https://img.shields.io/badge/téléchargements-10M%2B-brightgreen.svg)](#-catalogue-de-modules-edge)

| Fonction | Méthode | Vitesse / Échelle |
|----------|---------|-------------------|
| 🫁 **Respiration** | Passe-bande 0.1–0.5 Hz sur phase enroulée, variance circulaire, BPM passage par zéro ([#593](https://github.com/ruvnet/RuView/issues/593)) | 6–30 BPM, temps réel |
| 💓 **Rythme cardiaque** | Passe-bande 0.8–2.0 Hz, BPM passage par zéro | 40–120 BPM, temps réel |
| 👤 **Détection de présence** | Tête entraînée sur Hugging Face ([`ruvnet/wifi-densepose-pretrained`](https://huggingface.co/ruvnet/wifi-densepose-pretrained) ; encodeur v2 = 82.3% précision triplet temporel) + repli variance de phase sans modèle | < 1 ms, ~30 s de calibration |
| 🧬 **Plongements CSI** | Encodeur contrastif 128-dim sur Hugging Face, variante quantifiée 4-bit tient en 8 Ko | **164 183 plongements/s** sur M4 Pro |
| 🦴 **Estimation de pose 17 points** | Cog `cog-pose-estimation` v0.0.1 — binaires signés aarch64 + x86_64 | 8.4 ms à froid sur Pi 5 |
| 🚶 **Mouvement / activité** | Puissance bande de mouvement + accélération de phase | Temps réel |
| 🤸 **Détection de chute** | Seuil d'accélération de phase + 3 trames de debounce + 5 s de cooldown | < 200 ms |
| 🧮 **Comptage multi-personnes** | Normalisation P95 adaptative + facteur de déduplication ajustable | Temps réel, auto-calibrant |
| 🧱 **Détection à travers les murs** | Géométrie de zone de Fresnel + modélisation multitrajets | Jusqu'à ~5 m |
| 🧠 **Intelligence Edge** | **Catalogue de 105 modules** — santé, sécurité, bâtiment, commerce, industrie, recherche, IA | À partir de 140 € BOM |

## Démarrage rapide

```bash
# Option 1 : Docker (données simulées, aucun matériel requis)
docker pull ruvnet/wifi-densepose:latest
docker run -p 3000:3000 ruvnet/wifi-densepose:latest
# Ouvrir http://localhost:3000

# Option 2 : Détection réelle avec ESP32-S3 (9 €)
pip install ruview
# Voir docs/getting-started.fr.md pour le guide complet

# Option 3 : Python — disponible sur PyPI
pip install ruview
# ou : pip install wifi-densepose
```

## 🤗 Modèle pré-entraîné sur Hugging Face

```bash
pip install huggingface_hub
huggingface-cli download ruvnet/wifi-densepose-pretrained --local-dir models/wifi-densepose-pretrained
```

## Résultats & preuve

| Quoi | Où | Chiffres |
|------|-----|---------|
| **Modèle de pose MM-Fi (SOTA)** | [`ruvnet/wifi-densepose-mmfi-pose`](https://huggingface.co/ruvnet/wifi-densepose-mmfi-pose) | 82.69% torso-PCK@20 (simple) · 83.59% (ensemble+TTA) |
| **Encodeur pré-entraîné** | [`ruvnet/wifi-densepose-pretrained`](https://huggingface.co/ruvnet/wifi-densepose-pretrained) | 82.3% triplet temporel, 8 Ko int4 |
| **Preuve reproductible** | [`archive/v1/data/proof/verify.py`](archive/v1/data/proof/verify.py) | Rejeu de pipeline déterministe |

```bash
# Reproduire la preuve (doit afficher VERDICT: PASS) :
python archive/v1/data/proof/verify.py
```

## 🧩 Catalogue de modules Edge

105 modules Edge prêts à installer — santé, sécurité, bâtiment, commerce, industriel, recherche, IA, essaim, signal, réseau et développeur.

## 🔬 Comment ça fonctionne

Les routeurs WiFi inondent chaque pièce d'ondes radio. Quand une personne bouge — ou même respire — ces ondes se dispersent différemment. WiFi DensePose lit ce motif de dispersion et reconstruit ce qui s'est passé :

```
Routeur WiFi → ondes radio traversent la pièce → corps humain → dispersion
    ↓
Maillage ESP32 (4-6 nœuds) capture le CSI sur les canaux 1/6/11 via protocole TDM
    ↓
Fusion multi-bande : 3 canaux × 56 sous-porteuses = 168 sous-porteuses virtuelles par liaison
    ↓
Fusion multistatique : N×(N-1) liaisons → plongement cross-viewpoint pondéré par attention
    ↓
Porte de cohérence : accepte/rejette les mesures → stable pendant des jours sans réglage
    ↓
Traitement du signal : Hampel, SpotFi, Fresnel, BVP, spectrogramme → caractéristiques nettoyées
    ↓
Backbone IA (RuVector) : attention, algorithmes de graphe, compression, modèle de champ
    ↓
Réseau de neurones : signaux traités → 17 points clés du corps + signes vitaux + modèle de pièce
    ↓
Sortie : pose temps réel, respiration, rythme cardiaque, empreinte de pièce, alertes de dérive
```

Pas de caméras d'entraînement nécessaires — le système [auto-apprenant (ADR-024)](docs/adr/ADR-024-contrastive-csi-embedding-model.md) démarre à partir des données WiFi brutes seules. [MERIDIAN (ADR-027)](docs/adr/ADR-027-cross-environment-domain-generalization.md) garantit que le modèle fonctionne dans n'importe quelle pièce, pas seulement celle où il a été entraîné.

## Cas d'utilisation

| Secteur | Application |
|---------|-------------|
| 🏥 **Santé** | Surveillance des personnes âgées, détection des chutes, suivi du sommeil |
| 🏪 **Commerce** | Comptage de fréquentation, analyse des files d'attente, zones de chalandise |
| 🏢 **Bureau** | Utilisation des salles, optimisation CVC, détection de présence |
| 🏠 **Domotique** | Automatisation des pièces, suivi des personnes, sécurité |
| 🏭 **Industrie** | Sécurité des travailleurs, zones d'exclusion, détection de présence |
| 🔥 **Extrême** | Sauvetage, intervention incendie, détection à travers les décombres |

## Licence

MIT — voir [LICENSE](LICENSE).

---

*Traduction française du README. Pour toute question, ouvrez un ticket sur [GitHub](https://github.com/ruvnet/RuView/issues).*
