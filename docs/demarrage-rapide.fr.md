# Aetheris — Guide de démarrage rapide

## Prérequis

- **WiFi** : n'importe quel routeur WiFi 2.4 GHz
- **Optionnel** : ESP32-S3 (9 €) pour la détection complète
- **Ou** : Docker pour le mode démo

## Installation

```bash
# Option 1 : Python (recommandé pour débuter)
pip install aetheris

# Option 2 : Docker (simulation, pas de matériel)
docker pull aetheris/aetheris:latest
docker run -p 3000:3000 aetheris/aetheris:latest
# → http://localhost:3000

# Option 3 : Installation complète
git clone https://github.com/yannjordy/ruview.git
cd ruview
bash scripts/setup-fr.sh
```

## Démarrage rapide (3 minutes)

### 1. Mode démo (sans matériel)

```bash
docker run -p 3000:3000 aetheris/aetheris:latest
# Ouvrez http://localhost:3000 dans votre navigateur
```

### 2. Avec ESP32-S3

```bash
# Branchez l'ESP32-S3 sur un port USB
pip install aetheris

# Détection automatique des nœuds
aetheris scan

# Calibration de la pièce (30 secondes — restez immobile)
aetheris calibrate

# Lancement de la détection
aetheris start
```

### 3. Dashboard web

```bash
aetheris dashboard
# → http://localhost:3000
```

## Que peut détecter Aetheris ?

| Fonction | Matériel requis | Temps de calibration |
|----------|-----------------|---------------------|
| Présence | N'importe quel WiFi | 30 secondes |
| Respiration | ESP32-S3 | 30 secondes |
| Rythme cardiaque | ESP32-S3 + Seed | 1 minute |
| Pose corporelle | 3× ESP32-S3 | 2 minutes |
| Chute | ESP32-S3 | 30 secondes |
| Sommeil | ESP32-S3 | 1 nuit (auto-apprentissage) |
| À travers les murs | ESP32-S3 | 1 minute |

## Architecture

```
Routeur WiFi → ondes radio → ESP32 capture le CSI → Aetheris traite le signal
    ↓
Présence | Respiration | Rythme cardiaque | Pose | Chute
    ↓
Dashboard web | Home Assistant | Apple Home | MQTT
```

## Aide

```bash
aetheris --help
aetheris docs        # Ouvre la documentation
aetheris status      # État du système
aetheris logs        # Journaux en direct
```

## Prochaines étapes

- [ ] Ajouter plus de nœuds ESP32 pour une couverture multi-pièces
- [ ] Connecter à Home Assistant pour l'automatisation
- [ ] Configurer des alertes (email, notification push)
- [ ] Explorer les modules Edge avancés

---

*Aetheris — Voir l'invisible. https://github.com/yannjordy/ruview*
