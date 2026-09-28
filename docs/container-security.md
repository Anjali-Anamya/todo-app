# Container Security

## Implemented Controls

### Image Security
- Multi-stage Docker build
- Separate build and runtime images
- Production dependencies only
- Slim production runtime
- Development dependencies excluded from final image
- Docker image vulnerability scanning with Trivy

### Runtime Security
- Application runs as non-root `node` user
- Read-only root filesystem
- Temporary filesystem mounted at `/tmp`
- Linux capabilities dropped
- `no-new-privileges` enabled
- CPU and memory limits configured
- Automatic container restart enabled

### Secrets
- Database credentials removed from production Compose
- Credentials supplied through environment variables
- `.env` excluded from Git
- `.env.example` contains placeholders only

### Production Isolation
- phpMyAdmin excluded from production
- Development Compose Watch excluded
- Vite development server excluded
- Docker socket not mounted into the production application
- Production uses the compiled frontend

### Health
- Application healthcheck
- MySQL healthcheck
- Application starts only after healthy database dependency

## Security Scanning

Trivy is used for:

- Container image vulnerabilities
- Dependency vulnerabilities
- Secret detection
- Configuration/misconfiguration detection
