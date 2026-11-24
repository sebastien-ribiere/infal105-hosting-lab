# Recette technique de l’archive — 24 novembre 2026

Ce fichier documente **ce qui a été effectivement vérifié**. Il n'atteste pas qu'une session a été menée de bout en bout sur les postes CESI.

## Vérifications effectuées

- Kit initial vérifié depuis son archive source avant publication sur GitHub ; le laboratoire publié dérive de cette version, et non d’une reconstruction.
- Contrôle de syntaxe du code Python (`py_compile`), des scripts Bash (`bash -n`), des YAML via PyYAML, de la grille CSV et de l'arborescence.
- Tests HTTP locaux via `python -m unittest discover -s tests -v` : `/healthz`, 404, JSON invalide, score invalide, nom vide et `/readyz` indisponible si la DB simulée est absente.
- `scripts/verify.sh` testé contre un serveur HTTP simulant les réponses attendues ; modes complet et `HEALTH_ONLY` valides.
- `scripts/backup_restore.sh` testé avec un **faux client Docker** : enchaînement des commandes et garde anti-écrasement contrôlés. Aucune vraie DB n'a été restaurée par cette simulation.
- Analyse structurelle des fichiers : même image API et PostgreSQL entre Compose, Swarm et Kubernetes, labels/selectors cohérents, PVC raccordé à PostgreSQL, API liée au loopback en mode Compose.
- Contrôle du fil pédagogique : tous les TP00 à TP08 sont couverts ; TP06 est optionnel et remplace du temps de TP05. 3 × 7 heures = 6 heures d'apports / 15 heures de pratiques.

## Non vérifié ici — recette indispensable avant diffusion en classe

1. Construire réellement le conteneur API et lancer l'API + PostgreSQL dans Docker Compose, en testant la persistance après `down` puis `up`.
2. Exécuter Docker Swarm sur un manager mono-nœud et vérifier le secret, le démarrage de la DB, les répliques, la montée en charge, le rollback et la libération du port 8080.
3. Démarrer kind avec stockage par défaut, charger l'image et vérifier les probes, PVC, `port-forward` et remplacement des Pods.
4. Tester `backup_restore.sh` et `backup_restore.ps1` sur une vraie DB PostgreSQL puis comparer les données sources/restaurées.
5. Tester les scripts `.ps1` dans PowerShell 5.1 et 7 avec Docker Desktop si c'est le poste cible.
6. Obtenir un compte cloud pédagogique autorisé : tester droits/quota, le parcours réel AWS ou Azure et la suppression des ressources. Aucune ressource cloud n'a été créée au cours de cet audit.

**Décision :** paquet structurellement cohérent et documenté, **non certifié en conditions CESI** tant que les six contrôles ci-dessus n'ont pas été exécutés sur les environnements de formation.
