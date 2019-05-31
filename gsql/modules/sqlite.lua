--[[----------------------------------------------------------
    gsql.mysqloo - MySQLOO module for gSQL
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
    affectedRows = nil
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
            v = sql.SQLStr(v, true)
        end
        queryStr = gsql.replace(queryStr, k, v)
    end
    local query = sql.Query(queryStr)
    if query then
        self.affectedRows = sql.Query('SELECT changes() AS affectedRows LIMIT 1')
        callback(true, 'success', query, self.affectedRows)        
    else
        local err = sql.LastError()
        file.Append('gsql_logs.txt', '[gsql][query] : ' .. err)
        callback(false, 'error : ' .. err)
    end
end
