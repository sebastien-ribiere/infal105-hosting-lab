# INFAL105 — GuildOps Hosting Lab

## Ressources pour les étudiants

- **[Cahier de TP au format PDF](docs/INFAL105_Cahier_TP_etudiants.pdf)** — à lire pendant les trois journées. Liens directs vers les notions utiles.
- **[Version Markdown](TP_ETUDIANTS.md)** — accessible et consultable directement dans GitHub.
- **[Version DOCX](docs/INFAL105_Cahier_TP_etudiants.docx)** — édition et adaptation pédagogique.
- **Code et fichiers techniques** — `app/`, `Dockerfile`, `compose.yaml`, `swarm/`, `k8s/`, `cloud/`, `scripts/` et `tests/`.

Ce dépôt est **indépendant du projet de jeu GuildOps**. Il n'intègre pas les sources Godot/C# du jeu ; le scénario métier du tournoi est fictif.

### Pour commencer

1. Lire le [cahier de TP](TP_ETUDIANTS.md) puis les ressources indiquées au début du TP.
2. Travailler depuis la racine du projet ; ne jamais committer `.env`, `.local/` ni un secret réel.
3. Ne pas déployer dans le cloud sans autorisation du formateur, quotas connus et plan de suppression.
4. Le dossier `VALIDATION_ET_LIMITES.md` rappelle les tests non exécutés de bout en bout.


Ce projet est un **support de TP autonome** d'hébergement, et **non le jeu GuildOps**. Le véritable GuildOps est une application Godot/C# locale, hors ligne, préparée pour INFAL114. Le laboratoire simule une API HTTP qui enregistre des joueurs fictifs dans PostgreSQL. Les métriques de charge, de disponibilité et de coût des slides sont des hypothèses pédagogiques, pas des résultats de ce prototype.

**Objectif :** pratiquer Docker Compose, sécurité élémentaire, Swarm, kind/Kubernetes, et documenter un déploiement cloud sous le contrôle d'un compte CESI autorisé.

**Point de départ étudiant : [`TP_ETUDIANTS.md`](TP_ETUDIANTS.md).** Les manipulations ci-dessous sont des aide-mémoire ; les critères de réussite, preuves à rendre, erreurs attendues et consignes de sécurité sont détaillés dans le cahier de TP.

## Prérequis

Docker Engine, plugin Compose (`docker compose version`), Git facultatif, `curl` et Bash, ou PowerShell pour les tests HTTP (`scripts/verify.ps1`) ; pour le TP Kubernetes : `kind` et `kubectl` installés. Installer depuis les sources officielles de son OS et vérifier le daemon. Ne jamais utiliser de carte bancaire personnelle pour les TP cloud.

## 1. Docker Compose

Depuis **la racine** de l'archive :

```bash
cp .env.example .env
docker compose up -d --build
docker compose ps
./scripts/verify.sh
```

L'API est accessible sur http://localhost:8080. `/healthz` signale la vie du processus, `/readyz` teste réellement PostgreSQL, `/players` lit ou ajoute des joueurs fictifs. `POST /players` attend `{ "name": "Ada", "score": 25 }` (voir `scripts/verify.sh`).

Preuve de persistance : lancer le script, `docker compose down`, `docker compose up -d`, puis `curl http://localhost:8080/players`. Le volume **nommé** reste présent après `down`. **Ne pas lancer `docker compose down -v` sur une donnée qu'on souhaite conserver** : cette option détruit aussi les volumes du projet.

Nettoyage courant : `docker compose down`. Nettoyage intégral volontaire d'un laboratoire **jetable** : `docker compose down -v` (données perdues).

## 2. Docker Swarm (TP jetable)

Cette démonstration fonctionne sur un seul nœud mais ne fournit pas de haute disponibilité. Elle conserve **une seule base PostgreSQL**, pour pouvoir analyser les points uniques de panne.

```bash
# Sur un poste dédié : conserver l'image locale, arrêter Compose et libérer :8080.
docker compose down
# L'image locale doit exister sur le nœud manager avant de déployer.
docker image inspect guildops-hosting-lab:local
mkdir -p .local
printf 'lab-only-change-me' > .local/db_password
docker swarm init                  # seulement si le poste n'est pas déjà membre d'un swarm
docker stack config -c swarm/stack.yaml  # valide le stack et le chemin du secret
docker stack deploy --resolve-image never -c swarm/stack.yaml guildops
docker stack services guildops
docker service ps guildops_api
docker service scale guildops_api=3
docker service update --env-add LAB_RELEASE=v2 guildops_api
docker service rollback guildops_api
```

Sur plusieurs nœuds, **ne pas utiliser** `--resolve-image never` avec une image locale : il faut pousser l'image dans un **registre accessible à tous**, puis remplacer `image: guildops-hosting-lab:local` par sa référence publiée. `docker stack deploy` **ne construit pas** l'image. Si le service ne démarre pas sur un autre nœud, inspecter sa capacité à résoudre/puller l'image. La base est volontairement mono-instance.

Nettoyage **avant kind ou retour à Compose** : `docker stack rm guildops` ; attendre la disparition des tâches (`docker service ls`) et vérifier que le port 8080 est libre. Ne quitter Swarm (`docker swarm leave --force`) que si vous l'avez créé pour ce TP et que personne d'autre n'en dépend. Garder les données de labo ou supprimer explicitement les volumes jetables.

