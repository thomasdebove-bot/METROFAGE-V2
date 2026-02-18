# METROFAGE-V2

## Générer automatiquement un exécutable Windows (.exe)

Le script `build-executable.ps1` prépare l'environnement, installe les dépendances, génère l'exécutable PyInstaller et crée un fichier de configuration runtime.

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
4. génère `dist\metrofage.runtime.json`

## Déploiement sur un autre poste

Copiez **tout le dossier `dist`** sur le poste cible, puis lancez :

```powershell
.\metrofage.exe
```

Aucune installation Python n'est nécessaire sur le poste cible.

## Configuration embarquée (sans variables d'environnement sur le poste cible)

Le fichier `dist\metrofage.runtime.json` est lu automatiquement au démarrage par `launcher.py`.

Vous pouvez générer ce fichier directement prérempli pendant le build :

```powershell
.\build-executable.ps1 -Clean \
  -MetronomeEntries "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Entries (Tasks & Memos).csv" \
  -MetronomeMeetings "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Meetings.csv" \
  -MetronomeCompanies "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Companies.csv" \
  -MetronomeProjects "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Projects.csv"
```

Paramètres utiles :

- `-Host` (défaut: `0.0.0.0`)
- `-Port` (défaut: `8090`)
- `-EnableReload` (désactivé par défaut)
- `-Metronome*` et `-Logo*` pour injecter les chemins de données/images dans le fichier runtime

## Notes

- L'exécutable inclut l'interpréteur Python et les dépendances applicatives.
- Pour une exécution réellement autonome, le poste cible doit toujours avoir accès aux fichiers de données référencés (CSV/images).
