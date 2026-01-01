FROM python:3.11-slim

LABEL maintainer="XSource Security <contact@xsourcesec.com>"
LABEL org.opencontainers.image.source="https://github.com/XSource-Sec/agent-audit-action"
LABEL org.opencontainers.image.description="AgentAudit GitHub Action - AI Agent Security Testing"

# Install dependencies
RUN pip install --no-cache-dir requests

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