## 3. Kubernetes / kind

Depuis la racine, sur un cluster local jetable, après arrêt du stack Swarm et libération du port local 8080 :

```bash
kind create cluster --name guildops-lab
docker build -t guildops-hosting-lab:local .
kind load docker-image guildops-hosting-lab:local --name guildops-lab
kubectl apply -f k8s/00-namespace.yaml
# Secret de démonstration uniquement ; ne pas le publier dans un dépôt public :
kubectl -n guildops-lab create secret generic guildops-db --from-literal=password='lab-only-change-me'
kubectl apply -f k8s/
kubectl -n guildops-lab get deployments,pods,services,pvc
kubectl -n guildops-lab port-forward svc/guildops-api 8080:80
```

Dans un second terminal, `./scripts/verify.sh` (PowerShell : `./scripts/verify.ps1`). Pour observer le remplacement d'un Pod API : `kubectl -n guildops-lab delete pod -l app=guildops-api` puis regarder les nouveaux Pods. **Le Kubernetes de ce TP n'apporte pas la haute disponibilité à PostgreSQL.** En production, utiliser un service DB managé ou une architecture de réplication adaptée, avec tests de restauration. Un Secret Kubernetes doit aussi faire l'objet d'une vraie politique de protection.

Nettoyage : `kind delete cluster --name guildops-lab` (toutes les ressources du cluster sont perdues).

## 4. TP08 — sauvegarde et restauration sans toucher aux données sources

Le TP08 doit **restaurer dans une base de laboratoire distincte**, sans effacer `guildops`. Après avoir libéré le port 8080 et relancé `docker compose up -d --build`, créer au moins un joueur fictif puis lancer :

```bash
./scripts/backup_restore.sh
```

Sous PowerShell : `./scripts/backup_restore.ps1`. Le script crée `.local/backup.sql` (à ne pas committer), puis restaure vers `guildops_restore` et compare les nombres de lignes. Il échoue si la base de restauration existe déjà, afin d'éviter un écrasement silencieux. Une sauvegarde **testée** n'est pas une garantie de RPO/RTO ; noter les durées effectivement mesurées.

## 5. Cloud (parcours guidé, pas script auto-provisionnant)

Ne rien créer sans valider les droits, quotas, région et coût du compte pédagogique CESI. D'abord comparer registre / service conteneur / réseau / identité / DB / sauvegarde entre les offres. Si autorisé : publier une image taguée dans un registre approuvé, déployer un petit service HTTP avec ressources minimales, relever URL et journaux, puis **supprimer** toutes les ressources. Les services ECR/ECS/RDS, ACR/Container Apps et autres ne sont pas nécessairement disponibles dans tous les labs.

Si l'accès cloud ne permet pas la DB, tester uniquement `/healthz` et signaler explicitement que `/readyz` nécessite la connexion PostgreSQL. Si l'accès cloud n'est pas autorisé, utiliser le cluster local et livrer un schéma comparatif : cela ne vaut pas une preuve de déploiement cloud.

## Preuves pédagogiques à collecter

1. Schéma des flux et du stockage (Compose, Swarm et Kubernetes).
2. Traces des commandes et appels HTTP avant/après recréation.
3. Journal de modification/rollback, erreurs et points uniques de panne.
4. Liste des ressources cloud et des droits nécessaires, budget estimé ou information indisponible.
5. Procédure de suppression et de restauration, avec limites RPO/RTO explicites.

Ces exercices sont volontairement indépendants des statistiques et du moteur de GuildOps ; ne les associer au jeu réel qu'en tant que **scénario d'architecture**.

## Documents complémentaires

- `TP_ETUDIANTS.md` : **cahier de TP principal**, avec étapes, preuves et critères de réussite, TP00 à TP08.
- `scripts/verify.sh` / `scripts/verify.ps1` : tests HTTP avec attente de disponibilité, en mode complet ou `HEALTH_ONLY` sans DB.
- `scripts/backup_restore.sh` / `scripts/backup_restore.ps1` : sauvegarde et restauration de démonstration dans une autre base, avec contrôle des décomptes.
- `tests/test_http_api.py` : tests HTTP unitaires/de contrat en mode sans PostgreSQL (`python -m unittest discover -s tests -v`).
- `DEROULE_3_JOURS.md` : timing détaillé compatible avec l'objectif 30 % théorie / 70 % pratique.
- `cloud/DEPLIEMENT_GUIDE.md` : parcours cloud contrôlé (AWS/Azure/variante locale), sans ressource créée automatiquement.
- `cloud/COMPARATIF_OFFRES.csv` : grille de comparaison à renseigner avec des preuves datées.

Sous Windows PowerShell : `Copy-Item .env.example .env` remplace `cp .env.example .env` ; `./scripts/verify.ps1` vérifie les endpoints HTTP. Pour les commandes Bash/Linux (Swarm et kind), privilégier un terminal WSL2/Ubuntu avec le même moteur Docker. Le script PowerShell de sauvegarde fonctionne aussi avec Docker Desktop en mode conteneurs Linux.
