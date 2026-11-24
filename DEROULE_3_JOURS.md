# Déroulé pédagogique INFAL105 — version 2026

Base : fiche module CESI MAALSI V2 du 25/02/2026. Les temps sont des propositions d'animation ; les infrastructures disponibles au campus déterminent les variantes. Durée visée : **3 × 7 h**, soit **6 h d'apports (28,6 %) / 15 h de TP (71,4 %)**.

| Jour | Apports guidés | Exercices / travaux à produire | Total |
| --- | ---: | ---: | ---: |
| J1 | 100 min : modèles de cloud, empreinte environnementale, images/OCI, sécurité et rôle du manager Swarm | 20 min préparation ; 90 min Compose ; 30 min persistance ; 35 min sécurité ; 90 min Swarm ; 45 min scale/rollback ; 10 min bilan | 420 min |
| J2 | 120 min : objets K8s, concepts d'hébergement cloud, responsabilité partagée et services fournisseurs | 110 min kind ; 55 min observations K8s ; 35 min préflight cloud ; 80 min début déploiement cloud ; 20 min bilan | 420 min |
| J3 | 140 min : services et coûts, IAM, IaC, migration, réversibilité, TCO, matrice et ADR | 55 min suite TP cloud ; 65 min exploitation/IaC ; 60 min restauration/exit ; 100 min matrice/soutenance | 420 min |

Le cahier étudiant `TP_ETUDIANTS.md` donne les consignes opératoires, les preuves et le dépannage pour **TP00 à TP08**. **TP06 est une option qui remplace une partie du parcours cloud** si droits, temps et quotas le permettent ; elle ne s’ajoute pas aux 21 h.

Les modules introductifs du support (cloud public/privé/hybride, réglementation, normes ISO, métriques, TCO, grille de choix) sont un **fonds documentaire** pour les apports guidés et le coaching, pas une liste de toutes les slides à projeter en trois jours.

## Acquis à démontrer

- Modéliser l'exécution d'un service et le cycle de vie de ses données.
- Déployer un service conteneurisé sur Compose, Swarm et Kubernetes local, puis comparer avec le cloud.
- Distinguer service disponible, service tolérant aux pannes et service restaurable.
- Comparer une offre cloud, sa réversibilité et son coût sur un périmètre identique.
- Rendre une recommandation argumentée et conditionnelle, avec preuves, inconnues et points de revue.

## Variante cloud

L'accès AWS Academy/Azure/Openshift et les quotas sont variables. La fiche CESI prévoit une substitution possible entre TP de cluster local et managé. Si les droits ou le budget ne permettent pas de créer un cluster cloud, faire un schéma de comparaison et concentrer le TP effectif sur un service conteneur managé autorisé, ou revenir au local. **Ne jamais faire payer les étudiants**.

## Notes au formateur

La version formateur possède les notes d'animation et les corrigés des études de cas. Les étudiants reçoivent le support sans ces notes. Les corrections TCO et les résultats de la matrice sont des données fictives de l'exercice, pas des coûts fournisseurs ou des performances mesurées.
