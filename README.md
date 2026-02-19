# METROFAGE-V2

## Générer un `.exe` Windows avec les logos embarqués

### Option A (recommandée) : dossier `assets/`

1. Placez les logos dans `assets/` (à la racine du projet) avec ces noms exacts :
   - `Logo EIFFAGE.png`
   - `Carré eiffage.png`
   - `Carré eiffage 90.png`
   - `Logo TEMPO.png`
   - `Rythme.png`
   - `T logo.png`
   - `QR CODE.png`
2. Lancez :

```powershell
./build_exe.ps1 -ExeName Metrofage
```

### Option B : sans dossier `assets/`

Le script tente automatiquement de retrouver les logos via :
- le paramètre/fallback `C:\tempo-cr\assets`
- les variables d'environnement `METRONOME_LOGO_*`
- les chemins par défaut du projet (dont `C:\tempo-cr\...` et le partage réseau historique)

Vous pouvez forcer un dossier précis :

```powershell
./build_exe.ps1 -AssetsDir "C:\tempo-cr\assets" -ExeName Metrofage
```

## Exécution de l'application

- Double-cliquez `dist/Metrofage.exe`.
- L'exécutable démarre l'API sur `http://127.0.0.1:8090` et tente d'ouvrir le navigateur automatiquement.
- En cas d'erreur au démarrage, un fichier `metrofage-error.log` est écrit dans le dossier courant.

> Vous pouvez surcharger les chemins via les variables d'environnement `METRONOME_*` sur le poste cible.
