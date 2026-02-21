# Django + PostgreSQL + Nginx in Docker

## Project Structure

```
docker_project/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── .gitignore
├── README.md
├── nginx/
│   └── nginx.conf
└── myproject/
    ├── manage.py
    └── myproject/
        ├── __init__.py
        ├── settings.py
        ├── urls.py
        └── wsgi.py
```

## Services

- **django** — Django web application running via Gunicorn
- **db** — PostgreSQL 15 database
- **nginx** — Nginx reverse proxy on port 80

## Running the Project

```bash
docker-compose up -d
```

The app will be available at: http://localhost

## Stop the Project

```bash
docker-compose down
```

## View Logs

```bash
docker-compose logs -f
```
