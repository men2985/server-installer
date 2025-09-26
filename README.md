# Infra Swarm Installer

Instala **Traefik, Portainer, Redis (+RedisInsight), Postgres, n8n, Chatwoot y Evolution API (RabbitMQ incluido)** en Docker Swarm.  
Todo vive bajo `/home` para facilitar **backup** y **restore**.

---

## 🚀 Instalación rápida (línea mágica)

En tu VPS (ejecuta como **root**; el script instalará las dependencias necesarias automáticamente):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/men2985/server-installer/main/install.sh)
```

Durante la instalación el asistente detecta los stacks ya desplegados y te permite elegir qué módulos activar (Traefik, Portainer, Redis, Postgres, n8n, Chatwoot, Evolution API).
