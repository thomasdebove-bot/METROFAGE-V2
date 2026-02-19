# METROFAGE-V2

## Générer un `.exe` Windows avec les logos embarqués

1. Placez les logos dans le dossier `assets/` (à la racine du projet) avec ces noms exacts:
   - `Logo EIFFAGE.png`
   - `Carré eiffage.png`
   - `Carré eiffage 90.png`
   - `Logo TEMPO.png`
   - `Rythme.png`
   - `T logo.png`
   - `QR CODE.png`
2. Lancez PowerShell puis exécutez:

```powershell
./build_exe.ps1 -ExeName Metrofage
```

Le script installe `pyinstaller`, construit `dist/Metrofage.exe` et embarque les logos.

## Exécution de l'application

- Double-cliquez `dist/Metrofage.exe`.
- L'exécutable démarre l'API sur `http://127.0.0.1:8090` et tente d'ouvrir le navigateur automatiquement.
- En cas d'erreur au démarrage, un fichier `metrofage-error.log` est écrit dans le dossier courant.

> Vous pouvez surcharger les chemins via les variables d'environnement `METRONOME_*` sur le poste cible.
