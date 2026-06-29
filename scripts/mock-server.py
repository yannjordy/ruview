#!/usr/bin/env python3
"""Aetheris — Mock Backend Server (stdlib, zéro dépendance)

Simule le backend Rust pour développer/tester le Flutter app sans ESP32.
Usage : python scripts/mock-server.py

Endpoints :
  GET  /api/v1/rooms              → liste des pièces simulées
  GET  /api/v1/rooms/{id}/vitals  → lecture vitale simulée
  POST /api/v1/rooms/{id}/calibrate → calibration simulée
  PUT  /api/v1/config             → mise à jour config
  GET  /api/v1/config             → config actuelle
  WS   /ws                        → stream CSI temps réel + vitals
"""

import http.server
import json
import math
import random
import time
import threading
import struct
import hashlib
from http import HTTPStatus
from urllib.parse import urlparse, parse_qs

HOST = "0.0.0.0"
PORT = 3000

random.seed(42)

ROOMS = [
    {"id": "salon", "name": "Salon", "status": "online", "occupant_count": 2},
    {"id": "chambre", "name": "Chambre", "status": "online", "occupant_count": 1},
    {"id": "cuisine", "name": "Cuisine", "status": "offline", "occupant_count": 0},
    {"id": "bureau", "name": "Bureau", "status": "online", "occupant_count": 1},
    {"id": "garage", "name": "Garage", "status": "calibrating", "occupant_count": 0},
]

ROOM_VITALS = {
    "salon":  {"breathing_rate": 15.3, "heart_rate": 72, "hr_confidence": 0.88, "br_confidence": 0.92},
    "chambre": {"breathing_rate": 13.8, "heart_rate": 65, "hr_confidence": 0.91, "br_confidence": 0.95},
    "cuisine": {"breathing_rate": None, "heart_rate": None, "hr_confidence": None, "br_confidence": None},
    "bureau": {"breathing_rate": 16.1, "heart_rate": 78, "hr_confidence": 0.85, "br_confidence": 0.87},
    "garage": {"breathing_rate": None, "heart_rate": None, "hr_confidence": None, "br_confidence": None},
    "all":    {"breathing_rate": 15.1, "heart_rate": 72, "hr_confidence": 0.88, "br_confidence": 0.91},
}

config = {
    "mqtt_enabled": True,
    "ha_enabled": True,
    "sensitivity": 0.7,
    "recording_enabled": False,
    "dark_mode": True,
    "language": "fr",
}

CSI_HISTORY = []
T = 0.0


def generate_csi_frame():
    global T
    T += 0.033
    n_subcarriers = 56
    n_antennas = 3
    amplitudes = []
    phases = []
    for ant in range(n_antennas):
        amps = []
        phs = []
        for sc in range(n_subcarriers):
            base = 0.5 + 0.3 * math.sin(T * 2.0 + sc * 0.1 + ant * 1.5)
            noise = random.gauss(0, 0.05)
            breath = 0.1 * math.sin(T * 1.0 + sc * 0.05)
            amps.append(base + noise + breath)
            phs.append(math.sin(T * 1.5 + sc * 0.2 + ant) * 0.5)
        amplitudes.append(amps)
        phases.append(phs)
    return {"timestamp": int(time.time() * 1000), "amplitude": amplitudes, "phase": phases}


def generate_vitals():
    br = 15.0 + 2.0 * math.sin(T * 0.3) + random.gauss(0, 0.3)
    hr = 72 + 5 * math.sin(T * 0.5 + 1) + random.gauss(0, 1)
    return {
        "breathing_rate": round(br, 1),
        "heart_rate": round(hr),
        "hr_confidence": round(0.85 + 0.1 * math.sin(T * 0.2) + random.gauss(0, 0.02), 2),
        "br_confidence": round(0.88 + 0.08 * math.sin(T * 0.25) + random.gauss(0, 0.02), 2),
    }


