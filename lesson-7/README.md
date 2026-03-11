# Урок 7 — Terraform + EKS + Helm на AWS


---

## Зміст
- [Опис проєкту](#опис-проєкту)
- [Структура проєкту](#структура-проєкту)
- [Модулі Terraform](#модулі-terraform)
- [Helm-чарт](#helm-чарт)
- [Результати виконання](#результати-виконання)
- [Порядок розгортання](#порядок-розгортання)
- [Знищення інфраструктури](#знищення-інфраструктури)

---

## Опис проєкту

У цьому завданні я розгорнула повноцінну хмарну інфраструктуру на AWS з використанням Terraform та задеплоїла Django-застосунок у кластер Kubernetes (EKS) за допомогою Helm-чарта.

**Що реалізовано:**
- Кластер Kubernetes (EKS) у приватних підмережах VPC
- ECR репозиторій із завантаженим Docker-образом Django (linux/amd64)
- Helm-чарт із Deployment, Service (LoadBalancer), ConfigMap та HPA
- S3 + DynamoDB для зберігання Terraform state
- HPA масштабує поди від 2 до 6 при навантаженні CPU > 70%

---

## Структура проєкту

```
lesson-7/
├── main.tf                  # Головний файл — підключення всіх модулів
├── backend.tf               # Remote backend (S3 + DynamoDB)
├── outputs.tf               # Виводи: VPC ID, ECR URL, EKS endpoint
├── .gitignore
├── README.md
│
├── modules/
│   ├── s3-backend/          # S3 бакет + DynamoDB для Terraform state
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                 # VPC, публічні/приватні підмережі, IGW, NAT GW
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                 # ECR репозиторій із lifecycle policy
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── eks/                 # EKS кластер + Node Group + IAM ролі
│       ├── eks.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml   # Django Deployment з envFrom → ConfigMap
            ├── service.yaml      # LoadBalancer Service
            ├── configmap.yaml    # Змінні середовища з теми 4
            └── hpa.yaml          # HPA: 2–6 подів при CPU > 70%
```

---

## Модулі Terraform

### `s3-backend`
- **S3 Bucket** `dariia-kulikova-terraform-state-lesson7` — зберігає `terraform.tfstate` з версіюванням та шифруванням AES-256, публічний доступ заблоковано
- **DynamoDB** `terraform-locks-lesson7` — блокування стейту через `LockID` (PAY_PER_REQUEST)

### `vpc`
- **VPC** `10.0.0.0/16` з тегами для EKS (`kubernetes.io/cluster/lesson-7-eks`)
- **3 публічні підмережі** `10.0.1–3.0/24` з тегом `kubernetes.io/role/elb`
- **3 приватні підмережі** `10.0.4–6.0/24` з тегом `kubernetes.io/role/internal-elb`
- **Internet Gateway** + **3 NAT Gateways** (по одному на AZ)

### `ecr`
- Репозиторій `lesson-7-django` з `scan_on_push = true`
- Lifecycle policy: зберігає останні 10 версій, видаляє untagged після 30 днів

### `eks`
- **EKS Cluster** v1.29, endpoint public + private access
- **Node Group** `t3.medium`, desired=2, min=1, max=4 у приватних підмережах
- **IAM ролі**: `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`

---

## Helm-чарт

### `values.yaml` — ключові параметри

```yaml
image:
  repository: 746764748053.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django
  tag: "latest"

service:
  type: LoadBalancer
  port: 80
  targetPort: 8000

autoscaler:
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70

config:
  DJANGO_SETTINGS_MODULE: "myproject.settings"
  POSTGRES_HOST: "db"
  POSTGRES_PORT: "5432"
  POSTGRES_DB: "django_db"
  POSTGRES_USER: "django_user"
  POSTGRES_PASSWORD: "pass9764gd"
```

### Компоненти чарта

| Ресурс | Опис |
|--------|------|
| `Deployment` | 2 репліки Django, образ з ECR, `envFrom: configMapRef` |
| `Service` | LoadBalancer, port 80 → containerPort 8000 |
| `ConfigMap` | Змінні середовища Django та PostgreSQL з теми 4 |
| `HPA` | Масштабування 2→6 подів при CPU > 70% |

---

## Результати виконання

### Terraform outputs після `terraform apply`

```
ecr_repository_url  = "746764748053.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django"
eks_cluster_name    = "lesson-7-eks"
eks_cluster_endpoint = "https://4EA960FE77B290207198E9E0F9FCA5EB.gr7.us-west-2.eks.amazonaws.com"
s3_bucket_id        = "dariia-kulikova-terraform-state-lesson7"
vpc_id              = "vpc-0b4f008a12b350cd1"
```

### Кластер Kubernetes — ноди готові

```
NAME                                        STATUS   ROLES    AGE    VERSION
ip-10-0-5-228.us-west-2.compute.internal   Ready    <none>   115s   v1.29.15-eks-ecaa3a6
ip-10-0-6-167.us-west-2.compute.internal   Ready    <none>   118s   v1.29.15-eks-ecaa3a6
```

### Поди запущені

```
NAME                          READY   STATUS    RESTARTS   AGE
django-app-6769c4ddc6-dpmvz   1/1     Running   0          3m30s
django-app-6769c4ddc6-nrtt2   1/1     Running   0          3m50s
```

### Service — LoadBalancer з публічним DNS

```
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP
django-app-service   LoadBalancer   172.20.131.63   a4022235d1af1490784a1e958a0c8fb4-539497145.us-west-2.elb.amazonaws.com
```

### HPA — автомасштабування активне

```
NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS
django-app-hpa   Deployment/django-app   0%/70%    2         6         2
```

---

## Порядок розгортання

### 1. Передумови

```bash
# Встановити необхідні інструменти
brew install terraform awscli helm kubectl

# Налаштувати AWS credentials
aws configure
```

### 2. Розгортання інфраструктури

```bash
cd lesson-7

# Ініціалізація з локальним стейтом
terraform init

# Спочатку створити S3 + DynamoDB для remote backend
terraform apply -target=module.s3_backend

# Розкоментувати backend блок в backend.tf та мігрувати стейт
terraform init -migrate-state

# Розгорнути всю інфраструктуру (VPC + ECR + EKS ~15 хвилин)
terraform apply
```

### 3. Налаштувати kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

### 4. Завантажити Django образ в ECR

```bash
# Аутентифікація в ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin 746764748053.dkr.ecr.us-west-2.amazonaws.com

# Збудувати для linux/amd64 (важливо для Apple Silicon!)
docker buildx build --platform linux/amd64 -t lesson-7-django ~/devops-hw3/ --load

# Тегувати і пушити
docker tag lesson-7-django:latest 746764748053.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django:latest
docker push 746764748053.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django:latest
```

### 5. Встановити Metrics Server та задеплоїти через Helm

```bash
# Metrics Server для HPA
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Деплой застосунку
helm install django-app ./charts/django-app

# Перевірити статус
kubectl get pods
kubectl get svc
kubectl get hpa
```

---

## Знищення інфраструктури

Після перевірки роботи я знищила всі ресурси, щоб уникнути зайвих витрат (~$9/день).

```bash
# Видалити Helm реліз
helm uninstall django-app

# Знищити всю Terraform інфраструктуру
terraform destroy

# Видалити S3 бакет вручну (має версіоновані об'єкти)
python3 -c "
import boto3
s3 = boto3.resource('s3')
bucket = s3.Bucket('dariia-kulikova-terraform-state-lesson7')
bucket.object_versions.delete()
bucket.delete()
print('Бакет видалено!')
"
```

---

## ⚠️ Орієнтовна вартість ресурсів

| Ресурс | Вартість |
|--------|----------|
| EKS Cluster | ~$0.10/год |
| 2× t3.medium nodes | ~$0.083/год |
| 3× NAT Gateway | ~$0.135/год |
| LoadBalancer | ~$0.025/год |
| **Разом** | **~$9/день** |

> Інфраструктуру знищено одразу після перевірки викладачем.

---

## 💡 Важливі нотатки

1. **Apple Silicon (M1/M2)**: Docker образ потрібно збирати з `--platform linux/amd64`, інакше поди падають з `exec format error`
2. **Backend bootstrap**: S3 + DynamoDB потрібно створити до активації remote backend
3. **EKS теги на VPC**: підмережі повинні мати теги `kubernetes.io/cluster/<name>` для правильної роботи LoadBalancer
