<cfcomponent extends="storm.stormTableObject">
	<cffunction name="getUsers_withCars">
		<cfset this.getUsers(returnType = 'struct')>
		<cfloop from="1" to="#arrayLen(this.users)#" index="i">
			<cfset this.users[i].getUsersCars(returnType="struct")> 
			<cfloop from="1" to="#arrayLen(this.users[i].usersCars)#" index="n">
				<cfset this.users[i].usersCars[n].car = getStorm(this._dsn_).getOne('cars',this.users[i].usersCars[n].carID)> 
			</cfloop>
		</cfloop>
	</cffunction>
</cfcomponent>
