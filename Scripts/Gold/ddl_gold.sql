/*
	====================================
	Creating Views (Gold Layer)
	====================================
	This code implements the final year of the data warehouse where a star schema is created with
		3 views: dim_customers, dim_products, and fact_sales
*/

-- Customers: crm_cust_info, erp_cust_az12, and erp_loc_a101
CREATE VIEW Gold.dim_customers AS
(
	SELECT
		ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key, -- Surrogate Key
		ci.cst_id AS customer_id,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		-- Using the CASE below is crucial as when investigating, we saw that values ci.cst_gndr and ca.gen can differ from each other
		-- for the same customer ci.cst_gndr = Female and ca.gen = Male for the same customer. We asked the senior and said that whenever
		-- we have this problem, crm data is the master, otherwise, use COALESCE.
		CASE
			WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr
			ELSE COALESCE(ca.gen, 'Unknown')
		END AS gender,
		ca.bdate AS birthdate,
		ci.cst_create_date AS creation_date
	FROM Silver.crm_cust_info AS ci
	LEFT JOIN Silver.erp_cust_az12 AS ca
	ON ci.cst_key = ca.cid
	LEFT JOIN Silver.erp_loc_a101 AS la
	ON ci.cst_key = la.cid
);

-- Products: crm_prd_info, erp_px_cat_g1v2
CREATE VIEW Gold.dim_products AS
(
	SELECT
		ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_id) AS product_key, -- Surrogate Key
		pn.prd_id AS product_id,
		pn.prd_key AS product_number,
		pn.prd_nm AS product_name,
		pn.cat_id AS category_id,
		pc.cat AS category,
		pc.subcat AS subcategory,
		pc.maintenance,
		pn.prd_cost AS cost,
		pn.prd_line AS product_line,
		pn.prd_start_dt AS start_date
	FROM Silver.crm_prd_info AS pn
	LEFT JOIN Silver.erp_px_cat_g1v2 AS pc
	ON pn.cat_id = pc.id
	WHERE pn.prd_end_dt IS NULL -- Excluding historical products
);

-- Sales: Silver.crm_sales_details
CREATE VIEW Gold.fact_sales AS
(
	SELECT
		sd.sls_ord_num AS order_number,
		pr.product_key,
		cu.customer_key,
		sd.sls_order_dt AS order_date,
		sd.sls_ship_dt AS shipping_date,
		sd.sls_due_dt AS due_date,
		sd.sls_sales AS sales_amount,
		sd.sls_quantity AS quantity,
		sd.sls_price AS price
	FROM Silver.crm_sales_details AS sd
	-- Joining to get the surrogate keys from the other 2 dimensions
	LEFT JOIN Gold.dim_products AS pr
	ON sd.sls_prd_key = pr.product_number
	LEFT JOIN Gold.dim_customers AS cu
	ON sd.sls_cust_id = cu.customer_id
);
