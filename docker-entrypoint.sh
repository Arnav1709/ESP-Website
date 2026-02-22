#!/bin/bash
set -e

# Copy Docker-specific settings if local_settings.py doesn't exist
if [ ! -f /app/esp/esp/local_settings.py ]; then
    echo ">>> Creating local_settings.py from Docker template..."
    cp /app/esp/esp/local_settings.py.docker /app/esp/esp/local_settings.py
fi

# Create media symlinks if they don't exist
if [ ! -e /app/esp/public/media/images ]; then
    echo ">>> Creating media symlinks..."
    ln -sf /app/esp/public/media/default_images /app/esp/public/media/images
fi
if [ ! -e /app/esp/public/media/styles ]; then
    ln -sf /app/esp/public/media/default_styles /app/esp/public/media/styles
fi

# Wait for PostgreSQL to be ready
echo ">>> Waiting for PostgreSQL..."
until python -c "
import psycopg2
try:
    psycopg2.connect(host='db', dbname='devsite_django', user='esp', password='password')
except psycopg2.OperationalError:
    exit(1)
" 2>/dev/null; do
    sleep 2
done
echo ">>> PostgreSQL is ready!"

# Run migrations
echo ">>> Running migrations..."
cd /app/esp
python manage.py migrate --noinput

# Collect static files
echo ">>> Collecting static files..."
python manage.py collectstatic --noinput -v 0

echo ">>> Starting server..."
exec "$@"
