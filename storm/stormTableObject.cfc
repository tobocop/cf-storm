<cfcomponent extends="stormBase" hint="Extend this object from all extra-objects you decide to create to get some extra functionality">
	<cfscript>
		this._dsn_ = '';
	</cfscript>
	<cffunction name="init">
		<cfreturn this>
	</cffunction>
	<cffunction name="initStormTableObject" access="public" returnType="stormTableObject">
		<cfargument name="storm" type="storm" required="true">
		<cfset this._dsn_ = arguments.storm.dsn>
		<cfreturn this>
	</cffunction>


	<cffunction name="formatSQLDate" access="public" returnType="string">
		<cfargument name="date" type="string" required="true">
		<cfreturn dateFormat(arguments.date, 'yyyy-mm-dd') & ' ' & timeFormat(arguments.date, '00:00:00') />
	</cffunction>

	<cffunction name="save" access="public">
		<cfscript>getStorm(this._dsn_).save(this);</cfscript>
	</cffunction>

	<cffunction name="onMissingMethod" access="public" returnType="any">
		<cfargument name="missingMethodName" type="string" required="true">
		<cfargument name="missingMethodArguments" type="struct" required="true">
		<cfscript>
			var local = structNew();
			if(left(arguments.missingMethodName, 3) EQ 'get') {
				implicitGet(arguments.missingMethodName, arguments.missingMethodArguments);
			} else {
				throw("Table is not defined or you called a function that doesn't exist");
			}
		</cfscript>
		
	</cffunction>

	<cffunction name="implicitGet" hint="function for an implicit get">
		<cfargument name="tableToGet" type="string" required="true">
		<cfargument name="queryArguments" type="struct" required="true">
		<cfscript>
			var local = structNew();
			local.ac = arguments.queryArguments;

			if(structKeyExists(local.ac, 'where')) {
				local.ac.originalWhere = local.ac.where;
			} else {
				local.ac.originalWhere = '';
			}

			local.tableName = mid(arguments.tableToGet, 4, len(arguments.tableToGet));

			getStorm(this._dsn_).checkTableCache(local.tableName);
			getStorm(this._dsn_).checkTableCache(this._table_);

			try{
				local.ac.table = local.tableName;
				local.ac.where = local.ac.originalWhere;
				if(len(local.ac.where) GT 0)
				{
					local.ac.where &= ',';
				} else {
					local.ac.where = '';
				}
				local.ac.where &= '#local.tableName#.#getStorm(this._dsn_).getPrimaryKeyCol(this._table_)# = #getStorm(this._dsn_).getPrimaryKeyVal(this)#';

				this[local.tableName] = getStorm(this._dsn_).getMany(argumentCollection = local.ac);
			}
			catch (Any e)
			{
				try{
					local.ac.table = local.tableName;
					local.ac.where = local.ac.originalWhere;

					if(len(local.ac.where) GT 0) {
						local.ac.where &= ',';
					} else {
						local.ac.where = '';
					}

					local.ac.where &= '#local.tableName#.#getStorm(this._dsn_).getPrimaryKeyCol(local.tableName)# = #this[getStorm(this._dsn_).getPrimaryKeyCol(local.tableName)]#';
					this[local.tableName] = getStorm(this._dsn_).getMany(argumentCollection = local.ac);
				}
				catch (Any e) {


					throw("You tried to query a relationship that doesn't exist. Ensure the proper keys are in both tables.", 0, serializeJson(e.tagContext));
				}
			}
			
		</cfscript>
	</cffunction>

</cfcomponent>
