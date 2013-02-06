<cfcomponent extends="storm.stormTableObject">
		
	<cffunction name="getFullName">
		<cfreturn this.firstName & ' ' & this.lastName>
	</cffunction>
</cfcomponent>
