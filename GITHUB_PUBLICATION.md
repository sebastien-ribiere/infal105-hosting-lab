# Publication GitHub — vérifications avant mise en ligne

Ce support est autonome. **Ne pas le publier dans les dépôts du jeu réel GuildOps**, qui ont un autre périmètre.

Dépôt conseillé : `infal105-hosting-lab` (à créer sous le compte ou l'organisation choisi).

## Avant la première publication

- [ ] Choisir une licence pour le **code** et une politique de réutilisation pour les **supports pédagogiques**. Aucun choix de licence n'a été imposé ici.
- [ ] Vérifier que `.env`, `.local/`, fichiers SQL, données personnelles, captures et tokens sont absents.
- [ ] Vérifier les droits d'accès et la visibilité publique/privée souhaitée.
- [ ] Lancer `python -m unittest discover -s tests -v` et valider le workflow GitHub Actions.
- [ ] Sur un poste pédagogique, **exécuter réellement** Compose, Swarm, kind et la restauration PostgreSQL, conformément à `VALIDATION_ET_LIMITES.md`.
- [ ] Pour le cloud, obtenir les autorisations, quotas et un budget pédagogique ; ne pas inclure de clés d'accès dans le dépôt.

## Séparation recommandée

- GitHub : code source, manifests, scripts, cahier Markdown et, si souhaité, ses exports PDF/DOCX.
- Google Drive : point d'entrée depuis les supports INFAL105 figés (URL stable de l'archive).
- Jamais dans le dépôt étudiant : éléments de corrigé formateur ou identifiants de compte cloud.
