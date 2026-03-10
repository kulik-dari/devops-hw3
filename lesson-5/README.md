# XYZ Vulnerability Database

A comprehensive vulnerability data collection and management system that aggregates security vulnerabilities from multiple sources into a unified PostgreSQL database.

## Overview

This project provides a set of importers that collect vulnerability data from various security sources, including:

- National Vulnerability Database (NVD)
- GitHub Security Advisories (GHSA)
- WordPress Vulnerabilities
- ExploitDB
- Open Source Vulnerability (OSV)
- Microsoft Security Response Center (MSRC)
- Red Hat Security Data
- Japanese Vulnerability Notes (JVN)
- Apple Security Updates
- Packet Storm Security

## Database Schema

The system uses a PostgreSQL database with multiple tables to store vulnerability data from different sources. The core table is `vulnerabilities`, which has the following structure:

```
                   Table "public.vulnerabilities"
          Column           | Type  | Collation | Nullable | Default 
---------------------------+-------+-----------+----------+---------
 cve_id                    | text  |           |          | 
 ghsa_id                   | text  |           |          | 
 package_name              | text  |           |          | 
 vendor                    | text  |           |          | 
 product                   | text  |           |          | 
 vulnerable_version_ranges | jsonb |           |          | 
 fixed_version             | jsonb |           |          | 
 description               | text  |           |          | 
 severity                  | text  |           |          | 
 cwe_id                    | text  |           |          | 
 publication_date          | date  |           |          | 
 last_modified_date        | date  |           |          | 
 refs                      | jsonb |           |          | 
 source                    | text  |           |          | 
 review_status             | text  |           |          | 
 osv_id                    | text  |           |          | 
 source_data               | jsonb |           |          | 
Indexes:
    "idx_vuln_ids" btree (cve_id, ghsa_id, osv_id)
    "idx_vuln_source" btree (source, cve_id, ghsa_id, osv_id)
    "idx_vuln_source_data" gin (source_data) WHERE source_data IS NOT NULL
    "vulnerabilities_id_unique" UNIQUE CONSTRAINT, btree (cve_id, ghsa_id, osv_id)
Check constraints:
    "vuln_id_check" CHECK (cve_id IS NOT NULL OR ghsa_id IS NOT NULL OR osv_id IS NOT NULL)
```

Other tables in the database include:

| Table Name | Description |
|------------|-------------|
| vulnerabilities | Core table containing unified vulnerability data from NVD, GHSA, and OSV |
| exploitdb | Exploits from Exploit Database |
| import_metadata | Tracks import operations and their status |
| jvn_vulnerabilities | Vulnerabilities from Japanese Vulnerability Notes |
| malicious_packages | Known malicious software packages |
| msrc_vulnerabilities | Microsoft Security Response Center vulnerabilities |
| osv_vulnerabilities | Open Source Vulnerabilities |
| redhat_vulnerabilities | Red Hat Security Data |
| wp_vulnerabilities | WordPress plugin and theme vulnerabilities |

## Prerequisites

1. Python 3.x
2. PostgreSQL database or Cloud SQL (GCP)
3. Required environment variables (in a `.env` file):
   ```bash
   DB_HOST=127.0.0.1
   DB_PORT=5433
   DB_NAME=vulnerability_data
   DB_USER=postgres
   DB_PASSWORD=your_database_password
   NVD_API_KEY=your_nvd_api_key  # Optional but recommended
   GITHUB_TOKEN=your_github_token  # Required for GitHub Security Advisories
   ```

