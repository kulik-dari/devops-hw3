# Lesson DB Module — Універсальний Terraform-модуль для RDS / Aurora


---

## Результат виконання

| Компонент | Статус |
|-----------|--------|
| Універсальний модуль `rds` | ✅ Створено |
| RDS PostgreSQL (`use_aurora = false`) | ✅ Running |
| Aurora PostgreSQL (`use_aurora = true`) | ✅ Running |
| DB Subnet Group | ✅ Створено |
| Security Group | ✅ Створено |
| Parameter Group (`max_connections`, `log_statement`, `work_mem`) | ✅ Створено |
| Змінні з типами, описами та дефолтами | ✅ |
| `terraform validate` | ✅ Success |
| Terraform destroy після перевірки | ✅ Виконано |

---

## Результати розгортання

```
rds_aurora_endpoint   = "lesson-db-aurora.cluster-c7ugwg6iezn5.us-west-2.rds.amazonaws.com"
rds_postgres_endpoint = "lesson-db-postgres.c7ugwg6iezn5.us-west-2.rds.amazonaws.com:5432"
vpc_id                = "vpc-0a240cd72a2ae353d"
s3_bucket_id          = "dariia-kulikova-tf-state-db-module"
```

---

## Архітектура модуля

```
                    use_aurora = false          use_aurora = true
                         │                            │
                         ▼                            ▼
                  aws_db_instance            aws_rds_cluster
                  (RDS PostgreSQL            (Aurora PostgreSQL
                   або MySQL)                 або Aurora MySQL)
                                             aws_rds_cluster_instance
                                              (writer node)
                         │                            │
                         └──────────┬─────────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   Shared ресурси    │
                         │ aws_db_subnet_group │
                         │ aws_security_group  │
                         │ aws_*_parameter_group│
                         └─────────────────────┘
```

---

## Структура проєкту

```
lesson-db-module/
├── main.tf              # Підключення всіх модулів + приклади використання
├── backend.tf           # Remote backend (S3 + DynamoDB)
├── outputs.tf           # Outputs: endpoints, vpc_id
├── README.md
└── modules/
    ├── s3-backend/      # S3 бакет + DynamoDB для Terraform state
    │   ├── s3.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpc/             # VPC з публічними та приватними підмережами
    │   ├── vpc.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── rds/             # ← Головний модуль
        ├── shared.tf    # DB Subnet Group, Security Group, Parameter Groups
        ├── rds.tf       # aws_db_instance (use_aurora = false)
        ├── aurora.tf    # aws_rds_cluster + writer (use_aurora = true)
        ├── variables.tf # Всі змінні з типами, описами та дефолтами
        └── outputs.tf   # endpoint, port, sg_id, тип БД
```

---

## Що всередині модуля `rds`

### `shared.tf` — спільні ресурси для обох режимів

**`aws_db_subnet_group`** — розміщує БД у приватних підмережах VPC

**`aws_security_group`** — дозволяє доступ до порту БД (5432 для PostgreSQL, 3306 для MySQL) тільки з дозволених CIDR блоків

**`aws_db_parameter_group`** (для RDS) та **`aws_rds_cluster_parameter_group`** (для Aurora) — з параметрами:
- `max_connections` = 100 (pending-reboot)
- `log_statement` = none (immediate, тільки PostgreSQL)
- `work_mem` = 4096 KB (immediate, тільки PostgreSQL)

### `rds.tf` — стандартна RDS instance (`use_aurora = false`)

Створює `aws_db_instance` з:
- шифруванням сховища (`storage_encrypted = true`)
- підключенням до subnet group та security group
- підтримкою Multi-AZ через змінну `multi_az`

### `aurora.tf` — Aurora кластер (`use_aurora = true`)

Створює:
- `aws_rds_cluster` — кластер з master credentials
- `aws_rds_cluster_instance` — writer node

---

## Приклад використання модуля

### Звичайна RDS PostgreSQL

```hcl
module "rds_postgres" {
  source = "./modules/rds"

  identifier     = "my-postgres-db"
  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.10"
  instance_class = "db.t3.micro"

  db_name  = "appdb"
  username = "dbadmin"
  password = "MySecretPass123!"

  multi_az            = false
  subnet_ids          = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/16"]
}
```

