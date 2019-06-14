# gSQL
gSQL - Simple Query Library 

## What's this ?

**gSQL** is a simple object-oriented library designed to make effortless the use of the different existing SQL modules. The goal is that the developers only have to send the SQL queries and parameters, gSQL takes care of security and error management.

**With gSQL, write your code only ONCE and use it on any supported driver!**

## Supported modules
1. **[MySQLOO](https://github.com/FredyH/MySQLOO)** : An object oriented MySQL module for Garry's Mod
1. **[SQLite](https://wiki.garrysmod.com/page/Category:sql)** : Access powerful database software included with Garry's Mod

## Features
* Lightweight, only 5 methods
* Freaking easy to use
* **Write your code only once** to use it with several drivers
* Error logs management
* Security management: send your parameters, gSQL does the rest
* Parameter system in unprepared queries

## Available functions

**gSQL** includes a total of 5 functions that will allow you to interact with your SQL server in a basic way.

### Constructor : `gsql:new()`

* Prototype : `gsql:new(obj, driver, dbhost, dbname, dbuser, dbpass, port, callback)`
* Description : This function creates a new **gSQL** object and return it.
* Example :
```lua
local database = {
    host = 'localhost',
    name = 'gsql',
    user = 'root',
    pass = ''
}
local db = gsql:new(db, 'sqlite', database.host, database.name, database.user, database.pass, 3306, function(success, message)
    print(success)
    print(message)
end)
```

### Query : `gsql:query()`

* Prototype : `gsql:query(sqlStr, parameters, callback)`
* Description : This function do a basic query to the SQL server that has been set in `gsql:new`
* Example :
```lua
local parameters = {
    ['userid'] = ply:SteamID64()
}
db:query('SELECT * FROM development WHERE steamid = {{userid}}', parameters, function (success, message, data)
    if not success then print(message) return end
end)
```

### Prepare : `gsql:prepare()`

* Prototype : `gsql:prepare(sqlStr)`
* Description : Creates a prepared query and returns its ID in an internal table.
* Example :
```lua
local index = db:prepare('SELECT * FROM development WHERE number = ?')
```

### Delete : `gsql:delete()`

* Prototype : `gsql:prepare(index)`
* Description : Delete a prepared query, identified by its index, from an internal table
* Example :
```lua
if not db:delete(index) then
    print('An error occurred here, see your logs for more details.')
end
```

### Execute : `gsql:execute()`

* Prototype : `gsql:execute(index, parameters, callback)`
* Description : Execute a prepared query, identified by its index
* Example :
```lua
local index = db:prepare('SELECT * FROM development WHERE number = ?')
db:execute(index, {1533}, function(success, message, data)
    if not success then print(message) return end
    PrintTable(data)
end)
```

## License
This code is distributed free of charge under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). The code is distributed "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND. For more information, please visit [LICENSE](https://github.com/Gabyfle/gSQL/blob/master/LICENSE)