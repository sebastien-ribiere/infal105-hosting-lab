# TP Cloud — déploiement guidé, avec garde-fous

**Ce guide est un parcours à réaliser dans un compte pédagogique autorisé, pas une preuve d'exécution.** Selon les comptes, l'enseignant doit adapter le service, les quotas et la région ; certains services ne sont pas ouverts par le partenariat CESI.

## Avant toute création (obligatoire)

1. Confirmer le compte de formation, la région, l'heure de fin de la séance et la personne responsable du nettoyage.
2. Vérifier droits pour le registre, le service conteneur, la gestion réseau, les logs et le stockage. Noter les restrictions et les crédits accessibles.
3. Comparer deux offres à périmètre identique : image de l'API, 1 conteneur de petite taille, terminaison HTTP, journalisation, secret, DB si autorisée.
4. Ne jamais rendre une base PostgreSQL publique. Ne jamais enregistrer un secret réel dans un fichier partagé ou une capture.

## AWS (si les permissions du lab le permettent)

1. Créer un dépôt privé ECR dédié à l'atelier, avec nom explicitement jetable.
2. Authentifier le client Docker selon les instructions ECR affichées par le compte, taguer puis pousser l'image du laboratoire.
3. Déployer une tâche/service ECS Fargate de taille minimale **si autorisé**, avec image depuis ECR, port 8080, logs centralisés et accès contrôlé.
4. Vérifier `/healthz`, observer les logs et rapporter la configuration. `/readyz` renvoie 503 sans PostgreSQL : c'est attendu, et ne doit pas être présenté comme une application complète.
5. Si RDS est autorisé et budgété, ajouter une base privée et fournir les variables/secret de connexion à la tâche. Vérifier `/readyz` et un POST/GET `/players`.
6. Relever l'estimation de coût, ou noter « outil budgétaire non accessible » si c'est le cas dans AWS Academy.
7. Supprimer service/tâches, load balancer éventuel, RDS, logs inutiles, images et dépôt ECR ; vérifier qu'il ne reste pas de ressources facturables.

## Azure (si le compte le permet)

1. Créer un groupe de ressources jetable, puis un Azure Container Registry si autorisé.
2. Pousser l'image avec un tag non ambigu, conserver le digest.
3. Déployer Azure Container Apps en petite taille si autorisé, avec registre, identité, ingress HTTP et logs.
4. Vérifier `/healthz`. Si la base Azure Database for PostgreSQL Flexible Server est autorisée, la placer sur un réseau approprié et n'exposer aucune donnée réelle. Tester `/readyz` et `/players`.
5. Inventorier puis supprimer toutes les ressources du groupe ; vérifier les dépendances hors du groupe.

## Variante sans droits cloud

Déployer l'API avec Docker Compose ou kind et **documenter** pour une offre choisie les services correspondants, les droits nécessaires, les coûts potentiels, les étapes de migration et les responsabilités. Cette activité est une analyse de faisabilité, pas une preuve de déploiement cloud.

## Preuves demandées

- Schéma réseau et identités (ressources effectivement créées en trait plein ; services non créés en pointillés).
- Image/tag/digest, configuration du service, journaux et réponses HTTP avec date.
- Limites : comptes/quotas, données, observabilité, disponibilité et retour arrière.
- Inventaire final de suppression des ressources.
