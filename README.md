# BooksInventory
This is a project to build a database schema to manage a book store

To setup the book store we have translated an ER model into a set of tables.
The tables are designed in a way to avoid redundancy and ensuring they all follow 3rd Normal Form.
However while designing the tables we haven't taken into account the adavanced database features like Arrays, Types.
Since we haven't considered these latest features while designing we end up with more tables.

The tables and their attribtutes are listed below 

# Publisher

The table has below attributes 

publisherid, name, address, discount 


# Books

The table has below attributes 

isbn, title, qty_in_stock, price, year_published, publisherid


# Author 

The table has below attributes 

author_id, name, age, address, affiliation

# Writes

The table has below attributes

author_id, isbn, commission

# Sales

The table has below attributes

isbn, year, month, number

# Royalties

The table has below attributes

author_id, amount



