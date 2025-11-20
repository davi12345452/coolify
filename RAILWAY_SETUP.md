# 🚂 Guia de Deploy do Coolify na Railway

Este guia explica como fazer deploy do Coolify na plataforma Railway.

## 📋 Pré-requisitos

- Conta na Railway (https://railway.app)
- Conta no GitHub (para conectar o repositório)
- Repositório do Coolify no GitHub

## 🏗️ Passo a Passo

### 1. Criar um Novo Projeto na Railway

1. Acesse https://railway.app e faça login
2. Clique em **"New Project"**
3. Selecione **"Deploy from GitHub repo"**
4. Escolha o repositório do Coolify
5. Railway detectará automaticamente o `Dockerfile` e `railway.toml`

### 2. Adicionar Serviços Necessários

O Coolify precisa de 3 serviços principais:

#### 2.1. PostgreSQL (Banco de Dados)
1. No seu projeto Railway, clique em **"New"**
2. Selecione **"Database" → "PostgreSQL"**
3. Railway criará automaticamente e fornecerá a variável `DATABASE_URL`

#### 2.2. Redis (Cache e Filas)
1. Clique em **"New"** novamente
2. Selecione **"Database" → "Redis"**
3. Railway criará automaticamente e fornecerá a variável `REDIS_URL`

#### 2.3. Soketi (WebSocket Server) - OPCIONAL
Para funcionalidade completa de tempo real, você precisará de um servidor Soketi:

**Opção A: Deploy separado do Soketi**
1. Crie um novo serviço no Railway
2. Configure para usar a imagem: `quay.io/soketi/soketi:1.6-16-alpine`
3. Adicione as variáveis de ambiente:
   ```
   SOKETI_DEFAULT_APP_ID=coolify
   SOKETI_DEFAULT_APP_KEY=coolify
   SOKETI_DEFAULT_APP_SECRET=coolify
   SOKETI_DEFAULT_ENABLE_CLIENT_MESSAGES=true
   SOKETI_DEFAULT_ENABLED=true
   ```

**Opção B: Usar serviço externo de WebSocket**
- Pusher (https://pusher.com) - oferece plano gratuito
- Ably (https://ably.com)

### 3. Configurar Variáveis de Ambiente

No serviço principal do Coolify, adicione as seguintes variáveis de ambiente:

#### ✅ Obrigatórias

```bash
# Aplicação
APP_NAME=Coolify
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  # Ver instruções abaixo
APP_ID=coolify-production
APP_PORT=8080

# URL da aplicação (Railway fornecerá automaticamente)
APP_URL=${{RAILWAY_PUBLIC_DOMAIN}}

# Banco de Dados (Railway fornece automaticamente)
DATABASE_URL=${{Postgres.DATABASE_URL}}
DB_CONNECTION=pgsql

# Redis (Railway fornece automaticamente)
REDIS_URL=${{Redis.REDIS_URL}}
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Broadcasting (WebSocket)
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=coolify
PUSHER_APP_KEY=coolify
PUSHER_APP_SECRET=coolify
PUSHER_HOST=localhost  # Ou URL do Soketi se estiver usando serviço separado
PUSHER_PORT=6001
PUSHER_SCHEME=http

# Conta de Administrador Inicial
ROOT_USERNAME=admin
ROOT_USER_EMAIL=seu-email@example.com
ROOT_USER_PASSWORD=senha-super-segura-aqui
```

#### 📧 Recomendadas (Email)

```bash
# Configuração de Email (exemplo com Resend)
MAIL_MAILER=smtp
RESEND_API_KEY=re_xxxxxxxxxx  # Obtenha em https://resend.com

# Ou use SMTP tradicional
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=seu-email@gmail.com
MAIL_PASSWORD=sua-senha-de-app
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@coolify.io
MAIL_FROM_NAME=Coolify
```

#### 🔐 Opcionais (OAuth)

```bash
# GitHub OAuth
GITHUB_CLIENT_ID=seu_client_id
GITHUB_CLIENT_SECRET=seu_client_secret
GITHUB_REDIRECT_URI=https://seu-app.railway.app/auth/github/callback

# Google OAuth
GOOGLE_CLIENT_ID=seu_client_id
GOOGLE_CLIENT_SECRET=seu_client_secret
GOOGLE_REDIRECT_URI=https://seu-app.railway.app/auth/google/callback
```

### 4. Gerar APP_KEY

O Laravel precisa de uma chave de criptografia única. Você tem duas opções:

**Opção 1: Usando Artisan localmente**
```bash
# Clone o repositório
git clone seu-repositorio
cd coolify

# Instale dependências
composer install

# Gere a chave
php artisan key:generate --show
```

**Opção 2: Gerar manualmente**
```bash
# Em um terminal Linux/Mac
echo "base64:$(openssl rand -base64 32)"

# Ou use um gerador online:
# https://generate-random.org/laravel-key-generator
```

### 5. Configurar Domínio Personalizado (Opcional)

1. Na Railway, vá para o serviço Coolify
2. Clique na aba **"Settings"**
3. Role até **"Domains"**
4. Clique em **"Generate Domain"** para obter um domínio Railway gratuito
5. Ou adicione seu próprio domínio customizado

**Importante:** Atualize a variável `APP_URL` com o novo domínio!

### 6. Realizar o Deploy

1. Após configurar todas as variáveis, Railway iniciará o deploy automaticamente
2. Acompanhe os logs na aba **"Deployments"**
3. O primeiro deploy pode levar 5-10 minutos (compilação de assets + instalação de dependências)

### 7. Executar Migrations

Após o primeiro deploy bem-sucedido:

1. Na Railway, vá para o serviço Coolify
2. Clique na aba **"Settings"** → **"Deploy"**
3. Adicione um **"Deploy Command"** (One-time):
   ```bash
   php artisan migrate --force
   ```

**Ou** use o console da Railway:
1. Clique em **"..."** no serviço → **"Shell"**
2. Execute:
   ```bash
   php artisan migrate --force
   php artisan db:seed  # Se precisar de dados iniciais
   ```

### 8. Acessar a Aplicação

1. Abra a URL fornecida pela Railway
2. Faça login com as credenciais definidas em `ROOT_USER_EMAIL` e `ROOT_USER_PASSWORD`
3. Pronto! 🎉

## 🔍 Verificação de Saúde

A aplicação tem um endpoint de health check em `/health` que a Railway usa para monitorar o status.

## 📊 Monitoramento

### Logs
- Acesse os logs em tempo real na aba **"Deployments"** → Selecione um deploy → **"View Logs"**

### Métricas
- Railway fornece métricas de CPU, memória e rede na aba **"Metrics"**

## 🐛 Troubleshooting

### Problema: Deploy falha durante build
**Solução:**
- Verifique os logs de build
- Certifique-se de que todas as dependências do `composer.json` e `package.json` estão corretas
- Aumente o timeout de build se necessário

### Problema: Aplicação não inicia
**Solução:**
- Verifique se `APP_KEY` está configurada corretamente
- Confirme que `DATABASE_URL` e `REDIS_URL` estão conectadas
- Verifique os logs de runtime

### Problema: Erro 500
**Solução:**
- Defina `APP_DEBUG=true` temporariamente para ver o erro completo
- Verifique se as migrations foram executadas
- Confirme permissões de storage

### Problema: WebSocket não funciona
**Solução:**
- Verifique se o Soketi está rodando (se usando serviço separado)
- Ou configure um provedor externo como Pusher
- Certifique-se de que as variáveis `PUSHER_*` estão corretas

## 📝 Notas Importantes

### Limitações na Railway

1. **Docker-in-Docker**: Coolify gerencia containers Docker, mas Railway não suporta Docker-in-Docker nativamente. Isso significa que:
   - ✅ A interface do Coolify funcionará
   - ❌ Você **NÃO** poderá gerenciar containers Docker através do Coolify rodando na Railway
   - 💡 **Solução**: Use o Coolify na Railway apenas como interface de gerenciamento, e conecte servidores externos onde você realmente executará os containers

2. **Volumes Persistentes**:
   - Railway fornece volumes, mas são efêmeros por padrão
   - Configure volumes persistentes para dados importantes
   - Ou use S3/Object Storage externo

3. **Custos**:
   - Railway cobra por uso de CPU, memória e tráfego
   - Monitore seu uso para evitar surpresas
   - Plano gratuito tem limites mensais

### Recomendações

1. **Use S3 para Storage**:
   ```bash
   AWS_ACCESS_KEY_ID=seu_key_id
   AWS_SECRET_ACCESS_KEY=seu_secret_key
   AWS_DEFAULT_REGION=us-east-1
   AWS_BUCKET=coolify-storage
   AWS_ENDPOINT=https://s3.amazonaws.com  # Ou use MinIO, Backblaze B2, etc.
   ```

2. **Configure Backups de Banco de Dados**:
   - Use os backups automáticos da Railway
   - Ou configure backups externos

3. **Monitore Performance**:
   - Configure Sentry para rastreamento de erros
   - Use as métricas da Railway

## 🔗 Links Úteis

- [Documentação Railway](https://docs.railway.app/)
- [Documentação Coolify](https://coolify.io/docs)
- [Laravel Deployment](https://laravel.com/docs/deployment)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🆘 Suporte

Se encontrar problemas:
1. Verifique os logs na Railway
2. Consulte a documentação do Coolify
3. Abra uma issue no GitHub do Coolify
4. Pergunte na comunidade Railway Discord

---

**Importante**: Esta configuração permite rodar a **interface web** do Coolify na Railway, mas para funcionalidade completa de gerenciamento de containers, você precisará de servidores adicionais com Docker instalado que o Coolify gerenciará remotamente via SSH.
