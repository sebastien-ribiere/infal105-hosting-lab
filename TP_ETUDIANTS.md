# INFAL105 — Cahier de travaux pratiques

**GuildOps Hosting Lab | Version étudiant | 24 novembre 2026**

**Support de cours :** *Stratégie d'hébergement d'un applicatif* · 3 jours, 21 h.

Ce laboratoire utilise une **API Web de test indépendante** du jeu Godot/C# hors ligne GuildOps. Tous les noms, scores, charges et coûts du scénario sont fictifs. Le but est de produire des **preuves de fonctionnement et de décision**, pas de publier le véritable jeu.

**Sécurité des séances :** aucun compte bancaire personnel, aucune donnée réelle, aucun secret dans un dépôt ou une capture. Ne déployer dans le cloud qu'après validation des droits, de la région et du coût par le formateur. Les images, clusters et bases de données de ce kit sont **jetables**. Tous les tests destructifs se font exclusivement sur ce laboratoire.

## Comment utiliser ce cahier

Pour chaque TP, le parcours est le même : **repérer les fichiers → lire la notion utile → prédire le résultat → exécuter → conserver une preuve**. Les commandes servent à vérifier une hypothèse. Une sortie de terminal, sans explication de ce qu'elle prouve, n'est pas un livrable suffisant.

**Ressources de départ**

