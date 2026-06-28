create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);




------------------------------------------------------------------------------------------------------------



CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id int)
RETURNS numeric
AS $$
    SELECT COALESCE(SUM(quantity * price), 0)
    FROM order_items
    WHERE order_id = p_order_id;
$$ LANGUAGE sql;



CREATE OR REPLACE PROCEDURE create_order(p_customer_id int)
AS $$
    INSERT INTO orders (customer_id, order_date, total_amount)
    SELECT p_customer_id, CURRENT_TIMESTAMP, 0
    WHERE EXISTS 
		(SELECT 1 FROM customers WHERE customer_id = p_customer_id);
$$ LANGUAGE sql;




CREATE OR REPLACE PROCEDURE add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
AS $$
    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id 
      AND stock_quantity >= p_quantity 
      AND p_quantity > 0;

    INSERT INTO order_items (order_id, product_id, quantity, price)
    SELECT p_order_id, p_product_id, p_quantity, price
    FROM products
    WHERE product_id = p_product_id;
$$ LANGUAGE sql;



CREATE OR REPLACE FUNCTION trigger_update_order_total_func()
RETURNS TRIGGER
AS $$
BEGIN
    UPDATE orders 
    SET total_amount = calculate_order_total(COALESCE(NEW.order_id, OLD.order_id))
    WHERE order_id = COALESCE(NEW.order_id, OLD.order_id);
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_total
AFTER INSERT OR UPDATE OR DELETE 
ON order_items
FOR EACH ROW
EXECUTE FUNCTION 
trigger_update_order_total_func();



CREATE OR REPLACE FUNCTION trigger_log_order_func()
RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO order_log (order_id, customer_id, action, log_date)
    VALUES (NEW.order_id, NEW.customer_id, 'CREATED', CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_order
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION trigger_log_order();



---------------------------------------------------------------------------------




INSERT INTO customers (full_name, email, balance) VALUES ('customer1_name', 'customer1@email.com', 300.00);
INSERT INTO products (product_name, price, stock_quantity) VALUES ('product1', 100.00, 10);
INSERT INTO products (product_name, price, stock_quantity) VALUES ('product2', 20.00, 100);

CALL create_order(1); --create_order(p_customer_id int)

CALL add_product_to_order(1, 1, 1); --add_product_to_order(p_order_id int,p_product_id int,p_quantity int)
CALL add_product_to_order(1, 2, 2); --add_product_to_order(p_order_id int,p_product_id int,p_quantity int)

SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM order_log;






