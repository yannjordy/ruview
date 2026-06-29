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

## Prochaines étapes
1. Télécharger v2/ (Rust crates) via gh API (timeout réseau)
2. Intégrer i18n dans le CLI Rust et le dashboard web
3. Implémenter les optimisations concrètes du guide perf
4. Créer PR vers ruvnet/ruview
