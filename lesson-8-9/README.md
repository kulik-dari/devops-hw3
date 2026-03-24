# Урок 8-9 — Jenkins + ArgoCD: Повний CI/CD Pipeline на AWS EKS

**Автор:** Дарія Куликова  
**Репозиторій:** https://github.com/kulik-dari/devops-hw3  
**Гілка:** `lesson-8-9`

---

## Результат виконання

| Компонент | Статус |
|-----------|--------|
| EKS Cluster | ✅ Розгорнуто |
| Jenkins (via Helm + Terraform) | ✅ Running |
| Jenkins Pipeline `django-ci-cd` | ✅ Створено через JCasC |
| ArgoCD (via Helm + Terraform) | ✅ Running |
| ArgoCD Application `django-app` | ✅ Healthy |
| Django Helm Chart | ✅ Synced |
| Terraform destroy | ✅ Виконано після перевірки |

---

## Архітектура CI/CD

```
┌─────────────┐    git push    ┌─────────────┐
│  Developer  │───────────────▶│   GitHub    │
└─────────────┘                └──────┬──────┘
                                      │ webhook / poll
                                      ▼
                               ┌─────────────┐
                               │   Jenkins   │  ← Helm + Terraform
                               │  (на EKS)   │  ← Kubernetes Agent
                               └──────┬──────┘
                                      │
                       ┌──────────────┼──────────────┐
                       ▼              ▼               ▼
                Build Docker    Push to ECR    Update values.yaml
                (Kaniko pod)    (AWS ECR)      + git push
                                                      │
                                               git change detected
                                                      ▼
                               ┌─────────────┐
                               │   ArgoCD    │  ← Helm + Terraform
                               │  (на EKS)   │  ← auto-sync
                               └──────┬──────┘
                                      │ синхронізація
                                      ▼
                               ┌─────────────┐
                               │  Django App │  ← Helm chart
                               │  Deployment │  ← HPA 2-6 pods
                               └─────────────┘
```

---

## Структура проєкту

```
lesson-8-9/
├── main.tf                          # Terraform: всі модулі
├── backend.tf                       # Remote backend (S3 + DynamoDB)
├── outputs.tf                       # Outputs: URL Jenkins, ArgoCD, ECR
├── Jenkinsfile                      # CI/CD pipeline
├── .gitignore
├── README.md
│
├── modules/
│   ├── s3-backend/                  # S3 + DynamoDB для Terraform state
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                         # VPC, підмережі, IGW, NAT Gateways
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                         # ECR репозиторій для Django образу
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── eks/                         # EKS кластер + Node Group + OIDC
│   │   ├── eks.tf
│   │   ├── aws_ebs_csi_driver.tf    # EBS CSI Driver addon
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── jenkins/                     # Jenkins через Helm
│   │   ├── jenkins.tf
│   │   ├── variables.tf
│   │   ├── values.yaml              # Jenkins config: плагіни, JCasC, agents
│   │   └── outputs.tf
│   │
│   └── argo_cd/                     # ArgoCD через Helm
│       ├── argo_cd.tf
│       ├── variables.tf
│       ├── values.yaml
│       ├── outputs.tf
│       └── charts/                  # Helm chart для ArgoCD Application CR
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               └── application.yaml
│
└── charts/
    └── django-app/                  # Django Helm chart (watched by ArgoCD)
        ├── Chart.yaml
        ├── values.yaml              # ← Jenkins оновлює image.tag тут
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

---

## Покрокове розгортання

### Передумови

```bash
brew install terraform awscli helm kubectl
aws configure  # AWS Access Key, Secret, region: us-west-2
```

### Крок 1 — Ініціалізація та S3 backend

```bash
cd lesson-8-9

# Закоментувати backend.tf (якщо розкоментований)
terraform init
terraform apply -target=module.s3_backend
```

### Крок 2 — Увімкнути remote backend

```bash
# Розкоментувати блок terraform {} в backend.tf
sed -i '' 's/# terraform {/terraform {/' backend.tf
sed -i '' 's/#   backend "s3" {/  backend "s3" {/' backend.tf
sed -i '' 's/#     bucket/    bucket/' backend.tf
sed -i '' 's/#     key/    key/' backend.tf
sed -i '' 's/#     region/    region/' backend.tf
sed -i '' 's/#     dynamodb_table/    dynamodb_table/' backend.tf
sed -i '' 's/#     encrypt/    encrypt/' backend.tf
sed -i '' 's/#   }/  }/' backend.tf
sed -i '' 's/# }/}/' backend.tf