- [Dépôt GuildOps Hosting Lab sur GitHub](https://github.com/sebastien-ribiere/infal105-hosting-lab) : code, manifestes, scripts et versions PDF/DOCX du cahier.
- Les liens vers **Docker, Kubernetes, PostgreSQL, AWS et Azure** sont fournis au début du TP concerné. Ils pointent vers la documentation des éditeurs, pas vers des tutoriels aléatoires.
- Les noms de fichiers cités dans les exercices sont les **chemins du dépôt GitHub** : ils sont consultables directement dans l’arborescence du projet.

**Avant de demander de l'aide :** relever la commande, le message d'erreur complet, l'environnement actif et la dernière action réussie.

## Démarrage et organisation

1. Récupérer le dépôt : `git clone https://github.com/sebastien-ribiere/infal105-hosting-lab.git` puis `cd infal105-hosting-lab`. Sans Git : sur GitHub, choisir **Code → Download ZIP**, puis extraire le ZIP. Vérifier la présence de `compose.yaml`, `Dockerfile`, `app/`, `scripts/` et `k8s/`.
2. Travailler **en binôme**. Conserver dans un dossier séparé du dépôt les commandes, résultats, captures filtrées et décisions. Le fichier `.env` et `.local/` ne doivent jamais être remis.
3. Utiliser un terminal Bash Linux/WSL2 pour les commandes Bash. Avec PowerShell : `Copy-Item .env.example .env`, puis `./scripts/verify.ps1` pour les tests HTTP ; la variante de restauration PowerShell est également fournie. Si l'environnement est incompatible avec Swarm ou kind, choisir le **plan B validé par le formateur**.
4. Ne pas démarrer **Compose**, **Swarm** et le `port-forward` Kubernetes sur le port 8080 en parallèle. Terminer un environnement avant le suivant.

### Parcours, durée et livrables

- **J1 · TP00 — 20 min :** versions et démon Docker ; premier conteneur.
- **J1 · TP01 — 120 min :** Compose, requêtes HTTP et persistance après recréation.
- **J1 · TP02 — 35 min :** protections vérifiées et limites documentées.
- **J1 · TP03 — 135 min :** Swarm, répliques, mise à jour et rollback.
- **J1 · bilan — 10 min :** résultats et anomalies.
- **J2 · TP04 — 165 min :** kind, objets K8s, observation du remplacement de Pod.
- **J2 · TP05 — 115 min :** autorisations, budget et début de déploiement cloud.
- **J2 · bilan — 20 min :** distinguer hypothèses et mesures.
- **J3 · TP05 — 55 min :** terminer ou documenter l'alternative cloud, nettoyer.
- **J3 · TP07 — 65 min :** inventaire d'exploitation et préparation de l'IaC.
- **J3 · TP08 — 60 min :** sauvegarde, restauration isolée, preuves.
- **J3 · dossier et défense — 100 min :** recommandation, matrice et ADR.

Ces **900 min de TP** s'ajoutent à 360 min d'apports guidés. **TP06 est optionnel** : à substituer à une partie de TP05 si les quotas et le temps le permettent, pas à ajouter automatiquement au calendrier.

## J1 · TP00 — préparer l'atelier (20 min)

**Pour préparer le TP**

- **Dans le kit :** `.env.example`, `README.md`, `Dockerfile`. On repère les fichiers avant de démarrer.
- **À consulter :** [Installer Docker](https://docs.docker.com/get-started/get-docker/) et [installer Compose](https://docs.docker.com/compose/install/).
- **Point à comprendre :** le client Docker communique avec un moteur ; `docker version` vérifie les deux côtés.


**Question :** le poste peut-il exécuter une image puis la nettoyer ?

```bash
docker version
docker compose version
docker info
docker run --rm hello-world
```

Vérifier également que `curl` et Docker peuvent accéder aux images nécessaires. Noter la version du moteur et le mode Docker Desktop/WSL2 si applicable. **Critère :** le moteur exécute puis supprime un conteneur sans échec. Si le démon Docker est inaccessible ou que l'image ne se télécharge pas : relever le message, travailler sur un poste prêt et noter que le prérequis n'est pas acquis localement.

## J1 · TP01 — construire et vérifier Compose (90 + 30 min)

**Pour préparer le TP**

- **Dans le kit :** `Dockerfile` → `compose.yaml` → `.env.example` → `app/server.py` → `scripts/verify.sh` (ou `.ps1`).
- **À consulter :** [Docker Compose : premiers pas](https://docs.docker.com/compose/gettingstarted/) et [volumes Docker](https://docs.docker.com/engine/storage/volumes/).
- **Point à comprendre :** distinguer image, conteneur, réseau et volume ; relever ce qui survit à `docker compose down`.


**Question :** l'API et PostgreSQL utilisent-ils le réseau et le stockage prévus ?

1. Lire `Dockerfile`, `compose.yaml` et `.env.example`. Dessiner client → API → DB, ports publiés et volume. La DB ne doit pas être exposée à l'hôte.
2. Démarrer :

```bash
cp .env.example .env
docker compose config
docker compose up -d --build
docker compose ps
docker compose logs --tail=40 api postgres
./scripts/verify.sh
```

3. Expliquer la différence entre `/healthz` (processus) et `/readyz` (DB réellement joignable). `POST /players` crée un joueur fictif ; `GET /players` en affiche au plus 30.
4. **Persistance, 30 min :** noter un joueur présent, exécuter `docker compose down` puis `docker compose up -d` et refaire `GET /players`. `docker compose down` conserve le volume, tandis que **`down -v` le détruit**. Ne jamais utiliser cette option sur des données à conserver.

**Preuves :** schéma, `docker compose ps`, réponses HTTP et même ID de joueur avant/après recréation. **Critère :** API et DB prêtes, écriture et lecture réussies, joueur conservé après recréation. Un conteneur qui apparaît « Up » ne suffit pas.

## J1 · TP02 — durcissement de base (35 min)

**Pour préparer le TP**

- **Dans le kit :** `Dockerfile` et `compose.yaml` ; repérer `USER`, `read_only`, `cap_drop` et les ports.
- **À consulter :** [Bonnes pratiques de construction](https://docs.docker.com/build/building/best-practices/) et [sécurité du moteur Docker](https://docs.docker.com/engine/security/).
- **Point à comprendre :** une protection doit être **configurée et vérifiée**, pas seulement mentionnée.


**Question :** quelles protections sont configurées et lesquelles manquent ?

```bash
docker image inspect guildops-hosting-lab:local --format '{{.Config.User}}'
docker compose ps
docker compose config
```

Chercher le `USER` non-root de l'API, les capacités supprimées, le système de fichiers en lecture seule, le port API lié à `127.0.0.1`, l'absence de port PostgreSQL publié et le réseau interne `data`. Identifier aussi **une limite** : mot de passe démo en `.env`, base mono-instance, image non vérifiée par un scanner, absence de TLS du laboratoire local. Les réglages du TP ne rendent pas l'application prête pour une production.

**Preuve :** tableau « protection / observation / limite » et logs exempts de mot de passe. **Critère :** au moins trois contrôles prouvés et une limite documentée.

## J1 · TP03 — Swarm, mise à jour et rollback (90 + 45 min)

**Pour préparer le TP**

- **Dans le kit :** `swarm/stack.yaml`, `Dockerfile`, `scripts/verify.sh` et `README.md` (section Swarm).
- **À consulter :** [Démarrer avec Swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/) et [mises à jour de service](https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/).
- **Point à comprendre :** un *service* déclare un état attendu ; les *tasks* et conteneurs matérialisent cet état. Trois répliques sur un seul hôte ne créent pas une HA.


**Attention à la transition :** garder l'image construite mais **arrêter Compose** avant Swarm pour libérer le port 8080. Travailler sur un Swarm personnel au laboratoire, jamais sur un cluster partagé sans accord.

```bash
docker compose down
docker image inspect guildops-hosting-lab:local
mkdir -p .local
printf 'lab-only-change-me' > .local/db_password
docker swarm init
# Si le moteur est déjà membre d'un Swarm pédagogique autorisé, ne pas réinitialiser.
docker stack config -c swarm/stack.yaml
docker stack deploy --resolve-image never -c swarm/stack.yaml guildops
docker stack services guildops
docker service ps guildops_api
```

Sur Docker Desktop ou un poste à plusieurs interfaces, `docker swarm init` peut réclamer `--advertise-addr` ; demander quelle interface du **poste de laboratoire** convient. `--resolve-image never` ne convient qu'au cas **mono-nœud avec image locale déjà construite**. Pour plusieurs nœuds, utiliser un registre que tous peuvent joindre et retirer cette option. Si la commande `stack config` signale un fichier secret absent, vérifier `.local/db_password` et le chemin relatif à `swarm/stack.yaml`.

La base du stack Swarm utilise **un autre volume** que Compose : les données créées dans TP01 ne migrent pas automatiquement. Après déploiement, vérifier l'API (`./scripts/verify.sh`) puis pratiquer :

```bash
docker service scale guildops_api=3
docker service ps guildops_api
docker service update --env-add LAB_RELEASE=v2 guildops_api
curl -s http://127.0.0.1:8080/healthz
docker service rollback guildops_api
docker service ps guildops_api
```

Attendre la fin de chaque mise à jour avant de mesurer. **Critère :** nombre de tâches attendu et observation d'une réponse `release` cohérente avant/après rollback. Faire apparaître les **SPOF** (un seul hôte, une DB). La réplication d'API sur un manager unique n'est pas de la HA.

**Nettoyage avant J2 :** `docker stack rm guildops`, attendre la fin des tâches avec `docker service ls`, confirmer que le port 8080 est libre. Ne quitter Swarm que si vous l'avez créé et que personne d'autre ne l'utilise. Les volumes Swarm peuvent survivre au retrait d'un stack : les identifier et décider explicitement de leur conservation/suppression.

## J2 · TP04 — kind / Kubernetes (110 + 55 min)

**Pour préparer le TP**

- **Dans le kit :** `k8s/00-namespace.yaml` à `k8s/03-api.yaml`, puis `scripts/verify.sh`.
- **À consulter :** [kind : guide de démarrage](https://kind.sigs.k8s.io/docs/user/quick-start/), [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) et [Service](https://kubernetes.io/docs/concepts/services-networking/service/).
- **Point à comprendre :** un Service sélectionne des Pods par labels ; un Deployment maintient le nombre de Pods attendu.


**Question :** comment le plan de contrôle recrée-t-il un Pod, et qu'est-ce qui reste vulnérable ?

```bash
kind create cluster --name guildops-lab
docker build -t guildops-hosting-lab:local .
kind load docker-image guildops-hosting-lab:local --name guildops-lab
kubectl apply -f k8s/00-namespace.yaml
kubectl -n guildops-lab create secret generic guildops-db --from-literal=password='lab-only-change-me'
kubectl apply -f k8s/
kubectl -n guildops-lab rollout status deployment/postgres --timeout=180s
kubectl -n guildops-lab rollout status deployment/guildops-api --timeout=180s
kubectl -n guildops-lab get deployments,replicasets,pods,services,pvc -o wide
kubectl -n guildops-lab port-forward svc/guildops-api 8080:80
```

Laisser le `port-forward` actif dans son terminal ; dans un second, lancer `./scripts/verify.sh` (PowerShell : `./scripts/verify.ps1`). Observer les labels et selectors de Service, ConfigMap, Secret, PVC, Deployment, les deux Pods API et la DB mono-instance.

```bash
kubectl -n guildops-lab delete pod -l app=guildops-api
kubectl -n guildops-lab get pods -w
```

**Preuves :** état avant/après et schéma Services/Pods/volume. **Critère :** API disponible après recréation du Pod et distinction entre remplacement d'un Pod, sauvegarde des données et haute disponibilité. Nettoyer le cluster uniquement **après les preuves** : `kind delete cluster --name guildops-lab` (destructif pour ce cluster jetable).

## J2/J3 · TP05 — droits, registre et service cloud (35 + 80 + 55 min)

**Pour préparer le TP**

- **Dans le kit :** `cloud/DEPLIEMENT_GUIDE.md` et `cloud/COMPARATIF_OFFRES.csv`.
- **À consulter selon les droits :** [AWS ECS/Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/getting-started-fargate.html) ou [Azure Container Apps](https://learn.microsoft.com/fr-fr/azure/container-apps/get-started).
- **Point à comprendre :** une architecture plausible n'est pas une ressource autorisée. Vérifier **droits, quotas, région et coûts** avant toute création.


**Question :** le cloud pédagogique autorise-t-il réellement cette architecture ?

1. **Avant toute création :** compte CESI autorisé, responsable de nettoyage, quotas, crédits, durée, région, rôles IAM et garde-fous de sécurité ; consigner les informations indisponibles.
2. Compléter `cloud/COMPARATIF_OFFRES.csv`, à périmètre **identique**. Préciser les références et la date de consultation ; ne pas inventer de tarif ni d'accès.
3. Lire `cloud/DEPLIEMENT_GUIDE.md`, puis **si autorisé** : créer registre jetable, taguer et pousser l'image, déployer un petit service conteneur, observer logs et endpoint HTTP, documenter le digest, le coût et le nettoyage.
4. Si aucune base n'est accessible : `GET /healthz` peut répondre 200, mais **`/readyz` répond 503** ; noter que l'application n'est pas opérationnelle de bout en bout. Pour vérifier uniquement le processus, `HEALTH_ONLY=1 ./scripts/verify.sh` ou `./scripts/verify.ps1 -HealthOnly`.
5. **À la fin :** supprimer tous les services, registres, bases éventuelles et dépendances coûteuses, puis vérifier leur disparition.

**Preuves :** tableau droits/quotas, composants déployés, logs et HTTP, coût estimé ou non vérifiable, inventaire après nettoyage. Si accès refusé : étude argumentée et démonstration locale, clairement marquées **non équivalentes à un déploiement cloud**.

## J3 · TP06 — Kubernetes managé (optionnel, durée substituée à TP05)

**Pour préparer l'option**

- **Dans le kit :** les manifestes `k8s/`, le tableau de comparaison cloud et les preuves du TP04.
- **À consulter :** [Kubernetes : environnement d'apprentissage](https://kubernetes.io/docs/setup/learning-environment/) et la documentation du service managé **réellement autorisé** par le formateur.
- **Point à comprendre :** identifier les différences entre plan de contrôle local/managé, responsabilités, IAM, stockage et coûts.


Comparer local kind à EKS/AKS/autre : plan de contrôle, IAM, réseau, stockage, quotas, facturation, suppression. Créer un cluster **uniquement si** l'enseignant valide le compte, le budget et le temps de démantèlement. Sinon, rendre un schéma comparatif et une liste des étapes non réalisées ; ne pas présenter un déploiement fictif comme une expérience.

## J3 · TP07 — exploiter et préparer l'IaC (65 min)

**Pour préparer le TP**

- **Dans le kit :** `cloud/DEPLIEMENT_GUIDE.md`, `cloud/COMPARATIF_OFFRES.csv` et les résultats de TP05.
- **À consulter :** [AWS IAM : bonnes pratiques](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) (principes transposables) et la documentation des journaux du service choisi.
- **Point à comprendre :** distinguer ressources **observées** et ressources seulement **projetées** ; écrire de quoi reconstruire et détruire proprement.


À partir de l'environnement cloud **autorisé et réellement créé**, relever les rôles humains et machines, secrets, réseau, image/digest, limites de ressources, destination des logs, métriques, coût, suppression. Écrire un inventaire des objets et leurs dépendances, qui pourrait servir à une implémentation IaC ; le TP **n'exige pas** de construire toute une plateforme Terraform.

Si aucune ressource cloud n'est disponible, produire le même inventaire **projeté**, avec colonne « à créer / non testé », et baser les preuves d'exécution sur Compose ou kind. **Critère :** l'inventaire distingue systématiquement faits observés, hypothèses, droits manquants et objets à supprimer.

## J3 · TP08 — sauvegarde et restauration distincte (60 min)

**Pour préparer le TP**

- **Dans le kit :** `scripts/backup_restore.sh` (ou `.ps1`), `compose.yaml` et `app/server.py`.
- **À consulter :** [PostgreSQL : pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html) et [PostgreSQL : psql](https://www.postgresql.org/docs/current/app-psql.html).
- **Point à comprendre :** sauvegarder dans un fichier, restaurer **ailleurs**, puis contrôler des données. `pg_restore` ne s'applique pas au dump SQL texte de ce kit.


**Question :** peut-on reconstituer les données sans écraser la base source ?

1. Après avoir arrêté tout autre usage du port 8080, relancer le laboratoire Compose : `docker compose up -d --build`. Exécuter `./scripts/verify.sh` et conserver l'ID d'un joueur fictif.
2. Lancer `./scripts/backup_restore.sh` (Windows PowerShell : `./scripts/backup_restore.ps1`). Le script extrait `.local/backup.sql` et restaure la base **`guildops_restore`** dans le même PostgreSQL, sans modifier `guildops`.
3. Vérifier le nombre de joueurs dans chaque base et comparer au moins **un ID et son score**. Noter la taille du dump, le temps de sauvegarde et de restauration, les privilèges nécessaires et les données qui ne sont pas sauvegardées par `pg_dump` (réseau, secrets, comptes du fournisseur, etc.).
4. **Critique à formuler :** ce test ne mesure pas un RPO en production ; restaurer dans le même conteneur ne teste pas la perte de l'hôte. Proposer un test séparé sur une autre machine ou un autre cluster.

**Critère :** dump non vide, restauration isolée, égalité des décomptes et vérification d'un enregistrement. Le script refuse d'écraser `guildops_restore` si elle existe déjà. Pour recommencer, demander au formateur l'autorisation de supprimer **uniquement** cette base de test ; ne jamais faire un `down -v` sans vérifier ce qui doit être conservé.

## J3 · Dossier de stratégie et soutenance (100 min)

Rendre une synthèse d'architecture pour le scénario GuildOps Hosting Lab : objectifs, exigences et hypothèses, comparaison des solutions A/B/C, contraintes éliminatoires, matrice pondérée, TCO, sécurité/conformité, exploitation, stratégie de sauvegarde et de sortie, ADR final, preuves expérimentales datées. Si un critère manque de données, écrire **« non vérifié »** et proposer une mesure plutôt que d'inventer un chiffre.

**Checklist avant remise :** étapes reproductibles, commandes et erreurs pertinentes, résultats HTTP/ressources capturés sans secrets, tests de panne/rollback/restore, analyse des points uniques de panne, estimation de coûts avec sources et date, preuves de nettoyage, arbitrage conditionnel et questions ouvertes.

## Dépannage rapide

- **Docker daemon inaccessible :** contrôler `docker context ls` puis le moteur Docker Desktop/Engine.
- **Port 8080 occupé :** Compose, Swarm ou `port-forward` reste actif ; arrêter l'environnement précédent.
- **`/healthz` fonctionne, `/readyz` répond 503 :** vérifier les logs PostgreSQL et l'attente de disponibilité.
- **Swarm ne retrouve pas l'image :** `docker image inspect ...` ; registre partagé si multi-nœuds.
- **Secret Swarm introuvable :** vérifier `.local/db_password`, puis `docker stack config`.
- **`ImagePullBackOff` dans kind :** charger l'image avec `kind load docker-image ... --name guildops-lab`.
- **Pod/PVC en attente :** `kubectl -n guildops-lab describe pod ...` et `kubectl -n guildops-lab get pvc`.
- **Cloud : création refusée :** consigner rôle, quota ou service interdit ; utiliser le parcours sans droits.

**Fin de séance :** documenter les ressources qui subsistent intentionnellement ; supprimer et vérifier les autres. La démonstration ne doit laisser aucune facture au nom d'un étudiant.


## Pour aller plus loin après le cours

Les lectures proposées sont courtes et liées à une manipulation. Pour approfondir ensuite, reprendre les **résultats** du laboratoire plutôt que les commandes seules : quelles hypothèses ont été vérifiées ? Quelles ressources étaient réellement disponibles ? Qu'est-ce qui aurait changé sur plusieurs machines ?

**Trace de séance :** conserver un journal simple `hypothèse / commande ou observation / résultat / conséquence pour la stratégie`. Une preuve manquante vaut mieux qu'un chiffre inventé.
