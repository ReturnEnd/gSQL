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
require('mysqloo')

-- Connections cache
local cache = {}

local mod = {}
mod.__index = mod

function mod:new(dbhost, dbname, dbuser, dbpass, port, callback)
    local connUID = util.CRC(dbhost .. dbname .. dbuser)
    if cache[connUID] then return cache[connUID] end

    local newMod = {
        connection = nil,
        prepared = {},
        affectedRows = nil
    }
    setmetatable(newMod, mod)

    -- Creating a new Database object
    self.connection = mysqloo.connect(dbhost, dbuser, dbpass, dbname, port)
    function self.connection:onConnected()
        callback(true, 'success')
    end
    function self.connection:onConnectionFailed(err)
        file.Append('gsql_logs.txt', '[gsql][new] : ' .. err)
        callback(false, 'err : ' .. err)
    end
    self.connection:connect()

    cache[connUID] = self
    return self
end
setmetatable( mod, { __call = mod.new } )


--- Set a new Query object and start the query
-- @param queryStr string : A SQL query string
-- @param callback function : Function that'll be called when the query finished
-- @param paramaters table : A table containing all (optionnal) parameters
-- @return void
function mod:query(queryStr, parameters, callback)
    if (queryStr == nil) then error('[gsql][query] An error occured while trying to query : Argument \'queryStr\' is missing!') end
    parameters = parameters or {}
    -- By using this instead of a table in string.gsub, we avoid nil-related errors
    for k, v in pairs(parameters) do
        if type(v) == 'string' then
            v = self.connection:escape(v)
        end
        queryStr = gsql.replace(queryStr, k, v)
        print(queryStr)
    end
    local query = self.connection:query(queryStr) -- Doing the query
    query.onSuccess = function(query, data)
        self.affectedRows = query:affectedRows()
        callback(true, 'success', data, self.affectedRows)
    end
    query.onAborted = function(query)
        callback(false, 'aborted')
    end
    query.onError = function(query, err)
        file.Append('gsql_logs.txt', '[gsql][query] : ' .. err)
        callback(false, 'error : ' .. err)
    end
    query:start()
end

--- Add a new PreparedQuery object to the "prepared" table
-- @param queryStr string : A SQL query string
-- @return number : index of this object in the "prepared" table
-- @see gsql:execute
function mod:prepare(queryStr)
    self.prepared[#self.prepared + 1] = self.connection:prepare(queryStr)
    return #self.prepared
end

--- Delete a PreparedQuery object from the "prepared" table
-- @param index number : index of this object in the "prepared" table
-- @return bool : the status of this deletion
function mod:delete(index)
    if not self.prepared[index] then -- Checking if the index is correct
        file.Append('gsql_logs.txt', '[gsql][delete] : Invalid \'index\'. Requested deletion of prepared query number ' .. index .. ' as failed. Prepared query doesn\'t exist')
        error('[gsql] An error occured while trying to delete a prepared query! See logs for more informations')
        return false
    end
    -- Setting the PreparedQuery object to nil
    self.prepared[index] = nil
    return true
end

--- Execute all prepared queries ordered by their index in the "prepared" table
-- Call the callback function when it finished
-- @param index number : index of this object in the "prepared" table
-- @param callback function : function called when the PreparedQuery finished
-- @param parameters table : table of all parameters that'll be added to the prepared query
-- @return void
function mod:execute(index, parameters, callback)
    if not self.prepared[index] then -- Checking if the index is correct
        file.Append('gsql_logs.txt', '[gsql][execute] : Invalid \'index\'. Requested deletion of prepared query number ' .. index .. ' as failed. Prepared query doesn\'t exist')
        error('[gsql] An error occured while trying to execute a prepared query! See logs for more informations')
        return false
    end
    local i = 1
    for k, v in ipairs(parameters) do
        if (type(v) == 'number') then -- Thanks Lua for the absence of a switch statement
            self.prepared[index]:setNumber(i, v)
        elseif (type(v) == 'string') then
            self.prepared[index]:setString(i, v)
        elseif (type(v) == 'bool') then
            self.prepared[index]:setBool(i, v)
        elseif (type(v) == 'nil') then
            self.prepared[index]:setNull(i)
        else
            file.Append('gsql_logs.txt', '[gsql][execute] : Invalid type of parameter (parameter : ' .. k .. ' value : ' .. v .. ')')
            error('[gsql] : An error appears while preparing the query. See the logs for more informations!')
            return false
        end
        i = i + 1
    end
    self.prepared[index].onSuccess = function (query, data)
        callback(true, 'success', data)
    end
    self.prepared[index].onAborted = function(query)
        callback(false, 'aborted')
    end
    self.prepared[index].onError = function(query, err)
        file.Append('gsql_logs.txt', '[gsql][execute] : ' .. err)
        callback(false, 'error')
    end
    self.prepared[index]:start()
end

return mod