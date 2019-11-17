--  CREATING SCHEMA /DATABASE FOR THE CECS 535 Project
--  Author : Saikiran Potti , 5409047
 -- DROP SCHEMA SOPOTT05CECS535
CREATE SCHEMA IF NOT EXISTS SOPOTT05CECS535;
USE SOPOTT05CECS535;
-- CREATE TABLE
-- Publisher, with attributes publisherid, name, address, discount, where publisherid is the primary key (make this a system generated attribute).
-- Acessing the table using the schema to ensure it works even if we switch between schemas and avoids ambiguity

CREATE TABLE SOPOTT05CECS535.Publisher(
publisherid INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100),
address VARCHAR(200),
discount FLOAT
);



-- ALTER TABLE SOPOTT05CECS535.Publisher
 -- ADD PRIMARY KEY (publisher_id);



-- Books, with attributes isbn, title, qty in stock, price, year published, publisherid,
-- where isbn is the primary key and publisherid is a foreign key

CREATE TABLE SOPOTT05CECS535.Books(
isbn INT NOT NULL PRIMARY KEY,
title VARCHAR(100),
qty_in_stock INT,
price DOUBLE,
year_published YEAR,
publisherid INT
);

-- Adding a primary key and foriegn key for the table 

ALTER TABLE SOPOTT05CECS535.Books
ADD FOREIGN KEY (publisherid) REFERENCES SOPOTT05CECS535.Publisher(publisherid);


-- • Author, with attributes author-id, name, age, address, affiliation, where author-id is
-- the primary key (make this a system generated attribute). 
-- (Affiliation is the name of the institution where the authors works, if it exists).


--  SQL seems to not allow the name of an attribute to use '-' hence naming the attribute as author_id 
CREATE TABLE SOPOTT05CECS535.Author(
author_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
name VARCHAR(50),
age INT,
address VARCHAR(50),
affiliation VARCHAR(20)
);


-- Writes, with attributes author-id, isbn, commission. The primary key is (author-id, isbn);
-- each attribute is a foreign key. Note that this implies that a book may have multiple authors,
-- and an author may write several books (alone or with others).

CREATE TABLE SOPOTT05CECS535.Writes (
author_id INT,
isbn INT,
commission FLOAT
);


ALTER TABLE SOPOTT05CECS535.Writes
ADD FOREIGN KEY (author_id) REFERENCES SOPOTT05CECS535.Author(author_id),
ADD FOREIGN KEY (isbn) REFERENCES SOPOTT05CECS535.Books(isbn),
ADD PRIMARY KEY (author_id,isbn);


-- Sales, with attributes isbn, year, month, number. The primary key is (isbn, year, month);
-- isbn is a foreign key; number is the number of copies sold.


CREATE TABLE SOPOTT05CECS535.SALES (
isbn INT,
year YEAR,
month INT,
number INT
);

ALTER TABLE SOPOTT05CECS535.Sales
ADD PRIMARY KEY (isbn,year,month),
ADD FOREIGN KEY (isbn) REFERENCES SOPOTT05CECS535.Books(isbn);




 CREATE TABLE SOPOTT05CECS535.ROYALTIES (
 author_id INT NOT NULL PRIMARY KEY,
 amount FLOAT
);

-- Triggers
-- All publisher discounts should be between 1.00 and 10.00
 DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.ValDiscountIns
BEFORE INSERT 
ON SOPOTT05CECS535.Publisher 
FOR EACH ROW

BEGIN
	IF NEW.discount < 1 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="discount should be greater than 1";
	ELSEIF NEW.discount > 10 THEN 
	   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="discount should not be greater than 10";
		END IF;
END//
DELIMITER;


DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.ValDiscountUpd
BEFORE UPDATE 
ON SOPOTT05CECS535.Publisher 
FOR EACH ROW

BEGIN
	IF NEW.discount < 1 THEN 
		SIGNAL SQLSTATE '45000' SET message_text="discount should be greater than 1";
	ELSEIF NEW.discount > 10 THEN 
	   SIGNAL SQLSTATE '45000' SET message_text="discount cannot be greater than 10";
		END IF;
END//

DELIMITER;


-- All commissions are expressed as a number between 0 and 100 (percentages); all commissions for
-- a single book (across authors) should add up to 100.


 DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.Valcommision