### Aurora PostgreSQL

```hcl
module "rds_aurora" {
  source = "./modules/rds"

  identifier     = "my-aurora-cluster"
  use_aurora     = true
  engine         = "aurora-postgresql"
  engine_version = "15.10"
  instance_class = "db.t3.medium"

  db_name  = "auroradb"
  username = "auroraadmin"
  password = "AuroraSecret123!"

  subnet_ids          = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/16"]
}
```

### MySQL

```hcl
module "rds_mysql" {
  source = "./modules/rds"

  identifier     = "my-mysql-db"
  use_aurora     = false
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  db_name  = "mysqldb"
  username = "mysqladmin"
  password = "MysqlSecret123!"

  subnet_ids          = module.vpc.private_subnet_ids
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/16"]
}
```

---

## Опис всіх змінних

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|-----------------|------|
| `identifier` | `string` | — | Унікальний ідентифікатор для БД або кластера |
| `use_aurora` | `bool` | `false` | `true` = Aurora Cluster, `false` = звичайна RDS |
| `engine` | `string` | `"postgres"` | Тип: `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql` |
| `engine_version` | `string` | `"15.10"` | Версія двигуна БД |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу: `db.t3.micro`, `db.r6g.large` тощо |
| `allocated_storage` | `number` | `20` | Розмір диску в GB (тільки для RDS, не Aurora) |
| `storage_type` | `string` | `"gp2"` | Тип сховища: `gp2`, `gp3`, `io1` |
| `db_name` | `string` | — | Назва бази даних |
| `username` | `string` | — | Логін адміністратора БД |
| `password` | `string` | — | Пароль адміністратора (sensitive) |
| `multi_az` | `bool` | `false` | Увімкнути Multi-AZ (тільки для RDS) |
| `subnet_ids` | `list(string)` | — | ID підмереж для DB Subnet Group |
| `vpc_id` | `string` | — | ID VPC для Security Group |
| `allowed_cidr_blocks` | `list(string)` | `["10.0.0.0/16"]` | CIDR блоки для доступу до БД |
| `backup_retention_period` | `number` | `7` | Кількість днів зберігання бекапів |
| `max_connections` | `string` | `"100"` | PostgreSQL/MySQL: максимальна кількість з'єднань |
| `log_statement` | `string` | `"none"` | PostgreSQL: рівень логування SQL (`none`, `ddl`, `mod`, `all`) |
| `work_mem` | `string` | `"4096"` | PostgreSQL: пам'ять для сортування в KB |

---

## Як змінити тип БД, engine, клас інстансу

**Перейти на MySQL замість PostgreSQL:**
```hcl
engine         = "mysql"
engine_version = "8.0"
```

**Перейти на Aurora MySQL:**
```hcl
use_aurora     = true
engine         = "aurora-mysql"
engine_version = "8.0"
```

**Production клас інстансу:**
```hcl
instance_class = "db.r6g.large"
```

**Увімкнути Multi-AZ для RDS:**
```hcl
multi_az = true
```

**Детальне логування SQL:**
```hcl
log_statement = "all"
work_mem      = "65536"
```

---

## Порядок розгортання

```bash
cd lesson-db-module

# Крок 1: S3 backend
terraform init
terraform apply -target=module.s3_backend

# Крок 2: Розкоментувати backend.tf і мігрувати стейт
terraform init -migrate-state

# Крок 3: Розгорнути все
terraform apply
```

---

## Знищення ресурсів

> ✅ Всі ресурси знищені після перевірки

```bash
terraform destroy -lock=false

# Видалити S3 вручну
python3 -c "
import boto3
s3 = boto3.resource('s3')
bucket = s3.Bucket('dariia-kulikova-tf-state-db-module')
bucket.object_versions.delete()
bucket.delete()
print('S3 видалено!')
"
```

---

## Орієнтовна вартість

| Ресурс | Вартість |
|--------|----------|
| RDS `db.t3.micro` | ~$0.017/год (~$12/міс) |
| Aurora `db.t3.medium` | ~$0.082/год (~$59/міс) |
| Storage 20GB gp2 | ~$0.023/GB/міс |

> ⚠️ Завжди запускайте `terraform destroy` після перевірки!
