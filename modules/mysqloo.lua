--[[----------------------------------------------------------
    gsql.mysqloo - MySQLOO module for gSQL
    - Based on MySQLOO module https://github.com/FredyH/MySQLOO -

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
gsql.module.mysqloo = gsql.module.mysqloo or {
    -- [database] MYSQLOO Database object
    connection = nil,
    -- [table][Query] Queries
    queries = {},
    -- [table][PreparedQuery] Prepared queries
    prepared = {},
    -- [number] Number of affected rows in the last query
    affectedRows = nil
}

function gsql.module.mysqloo:init()
    -- Including the mysqloo driver
    success, err = pcall(require, 'mysqloo')
    if not success then
        file.Append('gsql_logs.txt', '[gsql][new] : ' .. err)
        error('[gsql] A fatal error appenned while trying to include MySQLOO driver!')
    end
    -- Creating a new Database object
    self.connection = mysqloo.connect(dbhost, dbuser, dbpass, dbname, port)
    function self.connection.onError(err)
        file.Append('gsql_logs.txt', '[gsql][new] : ' .. err)
        error('[gsql] A fatal error appenned while connecting to the database, please check your logs for more informations!')
    end
    self.connection:connect()
end

function gsql.module.mysqloo:query()
    if (queryStr == nil) then error('[gsql] An error occured while trying to query : Argument \'queryStr\' is missing!') end
    parameters = parameters or {}
    -- By using this instead of a table in string.gsub, we avoid nil-related errors
    for k, v in pairs(parameters) do
        if type(v) == 'string' then 
            v = self.connection:escape(v)
        end
        queryStr = self.replace(queryStr, k, v)
    end
    local query = self.connection:query(queryStr) -- Doing the query
    query.onSuccess = function(query, data)
        callback(true, 'success', data)
    end
    query.onAborted = function(query)
        callback(false, 'aborted')
    end
    query.onError = function(query, err)
        file.Append('gsql_logs.txt', '[gsql][query] : ' .. err)
        callback(false, 'error :' .. err)
    end
    query:start()
    self.affectedRows = query:affectedRows()
end