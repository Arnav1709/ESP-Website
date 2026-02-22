Docker based dev servers
========================

.. contents:: :local:

Introduction
------------

Follow the steps below to quickly set up a local development server using Docker.
This approach requires **only Docker and Docker Compose** to be installed — no
other host dependencies or specific Python versions needed.

The Docker setup runs three containers:

- **web**: The Django application (Python 3.7)
- **db**: PostgreSQL 14 database
- **memcached**: Memcached caching layer

Your working copy is mounted into the container, so you can edit code with your
preferred editor on your host machine and see changes reflected immediately.

Prerequisites
-------------

Install the following on your system:

* `Docker Engine <https://docs.docker.com/engine/install/>`_ (or Docker Desktop)
* `Docker Compose <https://docs.docker.com/compose/install/>`_ (included with Docker Desktop;
  on Linux you may need to install it separately)

That's it! No Python, Node.js, PostgreSQL, or any other dependency needs to be
installed on your host machine.

Quick Start
-----------

1. Clone the repository::

    git clone https://github.com/learning-unlimited/ESP-Website.git devsite
    cd devsite

   If you have SSH keys set up::

    git clone git@github.com:learning-unlimited/ESP-Website.git devsite
    cd devsite

2. Build and start all services::

    docker-compose up --build

   The first build will take several minutes as it installs system and Python
   dependencies. Subsequent starts will be much faster due to Docker layer caching.

3. The entrypoint script will automatically:

   - Create ``local_settings.py`` from the Docker template (if it doesn't exist)
   - Create media symlinks (``images``, ``styles``)
   - Wait for PostgreSQL to be ready
   - Run database migrations
   - Collect static files

4. Once you see ``Starting development server at http://0.0.0.0:8000/``,
   open your browser and navigate to http://localhost:8000.

5. To create an admin account, open a new terminal and run::

    docker-compose exec web python esp/manage.py createsuperuser

Stopping & Starting
--------------------

To stop the containers::

    docker-compose down

To stop and **delete the database** (fresh start)::

    docker-compose down -v

To start again (no rebuild needed unless you changed the Dockerfile)::

    docker-compose up

To rebuild after changing the Dockerfile or requirements.txt::

    docker-compose up --build

Common Commands
---------------

Run any ``manage.py`` command::

    docker-compose exec web python esp/manage.py <command>

Examples::

    # Open a Django shell
    docker-compose exec web python esp/manage.py shell_plus

    # Run migrations
    docker-compose exec web python esp/manage.py migrate

    # Run tests
    docker-compose exec web python esp/manage.py test

    # Open a bash shell inside the container
    docker-compose exec web bash

    # Connect to the PostgreSQL database
    docker-compose exec db psql -U esp devsite_django

Loading a Database Dump
-----------------------

If you have a database dump file, you can load it like so::

    # First, copy the dump into the db container
    docker cp /path/to/dump.sql $(docker-compose ps -q db):/tmp/dump.sql

    # Then load it
    docker-compose exec db psql -U esp devsite_django -f /tmp/dump.sql

To load a Postgres custom-format dump::

    docker-compose exec db pg_restore --verbose --dbname=devsite_django \
        --no-owner --no-acl -U esp /tmp/dump.sql

After loading, re-run migrations to ensure the schema is up to date::

    docker-compose exec web python esp/manage.py migrate

Configuration
-------------

The Docker setup uses ``esp/esp/local_settings.py.docker`` as the template for
``local_settings.py``. It is automatically copied on first run. If you need to
customize settings:

1. Edit ``esp/esp/local_settings.py`` directly (it is gitignored)
2. Or edit ``esp/esp/local_settings.py.docker`` to change the defaults for all
   Docker users

- ``DATABASES['default']['HOST']`` is ``'db'`` (the Docker service name) instead of
  ``'localhost'``
- ``CACHES['default']['LOCATION']`` is ``'memcached:11211'`` instead of
  ``'127.0.0.1:11211'``
- ``ALLOWED_HOSTS`` is ``['*']`` for convenience in local development

Troubleshooting
---------------

1. **Port already in use**

   If port 8000 (or 5432 or 11211) is in use, either stop the conflicting service
   or change the port mapping in ``docker-compose.yml``, e.g.::

       ports:
         - "9000:8000"

2. **Database connection errors**

   The entrypoint script waits for PostgreSQL to be ready, but if you still see
   connection errors, try::

       docker-compose restart web

3. **Permission issues with mounted volumes**

   On Linux, files created inside the container may be owned by root. Fix with::

       sudo chown -R $USER:$USER .

4. **Stale containers**

   If things seem broken after a ``git pull``, try a clean rebuild::

       docker-compose down -v
       docker-compose up --build