4. For Cloud SQL Proxy connections (optional):
   - [Cloud SQL Proxy](https://cloud.google.com/sql/docs/postgres/connect-admin-proxy) installed
   - GCP service account credentials with appropriate permissions
   - GCP instance connection name (project:region:instance)

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/XYZ-DB.git
   cd XYZ-DB
   ```

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

## Unified CLI Tool (XYZ)

The system includes a unified command-line interface tool that combines the functionality of both the vulnerability search and system scanner tools:

```bash
# Scan for a specific vulnerability
./xyz scan -v CVE-2021-44228

# Scan for a specific package
./xyz scan -p log4j

# Scan for a package in a specific ecosystem
./xyz scan -p axios -e npm

# Scan with exploit information
./xyz scan -v CVE-2021-44228 -x

# Scan system packages
./xyz scan -i

# Scan Python packages
./xyz scan --python

# Scan Node.js packages (will show transitive dependencies)
./xyz scan --node

# Scan everything
./xyz scan

# Scan with Cloud SQL Proxy
./xyz scan --use-proxy --instance "project:region:instance" --credentials-file /path/to/credentials.json

# Scan with pro tier and API key
./xyz scan --tier pro --api-key pro_12345abcdef

# Scan with premium tier and API key
./xyz scan --tier premium --api-key premium_12345abcdef6789
```

## Cloud SQL Proxy Integration

The system now supports connecting to a GCP-hosted PostgreSQL database through Cloud SQL Proxy:

1. Start the Cloud SQL Proxy manually (recommended):
   ```bash
   cloud-sql-proxy 'project:region:instance' --credentials-file=/path/to/credentials.json --port=5433
   ```

2. Run the scanner with proxy connection parameters:
   ```bash
   ./xyz scan --use-proxy --instance "project:region:instance" --credentials-file /path/to/credentials.json
   ```

3. Or specify database connection parameters directly:
   ```bash
   ./xyz scan --db-host 127.0.0.1 --db-port 5433 --db-name vulnerability_data --db-user postgres --db-password your_password
   ```

## Billing/Credits System

The system now includes a billing/credits system with scan limits based on user tiers:

| Tier | Daily Scan Limit | API Key Required | Database Access |
|------|-----------------|------------------|----------------|
| Free | 5 scans | No | Limited tables* |
| Pro | 25 scans | Yes | Extended tables** |
| Premium | 100 scans | Yes | All tables |

*Free tier has access to: vulnerabilities, exploitdb, malicious_packages, osv_vulnerabilities

**Pro tier adds access to: jvn_vulnerabilities, msrc_vulnerabilities, redhat_vulnerabilities, wp_vulnerabilities

To specify a tier and API key:

```bash
# Free tier (default)
./xyz scan

# Pro tier
./xyz scan --tier pro --api-key YOUR_API_KEY

# Premium tier
./xyz scan --tier premium --api-key YOUR_API_KEY

# Override default scan limit
./xyz scan --tier pro --api-key YOUR_API_KEY --scan-limit 30
```

### API Key Format

API keys follow a specific format based on the tier:

- Pro tier: Must start with `pro_` and be at least 12 characters long
- Premium tier: Must start with `premium_` and be at least 16 characters long

Example API keys:
- Pro tier: `pro_12345abcdef`
- Premium tier: `premium_12345abcdef6789`

## Vulnerability Scanner

The system includes a vulnerability scanner that can check packages against the database:

```bash
# Scan a single package
python scanner.py --input "vendor:product:version"

# Scan multiple packages from a file
python scanner.py --file packages.txt

# Scan packages from stdin
cat packages.txt | python scanner.py

# Output formats
python scanner.py --input "vendor:product:version" --format json
python scanner.py --input "vendor:product:version" --format csv
python scanner.py --input "vendor:product:version" --format text

# Save output to file
python scanner.py --input "vendor:product:version" --output results.json
```

## Running Importers

Each importer can be run in two modes:
- **Incremental mode**: Imports only new entries since the last import
- **Full mode**: Reimports the entire dataset

### Common Parameters

Most collectors support these additional parameters:

```bash
# Limit the number of items to process
python data_ingestion/osv1.py --limit 1000

# Set custom batch size for processing
python data_ingestion/osv1.py --batch-size 200

# Filter by age (process only recent items)
python data_ingestion/osv1.py --age-filter 7

# Specify custom logging interval
python data_ingestion/osv1.py --log-interval 500

# Debug mode for verbose output
python data_ingestion/osv1.py --debug
```

### 1. NVD (National Vulnerability Database)

```bash
# Incremental mode (default)
python -m data_ingestion.nvd incremental

# Full mode
python -m data_ingestion.nvd full
```

### 2. GitHub Security Advisories

```bash
# Incremental mode (default)
python -m data_ingestion.github incremental

# Full mode
python -m data_ingestion.github full
```

### 3. OSV (Open Source Vulnerabilities)

```bash
# Incremental mode (default)
python -m data_ingestion.osv1 incremental

# Full mode
python -m data_ingestion.osv1 full
```

### 4. ExploitDB

```bash
# Incremental mode (default)
python -m data_ingestion.exploitdb incremental

# Full mode
python -m data_ingestion.exploitdb full
```

### 5. OSSF Malicious Packages

```bash
# Incremental mode (default)
python -m data_ingestion.ossf_malicious1 incremental

# Full mode
python -m data_ingestion.ossf_malicious1 full
```

### 6. Microsoft Vulnerabilities

```bash
# Incremental mode (default)
python -m data_ingestion.microsoft_vulns incremental

# Full mode
python -m data_ingestion.microsoft_vulns full
```

### 7. WordPress Vulnerabilities

```bash
# Incremental mode (default)
python -m data_ingestion.wpvulns incremental

# Daily updates
python -m data_ingestion.wpvulns_daily
```

### 8. CVE Search

```bash
# Incremental mode (default)
python -m data_ingestion.cve_search incremental

# Full mode
python -m data_ingestion.cve_search full
```

### Running All Importers

To run all collectors in incremental mode:

```bash
for collector in osv1 exploitdb ossf_malicious1 github microsoft_vulns wpvulns cve_search nvd; do
    python -m data_ingestion.${collector} incremental
done
```

To run all collectors in full mode:

```bash
for collector in osv1 exploitdb ossf_malicious1 github microsoft_vulns wpvulns cve_search nvd; do
    python -m data_ingestion.${collector} full
done
```

### Automated Imports

Use the provided shell script to run all importers:

```bash
./run_importers.sh
```

The script automatically determines whether to run in full mode (on Sundays) or incremental mode (other days).

## Useful Database Queries

### Count Vulnerabilities by Source

```sql
-- Total vulnerabilities by source
SELECT 'OSV' as source, COUNT(*) FROM osv_vulnerabilities
UNION ALL
SELECT 'ExploitDB', COUNT(*) FROM exploitdb
UNION ALL
SELECT 'MSRC', COUNT(*) FROM msrc_vulnerabilities
UNION ALL
SELECT 'WordPress', COUNT(*) FROM wp_vulnerabilities
UNION ALL
SELECT 'Malicious Packages', COUNT(*) FROM malicious_packages
ORDER BY source;

-- Recent vulnerabilities (last 7 days)
SELECT 'OSV' as source, COUNT(*) 
FROM osv_vulnerabilities 
WHERE modified_at >= NOW() - INTERVAL '7 days'
UNION ALL
SELECT 'MSRC', COUNT(*) 
FROM msrc_vulnerabilities 
WHERE last_modified_date >= NOW() - INTERVAL '7 days'
UNION ALL
SELECT 'WordPress', COUNT(*) 
FROM wp_vulnerabilities 
WHERE updated_at >= NOW() - INTERVAL '7 days'
ORDER BY source;

-- Check import status
SELECT source, last_import_date, status, items_processed
FROM import_metadata
ORDER BY last_import_date DESC;
```

### Monitor Database Size

```sql
-- Table sizes
SELECT
    relname as table_name,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_table_size(relid)) as table_size,
    pg_size_pretty(pg_indexes_size(relid)) as index_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_table_size(relid)) as external_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

