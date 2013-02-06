<cfcomponent name="stormBase.cfc">
	<cffunction name="init" access="public">
		<cfargument name="storm" type="storm" required="true">
		<cfscript>
			if(NOT isDefined('application'))
			{
				application = structNew();
			}
			if(NOT structKeyExists(application, 'stormInstances')) {
				application.stormInstances = structNew();		
			}
			application.stormInstances[arguments.storm.dsn] = arguments.storm;
		</cfscript>
	</cffunction>
	<cffunction name="getStorm" access="public">
		<cfargument name="dsn" type="string" required="true">
		<cfreturn application.stormInstances[arguments.dsn]/>
	</cffunction>
</cfcomponent>
