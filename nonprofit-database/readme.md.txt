# Nonprofit Volunteer Database Project

A comprehensive database design and data cleaning project demonstrating end-to-end ETL processes for managing volunteer activities at a nonprofit organization.

## Project Overview

This project showcases database normalization, data quality management, and business intelligence capabilities through the development of a volunteer management system. The database supports organizational reporting requirements while implementing proper data governance and privacy protection measures.

### Key Achievements
- **Data Cleaning Pipeline**: Processed 3,600+ volunteer records with comprehensive quality validation
- **Database Normalization**: Designed and implemented 3NF relational structure with proper constraints
- **Business Intelligence**: Created interactive dashboards for stakeholder reporting
- **Data Governance**: Implemented anonymization protocols for privacy protection

## Technologies Used

- **Database**: PostgreSQL
- **Development Environment**: DBeaver
- **Data Processing**: SQL (DDL, DML, aggregation functions, custom functions)
- **Visualization**: Tableau Public, Google Sheets
- **Version Control**: Git/GitHub

## Database Architecture

### Schema Design
```
volunteers (131 unique records)
├── volunteer_id (PK)
├── first_name
└── last_name

volunteer_areas (8 standardized categories)
├── area_id (PK)
└── area_name

volunteer_sessions (3,600+ activity records)
├── session_id (PK)
├── volunteer_id (FK → volunteers)
├── area_id (FK → volunteer_areas)
├── date_volunteered
├── volunteer_time
├── total_miles_personal_car
├── comments
└── timestamp
```

### Data Pipeline Process
1. **Extraction**: CSV import from volunteer management system
2. **Transformation**: Data cleaning, standardization, and validation
3. **Loading**: Population of normalized database structure
4. **Reporting**: Aggregated views for business intelligence

## Data Quality Management

### Issues Addressed
- **Missing Values**: Removed 24 completely empty records
- **Data Type Inconsistencies**: Converted text fields to appropriate numeric/date types
- **Standardization**: Consolidated 50+ volunteer area variations into 8 categories
- **Name Normalization**: Corrected misspellings and format inconsistencies
- **Date Parsing**: Handled mixed date formats with custom validation functions

### Validation Results
- **99.3% data completeness** after cleaning
- **Zero constraint violations** in final normalized structure
- **100% referential integrity** maintained across foreign key relationships

## Business Intelligence Deliverables

### Interactive Dashboards
- **Annual Summary Dashboard**: [Google Sheets Pivot Table]https://docs.google.com/spreadsheets/d/14IoAjBkNWM5I5p7F53aTACOMppaTXjFBCZWcJQbmKEo/edit?usp=sharing)
- **Monthly Trend Analysis**: [Tableau Public Visualization](https://public.tableau.com/views/nonprofitvolunteerdata/2025?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link
)

### Reporting Capabilities
- Monthly volunteer participation metrics
- Volunteer area performance analysis
- Transportation cost tracking
- Historical trend identification

## Files Structure

```
nonprofit-volunteer-database/
├── README.md
├── data/
│   ├── nonprofit_annual_script.sql
│   ├── nonprofit_annual_dashboard_data.csv
│   └── nonprofit-data-dictionary.md
├── images/
│   ├── 2025-nonprofit-viz-tableau.png
│   ├── dashboard_annual_nonprofit.png
└── .gitignore
```

## Key SQL Techniques Demonstrated

### Data Cleaning & Transformation
```sql
-- Custom date parsing function
CREATE OR REPLACE FUNCTION parse_date(date_str TEXT) 
RETURNS DATE AS $$
BEGIN
    IF date_str ~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN
        RETURN TO_DATE(date_str, 'MM/DD/YYYY');
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Dynamic volunteer area standardization
UPDATE raw_data1 
SET volunteer_area = 
  CASE 
    WHEN volunteer_area LIKE 'inventory%' THEN 'inventory'
    WHEN volunteer_area LIKE '%transport%' THEN 'transportation'
    -- Additional standardization rules...
    ELSE 'other'
  END;
```

### Business Intelligence Views
```sql
-- Monthly reporting summary
CREATE VIEW monthly_volunteer_summary AS
SELECT 
    DATE_TRUNC('month', date_volunteered) as month,
    COUNT(DISTINCT volunteer_id) as total_volunteers,
    SUM(volunteer_time) as total_hours,
    SUM(total_miles_personal_car) as total_miles,
    COUNT(*) as total_sessions
FROM volunteer_sessions 
WHERE date_volunteered IS NOT NULL
GROUP BY DATE_TRUNC('month', date_volunteered);
```

## Privacy & Compliance

### Data Protection Measures
- **Name Anonymization**: 1:1 mapping of real names to consistent fake identifiers
- **Data Minimization**: Portfolio version contains only essential analytical fields
- **Access Controls**: Role-based permission structure documented
- **Audit Trail**: Preservation of original data entry timestamps

### Compliance Framework
- Volunteer information treated as confidential
- 5-year retention policy for operational records
- Aggregated historical data retained permanently
- Export procedures documented for transparency

## Business Impact

### Operational Improvements
- **50+ volunteer area variations** reduced to 8 standardized categories
- **Automated reporting** replacing manual monthly calculations
- **Data quality score** improved from 67% to 99.3%
- **Query performance** optimized through proper indexing and normalization

### Stakeholder Value
- Real-time volunteer engagement metrics
- Resource allocation insights for program management
- Transportation cost analysis for budget planning
- Historical trend data for strategic planning

## Setup Instructions

### Prerequisites
- PostgreSQL 12+
- Database management tool (DBeaver recommended)
- Access to sample CSV data

### Installation
1. Clone this repository
2. Execute `nonprofit_annual_script.sql` in your PostgreSQL environment
3. Import your CSV data using the provided table structure
4. Run validation queries to confirm successful setup

### Sample Data Format
```csv
timestamp,last_name,first_name,volunteer_area,date_volunteered,volunteer_time,comments,total_miles_personal_car
2/19/2023 18:50:01,Smith,John,Inventory,2/18/2023,3,Distribution help,2
```

## Future Enhancements

- Integration with external volunteer management APIs
- Real-time dashboard refresh capabilities
- Predictive analytics for future volunteer hours
- Mobile-responsive reporting interface

## Documentation

- [Data Dictionary](data-portfolio/nonprofit-database/data-dictionary.md) - Comprehensive field documentation
- [SQL Scripts](data-portfolio/nonprofit-database/data/nonprofit_annual_script.sql) - Complete database implementation
- [Sample Data](data-portfolio/nonprofit-database/data/nonprofit_annual_dashboard_data.csv) - Clean dataset for analysis

---

**Project Demonstrates**: Database design, ETL processing, data quality management, SQL development, business intelligence, data governance, and stakeholder communication through technical documentation and interactive visualizations.

**Contact**: This project showcases practical database development skills applicable to nonprofit organizations, healthcare systems, educational institutions, and other mission-driven entities requiring volunteer or participant tracking capabilities.