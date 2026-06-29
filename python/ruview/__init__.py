#!/usr/bin/env python3
"""Chargeur de localisation RuView.

Usage:
    from ruview.i18n import t, i18n

    # Utilisation
    print(t("sensor.presence"))
    print(t("alerts.fall_detected", room="Salon"))

    # Changer de langue
    i18n.set_lang("fr")
"""
