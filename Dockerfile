# Simplified Dockerfile for Railway using official PHP image
# Based on standard PHP-FPM + Nginx setup

# =================================================================
# Stage 1: Composer dependencies
# =================================================================
FROM composer:2 AS composer

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist --optimize-autoloader --ignore-platform-reqs

# =================================================================
# Stage 2: Frontend assets
# =================================================================
FROM node:24-alpine AS frontend

WORKDIR /app
COPY package*.json vite.config.js postcss.config.cjs ./
RUN npm ci
COPY . .
RUN npm run build

# =================================================================
# Final Stage: PHP + Nginx
# =================================================================
FROM php:8.4-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    postgresql15-client \
    git \
    curl \
    zip \
    unzip \
    supervisor

# Install PHP extensions (need postgresql-dev for pdo_pgsql build)
RUN apk add --no-cache --virtual .build-deps \
    postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql pcntl \
    && apk del .build-deps

# Install Redis extension
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS

# Ensure www-data user and group exist explicitly
RUN set -x \
    && addgroup -g 82 -S www-data 2>/dev/null || true \
    && adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true \
    && id www-data

# Configure PHP-FPM pool with explicit user
RUN echo "[www]" > /usr/local/etc/php-fpm.d/www.conf \
    && echo "user = www-data" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "group = www-data" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "listen = 127.0.0.1:9000" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm = dynamic" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.max_children = 20" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.start_servers = 2" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.min_spare_servers = 1" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "pm.max_spare_servers = 3" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "catch_workers_output = yes" >> /usr/local/etc/php-fpm.d/www.conf

# Copy application
WORKDIR /var/www/html
COPY --chown=www-data:www-data . .
COPY --from=composer --chown=www-data:www-data /app/vendor ./vendor
COPY --from=frontend --chown=www-data:www-data /app/public/build ./public/build

# Configure Nginx
RUN mkdir -p /run/nginx
COPY docker/railway/nginx.conf /etc/nginx/nginx.conf

# Configure Supervisor to manage both services
COPY docker/railway/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Laravel optimization (skip for now to avoid .env issues)
RUN php artisan config:clear || true

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
