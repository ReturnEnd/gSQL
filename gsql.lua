--[[----------------------------------------------------------
    gsql - Facilitate SQL programming for GmodLua

    @author Gabriel Santamaria <gaby.santamaria@outlook.fr>
------------------------------------------------------------]]
gsql = gsql or {
    -- [database] MYSQLOO Database object
    connection = nil,
    -- [table] Available drivers
    drivers = {
        ['mysqloo'] = true, -- Based on MySQLOO module https://github.com/FredyH/MySQLOO
        ['gmod'] = true
    },
    -- [table][Query] Queries
    queries = {},
    -- [table][PreparedQuery] Prepared queries
    prepared = {},
    -- [number] Number of affected rows in the last query
    affectedRows = nil
}

--- Class constructor function. Creates a new gSQL object, and a new MySQLOO connection
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
    if not self.drivers[driver] then
        file.Append('gsql_logs.txt', '[gsql][new] : the specified driver isn\'t supported by gSQL.')
        error('[gsql] A fatal error appenned while creating the gSQL object! Check your logs for more informations!')
    end

    if driver == 'mysqloo' then
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

--- Set a new Query object and start the query
-- @param queryStr string : A SQL query string
-- @param callback function : Function that'll be called when the query finished
-- @param paramaters table : A table containing all (optionnal) parameters
-- @return void
function gsql:query(queryStr, callback, parameters)
    if (queryStr == nil) then error('[gsql] An error occured while trying to query : Argument \'queryStr\' is missing!') end
    parameters = parameters or {}
    -- By using this instead of a table in string.gsub, we avoid nil-related errors
    for k, v in pairs(parameters) do
        v = self.connection:escape(v)
        queryStr = self.replace(queryStr, k, v)
    end
    local i = #self.queries + 1
    self.queries[i] = self.connection:query(queryStr) -- Doing the query
    self.queries[i].onSuccess = function(query, data)
        callback(true, 'success', data)
    end
    self.queries[i].onAborted = function(query)
        callback(false, 'aborted')
    end
    self.queries[i].onError = function(query, err)
        file.Append('gsql_logs.txt', '[gsql][query] : ' .. err)
        callback(false, 'error :' .. err)
    end
    self.queries[i]:start()
    self.affectedRows = query:affectedRows()
end

--- Add a new PreparedQuery object to the "prepared" table
-- @param queryStr string : A SQL query string
-- @return number : index of this object in the "prepared" table
-- @see gsql:execute
function gsql:prepare(queryStr)
    if (queryStr == nil) then
        file.Append('gsql_logs.txt', '[gsql][prepare] : Argument \'queryStr\' is missing. ')
        error('[gsql] An error occured when preparing a query!')
    elseif (type(queryStr) ~= 'string') then
        file.Append('gsql_logs.txt', '[gsql][prepare] : Incorrect type of \'queryStr\'.')
        error('[gsql] An error occured when preparing a query!')
    end
    self.prepared[#self.prepared + 1] = self.connection:prepare(queryStr)

    return #self.prepared
end

--- Delete a PreparedQuery object from the "prepared" table
-- @param index number : index of this object in the "prepared" table
-- @return bool : the status of this deletion
function gsql:delete(index)
    index = index or 1 -- First prepared query by default
    if (type(index) ~= 'number') then
        file.Append('gsql_logs.txt', '[gsql][delete] : Invalid type of \'index\'. It must be a number.')
        error('[gsql] An error occured while trying to delete a prepared query!')
    end
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
function gsql:execute(index, callback, parameters)
    parameters = parameters or {}
    local i = 1
    for _, v in pairs(parameters) do
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
