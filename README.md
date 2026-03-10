# Урок 5 — Terraform інфраструктура на AWS

## Зміст
- [Опис проєкту](#опис-проєкту)
- [Структура проєкту](#структура-проєкту)
- [Модулі](#модулі)
  - [s3-backend](#модуль-s3-backend)
  - [vpc](#модуль-vpc)
  - [ecr](#модуль-ecr)
- [Передумови](#передумови)
- [Налаштування](#налаштування)
- [Команди запуску](#команди-запуску)
- [Порядок першого запуску](#порядок-першого-запуску)
- [Виведення після apply](#виведення-після-apply)
- [Важливі попередження](#важливі-попередження)

---

## Опис проєкту

Цей проєкт реалізує повноцінну хмарну інфраструктуру на **AWS** за допомогою **Terraform** з модульною архітектурою. Проєкт охоплює:

- 🗄️ **Централізоване зберігання Terraform-стейтів** в S3 з блокуванням через DynamoDB
- 🌐 **Мережеву інфраструктуру** (VPC) з публічними та приватними підмережами у 3 зонах доступності
- 🐳 **Реєстр Docker-образів** (ECR) з автоматичним скануванням та lifecycle-політиками

Проєкт побудований за принципами **IaC (Infrastructure as Code)** і підходить для використання в реальних продакшн-середовищах.

---

## Структура проєкту

```
lesson-5/
├── main.tf              # Кореневий модуль — підключення всіх дочірніх модулів
├── backend.tf           # Налаштування віддаленого бекенду (S3 + DynamoDB)
├── outputs.tf           # Агреговані виводи з усіх модулів
├── .gitignore           # Виключення для git (папка .terraform, стейти тощо)
├── README.md            # Документація проєкту
└── modules/
    ├── s3-backend/      # Модуль для S3 бакета та DynamoDB таблиці
    │   ├── s3.tf        # Створення S3-бакета для зберігання стейтів
    │   ├── dynamodb.tf  # Створення DynamoDB для блокування стейтів
    │   ├── variables.tf # Змінні модуля
    │   └── outputs.tf   # Виведення: ARN бакета, ім'я таблиці
    ├── vpc/             # Модуль мережевої інфраструктури
    │   ├── vpc.tf       # VPC, підмережі, IGW, NAT Gateway, EIP
    │   ├── routes.tf    # Таблиці маршрутизації та асоціації
    │   ├── variables.tf # Змінні модуля
    │   └── outputs.tf   # Виведення: ID VPC, підмереж, шлюзів
    └── ecr/             # Модуль реєстру контейнерів
        ├── ecr.tf       # ECR репозиторій, lifecycle та access policy
        ├── variables.tf # Змінні модуля
        └── outputs.tf   # Виведення: URL репозиторію, ARN
```

---

## Модулі

### Модуль `s3-backend`

Створює інфраструктуру для **централізованого зберігання Terraform-стейтів**.

**Ресурси:**
- `aws_s3_bucket` — S3-бакет для зберігання файлів `terraform.tfstate`
- `aws_s3_bucket_versioning` — увімкнено версіювання для збереження історії змін
- `aws_s3_bucket_server_side_encryption_configuration` — шифрування AES-256 за замовчуванням
- `aws_s3_bucket_public_access_block` — повне блокування публічного доступу
- `aws_dynamodb_table` — таблиця для блокування стейтів (запобігає одночасним змінам), з Point-in-Time Recovery

**Змінні:**

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|-----------------|------|
| `bucket_name` | `string` | — | Глобально унікальна назва S3-бакета |
| `table_name` | `string` | `terraform-locks` | Назва DynamoDB таблиці |

**Виводи:**

| Вивід | Опис |
|-------|------|
| `bucket_id` | Назва/ID S3-бакета |
| `bucket_arn` | ARN S3-бакета |
| `bucket_domain_name` | Domain name (URL) бакета |
| `dynamodb_table_name` | Назва DynamoDB таблиці |
| `dynamodb_table_arn` | ARN DynamoDB таблиці |

---

### Модуль `vpc`

Створює **повноцінну мережеву інфраструктуру** з високою доступністю в 3 зонах.

**Ресурси:**
- `aws_vpc` — VPC з підтримкою DNS hostname та resolution
- `aws_subnet` (публічні × 3) — підмережі `10.0.1-3.0/24` в кожній AZ, з автоматичним призначенням публічних IP
- `aws_subnet` (приватні × 3) — підмережі `10.0.4-6.0/24` в кожній AZ, без публічних IP
- `aws_internet_gateway` — Internet Gateway для вихідного трафіку публічних підмереж
- `aws_eip` (× 3) — Elastic IP адреси для NAT Gateways
- `aws_nat_gateway` (× 3) — по одному NAT Gateway в кожній AZ для відмовостійкості
- `aws_route_table` (публічна) — спільна таблиця маршрутизації → IGW
- `aws_route_table` (приватні × 3) — окремі таблиці маршрутизації → NAT GW (по одній на AZ)
- `aws_route_table_association` (× 6) — прив'язка підмереж до таблиць маршрутизації

**Змінні:**

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|-----------------|------|
| `vpc_cidr_block` | `string` | `10.0.0.0/16` | CIDR блок VPC |
| `public_subnets` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | CIDR публічних підмереж |
| `private_subnets` | `list(string)` | `["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]` | CIDR приватних підмереж |
| `availability_zones` | `list(string)` | `["us-west-2a", "us-west-2b", "us-west-2c"]` | Зони доступності |
| `vpc_name` | `string` | `lesson-5-vpc` | Префікс назв ресурсів |

**Виводи:**

| Вивід | Опис |
|-------|------|
| `vpc_id` | ID VPC |
| `vpc_cidr_block` | CIDR блок VPC |
| `public_subnet_ids` | Список ID публічних підмереж |
| `private_subnet_ids` | Список ID приватних підмереж |
| `internet_gateway_id` | ID Internet Gateway |
| `nat_gateway_ids` | Список ID NAT Gateways |
| `nat_gateway_public_ips` | Публічні IP адреси NAT Gateways |

---

### Модуль `ecr`

Створює **реєстр Docker-образів** (Elastic Container Registry) з налаштованими політиками.

**Ресурси:**
- `aws_ecr_repository` — репозиторій з AES-256 шифруванням та налаштованою мутабельністю тегів
- `aws_ecr_lifecycle_policy` — автоматичне видалення:
  - нетеговані образи старші 30 днів
  - зберігати не більше 10 останніх версійних образів (`v*`)
- `aws_ecr_repository_policy` — IAM-політика доступу для поточного AWS акаунту (push/pull/manage)

**Змінні:**

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|-----------------|------|
| `ecr_name` | `string` | — | Назва ECR репозиторію |
| `scan_on_push` | `bool` | `true` | Автоматичне сканування образів при push |
| `image_tag_mutability` | `string` | `MUTABLE` | `MUTABLE` або `IMMUTABLE` |

**Виводи:**

| Вивід | Опис |
|-------|------|
| `repository_url` | URL репозиторію для push/pull образів |
| `repository_arn` | ARN ECR репозиторію |
| `registry_id` | ID реєстру (AWS account ID) |
| `repository_name` | Назва репозиторію |

---

## Передумови

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) налаштований з дійсними credentials
- AWS акаунт з правами на S3, DynamoDB, VPC, ECR

### Налаштування AWS credentials

```bash
aws configure
# AWS Access Key ID: ваш ключ
# AWS Secret Access Key: ваш секретний ключ
# Default region name: us-west-2
# Default output format: json

# Перевірка
aws sts get-caller-identity
```

---

## Налаштування

Перед запуском відкрийте `main.tf` і вкажіть своє ім'я для S3-бакета:

```hcl
variable "student_name" {
  default = "ваше-імя-terraform-state"  # замініть на своє (має бути глобально унікальним)
}
```

---

## Команди запуску

```bash
# Ініціалізація — завантаження провайдерів та модулів
terraform init

# Перегляд плану змін без застосування
terraform plan

# Застосування змін (створення ресурсів)
terraform apply

# Знищення всіх ресурсів
terraform destroy
```

---

