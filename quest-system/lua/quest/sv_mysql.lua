local mysql

if TTTQuests.Config.MySQL.Enabled then
	require("mysqloo")

	// Create connection to mysql database
	mysql = mysql || mysqloo.connect(TTTQuests.Config.MySQL.IP,
		TTTQuests.Config.MySQL.UserName,
		TTTQuests.Config.MySQL.Password,
		TTTQuests.Config.MySQL.Database,
		TTTQuests.Config.MySQL.Port
		)
	mysql.onConnected = function(self)
		TTTQuests.Log("Database has connected!", COLOR_RED)
	end

	mysql.onConnectionFailed = function(self, err)
		TTTQuests.Log("Connection to database failed! Error: " .. err, COLOR_RED)
	end
	mysql:connect()
	mysql:wait() // wait until connect
end

sql.MySQLQuery = function(query, ...)
	local result

	if mysql then
		local q = mysql:query( string.format( query, unpack( {...} ) ) )

		q.onSuccess = function(self, data)
			if ( table.Count(data) > 0 && data ) then
				result = data
			end
		end	
		q.onError = function(self, err, sql)
			result = false
		end
		q:start()
		q:wait() // wait until query finish
	else
		result = sql.Query( string.format( query, unpack( {...} ) ) )
	end
	return result
end

sql.MySQLTableExists = function(tableName)
	local result = sql.MySQLQuery(string.format("SELECT * FROM %s", tableName))

	return tobool(result)
end

sql.TableToParamString = function(tab, isMySQL)
	local params = ""

	// Convert Lua types to SQL types
	local types = {
		["number"] = isMySQL && "INT" || "INTEGER",
		["boolean"] = isMySQL && "TINYINT" || "INTEGER", // We'll present bool as 1 (true) and 0 (false)
		// Other types will be string. Even table.
	}

	for name, default in pairs(tab) do
		// Only true programmer will understand what is here
		params = params .. ( params != "" && ", " || "" ) .. name .. " "
				 .. ( types[type(default)] || "TEXT" ) .. " NOT NULL " .. ( !isstring(default) && ( " DEFAULT " .. tostring(default) ) || "" )
	end

	return params
end

TTTQuests.Log("Mysql module loaded!", COLOR_GREEN)