## Development

### Adding a New Importer

1. Create a new Python file in the `data_ingestion` directory
2. Implement the importer with support for both incremental and full modes
3. Add the importer to the `run_importers.sh` script

### Testing

Run tests using pytest:

```bash
pytest
```

## Troubleshooting

If you encounter any issues:
1. Check the logs for error messages
2. Verify database connectivity
3. Ensure all required environment variables are set
4. Verify API access for sources that require authentication

## Vulnerability Search Tool

The project includes a comprehensive search tool that can search for vulnerabilities across all tables in the database. You can search by vulnerability ID (CVE, GHSA, OSV) or by package name.

### Features

- Search by vulnerability ID (CVE, GHSA, OSV) across all database tables
- Search by package name (with optional ecosystem filter)
- Identify malicious packages and display detailed information
- Show available exploits for vulnerabilities
- Check if vulnerabilities are exploited in the wild
- Display affected packages for a specific vulnerability
- Support for multiple OSV sources (Ubuntu, Debian, Alpine, RedHat, SUSE, etc.)
- Optimized performance with batch queries and UNION operations
- Output in table or JSON format

### Usage

```bash
# Search by vulnerability ID
python -m tools.cve_search vuln CVE-2021-44228

# Show affected packages for a vulnerability
python -m tools.cve_search vuln CVE-2021-44228 --affected

# Search by package name
python -m tools.cve_search package log4j

# Search by package name with ecosystem
python -m tools.cve_search package axios --ecosystem npm

# Output in JSON format
python -m tools.cve_search vuln CVE-2021-44228 --format json
```

### Output Information

