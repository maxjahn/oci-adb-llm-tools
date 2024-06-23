
TRUNCATE TABLE REVIEWS_VS;
TRUNCATE TABLE REVIEWS;
TRUNCATE TABLE STOCK;
TRUNCATE TABLE PRODUCTS;

insert into products
(	name,
	category,
	rating) 
select distinct name, category, rating from SCOTCH_REVIEWS;

INSERT INTO REVIEWS (
    PROD_ID,
	NAME,
	CATEGORY,
	DESCRIPTION
)
	SELECT DISTINCT
        p.ID as prod_id,
        sr.NAME,
		sr.CATEGORY,
		sr.DESCRIPTION
	FROM
		SCOTCH_REVIEWS sr, PRODUCTS p
        WHERE sr.name = p.name;

INSERT INTO STOCK (
    PROD_ID,
    ITEM_NAME,
    CATEGORY,
    LOCATION,
    STOCK,
    RESTOCK_DATE
)
    SELECT DISTINCT
        p.ID as prod_id,
        p.NAME                                      AS ITEM_NAME,
        p.CATEGORY                                  AS CATEGORY,
        'online'                                  AS LOCATION,
        TRUNC(DBMS_RANDOM.VALUE(0, 20))           AS STOCK,
        SYSDATE + TRUNC(DBMS_RANDOM.VALUE(0, 21)) AS RESTOCK_DATE
    FROM
         products p
    ORDER BY
        DBMS_RANDOM.RANDOM FETCH FIRST 300 ROWS ONLY;

commit;