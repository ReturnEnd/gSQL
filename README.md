# gSQL
gSQL - Simple Query Librairy 

## What's this ?
Based on **MySQLOO**, gSQL is a simple object-oriented library designed to make effortless the use of **MySQLOO** module. The goal is that the developers only have to send the SQL queries and parameters, gSQL takes care of security and error management.

## How to use
gSQL is a very small and lightweight library. It contains only few methods which are described below.

#### Creating a new gSQL object
As we already said, **gSQL** is an object-oriented library, this means you have to work with objects instead of simple functions. You first need to create a new **gSQL** object :
```lua
local dbInfos = {
    ['dbhost'] = 'localhost',
    ['dbname'] = 'gsql',
    ['dbuser'] = 'root',
    ['dbpass'] = ''
}
-- This line create the new gSQL object, stored in our variable called "object"
local object = gsql:new(object, dbInfos['dbhost'], dbInfos['dbname'], dbInfos['dbuser'], dbInfos['dbpass'])
```
#### Doing a simple request
**gSQL**, makes SQL queries super-easy !
```lua
-- This is our query. Note that {{steamid}} is a parameter.
local queryStr = 'SELECT * FROM users WHERE steamid = {{steamid}}'
local parameters = {
    ['steamid'] = 'STEAM_0:0:0' -- Note that the key match with the name of the parameter in queryStr
}
local function callback(status, message, data)
    if status then
        PrintTable(data)
    else
        print("Error upon SQL query :" .. message)
    end
end
-- Then we can do our query
object:query(queryStr, callback, parameters)
```
#### Doing a prepared request
Prepared queries are like simple queries, excepts that they are compiled before passing any argument on them. You can then bind parameters to these queries, to get your data. For more informations about prepared queries, please visit : [Prepared statement (Wikipedia.com)](https://en.wikipedia.org/wiki/Prepared_statement)
In **gSQL**, you can do prepared queries as following : 
```lua
local queryStr = "INSERT INTO messages (author, content, date_time) VALUES(?, ?, ?)"
local parameters = {
    [1] = 'STEAM_0:0:0',
    [2] = 'This message will be added to a database!',
    [3] = os.time()
}
local index = object:prepare(queryStr) -- This add a new PreparedQuery object, with the queryStr string
-- Then, we can execute our prepared query, by giving some parameters
object:execute(index, callback, parameters)
```
#### Deleting a prepared request
**gSQL** allow you to delete prepared query you made. You have to precise the index of the prepared query you want to delete (given by `gsql:prepare`) :
```lua
-- This will delete the prepared query number index
object:delete(index)
```