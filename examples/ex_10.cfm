<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource', 'examples.objects')>

<cfset request.drinks = request.storm.getMany(table="drinks", returnType="struct")>

<!---<cfdump var="#request.drinks#" abort="false" label="request.drinks">--->

<cfloop from="1" to="#arrayLen(request.drinks)#" index="i">
	<cfloop from="1" to="#arrayLen(request.drinks[i].usersDrinks)#" index="n">
		<cfset request.drinks[i].usersDrinks[n].getUsers_withCars()>
	</cfloop>
</cfloop>

<cfdump var="#request.drinks#" abort="false" label="request.drinks">
