/*
    ==================================
    Inserting Data into Bronze Layer
    ==================================
    This script inserts data into tables of the bronze layer. First, tables are truncated, then filled with data using BULK INSERT.
    A stored procedure "load_bronze" is used to do all of that.
    Parameters: None.
    Usage: EXEC load_bronze;
*/


CREATE OR ALTER PROCEDURE Bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    SET @batch_start_time = GETDATE();

    BEGIN TRY
        PRINT '=======================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=======================================';

        PRINT '---------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '---------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: Bronze.crm_cust_info';
        TRUNCATE TABLE Bronze.crm_cust_info;

        PRINT '>> Inserting Data into Table: Bronze.crm_cust_info';
        BULK INSERT Bronze.crm_cust_info
        FROM 'D:\Data Warehouse Project\Project\Datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: Bronze.crm_prd_info';
        TRUNCATE TABLE Bronze.crm_prd_info;

        PRINT '>> Inserting Data into Table: Bronze.crm_prd_info';
        BULK INSERT Bronze.crm_prd_info
        FROM 'D:\Data Warehouse Project\Project\Datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: Bronze.crm_sales_details';
        TRUNCATE TABLE Bronze.crm_sales_details;

        PRINT '>> Inserting Data into Table: Bronze.crm_sales_details';
        BULK INSERT Bronze.crm_sales_details
        FROM 'D:\Data Warehouse Project\Project\Datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';


        PRINT '---------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '---------------------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: Bronze.erp_cust_az12';
        TRUNCATE TABLE Bronze.erp_cust_az12;

        PRINT '>> Inserting Data into Table: Bronze.erp_cust_az12';
        BULK INSERT Bronze.erp_cust_az12
        FROM 'D:\Data Warehouse Project\Project\Datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: Bronze.erp_loc_a101';
        TRUNCATE TABLE Bronze.erp_loc_a101;

        PRINT '>> Inserting Data into Table: Bronze.erp_loc_a101';
        BULK INSERT Bronze.erp_loc_a101
        FROM 'D:\Data Warehouse Project\Project\Datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: Bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE Bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data into Table: Bronze.erp_px_cat_g1v2';
        BULK INSERT Bronze.erp_px_cat_g1v2
        FROM 'D:\Data Warehouse Project\Project\Datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT 'Time Taken to Load: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' Seconds';
        PRINT '------------------';

        SET @batch_end_time = GETDATE();
        PRINT '==================================';
        PRINT 'Loading Bronze Layer is Complete';
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' Seconds';
        PRINT '==================================';
        

    END TRY
    BEGIN CATCH
        PRINT '==================================';
        PRINT 'Error Occurred During Loading Bronze Layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '==================================';
    END CATCH
END;
