FROM python:3.7-bullseye

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Skip manage.py's virtualenv activation hack
ENV VIRTUAL_ENV=/usr

# Set the working directory
WORKDIR /app

# Install system dependencies (adapted from esp/packages_base.txt for Debian)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    npm \
    texlive \
    texlive-latex-extra \
    imagemagick \
    dvipng \
    postgresql-client \
    libevent-dev \
    zlib1g-dev \
    inkscape \
    wamerican-large \
    wget \
    memcached \
    libmemcached-dev \
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libjpeg-dev \
    javascript-common \
    git \
    libfreetype6-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install LESS via npm (from packages_base_manual_install.sh)
RUN npm install --prefix /usr less@1.7.5 -g

# Copy requirements first for better Docker layer caching
COPY esp/requirements.txt /app/esp/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir -r /app/esp/requirements.txt

# Copy the rest of the application code
COPY . /app

# Copy the entrypoint script and make it executable
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && \
    chmod +x /app/docker-entrypoint.sh

# Expose the Django development server port
EXPOSE 8000

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["python", "esp/manage.py", "runserver", "0.0.0.0:8000"]