class SSEHandler:
    """Gère les connexions Server-Sent Events (fallback WebSocket)."""

    def __init__(self):
        self.clients = []
        self.running = True
        self._thread = threading.Thread(target=self._broadcast_loop, daemon=True)
        self._thread.start()

    def add_client(self, wfile):
        self.clients.append(wfile)

    def remove_client(self, wfile):
        if wfile in self.clients:
            self.clients.remove(wfile)

    def _broadcast_loop(self):
        while self.running:
            csi = generate_csi_frame()
            vitals = generate_vitals()
            payload = json.dumps({"type": "csi", "data": csi}) + "\n\n"
            payload2 = json.dumps({"type": "vitals", "data": vitals}) + "\n\n"
            dead = []
            for client in self.clients:
                try:
                    client.write(("data: " + payload).encode())
                    client.write(("data: " + payload2).encode())
                    client.flush()
                except Exception:
                    dead.append(client)
            for d in dead:
                self.remove_client(d)
            time.sleep(0.1)


sse_handler = SSEHandler()


class AetherisHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        ts = time.strftime("%H:%M:%S", time.localtime())
        print(f"  [{ts}] {args[0]} {args[1]} {args[2]}")

    def _send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_sse(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Connection", "keep-alive")
        self.end_headers()
        sse_handler.add_client(self.wfile)
        try:
            while True:
                time.sleep(1)
        except (BrokenPipeError, ConnectionResetError):
            sse_handler.remove_client(self.wfile)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        if path == "/api/v1/rooms":
            rooms_out = []
            for r in ROOMS:
                v = ROOM_VITALS.get(r["id"], {})
                rooms_out.append({
                    "id": r["id"],
                    "name": r["name"],
                    "status": r["status"],
                    "occupant_count": r["occupant_count"],
                    "breathing_rate": v.get("breathing_rate"),
                    "heart_rate": v.get("heart_rate"),
                    "last_updated": int(time.time() * 1000),
                })
            self._send_json(rooms_out)

        elif path.startswith("/api/v1/rooms/") and path.endswith("/vitals"):
            room_id = path.split("/")[4]
            vitals = ROOM_VITALS.get(room_id, ROOM_VITALS["all"])
            if room_id != "all" and vitals.get("breathing_rate") is None:
                self._send_json({"error": "room offline"}, status=503)
            else:
                self._send_json(vitals)

        elif path.startswith("/api/v1/rooms/") and path.endswith("/calibrate"):
            self._send_json({"progress": 100, "phase": "complete", "completed": True})

        elif path == "/api/v1/config":
            self._send_json(config)

        elif path == "/ws":
            self._send_sse()

        elif path == "/health" or path == "/api/v1/health":
            self._send_json({"status": "ok", "version": "1.3.0-mock", "uptime": int(time.time())})

        else:
            self._send_json({"error": "not found", "path": path}, status=404)

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        if path.startswith("/api/v1/rooms/") and path.endswith("/calibrate"):
            room_id = path.split("/")[4]
            duration = 3.0
            steps = 20
            for i in range(steps):
                prog = int((i + 1) / steps * 100)
                phase = "baseline" if prog < 40 else ("enroll" if prog < 70 else "optimize")
                time.sleep(duration / steps)
            for r in ROOMS:
                if r["id"] == room_id:
                    r["status"] = "online"
            self._send_json({"progress": 100, "phase": "complete", "completed": True})
        else:
            self._send_json({"error": "not found"}, status=404)

    def do_PUT(self):
        parsed = urlparse(self.path)
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length else b"{}"
        try:
            data = json.loads(body)
            config.update(data)
            self._send_json({"ok": True, "config": config})
        except json.JSONDecodeError:
            self._send_json({"error": "invalid json"}, status=400)


if __name__ == "__main__":
    print(f"\n  ╔══════════════════════════════════════╗")
    print(f"  ║      Aetheris Mock Server v1.3       ║")
    print(f"  ║                                      ║")
    print(f"  ║  API  → http://{HOST}:{PORT}/api/v1      ║")
    print(f"  ║  SSE  → http://{HOST}:{PORT}/ws          ║")
    print(f"  ║  Rooms → {len(ROOMS)} simulées              ║")
    print(f"  ║                                      ║")
    print(f"  ║  Quit → CTRL+C                       ║")
    print(f"  ╚══════════════════════════════════════╝\n")

    server = http.server.HTTPServer((HOST, PORT), AetherisHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Arrêt du serveur mock.")
        sse_handler.running = False
        server.shutdown()
