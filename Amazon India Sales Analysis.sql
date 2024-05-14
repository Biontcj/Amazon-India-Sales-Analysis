SELECT *
FROM SQLProject..['Product Info$']
ORDER BY 1
SELECT *
FROM SQLProject..['Shipping Info$']
ORDER BY 1


-- Top 10 Style in terms of items sold
SELECT TOP 10 Style, COUNT(*) AS 'Sold (Style)'
FROM SQLProject..['Product Info$']
GROUP BY Style
ORDER BY 'Sold (Style)' DESC

-- Top 10 Style in terms revenue
SELECT TOP 10 Style, SUM(Amount) AS 'Revenue (Style)'
FROM SQLProject..['Product Info$']
GROUP BY Style
ORDER BY 'Revenue (Style)' DESC

-- Ranking Category in terms of items sold
SELECT TOP 10 Category, COUNT(*) AS 'Sold (Category)'
FROM SQLProject..['Product Info$']
GROUP BY Category
ORDER BY 'Sold (Category)' DESC

--Ranking Category in terms of revenue
SELECT Category, SUM(Amount) AS 'Revenue (Category)'
FROM SQLProject..['Product Info$']
GROUP BY Category
ORDER BY 'Revenue (Category)' DESC

--Ranking Size in terms of revenue
SELECT Size, SUM(Amount) AS 'Revenue (Size)'
FROM SQLProject..['Product Info$']
GROUP BY Size
ORDER BY 'Revenue (Size)' DESC

-- Calculate total sales with and without promotions
SELECT SUM(CASE WHEN "promotion-ids" IS NOT NULL THEN Amount ELSE 0 END) AS "Sales With Promotion",
SUM(CASE WHEN "promotion-ids" IS NULL THEN Amount ELSE 0 END) AS "Sales Without Promotion"
FROM SQLProject..['Product Info$']

-- Most popular promotions
SELECT TOP 100 "promotion-ids", COUNT(*) AS 'Promotion Used'
FROM SQLProject..['Product Info$']
WHERE "promotion-ids" IS NOT NULL
GROUP BY "promotion-ids"
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

-- Cancellation Rate
SELECT COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) AS CancelledOrders,
COUNT(*) AS TotalOrders,
COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) * 1.0 / COUNT(*) AS CancellationRate
FROM SQLProject..['Shipping Info$']

 -- Cancellation Rate (Amazon Vs Merchant)
SELECT Fulfilment,COUNT(*) AS TotalOrders,
SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledOrders,
SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS CancellationRate
FROM SQLProject..['Shipping Info$']
GROUP BY Fulfilment
ORDER BY CancellationRate DESC

--Cancellations (by Category)
SELECT Category, TotalOrders, CancelledOrders, CancellationRate
FROM (
    SELECT 
        p.Category,
        COUNT(*) AS TotalOrders,
        SUM(CASE WHEN s.Status = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledOrders,
        SUM(CASE WHEN s.Status = 'Cancelled' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS CancellationRate,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN s.Status = 'Cancelled' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) DESC) AS rn
    FROM SQLProject..['Shipping Info$'] s
    JOIN SQLProject..['Product Info$'] p ON s."Order ID" = p."Order ID"
    GROUP BY p.Category
) AS CatCancelRate
WHERE rn <= 5
ORDER BY CancellationRate DESC

--States analysis
SELECT 
    si."ship-state", 
    COUNT(si.Qty) AS 'Total Sales Count',
    COUNT(CASE WHEN si.Fulfilment = 'Amazon' THEN 1 END) AS 'Amazon Sales',
    COUNT(CASE WHEN si.Fulfilment = 'Merchant' THEN 1 END) AS 'Merchant Sales',
    COUNT(CASE WHEN pi.Category = 'Set' THEN 1 END) AS 'Set Sales',
    COUNT(CASE WHEN pi.Category = 'kurta' THEN 1 END) AS 'kurta Sales',
    COUNT(CASE WHEN pi.Category = 'Western Dress' THEN 1 END) AS 'Western Dress Sales',
    COUNT(CASE WHEN pi.Category = 'Top' THEN 1 END) AS 'Top Sales',
    COUNT(CASE WHEN pi.Category = 'Blouse' THEN 1 END) AS 'Blouse Sales',
    COUNT(CASE WHEN pi.Category = 'Bottom' THEN 1 END) AS 'Bottom Sales',
    COUNT(CASE WHEN pi.Category = 'Dupatta' THEN 1 END) AS 'Dupatta Sales',
    COUNT(CASE WHEN pi.Category = 'Ethnic Dress' THEN 1 END) AS 'Ethnic Dress Sales',
    COUNT(CASE WHEN pi.Category = 'Saree' THEN 1 END) AS 'Saree Sales'
FROM 
    SQLProject..['Shipping Info$'] si
JOIN 
    SQLProject..['Product Info$'] pi ON si."Order ID" = pi."Order ID"
GROUP BY 
    si."ship-state"
ORDER BY 
    'Total Sales Count' DESC

-- Finding shipping time

-- Will status tell me of shpping time? ie. going from pending to shipped
SELECT Distinct Status
FROM SQLProject..['Shipping Info$']

--Seeing the order id with the most status updates
SELECT [Order ID], COUNT(*) AS Updates
FROM SQLProject..['Shipping Info$']
GROUP BY [Order ID]
HAVING COUNT(*) > 1
ORDER BY Updates DESC

-- Looking at the order id where there are duplicates
SELECT si.*
FROM SQLProject..['Shipping Info$'] si
JOIN (
    SELECT [Order ID], COUNT(*) AS Updates
    FROM SQLProject..['Shipping Info$']
    GROUP BY [Order ID]
    HAVING COUNT(*) > 1
) AS Subquery ON si.[Order ID] = Subquery.[Order ID]
ORDER BY Subquery.Updates DESC

-- Realising that there are be duplicates
-- Finding unique status where order id is the same
SELECT si1.*
FROM SQLProject..['shipping Info$'] si1
JOIN SQLProject..['shipping Info$'] si2 ON si1.[Order ID] = si2.[Order ID]
WHERE si1.Status <> si2.Status
ORDER BY si1.[Order ID]
-- All duplicate order ids and status are duplicated also 

-- However when looking at the Courier Status instead
SELECT si1.*
FROM SQLProject..['shipping Info$'] si1
JOIN SQLProject..['shipping Info$'] si2 ON si1.[Order ID] = si2.[Order ID]
WHERE si1.[Courier Status] <> si2.[Courier Status]
ORDER BY si1.[Order ID]
-- We can see that the courier status moves form unshipped to shipped but the date does not change. We can assume that the "date" in the table is either order or shipping date
