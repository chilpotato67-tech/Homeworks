# Step Project 2 — Jenkins + Worker + Docker (Node.js)

Це виконання Step Project 2 згідно вимог завдання:
- створено 2 VM через Vagrant: Jenkins Controller (master) + Jenkins Worker (agent)
- Jenkins Controller запущений на VM1 (в Docker)
- Jenkins Worker встановлений напряму на VM2 (systemd service, без Docker для Jenkins)
- Pipeline запускається вручну та виконується на Jenkins Worker
- Після успішних тестів Docker image пушиться в Docker Hub

## Окремий репозиторій з Node.js застосунком (forStep2)
RepoStep (source code):
https://github.com/chilpotato67-tech/RepoStep

Саме цей репозиторій використовується в Jenkins як SCM (звідки тягнеться код для pipeline).

## Docker Hub (результат push)
Docker image:
https://hub.docker.com/r/duckdogduc/forstep2

## Pipeline логіка
Pipeline виконує кроки:
1. Pull the code
2. Build Docker image (на Jenkins Worker)
3. Run tests (в Docker контейнері)
4. Login to Docker Hub (через Jenkins credentials)
5. Push image (TAG + latest)

Якщо тести провалюються — виводиться повідомлення: `Tests failed`

## Що знаходиться в цій папці (src)
- `Jenkinsfile` — Groovy pipeline
- `Dockerfile` — збірка Docker-образу
- `package.json` — залежності та scripts (start/test)
- `app.js` — Node.js застосунок
- `tests/` або `test.js` — тест  для pipeline
- `diagram.puml` — схема архітектури 
- `screen/` — скріншоти виконання 
- `jenkins-vagrant/` — Vagrant конфіг для 2 VM 