The search results include:

- Basic vulnerability information (ID, description, severity, etc.)
- Status indicators for malicious packages, available exploits, and exploited in the wild
- Detailed exploit information when available
- Detailed malicious package information when available
- Exploited in the wild vulnerability information when available
- Affected package details (vulnerable versions, fixed versions)

## System Package Scanner

The project includes a system package scanner that can identify vulnerabilities in currently installed packages on your system. The scanner checks system packages, Python packages, and Node.js packages against the vulnerability database.

### Features

- Scan system packages (Homebrew, apt, rpm, pacman)
- Scan Python packages (pip)
- Scan Node.js packages (npm)
- Identify critical and high severity vulnerabilities
- Detect malicious packages
- Find packages with known exploits
- Identify vulnerabilities exploited in the wild
- Detect and track npm transitive dependencies
- Provide detailed vulnerability information

### Usage

```bash
# Scan all package types
python -m tools.system_scanner --all

# Scan only system packages
python -m tools.system_scanner --system

# Scan only Python packages
python -m tools.system_scanner --python

# Scan only Node.js packages
python -m tools.system_scanner --node
```

### Testing

A test script is available to verify that both the vulnerability search tool and system scanner are working correctly:

```bash
# Run all tests
python -m tools.test_tools
```

The test script will:
1. Test the vulnerability search by ID
2. Test the package search
3. Test the Python package scanner
4. Test the system package scanner

### XYZ CLI Tool

A unified command-line interface tool called `XYZ` is available that combines the functionality of both the vulnerability search and system scanner tools:

```bash
# Scan for a specific vulnerability
./xyz scan -v CVE-2021-44228

# Scan for a specific package
./xyz scan -p log4j

# Scan for a package in a specific ecosystem
./xyz scan -p axios -e npm

# Scan with exploit information
./xyz scan -v CVE-2021-44228 -x

# Scan system packages
./xyz scan -i

# Scan Python packages
./xyz scan --python

# Scan Node.js packages (will show transitive dependencies)
./xyz scan --node

# Scan everything (all installed packages)
./xyz scan
```

### Output Information

The scanner output includes:

- Summary table of vulnerabilities by package
- Detailed information about critical and high severity vulnerabilities
- Information about malicious packages
- Information about vulnerabilities with known exploits
- Information about vulnerabilities exploited in the wild
- Transitive dependency information for npm packages:
  - Clearly marks which vulnerabilities are in transitive dependencies
  - Shows dependency paths for vulnerabilities in transitive dependencies
  - Provides a count of vulnerabilities found in transitive dependencies

## Useful Queries

The following SQL queries can be used to explore and analyze the vulnerability data in the database.

### Microsoft (MSRC) Vulnerabilities

```sql
-- Get basic information about Microsoft vulnerabilities
SELECT id, document_title, published_at, modified_at 
FROM msrc_vulnerabilities 
ORDER BY modified_at DESC LIMIT 10;

-- Get detailed information including title and description
SELECT id, cvrf_data->'Title'->'Value' as title, 
       jsonb_pretty(cvrf_data->'Notes'->0->'Value') as description 
FROM msrc_vulnerabilities 
ORDER BY modified_at DESC LIMIT 5;

-- Extract specific fields from CVRF data
SELECT id, jsonb_pretty(cvrf_data->'CVSSScoreSets') as cvss_score 
FROM msrc_vulnerabilities 
WHERE id = 'CVE-2025-0999';
```

### OSV Vulnerabilities

```sql
-- Get basic information about OSV vulnerabilities
SELECT id, summary, published_at, modified_at 
FROM osv_vulnerabilities 
ORDER BY modified_at DESC LIMIT 10;

-- Get detailed information about a specific vulnerability
SELECT id, summary, details, jsonb_pretty(affected) as affected_packages 
FROM osv_vulnerabilities 
WHERE id = 'RUSTSEC-2025-0008';
```

### RedHat Vulnerabilities

```sql
-- Get basic information about RedHat vulnerabilities
SELECT cve_id, package_name, description, severity, publication_date, last_modified_date 
FROM redhat_vulnerabilities 
ORDER BY last_modified_date DESC LIMIT 10;
```

### ExploitDB

```sql
-- Get basic information about exploits
SELECT id, description, date_published, author, type, platform, cve_id 
FROM exploitdb 
ORDER BY date_published DESC LIMIT 10;

-- Find exploits for a specific CVE
SELECT id, description, date_published, author, type, platform 
FROM exploitdb 
WHERE cve_id = 'CVE-2022-37454';
```

