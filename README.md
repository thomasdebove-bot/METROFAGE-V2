# METROFAGE-V2

## Générer automatiquement un exécutable Windows (.exe)

Le script `build-executable.ps1` prépare l'environnement, installe les dépendances, génère l'exécutable PyInstaller et crée la configuration runtime.

## Prérequis

- Windows + PowerShell
- Python installé et disponible dans le `PATH`

## Procédure (automatique)

Depuis le dossier du projet :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build-executable.ps1 -Clean
```

Cette commande :

1. crée `.venv-build`
2. installe `fastapi`, `uvicorn`, `pandas`, `openpyxl`, `pyinstaller`
3. construit l'exécutable (`dist\metrofage.exe`)
4. génère `dist\metrofage.runtime.json` (et aussi `dist\<AppName>.runtime.json`)

## Déploiement sur un autre poste

Copiez **tout le dossier `dist`** sur le poste cible, puis lancez :

```powershell
.\metrofage.exe
```

Aucune installation Python n'est nécessaire sur le poste cible.

## Configuration préremplie pendant le build

Le fichier `*.runtime.json` est lu automatiquement au démarrage par `launcher.py`.

Exemple de build avec chemins de données intégrés :

```powershell
.\build-executable.ps1 -Clean `
  -MetronomeEntries "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Entries (Tasks & Memos).csv" `
  -MetronomeMeetings "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Meetings.csv" `
  -MetronomeCompanies "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Companies.csv" `
  -MetronomeProjects "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Projects.csv"
```

> En PowerShell, la continuation de ligne se fait avec le caractère backtick `` ` `` (et non `\`).

Paramètres utiles :

- `-PythonExe` pour cibler un Python précis
- `-AppName` pour nommer l'exécutable
- `-Host` (défaut: `0.0.0.0`)
- `-Port` (défaut: `8090`)
- `-EnableReload` (désactivé par défaut)
- `-Metronome*` et `-Logo*` pour injecter les chemins de données/images

## Notes importantes

- L'exécutable inclut l'interpréteur Python et les dépendances applicatives.
- Le poste cible doit tout de même avoir accès aux fichiers CSV/images référencés (réseau UNC ou copie locale).
