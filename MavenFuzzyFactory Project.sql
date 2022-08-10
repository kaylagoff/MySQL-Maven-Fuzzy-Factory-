-- Maven Fuzzy Factory code project for Maven Analytics Advanced MySQL course
-- Showing trends for gsearch sessions and orders by month

SELECT YEAR(website_sessions.created_at) AS year,
		MONTH(website_sessions.created_at) AS month, 
        COUNT(DISTINCT orders.order_id) AS orders, 
        COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
         COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS con_rt
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
		AND website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;

-- Monthly trend for gsearch by nonbrand and brand campaigns 

SELECT
		YEAR(website_sessions.created_at) AS year,
		MONTH(website_sessions.created_at) AS month, 
        COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders, 
        COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_orders, 
        COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions, 
        COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
		AND website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;

-- Monthly trends for sessions and orders split by device type for nonbrand campaigns

SELECT
		YEAR(website_sessions.created_at) AS year,
		MONTH(website_sessions.created_at) AS month, 
        COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders, 
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders, 
        COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions, 
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
		AND website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;

-- Monthly trends for gsearch compared to monthly trends for all other channels (bsearch)

SELECT distinct
		utm_source,
        utm_campaign,
        http_referer
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';

SELECT
		YEAR(website_sessions.created_at) AS year,
		MONTH(website_sessions.created_at) AS month, 
        COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_sessions, 
        COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_sessions,
		COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_sessions,
		COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_sessions
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;

-- Session to order conversion rates by month for the first 8 months

SELECT YEAR(website_sessions.created_at) AS year,
		MONTH(website_sessions.created_at) AS month, 
        COUNT(DISTINCT orders.order_id) AS orders, 
        COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
		COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS con_rt
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;

-- Estimate revenue for the gsearch lander test
-- Test 6/19-7/28

SELECT 
	MIN(website_pageview_id) AS first_test_pv
    FROM website_pageviews
    WHERE pageview_url = '/lander-1'; -- first pageview 23504
    
CREATE TEMPORARY TABLE pv_first_test
SELECT website_pageviews.website_session_id,
		MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_sessions.website_session_id = website_pageviews.website_session_id
	AND website_pageviews.created_at < '2012-07-28'
	AND website_pageviews.website_pageview_id >= 23504
	AND utm_campaign = 'nonbrand'
    AND utm_source = 'gsearch'
GROUP BY 1;

CREATE TEMPORARY TABLE nonbrand_test_lp
SELECT pv_first_test.website_session_id, 
		website_pageviews.pageview_url AS landing_page
FROM pv_first_test
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = pv_first_test.website_session_id
WHERE website_pageviews.pageview_url IN ('/home', '/lander-1');

SELECT 
        landing_page,
        COUNT(DISTINCT orders.order_id) AS orders, 
        COUNT(DISTINCT nonbrand_test_lp.website_session_id) AS sessions,
		COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT nonbrand_test_lp.website_session_id) AS con_rt
FROM nonbrand_test_lp
LEFT JOIN orders
	ON orders.website_session_id = nonbrand_test_lp.website_session_id
GROUP BY landing_page;

-- Finding most recent pageview for gsearch nonbrand where traffic was sent /home

SELECT
	MAX(website_sessions.website_session_id)
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
		AND pageview_url = '/home'
        AND website_sessions.created_at < '2012-11-27'; -- max session id 17145
        
SELECT
	COUNT(website_session_id)
FROM website_sessions
WHERE utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
        AND website_sessions.created_at < '2012-11-27'
        AND website_session_id > 17145; -- 22,972 sessions since test
-- X .0087 incremental conversion = 202 incremental orders since 7/29

-- Conversion funnel from /lander-1 and /home for same time period

CREATE TEMPORARY TABLE cfunnel
SELECT
	website_session_id,
    MAX(home_page) AS home_view,
    MAX(lander_page) AS lander_view,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
   -- website_pageviews.created_at AS pageview_created_at,
	CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END as home_page,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END as lander_page,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END as products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END as mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END as cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END as shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END as billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.created_at < '2012-07-28'
    AND website_sessions.created_at > '2012-06-19'
ORDER BY website_sessions.website_session_id, website_pageviews.created_at) AS pv_level
GROUP BY website_session_id;

