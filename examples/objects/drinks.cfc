<cfcomponent extends="storm.stormTableObject">
	<cffunction name="init">
		<cfset this.getUsersDrinks(returnType="struct")>
	</cffunction>
</cfcomponent>