BEFORE INSERT 
ON SOPOTT05CECS535.Writes
FOR EACH ROW
BEGIN
      DECLARE total INT;
      SELECT sum(commission) INTO total FROM SOPOTT05CECS535.Writes GROUP BY isbn HAVING isbn=NEW.isbn;
    
      IF NEW.commission < 0 THEN
         SIGNAL SQLSTATE '45000' SET message_text="The commision percentage cannot be less than 0";
	  ELSEIF NEW.commission >100 THEN
         SIGNAL SQLSTATE '45000' SET message_text="The commision percentage cannot be greater than 100";
	 END IF;
       IF NEW.commission+total > 100 THEN
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT= "The total commission for the book is more than 100 percentage";
	  END IF;
END//
DELIMITER;


-- All numbers in Sales should be greater than 0.

DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.ValSalesNumberIns
BEFORE INSERT
ON SOPOTT05CECS535.Sales
FOR EACH ROW
BEGIN
      IF NEW.number < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="The sales number should always be greater than 0";
      END IF;
END//
DELIMITER;

 DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.ValSalesNumberUpd
BEFORE INSERT
ON SOPOTT05CECS535.Sales
FOR EACH ROW
BEGIN
      IF NEW.number < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="The sales number should always be greater than 0";
      END IF;
END//
DELIMITER;

-- Create a trigger such that, when an insertion happens in Sales and a book b has sold, the quantity
-- (number of copies) sold is subtracted from the quantity in stock for b in Books. If you end up with a
-- negative number, set the quantity in stock to zero. If the quantity in stock is already zero, reject the
-- insertion in Sales.


DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.QTY_BOOKS_UPDATE
BEFORE INSERT
ON SOPOTT05CECS535.Sales
FOR EACH ROW
BEGIN
    DECLARE instock int;
    SELECT qty_in_stock INTO instock FROM SOPOTT05CECS535.Books WHERE isbn=NEW.isbn;
      IF (instock = 0) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="You are out of stock and can't sell books";
     ELSEIF (instock - NEW.number) > 0 THEN 
     UPDATE SOPOTT05CECS535.Books SET SOPOTT05CECS535.Books.qty_in_stock = qty_in_stock - NEW.number 
     WHERE isbn =NEW.isbn;
	ELSEIF (instock - NEW.isbn) < 0 THEN 
    UPDATE SOPOTT05CECS535.Books SET SOPOTT05CECS535.Books.qty_in_stock = 0 WHERE isbn =NEW.isbn;
	END IF;
END//
DELIMITER;



-- add a new author (with zero royalties) when an author is added to Author
-- This trigger will run only if there is atleast one record in 
DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.ROYALTIES_UPD
AFTER INSERT 
ON SOPOTT05CECS535.Author
FOR EACH ROW
BEGIN
     DECLARE records INT;
     SELECT COUNT(*) INTO records FROM SOPOTT05CECS535.ROYALTIES;
     IF records > 0 THEN
     INSERT INTO SOPOTT05CECS535.ROYALTIES(author_id,amount) VALUES(NEW.author_id,0);
     END IF;
END//

-- update royalties amount for the author whenever records are inserted into sales table 
-- for every book sold , need to find the authors for the book, their respective commissions and the price of the book, discount
-- new amount = amount + (price - discount) * (commission/100) * NEW.number
DELIMITER //
CREATE TRIGGER SOPOTT05CECS535.ROYALITES_UPDSales
AFTER INSERT 
ON SOPOTT05CECS535.Sales
FOR EACH ROW
BEGIN
     DECLARE pricev,discountv,commissionv FLOAT;
     DECLARE authoridv,recordsv,publisheridv INT;
     DECLARE ch_done INT DEFAULT 0;
     DECLARE cursor_i CURSOR FOR SELECT author_id,commission FROM SOPOTT05CECS535.Writes WHERE isbn = NEW.isbn;
	 DECLARE CONTINUE HANDLER FOR NOT FOUND SET ch_done = 1;
	 SELECT price,publisherid INTO pricev,publisheridv FROM SOPOTT05CECS535.Books WHERE isbn= NEW.isbn;
     SELECT discount INTO discountv FROM SOPOTT05CECS535.Publisher WHERE publisherid = publisheridv;
     SELECT COUNT(*) INTO recordsv FROM SOPOTT05CECS535.ROYALTIES;
	 IF recordsv >0 THEN
     OPEN cursor_i;
     read_loop : LOOP
     FETCH cursor_i INTO authoridv,commissionv;

	 IF ch_done=1 THEN
      LEAVE read_loop;
     END IF;
        UPDATE SOPOTT05CECS535.ROYALTIES SET amount = amount + (pricev -discountv) * (commissionv/100) * NEW.number
        WHERE author_id = authoridv;
     -- SELECT authoridv,commissionv as "author id and commision";
     END LOOP;
     CLOSE cursor_i;
       END IF;
