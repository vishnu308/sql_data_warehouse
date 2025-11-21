# Superstore Data Warehouse

A production-ready Oracle data warehouse implementation for analyzing retail sales data using a dimensional modeling approach (star schema).

## 📋 Project Overview

This project demonstrates a complete data warehouse solution built on Oracle 19c, featuring:
- **ETL Pipeline**: Automated data extraction, transformation, and loading processes
- **Star Schema Design**: Optimized dimensional model for analytical queries
- **Data Quality Framework**: Built-in validation and error handling
- **Deployment Automation**: Scripts for consistent, repeatable deployments
- **Comprehensive Documentation**: Detailed guides for setup, deployment, and troubleshooting

### Business Context

The data warehouse analyzes sales data from a global superstore, providing insights into:
- Sales performance across products, regions, and customer segments
- Profitability analysis and margin trends
- Seasonal patterns and growth trajectories
- Customer behavior and purchasing patterns

## 🏗️ Architecture

### Star Schema Design

```
                    ┌─────────────┐
                    │  DIM_TIME   │
                    └──────┬──────┘
                           │
    ┌─────────────┐   ┌───┴────────┐   ┌──────────────┐
    │DIM_CUSTOMER │───│ FACT_SALES │───│ DIM_PRODUCT  │
    └─────────────┘   └───┬────────┘   └──────────────┘
                           │
                    ┌──────┴──────┐
                    │ DIM_REGION  │
                    └─────────────┘
```

**Fact Table:**
- `FACT_SALES`: Transactional sales data with measures (sales, profit, quantity, discount, shipping cost)

**Dimension Tables:**
- `DIM_TIME`: Date hierarchy (year, quarter, month, week)
- `DIM_CUSTOMER`: Customer information and segmentation
- `DIM_PRODUCT`: Product catalog with category hierarchy
- `DIM_REGION`: Geographic hierarchy (market, region, country, state, city)

## 📁 Project Structure

```
sql_data_warehouse/
├── PLSQL/                          # Database scripts
│   ├── 00_cleanup.sql              # Drop existing objects
│   ├── 00_logging_framework.sql   # Logging infrastructure (NEW)
│   ├── 01_staging.sql              # External table setup
│   ├── 02_dimensions.sql           # Dimension table DDL
│   ├── 03_fact_table.sql           # Fact table DDL
│   ├── 04_etl_dim_time.sql         # Time dimension ETL
│   ├── 05_etl_dimensions.sql       # Dimension ETL processes
│   ├── 06_etl_fact_sales.sql       # Fact table ETL
│   ├── 07_data_quality_checks.sql  # Data validation (NEW)
│   ├── 08_rollback_procedures.sql  # Backup/restore (NEW)
│   ├── 09_gather_statistics.sql    # Optimizer statistics (NEW)
│   └── check_duplicates.sql        # Duplicate detection
│
├── config/                         # Configuration files (NEW)
│   └── database_config.sql         # Environment settings
│
├── deploy/                         # Deployment automation (NEW)
│   ├── master_deploy.sql           # Main deployment script
│   ├── pre_deployment_checks.sql   # Pre-flight validation
│   └── post_deployment_validation.sql # Post-deployment tests
│
├── security/                       # Access control (NEW)
│   └── access_control.sql          # Roles and privileges
│
├── monitoring/                     # Performance monitoring (NEW)
│   └── performance_queries.sql     # Monitoring queries
│
├── tests/                          # Testing framework (NEW)
│   └── test_suite.sql              # Automated tests
│
├── Analysis/                       # Analytical queries and insights
│   ├── 01_sales_performance.sql    # Business metrics queries
│   ├── 01_insights.md              # Sales analysis insights
│   ├── 02_visualization_queries.sql # Chart data queries
│   ├── 02_visualization_insights.md # Visualization findings
│   ├── 03_excel_export_queries.sql # Excel export queries
│   └── 04_powerbi_dax_measures.txt # Power BI DAX measures
│
├── Dataset/                        # Source data
│   └── superstore.csv              # Retail sales data
│
├── DEPLOYMENT.md                   # Deployment guide (NEW)
├── CONFIG.md                       # Configuration guide (NEW)
├── TROUBLESHOOTING.md              # Common issues (NEW)
├── RELEASE_NOTES.md                # Version history (NEW)
└── README.md                       # This file
```

## 🚀 Quick Start

### Prerequisites

- Oracle Database 19c or higher
- SQL*Plus or SQL Developer
- Appropriate database privileges (CREATE TABLE, CREATE DIRECTORY, etc.)
- Access to file system for external table directory

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sql_data_warehouse
   ```

2. **Configure environment**
   - Edit `config/database_config.sql` with your environment settings
   - Update directory paths for your system

3. **Deploy the data warehouse**
   ```bash
   sqlplus username/password@database @deploy/master_deploy.sql
   ```

4. **Verify deployment**
   - Check deployment logs for any errors
   - Run post-deployment validation queries

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## 💻 Technology Stack

- **Database**: Oracle Database 19c
- **Language**: PL/SQL
- **ETL**: Custom PL/SQL procedures
- **Data Loading**: Oracle External Tables
- **Version Control**: Git
- **BI Tools**: SQL Developer, Excel, Power BI (optional)

## 📊 Sample Queries

### Total Sales by Category
```sql
SELECT 
    p.category,
    SUM(f.sales) as total_sales,
    SUM(f.profit) as total_profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) as margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;
```

### Monthly Sales Trend
```sql
SELECT 
    t.year,
    t.month,
    SUM(f.sales) as monthly_sales
FROM fact_sales f
JOIN dim_time t ON f.time_key = t.time_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;
```

More queries available in the `Analysis/` directory.

## 🔒 Security Considerations

- External table directories require appropriate OS-level permissions
- Database users should follow principle of least privilege
- Sensitive configuration files are excluded from version control
- See `security/access_control.sql` for role-based access control setup

## 📈 Performance

- Fact table uses bitmap indexes on foreign keys
- Dimension tables use B-tree indexes on surrogate keys
- Statistics are gathered automatically post-ETL
- External table provides efficient bulk loading

## 🧪 Testing

Run the test suite to validate the data warehouse:
```bash
sqlplus username/password@database @tests/test_suite.sql
```

## 📝 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Step-by-step deployment instructions
- **[CONFIG.md](CONFIG.md)**: Configuration parameters and settings
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Common issues and solutions
- **[RELEASE_NOTES.md](RELEASE_NOTES.md)**: Version history and changes

## 🤝 Contributing

This is a learning project demonstrating data warehouse best practices. Suggestions for improvements are welcome.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎓 Learning Objectives

This project demonstrates:
- Dimensional modeling (star schema)
- ETL design patterns
- PL/SQL best practices
- Data quality management
- Production deployment strategies
- Performance optimization techniques

## 📧 Support

For issues or questions:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review deployment logs
3. Consult Oracle documentation for specific errors

---

**Version**: 1.0.0 (Production)  
**Last Updated**: November 2025