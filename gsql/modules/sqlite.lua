--[[----------------------------------------------------------
    gsql.sqlite - SQLite module for gSQL
    - Based on the default SQLite engine of Garry's Mod https://wiki.garrysmod.com/page/Category:sql -

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
gsql.module = gsql.module or {}
gsql.module.sqlite = gsql.module.sqlite or {
    -- [number] Number of affected rows in the last query
    affectedRows = nil,
    -- [table] Every requests wich will be used as PREPARED QUERIES
    prepared = {}
}

--- Just does nothing, because the "sql" lib is loaded by default by Gmod
function gsql.module.sqlite:init(driver, dbhost, dbname, dbuser, dbpass, port, callback)
    callback(true, 'success')
end

--- Start a new query with the sqlite lib
-- @param queryStr string : A SQL query string
-- @param callback function : Function that'll be called when the query finished
-- @param paramaters table : A table containing all (optionnal) parameters
-- @return void
function gsql.module.sqlite:query(queryStr, parameters, callback)
    if (queryStr == nil) then error('[gsql][query] An error occured while trying to query : Argument \'queryStr\' is missing!') end
    parameters = parameters or {}
    for k, v in pairs(parameters) do
        if type(v) == 'string' then
            v = '"' .. v .. '"'
            v = sql.SQLStr(v, true)
        end
        queryStr = gsql.replace(queryStr, k, v)
    end
    local query = sql.Query(queryStr)
    if query or query == nil then
        if query == nil then query = {} end
        self.affectedRows = sql.Query('SELECT changes() AS affectedRows LIMIT 1')
        callback(true, 'success', query, self.affectedRows)        
    else
        local err = sql.LastError()
        file.Append('gsql_logs.txt', '[gsql][query] : ' .. err)
        callback(false, 'error : ' .. err)
    end
end

--- Add a new SQL string into the sqlite.prepared table
-- @param queryStr string : A SQL query string
-- @return number : index of this object in the "prepared" table
-- @see gsql:execute
function gsql.module.sqlite:prepare(queryStr)
    self.prepared[#self.prepared + 1] = queryStr
    return #self.prepared
end

--- Delete an SQL string from the sqlite.prepared table
-- @param index number : index of this object in the sqlite.prepared table
-- @return bool : the status of this deletion
function gsql.module.sqlite:delete(index)
    if not self.prepared[index] then -- Checking if the index is correct
        file.Append('gsql_logs.txt', '[gsql][delete] : Invalid \'index\'. Requested deletion of prepared query number ' .. index .. ' as failed. Prepared query doesn\'t exist')
        error('[gsql] An error occured while trying to delete a prepared query! See logs for more informations')
        return false
    end
    -- Setting the sqlite.prepared index to nil
    self.prepared[index] = nil
    return true
end

--- Bind every parameters of an SQL string
-- @param sql string
-- @param parameters table
-- @return string : the SQL string with binded parameters
function gsql.module.sqlite.bindParams(sqlstr, parameters)
    for k, v in pairs( parameters ) do
        if v == nil then
            v = 'NULL'
        elseif type( v ) != "number" then
            v = sql.SQLStr(v, true)
            v = '"' .. v .. '"'
        end
        sqlstr = string.gsub( sqlstr, "?" .. k, v )
    end
    return sqlstr
end

--- Execute all prepared queries ordered by their index in the "prepared" table
-- Call the callback function when it finished
-- @param index number : index of this object in the "prepared" table
-- @param callback function : function called when the query is finished
-- @param parameters table : table of all parameters that'll be added to the prepared query
-- @return void
function gsql.module.sqlite:execute(index, parameters, callback)
    if not self.prepared[index] then -- Checking if the index is correct
        file.Append('gsql_logs.txt', '[gsql][execute] : Invalid \'index\'. Requested deletion of prepared query number ' .. index .. ' as failed. Prepared query doesn\'t exist')
        error('[gsql] An error occured while trying to execute a prepared query! See logs for more informations')
        return false
    end
    local sqlStr = self.bindParams(self.prepared[index], parameters)
    self:query(sqlStr, {}, callback) -- We don't need to pass a second time the arguments since we already bound them
end
