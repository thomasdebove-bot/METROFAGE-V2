"""Point d'entrée exécutable pour METROFAGE-V2."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any, Dict

import uvicorn


def _runtime_dir() -> Path:
    """Retourne le dossier de runtime (dossier de l'exe en mode PyInstaller)."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def _runtime_config_candidates() -> list[Path]:
    """Fichiers de config supportés (nouveau + compatibilité)."""
    runtime_dir = _runtime_dir()

    app_name = Path(sys.executable).stem if getattr(sys, "frozen", False) else "metrofage"
    return [
        runtime_dir / f"{app_name}.runtime.json",
        runtime_dir / "metrofage.runtime.json",
    ]


def _load_runtime_config() -> Dict[str, Any]:
    """Charge la configuration runtime facultative."""
    for config_path in _runtime_config_candidates():
        if not config_path.exists():
            continue
        try:
            return json.loads(config_path.read_text(encoding="utf-8"))
        except Exception:
            continue
    return {}


def _apply_data_env(config: Dict[str, Any]) -> None:
    """Injecte les variables METRONOME_* avant l'import de l'application."""
    env_config = config.get("metronome_env", {})
    if not isinstance(env_config, dict):
        return

    for key, value in env_config.items():
        if isinstance(key, str) and key.startswith("METRONOME_") and value is not None and str(value).strip() != "":
            os.environ[key] = str(value)


def _read_runtime_options(config: Dict[str, Any]) -> tuple[str, int, bool]:
    """Construit les options host/port/reload avec priorité env > fichier > défauts."""
    metrofage_cfg = config.get("metrofage", {}) if isinstance(config.get("metrofage"), dict) else {}

    host = os.getenv("METROFAGE_HOST") or str(metrofage_cfg.get("host", "0.0.0.0"))

    raw_port = os.getenv("METROFAGE_PORT") or metrofage_cfg.get("port", 8090)
    try:
        port = int(raw_port)
    except Exception:
        port = 8090

    raw_reload = os.getenv("METROFAGE_RELOAD")
    if raw_reload is None:
        raw_reload = metrofage_cfg.get("reload", False)

    if isinstance(raw_reload, bool):
        reload_enabled = raw_reload
    else:
        reload_enabled = str(raw_reload).strip().lower() in {"1", "true", "yes", "on"}

    return host, port, reload_enabled


def main() -> None:
    """Lance le serveur FastAPI avec config locale optionnelle + variables d'environnement."""
    config = _load_runtime_config()
    _apply_data_env(config)

    from app import app  # import tardif: les env METRONOME_* doivent déjà être appliquées

    host, port, reload_enabled = _read_runtime_options(config)
    uvicorn.run(app, host=host, port=port, reload=reload_enabled)


if __name__ == "__main__":
    main()
