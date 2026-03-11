# Урок 7 — EKS + Helm на AWS

Цей проєкт розгортає кластер Kubernetes (EKS) на AWS та деплоїть Django-застосунок за допомогою Helm-чарта.

---

## Зміст
- [Структура проєкту](#структура-проєкту)
- [Модулі Terraform](#модулі-terraform)
- [Helm-чарт](#helm-чарт)
- [Порядок розгортання](#порядок-розгортання)
- [Команди](#команди)

---

## Структура проєкту

```
lesson-7/
├── main.tf
├── backend.tf
├── outputs.tf
├── .gitignore
├── README.md
├── modules/
│   ├── s3-backend/   # S3 + DynamoDB для Terraform state
│   ├── vpc/          # VPC, підмережі, IGW, NAT Gateways
│   ├── ecr/          # ECR репозиторій для Docker-образів
│   └── eks/          # EKS кластер + Node Group
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

---

## Модулі Terraform

### `s3-backend`
- **S3 Bucket** — зберігає `terraform.tfstate` з версіюванням та шифруванням AES-256
- **DynamoDB** — блокування стейту через `LockID`

### `vpc`
- **VPC** — `10.0.0.0/16` з підтримкою EKS тегів
- **3 публічні підмережі** — `10.0.1–3.0/24` (tag: `kubernetes.io/role/elb`)
- **3 приватні підмережі** — `10.0.4–6.0/24` (tag: `kubernetes.io/role/internal-elb`)
- **Internet Gateway + 3 NAT Gateways**

### `ecr`
- ECR репозиторій `lesson-7-django`
- Scan on push, lifecycle policy (зберігає останні 10 версій)

### `eks`
- **EKS Cluster** v1.29
- **Node Group** — `t3.medium`, 2–4 вузли
- **IAM ролі** для кластера та нод
- Ноди в **приватних підмережах** (безпечно)

---

## Helm-чарт

### Компоненти

| Ресурс | Опис |
|--------|------|
| `Deployment` | Django-образ з ECR, envFrom → ConfigMap |
| `Service` | LoadBalancer, port 80 → 8000 |
| `ConfigMap` | Змінні середовища (DB, Django settings) |
| `HPA` | 2–6 подів при CPU > 70% |

### Параметри `values.yaml`

| Параметр | Значення |
|----------|----------|
| `image.repository` | ECR URL |
| `image.tag` | `latest` |
| `service.type` | `LoadBalancer` |
| `autoscaler.minReplicas` | `2` |
| `autoscaler.maxReplicas` | `6` |
| `autoscaler.targetCPUUtilizationPercentage` | `70` |

---

## Порядок розгортання

### 1. Створити S3 backend та інфраструктуру

```bash
cd lesson-7

# Ініціалізація з локальним стейтом
terraform init

# Спочатку створити S3 + DynamoDB
terraform apply -target=module.s3_backend

# Розкоментувати backend блок в backend.tf та мігрувати стейт
terraform init -migrate-state

# Розгорнути все (VPC + ECR + EKS ~15 хвилин)
terraform apply
```

### 2. Налаштувати kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

### 3. Завантажити Docker-образ в ECR

```bash
# Отримати ECR URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Аутентифікація Docker в ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin $ECR_URL

# Збудувати та запушити образ
docker build -t django-app ../myproject/
docker tag django-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 4. Встановити Metrics Server (потрібен для HPA)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 5. Задеплоїти через Helm

```bash
helm install django-app ./charts/django-app

# Перевірити статус
kubectl get pods
kubectl get svc
kubectl get hpa
```

### 6. Отримати публічну IP-адресу

```bash
kubectl get svc django-app-service
# Скопіювати EXTERNAL-IP
```

---

## Команди

```bash
# Переглянути всі ресурси
kubectl get all

# Логи подів
kubectl logs -l app=django-app

# Оновити Helm-реліз
helm upgrade django-app ./charts/django-app

# Видалити Helm-реліз
helm uninstall django-app

# Знищити всю інфраструктуру
terraform destroy
```

---

## ⚠️ Попередження про вартість

| Ресурс | Орієнтовна вартість |
|--------|---------------------|
| EKS Cluster | ~$0.10/год |
| 2× t3.medium | ~$0.083/год |
| 3× NAT Gateway | ~$0.135/год |
| LoadBalancer | ~$0.025/год |
| **Разом** | **~$9/день** |

**Завжди запускайте `terraform destroy` після тестування!**
