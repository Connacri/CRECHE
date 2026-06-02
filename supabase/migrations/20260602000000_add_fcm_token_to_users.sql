-- Ajout de la colonne fcm_token à la table users pour Firebase Cloud Messaging
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index pour accélérer la recherche par token si nécessaire
CREATE INDEX IF NOT EXISTS users_fcm_token_idx ON public.users (fcm_token);

-- Commentaire pour la documentation
COMMENT ON COLUMN public.users.fcm_token IS 'Token Firebase Cloud Messaging pour les notifications push';