SELECT
	CASE WHEN home_view = 1 THEN 'saw_home'
			WHEN lander_view = 1 THEN 'saw_lander'
            ELSE 'error'
            END AS segment,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM cfunnel
GROUP BY 1;

SELECT
	CASE WHEN home_view = 1 THEN 'saw_home'
			WHEN lander_view = 1 THEN 'saw_lander'
            ELSE 'error'
            END AS segment,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) /COUNT(DISTINCT website_session_id) AS lander_clickthrough,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_clickthrough,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_clickthrough,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_clickthrough,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_clickthrough,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_clickthrough
FROM cfunnel
GROUP BY 1;

-- Impact of billing test, lift generated from test 9/10-11/10 in terms of revenue per billing page session 

SELECT billing_v,
		COUNT(DISTINCT website_session_id) AS sessions,
		SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_bill
FROM 
(
SELECT website_pageviews.website_session_id,
		website_pageviews.pageview_url AS billing_v,
        orders.order_id,
        orders.price_usd
FROM website_pageviews
LEFT JOIN orders
	ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at < '2012-11-10'
		AND website_pageviews.created_at > '2012-09-10'
        AND website_pageviews.pageview_url IN ('/billing', '/billing-2')) AS billing_pv
GROUP BY 1;
-- /billing = $22.83; /billing-2 = $31.34; resulting in lift of $8.52 per billing page view

-- Number of billing page sessions last month 

SELECT
	COUNT(website_session_id) AS billing_last_month
FROM website_pageviews
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2')
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27';
    
-- Volume growth by quarter
USE mavenfuzzyfactory;

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2014-12-31'
GROUP BY 1,2
ORDER BY 1,2;

-- Quarterly figures since launch for session to order conversion rate, revenue per order, and revenue per session

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd) / COUNT(DISTINCT orders.order_id) AS rev_per_order,
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS rev_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

-- Quarterly view of orders from gsearch nonbrand, bsearch nonbrand, brand search overall, organic search, and direct type in

SELECT 
		YEAR(sessions_w_channel_grp.created_at) AS yr,
		QUARTER(sessions_w_channel_grp.created_at) AS qtr,
        COUNT(DISTINCT CASE WHEN channel_group = 'gsearch_nonbrand' THEN order_id ELSE NULL END) AS gsearch_nonbrand_orders,
        COUNT(DISTINCT CASE WHEN channel_group = 'bsearch_nonbrand'  THEN order_id ELSE NULL END) AS bsearch_nonbrand_orders,
		COUNT(DISTINCT CASE WHEN channel_group = 'brand' THEN order_id ELSE NULL END) AS brand_orders,
        COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN order_id ELSE NULL END) AS direct_orders,
        COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN order_id ELSE NULL END) AS organic_orders
        
FROM 
(SELECT website_session_id,
		created_at,
        CASE
			WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
            WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN 'gsearch_nonbrand'
            WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN 'bsearch_nonbrand'
            WHEN utm_campaign = 'brand' THEN 'brand'
            WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		END AS channel_group
FROM website_sessions 
) AS sessions_w_channel_grp
	LEFT JOIN orders
		ON sessions_w_channel_grp.website_session_id = orders.website_session_id
GROUP BY YEAR(created_at), QUARTER(created_at);

-- Overall session to order conversion rate trends for same channel groups by quarter

SELECT 
		YEAR(sessions_w_channel_grp.created_at) AS yr,
		QUARTER(sessions_w_channel_grp.created_at) AS qtr,
        COUNT(DISTINCT CASE WHEN channel_group = 'gsearch_nonbrand' THEN order_id ELSE NULL END) / 
        COUNT(DISTINCT CASE WHEN channel_group = 'gsearch_nonbrand' THEN sessions_w_channel_grp.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rate,
        COUNT(DISTINCT CASE WHEN channel_group = 'bsearch_nonbrand'  THEN order_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN channel_group = 'bsearch_nonbrand' THEN sessions_w_channel_grp.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rate,
		COUNT(DISTINCT CASE WHEN channel_group = 'brand' THEN order_id ELSE NULL END) / 
        COUNT(DISTINCT CASE WHEN channel_group = 'brand' THEN sessions_w_channel_grp.website_session_id ELSE NULL END) AS brand_conv_rate,
        COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN order_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN sessions_w_channel_grp.website_session_id ELSE NULL END) AS direct_type_in_conv_rate,
        COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN order_id ELSE NULL END) /
        COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN sessions_w_channel_grp.website_session_id ELSE NULL END) AS organic_conv_rate
        
