<cfcomponent extends="stormBase" name="storm.cfc" hint="An ORM based on the idea of what coldfusion does well, structs and queries">
	<cfset this.dsn = ''>
	<cfset this.objectPath = ''>
	<cfset this.enableObjects = false>
	<cfset this.objects = structNew()>
	<cfset this.cache = structNew()>
	<cfset this.cache.tables = structNew()>
	<cfset this.scaleType = 'decimal,numeric'>

	<cffunction name="init" access="public" returnType="storm" hint="Initializes the object, requires a dsn">
		<cfargument name='dsn' type="string" required="true" hint="The dsn setup in your coldfusion admin for the DB you wish to interact wit">
		<cfargument name='objectPath' type="string" required="false" default="" hint="This is where storm will look for custom objects to extend functionality. It's a dot path">
		<cfset this.dsn = arguments.dsn>
		<cfset this.cache = structNew()>
		<cfset this.cache.tables = structNew()>
		<cfif arguments.objectPath NEQ ''>
			<cfset this.enableObjects = true>
			<cfset this.objectPath = arguments.objectPath>
			<cfdirectory directory="#expandPath('/' & listChangeDelims(this.objectPath, '/', '.') & '/')#" action="list" name="local.qStormObjects">
			<cfloop query="local.qStormObjects">
				<cfset local.objectName = listFirst(local.qStormObjects.name, '.')>
				<cfset this.objects[local.objectName] = this.objectPath & '.' & local.objectName>
			</cfloop>
		</cfif>
		<cfset super.init(this)>
		<cfreturn this>
	</cffunction>

	<cffunction name="getOne" access="public" returnType="struct" hint="When you want only one struct, either by an ID or a new struct">
		<cfargument name="table" type="string" required="true" hint="The full table name you are trying to interact with">
		<cfargument name="id" type="numeric" required="false" hint="The primary key for the table passed in above">

		<cfset var local = StructNew()>

		<cfset checkTableCache(arguments.table)>

		<cfif structKeyExists(arguments, 'id')>
			<cfset local.qGet = getMany(table=arguments.table, where="#getPrimaryKeyCol(arguments.table)# = #arguments.id#")>
			<cfset local.ret = queryToStruct(getColumns(arguments.table) ,local.qGet)>
		<cfelse>
			<cfloop list="#getColumns(arguments.table)#" index="local.column">
				<cfset local.ret[local.column] = ''>
			</cfloop>
		</cfif>
		<cfif local.ret[getPrimaryKeyCol(arguments.table)] EQ ''>
			<cfset local.ret[getPrimaryKeyCol(arguments.table)] = 0>
		</cfif>

		<cfset local.ret._table_ = arguments.table>

		<cfreturn checkRet(local.ret)>
	</cffunction>
	<cffunction name="checkRet" access="private" returnType="any" hint="Checks to see if we can return an object instead of a struct">
		<cfargument name="ret" type="struct" required="true">

		<cfset var local = structNew()>
		<cfif this.enableObjects> 
			<cfif structKeyExists(this.objects, arguments.ret._table_)>
				<cfset local.objRet = createObject('component', this.objects[arguments.ret._table_]).initStormTableObject(this)>	
				<cfloop collection="#arguments.ret#" item="local.key">
					<cfset local.objRet[local.key] = arguments.ret[local.key]>
				</cfloop>
				<cfset local.objRet.init()>
				<cfreturn local.objRet>
			</cfif>
		</cfif>
		<cfreturn arguments.ret>
	</cffunction>

	<cffunction name="getMany" access="public" returnType="any" hint="When you want to get many objects from a table passed back as a query or struct">
		<cfargument name="table" type="string" required="true" hint="The full table name you are trying to interact with">
		<cfargument name="where" type="string" required="false" hint="Any where statements, only evaluateds AND's, not OR's. The format is [table].[column] = [whatever], [table].[column] = [whatever]">
		<cfargument name="order" type="string" required="false" hint="The exact order statement you want without the ORDER BY">
		<cfargument name="join" type="array" required="false" hint="An Example of this argument would be [{table} to {table2}]. {table} will be used as the table for the inner join or INNER JOIN {table} ON {table} = {table2} ">
		<cfargument name="columns" type="string" required="false" hint="The column list you would like returned if you don't want the entire table.">
		<cfargument name="limit" type="numeric" required="false" hint="How many records you would like the query limited to">
		<cfargument name="returnType" type="string" required="false" default="query" hint="Struct or query. multiple results will return an array of structs">

		<cfset var local = StructNew()>

		<cfset checkTableCache(arguments.table)>

		<cfset local.counter = 0>


		<cfquery name="local.qGet" datasource="#this.dsn#">
			SELECT 

				<cfif structKeyExists(arguments, 'limit')>
					TOP #arguments.limit# 
				</cfif>
				
				<cfif NOT structKeyExists(arguments, 'columns')>
					#arguments.table & '.' & listChangeDelims(getColumns(arguments.table), ',' & arguments.table & '.', ',')#

					<cfif structKeyExists(arguments, 'join')>
						<cfloop array="#arguments.join#" index="local.join">
							<cfset local.table = listFirst(local.join, ' ')>
							<cfset checkTableCache(local.table)>
							, #local.table & '.' & listChangeDelims(getColumns(local.table), ',' & local.table & '.', ',')#
						</cfloop>
					</cfif>
				<cfelse>
					#arguments.columns#
				</cfif>

			FROM #arguments.table# WITH(NOLOCK)

			<cfif structKeyExists(arguments, 'join')>
				<cfloop array="#arguments.join#" index="local.join">
					<cfset local.table = listFirst(local.join, ' ')>
					<cfset local.table2 = listLast(local.join, ' ')>
					<cfset checkTableCache(local.table)>
					<cfset checkTableCache(local.table2)>
					<cfif checkIfColumnExists(local.table, getPrimaryKeyCol(local.table2))>
						<cfset local.joinStatement = "#local.table#.#getPrimaryKeyCol(local.table2)# = #local.table2#.#getPrimaryKeyCol(local.table2)#">
					<cfelseif checkIfColumnExists(local.table2, getPrimaryKeyCol(local.table))>
						<cfset local.joinStatement = "#local.table#.#getPrimaryKeyCol(local.table)# = #local.table2#.#getPrimaryKeyCol(local.table)#">
					</cfif>
					INNER JOIN #local.table# WITH(NOLOCK) ON #local.joinStatement#
				</cfloop>
			</cfif>

			<cfif structKeyExists(arguments, 'where')>
				WHERE 1=1

				<cfloop list="#arguments.where#" index="local.whereStatement">
					<cfset local.whereStruct = StructNew()>
					<cfset local.whereStruct.tableColumn = listGetAt(local.whereStatement, 1, ' ')>
					<cfset local.whereStruct.operator = listGetAt(local.whereStatement, 2, ' ')>
					<cfset local.whereStruct.value = listGetAt(local.whereStatement, 3, ' ')>


					<cfif listLen(local.whereStruct.tableColumn, '.') EQ 1>
						<cfset local.whereStruct.table = arguments.table>
						<cfset local.whereStruct.column = listFirst(local.whereStruct.tableColumn, '.')>
					<cfelse>
						<cfset local.whereStruct.table = listFirst(local.whereStruct.tableColumn, '.')>
						<cfset local.whereStruct.column = listLast(local.whereStruct.tableColumn, '.')>
					</cfif>

					<cfif local.whereStruct.operator EQ 'IS'>
						AND #local.whereStruct.table#.#local.whereStruct.column# #listRest(local.whereStatement, ' ')#
					<cfelse>
						AND #local.whereStruct.table#.#local.whereStruct.column# #local.whereStruct.operator# 
							

						<cfif listFindNoCase(this.scaleType, getColumnStruct(local.whereStruct.table, local.whereStruct.column).type) EQ 0>
							<cfqueryparam value="#local.whereStruct.value#" cfsqltype="cf_sql_#getColumnStruct(local.whereStruct.table, local.whereStruct.column).type#">
						<cfelse>
							<cfqueryparam value="#local.whereStruct.value#" cfsqltype="cf_sql_#getColumnStruct(local.whereStruct.table, local.whereStruct.column).type#" maxLength="#getColumnStruct(local.whereStruct.table, local.whereStruct.column).length#" scale="#getColumnStruct(local.whereStruct.table, local.whereStruct.column).scale#">
						</cfif>
					</cfif>
				</cfloop>
			</cfif>

			<cfif structKeyExists(arguments, 'order')>
				ORDER BY #arguments.order#
			</cfif>

		</cfquery>

		<cfif arguments.returnType EQ 'struct'>
			<cfset local.ret = arrayNew(1)>
			<cfloop query="local.qGet">
				<cfset local.ret[local.qGet.currentRow] = queryToStruct(getColumns(arguments.table) ,local.qGet)>
				<cfset local.ret[local.qGet.currentRow]._table_ = arguments.table>
				<cfset local.ret[local.qGet.currentRow] = checkRet(local.ret[local.qGet.currentRow])>
			</cfloop>
			<cfreturn local.ret>
		<cfelse>
			<cfreturn local.qGet>
		</cfif>
	</cffunction>

	<cffunction name="save" access="public" returnType="struct" hint="Saving a storm struct">
		<cfargument name="structToSave" type="any" required="true" hint="A storm struct/object you would get from the getOne command">

		<cfset checkTableCache(arguments.structToSave._table_)>

		<!--- 
		<cfset validate(arguments.structToSave)>
		 --->

		<cfif getPrimaryKeyVal(arguments.structToSave) GT 0>
			<cfset updateExisting(arguments.structToSave)>
		<cfelse>
			<cfset arguments.structToSave[getPrimaryKeyCol(arguments.structToSave._table_)] = insertNew(arguments.structToSave)>
		</cfif>

		<cfreturn arguments.structToSave>
	</cffunction>

	<cffunction name="insertNew" access="private" returnType="numeric" hint="Inserts a new record">
		<cfargument name="st" type="struct" required="true" hint="A storm struct you would get fromt he getOne command">

		<cfset var local = StructNew()>

		<cfset local.counter = 0>
		<cfset local.cleanedColumns = cleanColumns(arguments.st._table_)>

		<cfquery name="local.qInsert" datasource="#this.dsn#">
			SET nocount ON;
			INSERT INTO #arguments.st._table_#
			(#local.cleanedColumns#)
			VALUES
			(
				<cfloop list="#local.cleanedColumns#" index="local.column">
					<cfset local.counter++>
					<cfswitch expression="#local.column#">
						<cfcase value="created">
							getDate()
						</cfcase>
						<cfcase value="modified">
							getDate()
						</cfcase>
						<cfdefaultcase>
							<cfif arguments.st[local.column] NEQ ''>
								<cfif listFindNoCase(this.scaleType, getColumnStruct(arguments.st._table_, local.column).type) EQ 0 AND NOT FindNoCase('date' ,getColumnStruct(arguments.st._table_, local.column).type)>
									<cfqueryparam value="#arguments.st[local.column]#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#">
								<cfelseif FindNoCase('date' ,getColumnStruct(arguments.st._table_, local.column).type)> 
									<cfqueryparam value="#dateFormat(arguments.st[local.column], 'yyyy-mm-dd') & ' ' & timeFormat(arguments.st[local.column], 'HH:mm:ss:l')#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#">
								<cfelseif getColumnStruct(arguments.st._table_, local.column).scale GT 0> 
									<cfqueryparam value="#arguments.st[local.column]#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#" maxLength="#getColumnStruct(arguments.st._table_, local.column).length#" scale="#getColumnStruct(arguments.st._table_, local.column).scale#">
								<cfelse>
									<cfqueryparam value="#arguments.st[local.column]#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#" maxLength="#getColumnStruct(arguments.st._table_, local.column).length#">
								</cfif>
							<cfelse>
								null
							</cfif>
						</cfdefaultcase>
					</cfswitch>
					<cfif listLen(local.cleanedColumns) NEQ local.counter>,</cfif>
				</cfloop>
			)
			SET nocount OFF;

			SELECT ident_current('#arguments.st._table_#') AS newID;
		</cfquery>

		<cfreturn local.qInsert.newID>
	</cffunction>

	<cffunction name="updateExisting" access="private" returnType="void" hint="Updates a record">
		<cfargument name="st" type="struct" required="true" hint="A storm struct you would get fromt he getOne command">

		<cfset var local = StructNew()>

		<cfset local.counter = 0>
		<cfset local.cleanedColumns = cleanColumns(arguments.st._table_)>

		<cfquery name="local.qUpdate" datasource="#this.dsn#">
			UPDATE #arguments.st._table_#		
			SET
				<cfloop list="#local.cleanedColumns#" index="local.column">
					<cfset local.counter++>
					<cfswitch expression="#local.column#">
						<cfcase value="created">created = created<cfif listLen(local.cleanedColumns) NEQ local.counter>,</cfif></cfcase>
						<cfcase value="modified">
							modified = getDate()
							<cfif listLen(local.cleanedColumns) NEQ local.counter>,</cfif>
						</cfcase>
						<cfdefaultcase>
							<cfif arguments.st[local.column] NEQ ''>
								<cfif listFindNoCase(this.scaleType,getColumnStruct(arguments.st._table_, local.column).type) EQ 0 AND NOT FindNoCase('date' ,getColumnStruct(arguments.st._table_, local.column).type)>
									#local.column# = <cfqueryparam value="#arguments.st[local.column]#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#">
								<cfelseif FindNoCase('date' ,getColumnStruct(arguments.st._table_, local.column).type)> 
									#local.column# = <cfqueryparam value="#dateFormat(arguments.st[local.column], 'yyyy-mm-dd') & ' ' & timeFormat(arguments.st[local.column], 'HH:mm:ss:l')#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#">
								<cfelseif getColumnStruct(arguments.st._table_, local.column).scale GT 0> 
									#local.column# = <cfqueryparam value="#arguments.st[local.column]#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#" maxLength="#getColumnStruct(arguments.st._table_, local.column).length#" scale="#getColumnStruct(arguments.st._table_, local.column).scale#">
								<cfelse>
									#local.column# = <cfqueryparam value="#arguments.st[local.column]#" cfsqltype="cf_sql_#getColumnStruct(arguments.st._table_, local.column).type#" maxLength="#getColumnStruct(arguments.st._table_, local.column).length#">
								</cfif>
								<cfif listLen(local.cleanedColumns) NEQ local.counter>,</cfif>
							<cfelseif getColumnStruct(arguments.st._table_, local.column).canNull EQ "YES">
								#local.column# = null 
								<cfif listLen(local.cleanedColumns) NEQ local.counter>,</cfif>
							</cfif>
						</cfdefaultcase>
					</cfswitch>
				</cfloop>
			WHERE #getPrimaryKeyCol(arguments.st._table_)# = <cfqueryparam value="#getPrimaryKeyVal(arguments.st)#" cfsqltype="cf_sql_integer">
		</cfquery>
		
	</cffunction>

	<cffunction name="delete" access="public" returnType="boolean" hint="deletes a stormObject">
		<cfargument name="structTodelete" type="any" required="true" hint="A storm struct/object you would delete">
		<cfset local.ret = false>
		<cfset checkTableCache(arguments.structTodelete._table_)>
		<cfif getPrimaryKeyVal(arguments.structTodelete) NEQ 0>
			<cfquery name="delete" datasource="#this.dsn#">
				DELETE FROM #arguments.structTodelete._table_# 
				WHERE #getPrimaryKeyCol(arguments.structTodelete._table_)# = <cfqueryparam value="#getPrimaryKeyVal(arguments.structTodelete)#" cfsqltype="cf_sql_#getColumnStruct(arguments.structTodelete._table_,getPrimaryKeyCol(arguments.structTodelete._table_)).type#">
			</cfquery>
			<cfset local.ret = true>
		</cfif>
		<cfreturn local.ret>
	</cffunction>

	<cffunction name="populate" access="public" returnType="struct" hint="Populates a storm struct based on whatever struct you pass in">
		<cfargument name="table" type="string" required="true" hint="The table for the storm struct you would like back">
		<cfargument name="st" type="struct" required="true" hint="The structure you would like to match up with a storm struct">

		<cfset var local = StructNew()>
		
		<cfset checkTableCache(arguments.table)>

		<cfset local.ret = StructNew()>
		<cfset local.ret._table_ = arguments.table>

		<cfloop list="#getColumns(arguments.table)#" index="local.column">
			<cfif structKeyExists(arguments.st, local.column)>
				<cfset local.ret[local.column] = arguments.st[local.column]>
			<cfelse>
				<cfset local.ret[local.column] = ''>
			</cfif>
		</cfloop>
		<cfreturn checkRet(local.ret)>	
	</cffunction>

	<cffunction name="validate" access="public" returnType="array" hint="Validates a storm struct according to the column paramaters from the database">
		<cfargument name="st" type="struct" required="true" hint="A storm struct you would get fromt he getOne command">

		<cfset var local = StructNew()>

		<cfset checkTableCache(arguments.st._table_)>
		<cfset local.errors = arrayNew(1)>

		<cfloop collection="#arguments.st#" item="local.column">
			<cfif local.column NEQ '_table_'>
				<cfif arguments.st[local.column] EQ '' AND getColumnStruct(arguments.st._table_, local.column).canNull EQ "NO">
					<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# cannot be null')>
				<cfelseif len(arguments.st[local.column]) GT 0>
					<cfswitch expression = "#getColumnStruct(arguments.st._table_, local.column).type#">
						<cfcase value="varchar"></cfcase>
						<cfcase value="datetime"></cfcase>
						<cfcase value="char"></cfcase>
						<cfcase value="real"></cfcase>
						<cfcase value="nchar"></cfcase>
						<cfcase value="text"></cfcase>
						<cfcase value="smalldatetime"></cfcase>
						<cfcase value="ntext"></cfcase>
						<cfcase value="varbinary"></cfcase>
						<cfcase value="smallint"></cfcase>
						<cfcase value="float"></cfcase>
						<cfcase value="smallmoney"></cfcase>
						<cfcase value="nvarchar"></cfcase>
						<cfcase value="money"></cfcase>
						<cfcase value="binary"></cfcase>
						<cfcase value="decimal">
							<cfset local.regex = "^[0-9]{0,#getColumnStruct(arguments.st._table_, local.column).length - getColumnStruct(arguments.st._table_, local.column).scale#}\.?[0-9]{0,#getColumnStruct(arguments.st._table_, local.column).scale#}$">
							<cfif NOT reFind(local.regex, arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# does not fit with a decimal(#getColumnStruct(arguments.st._table_, local.column).length#, #getColumnStruct(arguments.st._table_, local.column).scale#)')>
							</cfif>
						</cfcase>
						<cfcase value="int identity">
							<cfif NOT reFind('^[1-9]+[0-9]*$', arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is not a numeric value')>
							</cfif>
						</cfcase>
						<cfcase value="bigint identity">
							<cfif NOT reFind('^[1-9]+[0-9]*$', arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is not a numeric value')>
							</cfif>
						</cfcase>
						<cfcase value="integer">
							<cfif NOT reFind('^-?[0-9]+[0-9]*$', arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is not a numeric value')>
							</cfif>
						</cfcase>
						<cfcase value="numeric">
							<cfif NOT reFind('^-?[0-9]+[0-9]*$', arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is not a numeric value')>
							</cfif>
						</cfcase>
						<cfcase value="tinyint">
							<cfif NOT reFind('^-?[0-9]+[0-9]*$', arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is not a numeric value')>
							</cfif>
						</cfcase>
						<cfcase value="bigint">
							<cfif NOT reFind('^-?[0-9]+[0-9]*$', arguments.st[local.column])>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is not a numeric value')>
							</cfif>
						</cfcase>
						<cfcase value="bit">
							<cfif arguments.st[local.column] NEQ 0 AND arguments.st[local.column] NEQ 1>
								<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# needs to be a 0 or 1.')>
							</cfif>
						</cfcase>
						<cfdefaultcase>
							<cfdump var="#getColumnStruct(arguments.st._table_, local.column)#" label="getColumnStruct(arguments.st._table_, local.column)" />
							<cfabort/>
						</cfdefaultcase>
					</cfswitch>
					<cfif len(arguments.st[local.column]) GT getColumnStruct(arguments.st._table_, local.column).length AND getColumnStruct(arguments.st._table_, local.column).type NEQ 'datetime'>
						<cfset arrayAppend(local.errors, 'Column: #local.column# = #arguments.st[local.column]# is to long by #len(arguments.st[local.column]) - getColumnStruct(arguments.st._table_, column).length# characters')>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn local.errors>
	</cffunction>
	
	<cffunction name="generateForm" access="public" returnType="string" hint="Generates a helper form to get going creating an edit page for a table">
		<cfargument name="table" required="true" type="string" hint="The table you are ultimately trying to save to or update">

		<cfset var local = StructNew()>

		<cfset checkTableCache(arguments.table)>

		<cfset local.cleanedColumns = cleanColumns(arguments.table)>

		<cfoutput>
			<cfset local.primaryKeyField = '<input type="hidden" value="" name="#getPrimaryKeyCol(arguments.table)#"'>
			<cfsavecontent variable="local.ret">
				<form method="post" action="asd.cfm">
					#local.primaryKeyField#
					<ul>
						<cfloop list="#local.cleanedColumns#" index="local.column">
							<cfset local.label = local.column>
							<cfif Find('_', local.column)>
								<cfset local.label = Replace(local.label, '_', ' ')>
							<cfelseif REFind('[A-Z]', local.column)>
								<cfset local.label = REReplace(local.label, '([A-Z]{1})', ' \U\1', 'all')>
							</cfif>
							<li>
								<label>#local.label#:</label>
								<input type="text" value="" name="#local.column#">
							</li>
						</cfloop>
					</ul>
				</form>
			</cfsavecontent>
		</cfoutput>

		<cfreturn local.ret>
	</cffunction>

	<cffunction name="queryToStruct" access="private" returnType="struct" hint="Converts a query to a struct">
		<cfargument name="columns" type="string" required="true" hint="The columns of the query">
		<cfargument name="query" type="query" required="true" hint="The query to conver">

		<cfset var local = StructNew()>
		
		<cfset local.ret = StructNew()>



		<cfloop list="#arguments.columns#" index="local.column">
			<!--- This if statement is to handle binary objects. I'm assuming if you're using them you want the byteArray Back --->
			<cfif NOT isArray(arguments.query[local.column][1])>
				<cfset local.ret[local.column] = trim(arguments.query[local.column][arguments.query.currentRow])>	
			<cfelse>
				<cfdump var="Binary data types are not supported. Column: #local.column#">
				<cfabort>
			</cfif>
		</cfloop>
		
		<cfreturn local.ret>
	</cffunction>

	<cffunction name="checkTableCache" access="public" returnType="void" hint="Checks the cache to see if we already have generated the necessary parameters to work with this table">
		<cfargument name="table" type="string" required="true" hint="The table that is being checked">

		<cfset var local = StructNew()>

		<cfif NOT structKeyExists(this.cache.tables, arguments.table)>
			<cfset this.cache.tables[arguments.table] = StructNew()>

			<cfdbinfo datasource="#this.dsn#" name="local.qGetColumns" type="columns" table="#arguments.table#">

			<cfset this.cache.tables[arguments.table].columns = ValueList(local.qGetColumns.column_name, ',')>
			<cfset this.cache.tables[arguments.table].stColumns = StructNew()>

			<cfloop query="local.qGetColumns">
				<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name] = StructNew()>
				<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].length = local.qGetColumns.column_size>
				<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].canNull = local.qGetColumns.is_nullable>
				<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].type = local.qGetColumns.type_name>

				<cfif  local.qGetColumns.type_name EQ 'int'>
					<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].type = 'integer'>
				<cfelseif listFindNoCase(this.scaleType, local.qGetColumns.type_name)>
					<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].type = local.qGetColumns.type_name>
					<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].scale = local.qGetColumns.decimal_digits>
					<cfset this.cache.tables[arguments.table].stColumns[local.qGetColumns.column_name].length = local.qGetColumns.column_size + 1>
				</cfif>
				<cfif local.qGetColumns.is_primaryKey EQ 'YES'>
					<cfset this.cache.tables[arguments.table].primaryKey = local.qGetColumns.column_name>
				</cfif>
			</cfloop>
		</cfif>	
	</cffunction>

	<cffunction name="getColumns" access="private" returnType="string" hint="Gets the columns of a table from the cache">
		<cfargument name="table" type="string" required="true" hint="The table we are trying to interact with">
		<cfreturn trim(this.cache.tables[arguments.table].columns)>
	</cffunction>

	<cffunction name="getColumnStruct" access="private" returnType="struct" hint="Gets the properties for a specific column we're working with from the cache">
		<cfargument name="table" type="string" required="true" hint="The table the column belongs to">
		<cfargument name="column" type="string" required="true" hint="The column we are trying to work with">
		<cfreturn this.cache.tables[arguments.table].stColumns[arguments.column]>
	</cffunction>

	<cffunction name="checkIfColumnExists" access="private" returnType="boolean" hint="Checks to see if a particular table has a column">
		<cfargument name="table" type="string" required="true" hint="The table we are trying to work with">
		<cfargument name="column" type="string" required="true" hint="The column we are trying to check if exists">
		<cftry>
			<cfset getColumnStruct(arguments.table, arguments.column)>
			<cfreturn true>
			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
	
	</cffunction>

	<cffunction name="cleanColumns" access="private" returnType="string" hint="Removes the primary key column from the column list for saving and updating">
		<cfargument name="table" type="string" required="true" hint="The table we are trying to save or update">
		<cfreturn trim(replace(getColumns(arguments.table), getPrimaryKeyCol(arguments.table) & ',', ''))>
	</cffunction>

	<cffunction name="getPrimaryKeyVal" access="public" returnType="numeric" hint="Gets the value of the primary key from a storm structure">
		<cfargument name="stTable" type="struct" required="true" hint="A storm structure">

		<cfset var local = StructNew()>

		<cfset local.pk = arguments.stTable[getPrimaryKeyCol(arguments.stTable._table_)]>

		<cfif isNumeric(local.pk)>
			<cfreturn local.pk>
		<cfelse>
			<cfreturn 0>
		</cfif>
	</cffunction>

	<cffunction name="getPrimaryKeyCol" access="public" returnType="string" hint="Gets the column for the primary key of a particular table">
		<cfargument name="table" type="string" required="true" hint="The table you want the primary key from">
		<cfreturn this.cache.tables[arguments.table].primaryKey>
	</cffunction>
</cfcomponent>
