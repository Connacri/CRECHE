-- Missing RPC functions for user management

CREATE OR REPLACE FUNCTION public.ensure_user_row(p_id text, p_email text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (p_id, p_email)
  ON CONFLICT (id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user_profile(p_id text, p_data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users
  SET
    name = COALESCE(p_data->>'name', name),
    first_name = COALESCE(p_data->>'first_name', first_name),
    last_name = COALESCE(p_data->>'last_name', last_name),
    phone_number = COALESCE(p_data->>'phone_number', phone_number),
    address = COALESCE(p_data->>'address', address),
    city = COALESCE(p_data->>'city', city),
    country = COALESCE(p_data->>'country', country),
    postal_code = COALESCE(p_data->>'postal_code', postal_code),
    organization_name = COALESCE(p_data->>'organization_name', organization_name),
    license_number = COALESCE(p_data->>'license_number', license_number),
    bio = COALESCE(p_data->>'bio', bio),
    profile_completed = COALESCE((p_data->>'profile_completed')::boolean, profile_completed),
    updated_at = NOW()
  WHERE id = p_id;
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.ensure_user_row(text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_user_profile(text, jsonb) TO authenticated, service_role;
