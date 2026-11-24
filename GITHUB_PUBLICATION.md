# Dépôt GitHub — maintenance et vérifications

Ce support est autonome. **Ne pas le publier dans les dépôts du jeu réel GuildOps**, qui ont un autre périmètre.

Dépôt étudiant : [https://github.com/sebastien-ribiere/infal105-hosting-lab](https://github.com/sebastien-ribiere/infal105-hosting-lab) (public).

## Avant les séances et chaque nouvelle version

- [ ] Choisir une licence pour le **code** et une politique de réutilisation pour les **supports pédagogiques**. Aucun choix de licence n'a été imposé ici.
- [ ] Vérifier que `.env`, `.local/`, fichiers SQL, données personnelles, captures et tokens sont absents.
- [ ] Vérifier que le dépôt reste accessible en lecture aux étudiants.
- [ ] Lancer `python -m unittest discover -s tests -v` et valider le workflow GitHub Actions.
- [ ] Sur un poste pédagogique, **exécuter réellement** Compose, Swarm, kind et la restauration PostgreSQL, conformément à `VALIDATION_ET_LIMITES.md`.
- [ ] Pour le cloud, obtenir les autorisations, quotas et un budget pédagogique ; ne pas inclure de clés d'accès dans le dépôt.

## Séparation recommandée

- GitHub : code source, manifests, scripts, cahier Markdown et, si souhaité, ses exports PDF/DOCX.
- Supports INFAL105 : leur lien vers le dépôt GitHub est le point d’entrée étudiant. Les archives Drive ne sont pas nécessaires aux exercices.
- Jamais dans le dépôt étudiant : éléments de corrigé formateur ou identifiants de compte cloud.
