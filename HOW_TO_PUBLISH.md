# Publish this starter on GitHub

**Assumption:** your GitHub username is `Deluxe0111`.

1. Visit <https://github.com/new>.
2. Owner: `Deluxe0111` | Repository name: **`mega-evolution-gen3`** | Description: `Standalone Mega Evolution mod for Gen1Recomp Generation 3`.
3. Choose **Public** and leave **Add a README**, **.gitignore** and **licence** unchecked (the starter already has the first two; artwork is separately credited).
4. Create the repository.
5. In PowerShell or Git Bash **inside the extracted starter project directory**, run:

```bash
git init
git add .
git commit -m "Initial Mega Evolution Gen 3 foundation"
git branch -M main
git remote add origin https://github.com/Deluxe0111/mega-evolution-gen3.git
git push -u origin main
```

If you'd rather use GitHub Desktop, choose **File → Add local repository → Create a repository here** for the extracted folder, commit, then **Publish repository**.

6. Once published, add assets by running `1_IMPORT_EBDX_ASSETS.bat` (or copying the existing extractor output). Review `CREDITS.md` and the original EBDX credits before committing the art.

Do not assume a GitHub Release exists after the initial push. The starter is only a project foundation.
