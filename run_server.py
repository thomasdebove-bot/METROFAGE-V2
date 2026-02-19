from __future__ import annotations

import os
import sys
import traceback
import webbrowser
from pathlib import Path

import uvicorn

LOG_FILE = Path.cwd() / "metrofage-error.log"


def _write_error_log(content: str) -> None:
    try:
        LOG_FILE.write_text(content, encoding="utf-8")
    except Exception:
        pass


def main() -> None:
    host = os.getenv("METROFAGE_HOST", "127.0.0.1")
    port = int(os.getenv("METROFAGE_PORT", "8090"))

    # Import direct de l'application ASGI pour éviter l'échec
    # d'import dynamique "app:app" dans l'exécutable PyInstaller.
    from app import app as asgi_app

    try:
        webbrowser.open(f"http://{host}:{port}")
    except Exception:
        pass

    uvicorn.run(asgi_app, host=host, port=port, reload=False, log_level="info")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        details = "\n".join(
            [
                "METROFAGE: démarrage impossible.",
                f"Erreur: {exc}",
                "",
                traceback.format_exc(),
            ]
        )
        print(details)
        _write_error_log(details)

        if sys.stdin is not None and sys.stdin.isatty():
            input("\nAppuyez sur Entrée pour fermer...")
        raise