END//

-- Random data inserted into Tables 

INSERT INTO SOPOTT05CECS535.Publisher(name, address, discount)
VALUES
 ('Sams', 'Louisville', 5),
 ('Grames','Chicago',10),
 ('Pages','LA',7),
 ('GBooks','Seattle',4),
 ('Amazon','NY',9);
 
 INSERT INTO SOPOTT05CECS535.Books(isbn, title, qty_in_stock, price, year_published, publisherid)
 VALUES
 (12345,'Amazing Ideas',50,45.6,2015,1),
 (23454,'Incredible Hulks',150,31.2,2016,1),
 (22222,'Database Management',120,131.2,2016,2),
 (22122,'Artificial Intelligence',200,131.2,2014,3),
  (44222,'Algorithms',350,131.2,2011,4);
  
  
  INSERT INTO SOPOTT05CECS535.Author(name, age, address, affiliation)
 VALUES
 ('Bill',43,'Louisville Ky','Inventive'),
  ('John',24,'London UK','Creative'),
   ('Dave',33,'Bradford UK','Optimistic'),
    ('Darren',23,'Manchester UK','Authoritative'),
     ('Sven',47,'France Paris','Confidential'),
     ('Snowden',34,'AutoBio','PublicPrivacy'),
     ('Ben',34,'Documentary','Sports');
     
     INSERT INTO SOPOTT05CECS535.Writes(author_id, isbn, commission)
     VALUES
     (1,12345,60),
     (2,22222,30),
     (3,12345,20),
     (4,44222,25),
     (5,22122,45),
     (4,23454,53),
     (2,23454,10),
     (1,22222,5),
     (6,12345,2),
     (7,22222,3);
     
     -- INSERT INTO Writes(author_id,isbn,commission) VALUES (2,12345,-1)
     INSERT INTO SOPOTT05CECS535.Sales(isbn, year, month, number)
     VALUES
    (12345,1989,12,45),
    (23454,2012,08,33),
    (22122,2018,06,99),
    (44222,2017,02,129),
    (44222,2018,02,129),
     (44222,2019,02,129),
     (22222,2019,03,10);

   --  INSERT INTO SOPOTT05CECS535.Sales(isbn, year, month, number) VALUES (23454,2019,06,10);
 
--  Royalties: this is what is paid to an author for the sales of her/his books. It is calculated as: the
-- price of book minus discount times the commission (percentage) times number sold. Create a table
-- ROYALTIES(author-id,amount) and populate it by using a query over the existing data. Then create
-- a trigger to keep the table up-to-date. This involves
-- add a new author (with zero royalties) when an author is added to Author.
--  Update the royalty amount each time that there are new sales.






-- This query inserts the data into Royalties table which keeps track of authors income from the books
-- amount = (price -discount) * (commission/100) * number of books sold
INSERT INTO SOPOTT05CECS535.ROYALTIES(author_id,amount)
SELECT author_id,sum(A.finalamount) as amount
FROM 
(SELECT T.author_id,T.isbn,number*amount as finalamount
FROM
(SELECT A.author_id,B.price,B.isbn,W.commission,P.discount, (price - discount) * (commission/100) as amount
FROM BOOKS B,AUTHOR A,WRITES W,Publisher P
WHERE B.isbn = W.isbn and A.author_id = W.author_id and P.publisherid=B.publisherid) T, Sales S
WHERE T.isbn=S.isbn) A
GROUP BY A.author_id;

-- This query inserts 0 to amount for the books yet to be sold from the authors 
-- If a new author is added inserting (author_id,0) will be handled by the trigger 
INSERT INTO SOPOTT05CECS535.ROYALTIES(author_id,amount)
SELECT author_id,0 as amount
FROM SOPOTT05CECS535.Author
WHERE author_id NOT IN (SELECT author_id FROM SOPOTT05CECS535.ROYALTIES);

-- 
