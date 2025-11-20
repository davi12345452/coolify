# 🚀 Coolify na Railway - Início Rápido

## O que você precisa criar na Railway:

### 1️⃣ Serviços (3 no total)

#### Serviço 1: Coolify (Aplicação Principal)
- **Source**: Seu repositório GitHub
- **Build**: Automático (usa o Dockerfile na raiz)

#### Serviço 2: PostgreSQL
- **Tipo**: Database → PostgreSQL
- **Versão**: 15 (padrão está OK)

#### Serviço 3: Redis
- **Tipo**: Database → Redis
- **Versão**: 7 (padrão está OK)

---

## 🔧 Variáveis de Ambiente Mínimas

Cole estas variáveis no serviço **Coolify** (ajuste os valores):

```bash
# === OBRIGATÓRIAS ===
APP_NAME=Coolify
APP_ENV=production
APP_DEBUG=false
APP_KEY=                        # ⚠️ GERE COM: php artisan key:generate --show
APP_ID=coolify-prod
APP_PORT=8080
APP_URL=${{RAILWAY_PUBLIC_DOMAIN}}

# === DATABASE (auto-preenchido pela Railway) ===
DATABASE_URL=${{Postgres.DATABASE_URL}}
DB_CONNECTION=pgsql

# === REDIS (auto-preenchido pela Railway) ===
REDIS_URL=${{Redis.REDIS_URL}}
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# === WEBSOCKET (configuração básica) ===
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=coolify
PUSHER_APP_KEY=coolify
PUSHER_APP_SECRET=coolify
PUSHER_HOST=localhost
PUSHER_PORT=6001
PUSHER_SCHEME=http

# === CONTA ADMIN (você escolhe) ===
ROOT_USERNAME=admin
ROOT_USER_EMAIL=seu-email@example.com
ROOT_USER_PASSWORD=SuaSenhaSegura123!
```

---

## 📝 Passos para Deploy

1. **Criar projeto na Railway**
   - New Project → Deploy from GitHub repo
   - Selecione o repositório do Coolify

2. **Adicionar PostgreSQL**
   - No projeto → New → Database → PostgreSQL

3. **Adicionar Redis**
   - No projeto → New → Database → Redis

4. **Configurar variáveis de ambiente**
   - No serviço Coolify → Variables
   - Cole as variáveis acima

5. **Gerar APP_KEY** (se não tiver)
   ```bash
   # Opção 1: Localmente com PHP
   php artisan key:generate --show

   # Opção 2: Online
   # https://generate-random.org/laravel-key-generator

   # Opção 3: Terminal
   echo "base64:$(openssl rand -base64 32)"
   ```

6. **Fazer deploy**
   - Railway inicia automaticamente após configurar as variáveis
   - Aguarde 5-10 minutos para o primeiro build

7. **Executar migrations** (APÓS primeiro deploy)
   - No serviço Coolify → Settings → Shell
   - Execute: `php artisan migrate --force`

8. **Acessar aplicação**
   - Clique no domínio gerado pela Railway
   - Login com ROOT_USER_EMAIL e ROOT_USER_PASSWORD

---

## ⚠️ IMPORTANTE: Limitação do Coolify na Railway

**O Coolify NÃO poderá gerenciar containers Docker diretamente na Railway** porque Railway não suporta Docker-in-Docker.

### Para que funcione completamente:

1. ✅ Use o Coolify na Railway apenas como **interface de controle**
2. ✅ Conecte **servidores externos** (VPS, AWS EC2, etc.) através da interface
3. ✅ O Coolify gerenciará esses servidores remotamente via SSH
4. ✅ Os containers Docker rodarão nos servidores externos, não na Railway

### Alternativa:
Se você precisa rodar containers Docker localmente, **NÃO use Railway**.
Faça deploy em:
- VPS (DigitalOcean, Linode, Hetzner)
- AWS EC2
- Google Cloud Compute
- Qualquer servidor com Docker instalado

---

## 🔗 Links Úteis

- **Guia Completo**: Ver arquivo `RAILWAY_SETUP.md` (mais detalhado)
- **Documentação Railway**: https://docs.railway.app/
- **Documentação Coolify**: https://coolify.io/docs

---

## 🆘 Problemas Comuns

| Problema | Solução |
|----------|---------|
| Deploy falha | Verifique logs de build, confirme que APP_KEY está configurada |
| Erro 500 | Execute `php artisan migrate --force` |
| Não consigo fazer login | Verifique se ROOT_USER_EMAIL e ROOT_USER_PASSWORD estão corretos |
| WebSocket não funciona | Normal para configuração básica, funcionalidades em tempo real podem não funcionar sem Soketi |

---

**Precisa de mais detalhes?** Consulte `RAILWAY_SETUP.md` para documentação completa!
