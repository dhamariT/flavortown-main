require 'securerandom'
require 'base64'
require 'yaml'

# Generate secrets
secret_key_base = SecureRandom.hex(64)
rails_master_key = SecureRandom.hex(16)
postgres_password = SecureRandom.base64(16).gsub(/[^a-zA-Z0-9]/, '') # simple alphanumeric

# Config values (must match configmap.yaml)
postgres_user = "postgres"
postgres_host = "postgres-service"
postgres_port = "5432"
postgres_db = "buildboard_production"

database_url = "postgresql://#{postgres_user}:#{postgres_password}@#{postgres_host}:#{postgres_port}/#{postgres_db}"

# Base64 encode
def encode(value)
  Base64.strict_encode64(value)
end

secrets_yaml = <<~YAML
apiVersion: v1
kind: Secret
metadata:
  name: buildboard-secrets
  labels:
    app: buildboard
type: Opaque
data:
  # Database URL
  database-url: #{encode(database_url)}

  # Rails master key
  rails-master-key: #{encode(rails_master_key)}

  # Secret key base
  secret-key-base: #{encode(secret_key_base)}

  # PostgreSQL password
  postgres-password: #{encode(postgres_password)}
YAML

File.write('k8s/secrets.yaml', secrets_yaml)
puts "Generated k8s/secrets.yaml with new secrets."
