# Aetheris — Mémo de session

## Contexte
Projet forké depuis ruvnet/ruview (WiFi-DensePose). Renommé **Aetheris**.  
Plateforme de détection spatiale par WiFi (présence, respiration, rythme cardiaque, pose, chute).

## Actions réalisées

### Rebranding
- README.md : π Aetheris
- README.fr.md : π Aetheris
- pyproject.toml : name = "aetheris" v1.3.0
- deploy.sh : PROJECT_NAME = "aetheris"
- scripts/setup-fr.sh : Aetheris
- python/ruview/__init__.py : Aetheris
- lang/fr.json, en.json : "name": "Aetheris"
- CHANGELOG.md : Ajout entrée rebranding

### Nouveautés
- `docs/demarrage-rapide.fr.md` — Guide de démarrage rapide en français
- `config/smart-sleep.toml` — Mode veille intelligente (apnée, ronflement, chute au lever)
- `config/pet-detection.toml` — Détection d'animaux (chiens, chats, zones d'exclusion)

## Réseau
- GitHub instable — clone complet impossible (timeout à ~36 KB/s)
- Solution : push incrémental (fonctionne), PR future
- Original : ruvnet/ruview (~175 MB)
- Fork : yannjordy/ruview

## Fichiers clés
- `CLAUDE.md` — Config Claude Code (contexte projet)
- `CHANGELOG.md` — Journal des modifications
- `docs/optimisation-performances.fr.md` — Guide perf
- `lang/fr.json`, `lang/en.json` — Traductions i18n
- `python/ruview/i18n.py` — Chargeur i18n Python

### 3D Engine (Flutter)
- `flutter/lib/widgets/pose_3d_math.dart` — Vec3, Mat4, Projection, SmoothValue spring physics
- `flutter/lib/widgets/pose_renderer.dart` — Squelette 3D perspective avec COCO 17 keypoints, glow, transitions douces, respiration thoracique
- `flutter/lib/widgets/room_scene.dart` — Pièce 3D avec sol grille, murs semi-transparents, occupants animés (pulse respiration)
- `flutter/lib/widgets/breathing_indicator.dart` — Animation pulmonaire avec expansion/contraction, couleur dynamique, glow
- `flutter/lib/widgets/signal_particles.dart` — Particules WiFi flottantes (dérive sinusoïdale, alpha oscillation)
- Dashboard + RoomDetail intégrés avec les widgets 3D

### Problème résolu
- `.gitignore` avait `lib/` qui matchait `flutter/lib/` — ajouté `!flutter/lib/` pour exclure

## Prochaines étapes
1. Télécharger v2/ (Rust crates) via gh API (timeout réseau)
2. Intégrer i18n dans le CLI Rust et le dashboard web
3. Implémenter les optimisations concrètes du guide perf
4. Créer PR vers ruvnet/ruview
