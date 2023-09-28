-- What is the total amount each customer spent at the restaurant?
select s.customer_id , sum(ms.price) as total_spent from sales s 
join members m 
on s.customer_id = m.customer_id 
join menu ms on s.product_id = ms.product_id 
group by  s.customer_id 
order by total_spent  desc;
-- How many days has each customer visited the restaurant?
select customer_id , count(distinct order_date) as total_visited_days from sales
GROUP BY customer_id 
order by total_visited_days desc;
-- What was the first item from the menu purchased by each customer?
with first_item as(select customer_id,product_name, 
row_number() over(PARTITION BY customer_id) as first_product
from sales s
join menu m 
on s.product_id = m.product_id)
select  customer_id,product_name from first_item 
where first_product= 1 
-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name , count(s.product_id) as frequency from 
menu m 
join sales s on s.product_id = m.product_id
GROUP BY m.product_name 
order by frequency desc;
-- Which item was the most popular for each customer?
select customer_id,product_name from (select s.customer_id,m.product_name , count(s.product_id) as frequency,
dense_rank() over(PARTITION by customer_id order by count(s.product_id) desc)as rnk  from 
menu m 
join sales s on s.product_id = m.product_id
GROUP BY s.customer_id,m.product_name) t
where t.rnk=1;
-- Which item was purchased first by the customer after they became a member?
with selection as(select s.customer_id,ms.product_name, 
dense_rank() 
over(PARTITION by s.customer_id order by order_date) as first_buy from sales s
join members m 
on s.customer_id = m.customer_id
join menu ms on s.product_id = ms.product_id 
where order_date>join_date)
select customer_id ,product_name from 
selection where first_buy=1 ;
-- Which item was purchased just before the customer became a member?
with selection as(select s.customer_id,ms.product_name, 
dense_rank() 
over(PARTITION by s.customer_id order by order_date) as first_buy from sales s
join members m 
on s.customer_id = m.customer_id
join menu ms on s.product_id = ms.product_id 
where order_date<join_date)
select customer_id ,product_name from 
selection where first_buy=1 ;
-- What is the total items and amount spent for each member before they became a member?
select s.customer_id , count(distinct(product_name)) as total_products, 
sum(price) as total_spent from sales  s 
join menu m
on s.product_id = m.product_id 
left join members ms on s.customer_id = ms.customer_id
where order_date < join_date
group by  s.customer_id ;
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
with total_points as(select s.customer_id,m.product_name,m.price ,
case when m.product_name = "sushi" then (m.price*2)
else m.price 
end as new_price from sales s 
left join menu m 
on s.product_id = m.product_id) 
select customer_id, sum(new_price*10) as total_points_left
from total_points 
group by   customer_id;
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
-- - how many points do customer A and B have at the end of January?
with new_points AS (
    select s.customer_id, m.product_name, m.price,
           CASE
               when m.product_name = 'sushi' THEN (m.price * 2)
               when s.order_date BETWEEN ms.join_date AND (ms.join_date + INTERVAL 6 DAY) THEN (m.price * 2)
               ELSE m.price
           END AS new_price
    from sales s
    left join menu m ON s.product_id = m.product_id
    join members ms ON s.customer_id = ms.customer_id
    WHERE s.order_date <= '2021-02-28'
)
select customer_id, SUM(new_price * 10) AS total_points_left
from  new_points
group by customer_id;


-- Bonus Questions

-- The following questions are related creating basic data tables that Danny and 
-- his team can use to quickly derive insights 
-- without needing to join the underlying tables using SQL.
-- if they are not members then "N" else "Y"?
select s.customer_id, s.order_date ,m.product_name,m.price,
case 
    when s.order_date< ms.join_date then "N"
    when ms.join_date is null then "N"
    else "Y"
end as member from sales s
left join menu m on s.product_id = m.product_id 
left join members ms on s.customer_id = ms.customer_id 

-- Rank All The Things
-- Danny also requires further information about 
-- the ranking of customer products, but he purposely 
-- does not need the ranking for non-member purchases 
-- so he expects null ranking values for the records
--  when customers are not yet part of the loyalty program
with rankers as(select s.customer_id, s.order_date ,m.product_name,m.price,
case 
    when s.order_date< ms.join_date then "N"
    when ms.join_date is null then "N"
    else "Y"
end as member from sales s
left join menu m on s.product_id = m.product_id 
left join members ms on s.customer_id = ms.customer_id ) 
select *, 
case 
    when member = "N" then null 
    else row_number() over(PARTITION by customer_id,member order by order_date) 
end as ranking
from rankers ;




