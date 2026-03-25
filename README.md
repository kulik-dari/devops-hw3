# DevOps Homework

Репозиторій з домашніми завданнями курсу GoIT Neoversity DevOps.

## Уроки

| Урок | Тема | Гілка |
|------|------|--------|
| Lesson 5 | Terraform: S3 + VPC + ECR на AWS | `main` |
| Lesson 7 | EKS + Helm: Django на Kubernetes | `lesson-7` |
| Lesson 8-9 | Jenkins + ArgoCD: Повний CI/CD Pipeline | `lesson-8-9` |

## Lesson 8-9 — Jenkins + ArgoCD CI/CD

Повний CI/CD pipeline: Jenkins збирає Django образ → пушить в ECR → оновлює Helm chart → ArgoCD автоматично синхронізує в EKS.

👉 [Дивитись lesson-8-9](https://github.com/kulik-dari/devops-hw3/tree/lesson-8-9/lesson-8-9)

## Lesson 7 — EKS + Helm

EKS кластер через Terraform, Django застосунок через Helm chart з HPA.

👉 [Дивитись lesson-7](https://github.com/kulik-dari/devops-hw3/tree/lesson-7/lesson-7)

## Lesson 5 — Terraform AWS Infrastructure

Модульна Terraform інфраструктура: S3 backend, VPC з NAT Gateways, ECR репозиторій.

👉 [Дивитись lesson-5](https://github.com/kulik-dari/devops-hw3/tree/main/lesson-5)
