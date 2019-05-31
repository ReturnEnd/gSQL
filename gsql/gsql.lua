--[[----------------------------------------------------------
    gsql - Facilitate SQL programming for GmodLua

    @author Gabriel Santamaria <gaby.santamaria@outlook.fr>

    Copyright 2019 Gabriel Santamaria

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

------------------------------------------------------------]]
gsql = gsql or {
    used = nil -- currently used driver
}

--- Class constructor function. Creates a new gSQL object
-- @param obj table : the object that'll be used after this method
-- @param driver string : the driver which will be used in this instance
-- @param dbhost string : host name of the database
-- @param dbname string : database name
-- @param dbuser string : database user that'll be used to get datas from the database
-- @param dbpass string : database user's password
-- @param port number : port number on which the database is hosted
-- @return gsql : a gsql object
function gsql:new(obj, driver, dbhost, dbname, dbuser, dbpass, port)
    obj = obj or {}
    port = port or 3306
    self.__index = self
    setmetatable(obj, self)
    -- Creating log file if doesn't already exists
    if not file.Exists('gsql_logs.txt', 'DATA') then
        file.Write('gsql_logs.txt', '')
    end
    -- Checking if the chosen module exists
    if not self.module[driver] then
        file.Append('gsql_logs.txt', '[gsql][new] : the specified driver isn\'t supported by gSQL.')
        error('[gsql] A fatal error appenned while creating the gSQL object! Check your logs for more informations!')
    end
    self.used = driver
    self.module[driver]:init()

    return self
end

--- Helper function that replace parameters found in a string by the parameter itself.
-- @param queryStr string : the string that'll be affected by this function
-- @param name string : the name of the parameter which have to be found and replaced
-- @param value any : the value of the parameter
-- @return string : the new string, with parameters values instead of names
function gsql.replace(queryStr, name, value)
    local pattern = '{{' .. name .. '}}'
    return string.gsub(queryStr, pattern, value)
end

--- Make a query from an SQL string
-- @param queryStr string : A SQL query string
-- @param callback function : Function that'll be called when the query finished
-- @param paramaters table : A table containing all (optionnal) parameters
-- @return void
function gsql:query(queryStr, parameters, callback)
    if self.used == nil then error('gSQL hasn\'t been initialized. Can\'t query anything from a database.') end
    if queryStr == nil then error('[gsql] An error occured while trying to query : Argument \'queryStr\' is missing!') end
    if not isfunction(callback) then 
        error('[gsql] An error occured while trying to query : Argument \'callback\' isn\'t correct. See logs to get more informations!')
        file.Append('gsql_logs.txt', '[gsql][query] : the specified driver isn\'t supported by gSQL.')
    end
    parameters = parameters or {}

    self.module[driver]:query(queryStr, parameters, callback)
end

--- Prepare a new SQL string. Ready to execute
-- @param queryStr string : A SQL query string
-- @return number : index of this object in the "prepared" table
-- @see gsql:execute
function gsql:prepare(queryStr)
    if (queryStr == nil) then
        file.Append('gsql_logs.txt', '[gsql][prepare] : Argument \'queryStr\' is missing.')
        error('[gsql] An error occured when preparing a query!')
    elseif (type(queryStr) ~= 'string') then
        file.Append('gsql_logs.txt', '[gsql][prepare] : Incorrect type of \'queryStr\'.')
        error('[gsql] An error occured when preparing a query!')
    end

    return self.module[driver]:prepare(queryStr)
end

--- Delete a prepared query, identified by its index
-- @param index number : index of this object in the "prepared" table
-- @return bool : the status of this deletion
function gsql:delete(index)
    if (index == nil) then
        file.Append('gsql_logs.txt', '[gsql][delete] : Argument \'index\' is missing.')
        error('[gsql] An error occured when deleting a query!')
    elseif (type(index) ~= 'number') then
        file.Append('gsql_logs.txt', '[gsql][delete] : Invalid type of \'index\'. It must be a number.')
        error('[gsql] An error occured while trying to delete a prepared query!')
    end

    return self.module[driver]:delete(index)
end

--- Execute a prepared query, identified by its index
-- @param index number : index of this object in the "prepared" table
-- @param callback function : function called when the PreparedQuery finished
-- @param parameters table : table of all parameters that'll be added to the prepared query
-- @return void
function gsql:execute(index, parameters, callback)
    if (index == nil) then
        file.Append('gsql_logs.txt', '[gsql][execute] : Argument \'index\' is missing.')
        error('[gsql] An error occured when executing a query!')
    elseif (type(index) ~= 'number') then
        file.Append('gsql_logs.txt', '[gsql][execute] : Invalid type of \'index\'. It must be a number. You gived a ' .. type(index))
        error('[gsql] An error occured while trying to execute a prepared query!')
    end
    parameters = parameters or {}

    self.module[driver]:execute(index, parameters, callback)
end
