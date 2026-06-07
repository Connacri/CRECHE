# Workflow de l'Application Crèche

Ce document détaille le fonctionnement de la plateforme Crèche selon les différents rôles utilisateurs.

## 🎭 Rôles et Responsabilités

### 1. Parent (Client)
- **Gestion des Enfants** : Enregistrement et suivi des profils enfants.
- **Inscriptions** : Recherche de cours/clubs et soumission de demandes d'inscription.
- **Suivi en temps réel** : Consultation de la timeline journalière (repas, activités, sommeil).
- **Sécurité** : Suivi Geofencing des trajets de transport.
- **Paiement** : Consultation des factures et historique des paiements.

### 2. École / Club (Propriétaire / Admin local)
- **Gestion Administrative** : Création et gestion des cours, classes et événements.
- **Validation** : Approbation ou refus des demandes d'inscription des parents.
- **Planning** : Organisation des horaires et assignation des ressources (salles, coachs).
- **Comptabilité** : Émission de factures et suivi des paiements.
- **Stock** : Gestion des inventaires et commandes fournisseurs.

### 3. Coach (Intervenant)
- **Pédagogie** : Saisie des activités quotidiennes pour chaque enfant.
- **Présence** : Suivi des présences aux sessions.
- **Communication** : Interaction directe sur le suivi des élèves.

### 4. Transporteur (Logistique)
- **Sécurité** : Mise à jour de la position GPS pour le Geofencing.
- **Statut** : Information sur l'état du ramassage scolaire.

### 5. Fournisseur (Partenaire)
- **Commandes** : Réception des demandes de fournitures ou repas des écoles.
- **Logistique** : Mise à jour du statut des livraisons.

---

## 🔄 Flux Principaux

### A. Flux d'Inscription (Enrollment)
1. **Parent** -> Soumet une demande d'inscription pour un enfant sur un cours spécifique. (Statut: `pending`)
2. **École/Coach** -> Reçoit une notification. Analyse la demande.
3. **École/Coach** -> Approuve la demande. (Statut: `approved`).
4. **Système** -> Décrémente le nombre de places disponibles (`current_students`).
5. **Parent** -> Accède au planning et au suivi journalier de l'enfant.

### B. Flux Quotidien (Daily Life)
1. **Coach** -> Enregistre une activité (ex: "Repas terminé").
2. **Supabase Realtime** -> Diffuse l'information instantanément.
3. **Parent** -> Voit l'activité apparaître sur son Dashboard sans rafraîchir.

### C. Flux Financier (Finance)
1. **École** -> Génère une facture liée à une inscription ou une adhésion.
2. **Parent** -> Reçoit la facture sur son application.
3. **Paiement** -> Le paiement est effectué (souvent hors-ligne ou via QR Code).
4. **École** -> Enregistre le paiement, ce qui met à jour le statut de la facture.

---

## 🛠 Structure de Données (Supabase)

L'application repose sur une base de données relationnelle sécurisée par **RLS (Row Level Security)** :
- `users` : Profils et rôles.
- `children` : Données enfants liées aux parents.
- `courses` : Offres pédagogiques/sportives.
- `enrollments` : Pivot entre enfants, parents et cours.
- `daily_activities` : Journal de bord.
- `invoices` & `payments` : Flux financiers.
- `inventory_items` : Gestion des ressources.
