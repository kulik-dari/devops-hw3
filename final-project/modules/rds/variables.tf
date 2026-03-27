variable "identifier" {
  type        = string
  description = "Унікальний ідентифікатор для БД / кластера"
}

variable "use_aurora" {
  type        = bool
  default     = false
  description = "true = Aurora Cluster, false = звичайна RDS instance"
}

variable "engine" {
  type        = string
  default     = "postgres"
  description = "Тип двигуна БД: postgres, mysql, aurora-postgresql, aurora-mysql"
}

variable "engine_version" {
  type        = string
  default     = "15.4"
  description = "Версія двигуна БД"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Клас інстансу: db.t3.micro, db.t3.medium, db.r6g.large тощо"
}

variable "allocated_storage" {
  type        = number
  default     = 20
  description = "Розмір сховища в GB (тільки для RDS, не Aurora)"
}

variable "storage_type" {
  type        = string
  default     = "gp2"
  description = "Тип сховища: gp2, gp3, io1"
}

variable "db_name" {
  type        = string
  description = "Назва бази даних"
}

variable "username" {
  type        = string
  description = "Ім'я адміністратора БД"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Пароль адміністратора БД"
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Увімкнути Multi-AZ для RDS (тільки для звичайної RDS)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Список ID підмереж для DB Subnet Group"
}

variable "vpc_id" {
  type        = string
  description = "ID VPC для Security Group"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "CIDR блоки яким дозволено доступ до БД"
}

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "Кількість днів зберігання backup (0 = вимкнено)"
}

variable "max_connections" {
  type        = string
  default     = "100"
  description = "Максимальна кількість з'єднань (параметр max_connections)"
}

variable "log_statement" {
  type        = string
  default     = "none"
  description = "Рівень логування SQL (PostgreSQL): none, ddl, mod, all"
}

variable "work_mem" {
  type        = string
  default     = "4096"
  description = "Пам'ять для операцій сортування в KB (PostgreSQL: work_mem)"
}