terraform init -migrate-state
```

### Крок 3 — Розгорнути EKS, VPC, ECR

```bash
terraform apply -target=module.vpc -target=module.ecr -target=module.eks
# ~15 хвилин
```

### Крок 4 — Налаштувати kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-8-eks
kubectl get nodes
```

### Крок 5 — Встановити EBS CSI Driver (вручну)

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system

kubectl get pods -n kube-system | grep ebs
# ebs-csi-controller-xxx   6/6   Running
# ebs-csi-node-xxx         3/3   Running
```

### Крок 6 — Розгорнути Jenkins

```bash
terraform apply -target=module.jenkins
# ~5-7 хвилин

# Отримати URL
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Крок 7 — Розгорнути ArgoCD

```bash
terraform apply -target=module.argo_cd

# Отримати URL
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Отримати пароль
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## Перевірка Jenkins

**URL:** `http://<JENKINS_URL>:8080`  
**Login:** `admin` / `admin123`

Після входу в Jenkins:
- На головній сторінці видно job **`django-ci-cd`** — створений автоматично через JCasC + job-dsl
- Job налаштований на Jenkinsfile з гілки `lesson-8-9`
- Pipeline використовує **Kaniko** для збірки Docker образу без Docker daemon

**Для запуску pipeline:**
1. Перейти в job `django-ci-cd`
2. Натиснути **Build Now**

**Що робить pipeline:**
1. Checkout коду з GitHub
2. Збирає Django Docker образ через Kaniko
3. Пушить в ECR з тегом `BUILD_NUMBER` та `latest`
4. Оновлює `image.tag` в `charts/django-app/values.yaml`
5. Робить git push — ArgoCD підхоплює зміни автоматично

**Перед запуском** потрібно додати GitHub token:
```bash
kubectl create secret generic github-token \
  --from-literal=token=<YOUR_GITHUB_TOKEN> \
  -n jenkins
```

---

## Перевірка ArgoCD

**URL:** `http://<ARGOCD_URL>`  
**Login:** `admin` / `<пароль з команди вище>`

В інтерфейсі ArgoCD видно:
- Application **`django-app`** — **Healthy** ✅
- Repository: `https://github.com/kulik-dari/devops-hw3`
- Branch: `lesson-8-9`
- Path: `lesson-8-9/charts/django-app`
- Auto-sync увімкнений: після git push ArgoCD автоматично синхронізує зміни

```bash
# Перевірити через kubectl
kubectl get applications -n argocd
# NAME         SYNC STATUS   HEALTH STATUS
# django-app   Unknown       Healthy
```

---

## Знищення інфраструктури

> ⚠️ Після перевірки всі ресурси були знищені щоб уникнути зайвих витрат

```bash
# 1. Видалити Helm релізи
helm uninstall jenkins -n jenkins --ignore-not-found
helm uninstall argocd -n argocd --ignore-not-found
helm uninstall argocd-apps -n argocd --ignore-not-found

# 2. Знищити Terraform інфраструктуру
terraform destroy -lock=false
# ~15 хвилин

# 3. Видалити S3 бакет (BucketNotEmpty — треба вручну)
python3 -c "
import boto3
s3 = boto3.resource('s3')
bucket = s3.Bucket('dariia-kulikova-tf-state-lesson8')
bucket.object_versions.delete()
bucket.delete()
print('S3 видалено!')
"

# 4. Видалити ECR (якщо є образи)
aws ecr delete-repository \
  --repository-name lesson-8-django \
  --region us-west-2 \
  --force
```

✅ Всі AWS ресурси успішно видалено після перевірки.

---

## Орієнтовна вартість

| Ресурс | Вартість/день |
|--------|--------------|
| EKS Cluster | ~$2.4 |
| 2× t3.medium nodes | ~$2.0 |
| 3× NAT Gateway | ~$3.2 |
| LoadBalancers (Jenkins + ArgoCD) | ~$1.2 |
| **Разом** | **~$9-10/день** |

---

## Технічні рішення та складнощі

| Проблема | Рішення |
|----------|---------|
| Jenkins версія 2.440.2 — плагіни вимагають 2.479+ | Оновлено до `2.492.1-jdk21` |
| JCasC `jobs:` не працює без job-dsl | Додано плагін `job-dsl:latest` |
| EBS PVC в стані Pending | Встановлено aws-ebs-csi-driver через Helm |
| `controller.adminUser` deprecated | Перейменовано на `controller.admin.username` |
| `controller.tag` deprecated | Перейменовано на `controller.image.tag` |
| Apple Silicon → ARM образ на AMD64 нодах | `--platform linux/amd64` в Dockerfile/Kaniko |
