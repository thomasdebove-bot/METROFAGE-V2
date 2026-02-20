# METROFAGE-V2

## Generer un `.exe` Windows avec les logos embarques

### Option A (recommandee) : dossier `assets/`

1. Placez les logos dans `assets/` (a la racine du projet) avec ces noms :
   - `Logo EIFFAGE.png`
   - `Carre eiffage.png` (ou `Carré eiffage.png`)
   - `Carre eiffage 90.png` (ou `Carré eiffage 90.png`)
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
- `C:\tempo-cr\assets`
- les variables d'environnement `METRONOME_LOGO_*`
- le dossier du script

Vous pouvez forcer un dossier precis :

```powershell
./build_exe.ps1 -AssetsDir "C:\tempo-cr\assets" -ExeName Metrofage
```

## Execution de l'application

- Double-cliquez `dist/Metrofage.exe`.
- L'executable demarre l'API sur `http://127.0.0.1:8090` et tente d'ouvrir le navigateur.
- En cas d'erreur au demarrage, un fichier `metrofage-error.log` est ecrit dans le dossier courant.

- Les images dans le HTML acceptent maintenant: `http(s)`, `file://` et chemins locaux Windows (elles sont converties en data URI).


## Depannage

Si vous voyez `Could not import module "app"`, recompilez avec la version la plus recente de `run_server.py` puis relancez `build_exe.ps1`.

- Si les images des fiches (taches/memos/projets) ne s'affichent pas sur un autre PC, definissez le dossier racine des images:

```powershell
$env:METRONOME_IMAGES_ROOT = "C:\tempo-cr"
```

Le moteur cherchera alors les images par nom de fichier (recherche recursive) dans ce dossier en plus des chemins habituels.

- Par defaut, le resolveur cherche aussi dans le partage reseau: `\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Content`.
- Vous pouvez surcharger ce chemin avec la variable d'environnement `METRONOME_CONTENT`.

- Le resolveur gere aussi les noms avec accents/encodage (ex: `Carré` / `CarrÃ©`) et les chemins contenant `?` ou `#` (exports CSV).