FROM 
(SELECT website_session_id,
		created_at,
        CASE
			WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
            WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN 'gsearch_nonbrand'
            WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN 'bsearch_nonbrand'
            WHEN utm_campaign = 'brand' THEN 'brand'
            WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		END AS channel_group
FROM website_sessions 
) AS sessions_w_channel_grp
	LEFT JOIN orders
		ON sessions_w_channel_grp.website_session_id = orders.website_session_id
GROUP BY YEAR(created_at), QUARTER(created_at);

-- Monthly trending for revenue and margin by product, total margin and revenue

SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    SUM(CASE WHEN primary_product_id = 1 THEN price_usd ELSE NULL END) AS product_1_revenue,
	SUM(CASE WHEN primary_product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS product_1_margin,
    SUM(CASE WHEN primary_product_id = 2 THEN price_usd ELSE NULL END) AS product_2_revenue,
    SUM(CASE WHEN primary_product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS product_2_margin,
    SUM(CASE WHEN primary_product_id = 3 THEN price_usd ELSE NULL END) AS product_3_revenue,
    SUM(CASE WHEN primary_product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS product_3_margin,
    SUM(CASE WHEN primary_product_id = 4 THEN price_usd ELSE NULL END) AS product_4_revenue,
    SUM(CASE WHEN primary_product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS product_4_margin,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd) - SUM(cogs_usd) AS total_margin
FROM orders
GROUP BY 1, 2
ORDER BY 1, 2;

-- Monthly sessions to the /products page, % of sessions clicking through another page, product page views to order rate

CREATE TEMPORARY TABLE product_pageviews
SELECT 
	website_session_id,
    website_pageview_id,
    created_at AS saw_prod_pg
FROM website_pageviews
WHERE pageview_url = '/products';

SELECT
	YEAR(product_pageviews.saw_prod_pg) AS yr,
    MONTH(product_pageviews.saw_prod_pg) AS mo,
	COUNT(DISTINCT product_pageviews.website_session_id) AS products_page_sessions,
    COUNT(DISTINCT website_pageviews.website_session_id) AS click_to_next_pg,
    COUNT(DISTINCT website_pageviews.website_session_id) / COUNT(DISTINCT product_pageviews.website_session_id) AS clickthrough_rate,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT product_pageviews.website_session_id) AS viewed_prod_to_ord_rate
FROM product_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = product_pageviews.website_session_id
        AND website_pageviews.website_pageview_id  > product_pageviews.website_pageview_id
	LEFT JOIN orders
		ON orders.website_session_id = product_pageviews.website_session_id
GROUP BY 1, 2;
    
-- Sales data since 12/5/2014 when product 4 made available as primary product, cross selling data

CREATE TEMPORARY TABLE primary_products
SELECT 
	order_id,
    primary_product_id,
    created_at
FROM orders
WHERE created_at > '2014-12-05';

SELECT 
	primary_product_id,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(CASE WHEN cross_sell_prod_id = 1 THEN order_id ELSE NULL END) AS prod_1_cross_sell,
    COUNT(CASE WHEN cross_sell_prod_id = 2 THEN order_id ELSE NULL END) AS prod_2_cross_sell,
    COUNT(CASE WHEN cross_sell_prod_id = 3 THEN order_id ELSE NULL END) AS prod_3_cross_sell,
    COUNT(CASE WHEN cross_sell_prod_id = 4 THEN order_id ELSE NULL END) AS prod_4_cross_sell,
    COUNT(CASE WHEN cross_sell_prod_id = 1 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS prod_1_cross_sell_rt,
    COUNT(CASE WHEN cross_sell_prod_id = 2 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS prod_2_cross_sell_rt,
    COUNT(CASE WHEN cross_sell_prod_id = 3 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS prod_3_cross_sell_rt,
    COUNT(CASE WHEN cross_sell_prod_id = 4 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS prod_4_cross_sell_rt
FROM
(
SELECT 
	primary_products.*,
    order_items.product_id AS cross_sell_prod_id
FROM primary_products
	LEFT JOIN order_items
		ON primary_products.order_id = order_items.order_id
        AND order_items.is_primary_item = 0) AS primary_cross_sell
GROUP BY 1;