### WordPress Vulnerabilities

```sql
-- Get basic information about WordPress vulnerabilities
SELECT wpvulndb_id, title, component_type, slug, fixed_in_version, 
       published_date, updated_date, cve_id 
FROM wp_vulnerabilities 
ORDER BY updated_date DESC LIMIT 10;

-- Get detailed information about a specific WordPress vulnerability
SELECT wpvulndb_id, title, description, component_type, slug, 
       jsonb_pretty(affected_versions) as affected_versions, 
       fixed_in_version, jsonb_pretty(reference_urls) as reference_urls, 
       vulnerability_type, cvss_score, cvss_vector, cve_id 
FROM wp_vulnerabilities 
WHERE wpvulndb_id = '107791b5286d55acd2a3fcea26e23e50c87c9380aebbc5fccab7f33abc59d64e';
```

### Malicious Packages

```sql
-- Get basic information about malicious packages
SELECT package_name, package_ecosystem, description, detection_date, source, severity 
FROM malicious_packages 
ORDER BY detection_date DESC LIMIT 10;

-- Get detailed information about a specific malicious package
SELECT package_name, package_ecosystem, description, detection_date, 
       jsonb_pretty(refs) as references, jsonb_pretty(affected_versions) as affected_versions, 
       jsonb_pretty(metadata) as metadata 
FROM malicious_packages 
WHERE package_name = '@c11-lib-ts/document-handler';

-- Get distribution of malicious packages by ecosystem
SELECT package_ecosystem, COUNT(*) as count 
FROM malicious_packages 
GROUP BY package_ecosystem 
ORDER BY count DESC;

-- Get distribution of malicious packages by detection date (month)
SELECT DATE_TRUNC('month', detection_date) as month, COUNT(*) as count 
FROM malicious_packages 
GROUP BY month 
ORDER BY month DESC LIMIT 12;
```

### Cross-Reference Queries

```sql
-- Find vulnerabilities across multiple sources for the same CVE
SELECT 'NVD' as source, cve_id, description, severity, publication_date 
FROM vulnerabilities 
WHERE cve_id = 'CVE-2022-37454' AND source = 'nvd'
UNION ALL
SELECT 'RedHat' as source, cve_id, description, severity, publication_date 
FROM redhat_vulnerabilities 
WHERE cve_id = 'CVE-2022-37454'
UNION ALL
SELECT 'WordPress' as source, cve_id, description, NULL as severity, published_date as publication_date 
FROM wp_vulnerabilities 
WHERE cve_id = 'CVE-2022-37454'
UNION ALL
SELECT 'ExploitDB' as source, cve_id, description, NULL as severity, date_published as publication_date 
FROM exploitdb 
WHERE cve_id = 'CVE-2022-37454';

-- Find all vulnerabilities for a specific package
SELECT cve_id, package_name, description, severity, publication_date, source 
FROM vulnerabilities 
WHERE package_name = 'log4j'
UNION ALL
SELECT cve_id, package_name, description, severity, publication_date, 'redhat' as source 
FROM redhat_vulnerabilities 
WHERE package_name = 'log4j';

-- Get vulnerability statistics by source
SELECT 'NVD' as source, COUNT(*) as count 
FROM vulnerabilities 
WHERE source = 'nvd'
UNION ALL
SELECT 'GitHub' as source, COUNT(*) as count 
FROM vulnerabilities 
WHERE source = 'github'
UNION ALL
SELECT 'RedHat' as source, COUNT(*) as count 
FROM redhat_vulnerabilities
UNION ALL
SELECT 'MSRC' as source, COUNT(*) as count 
FROM msrc_vulnerabilities
UNION ALL
SELECT 'OSV' as source, COUNT(*) as count 
FROM osv_vulnerabilities
UNION ALL
SELECT 'WordPress' as source, COUNT(*) as count 
FROM wp_vulnerabilities
UNION ALL
SELECT 'ExploitDB' as source, COUNT(*) as count 
FROM exploitdb
UNION ALL
SELECT 'Malicious Packages' as source, COUNT(*) as count 
FROM malicious_packages
ORDER BY count DESC;
```

## Future Implementations

The following collectors are planned for future implementation:

1. Apple Security Updates
2. PacketStorm Vulnerabilities

## License

[Your License Information]

## Contributors

[Your Contributor Information]