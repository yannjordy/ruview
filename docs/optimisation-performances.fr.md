# Optimisation des performances RuView

## 1. Pipeline de traitement du signal

### Problèmes identifiés
- **Latence de fusion multistatique** : l'attention-weighted fusion sur N×(N-1) liaisons est en O(n²)
- **Goulot d'étranglement du CSI** : le parsing des trames CSI sur ESP32 peut perdre des paquets à haut débit
- **Redondance sous-porteuses** : 168 sous-porteuses virtuelles → beaucoup sont corrélées

### Optimisations suggérées

| Problème | Solution | Gain estimé |
|----------|----------|-------------|
| Lenteur fusion multistatique | Échantillonnage aléatoire de liaisons au lieu de toutes les paires (subsampling) | 3-5× |
| Parssing CSI lent | Buffer ring + DMA sur ESP32-S3 | 2× |
| Sous-porteuses redondantes | PCA en temps réel → réduire de 168 à 32 dimensions | 2-3× sans perte significative |
| Phase unwrapping lent | Algorithme ITL + SIMD (ARM NEON / x86 AVX2) | 1.5× |

## 2. Inférence du modèle neuronal

### Métriques actuelles
- Encodage : 164 183 plongements/s sur M4 Pro
- Estimation de pose : 8.4 ms à froid sur Pi 5
- Modèle : 8 Ko (quantifié int4) → 48 Ko (safetensors)

### Optimisations

**Quantification**
- Le modèle int4 8 Ko est déjà très optimisé
- Proposition : ajouter quantification int2 pour déploiement ESP32 (gain ×2 en taille)
- Backend ONNX Runtime pour exploitation accélérée matériellement

**Inférence**
- Compiler le modèle via TVM (Apache TVM) pour cibles ARM/x86
- Utiliser XNNPACK pour accélération sur mobile et edge
- Ajouter batch processing pour les déploiements multi-pièces

## 3. ESP32 Firmware

### Consommation mémoire
- Actuel : pipeline CSI + SNN sur ESP32-S3 avec 8 MB flash
- Optimisation : utiliser PSRAM pour les buffers CSI

| Optimisation | Mémoire libérée |
|-------------|-----------------|
| Compiler avec `-Os` | ~15% |
| Supprimer logs debug en production | ~5% |
| Utiliser buffers circulaires au lieu d'allocation dyn. | ~10% |
| Quantification des poids SNN en int8 | ~50% sur les modèles |

## 4. Base de données & stockage

- **opencoe.db** : la base SQLite peut devenir volumineuse (826 MB observé)
- Solution : implémenter une politique de rétention :
  - Données brutes CSI : 24h max
  - Signes vitaux agrégés : 30 jours
  - Événements (alertes) : 90 jours
- Compression des données CSI stockées (gzip ou lz4)

## 5. Réseau & communication

### MQTT
- Actuel : protocole MQTT avec QoS 1
- Optimisation : QoS 0 pour les données temps réel, QoS 1 pour les alertes
- Activer MQTT v5 avec message expiry pour éviter les files d'attente

### WebSocket
- Utiliser protobuf au lieu de JSON pour les trames CSI binaires
- Compression WebSocket (permessage-deflate)

## 6. Docker & déploiement

- Image actuelle : ~450 MB
- Optimisation : image multi-stage avec base Alpine (~120 MB)
- Ajouter HEALTHCHECK et --restart=always
- Utiliser Docker Compose pour déploiement multi-service

## Benchmarks recommandés

```bash
# Benchmark du pipeline signal
cd v2 && cargo bench -p wifi-densepose-signal

# Benchmark du modèle d'inférence
cd v2 && cargo bench -p wifi-densepose-nn

# Test de performance du serveur
cd v2 && cargo bench -p wifi-densepose-sensing-server
```

## Monitoring des performances

Ajouter métriques Prometheus :
- `ruview_signal_latency_ms` — latence du pipeline signal
- `ruview_inference_time_us` — temps d'inférence modèle
- `ruview_csi_packets_total` — paquets CSI traités
- `ruview_memory_bytes` — consommation mémoire
- `ruview_nodes_online` — nœuds actifs
