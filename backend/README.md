# Backend

This folder contains the Supabase CLI project for Dock UI. Keep application source in `DesignUI/` and backend schema, migrations, and Edge Functions here.

## Common commands

Run these from this `backend` folder:

```sh
# Deploy the StudioAI Edge Function
supabase functions deploy StudioAI

# Apply committed database migrations to the linked DockUI project
supabase db push

# Create a timestamped migration
supabase migration new describe_the_change

# Set an Edge Function secret without committing it
supabase secrets set OPENAI_API_KEY=your_value
```

The local project is linked to DockUI (`dwxfipenxnqkhgtwggrv`). Secrets and `.temp` metadata stay out of Git.
