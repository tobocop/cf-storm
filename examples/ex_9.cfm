<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource', 'examples.objects')>

<cfset request.users = request.storm.getMany(table='users', returnType="struct")>

<cfdump var="#request.users#" abort="false" label="request.user">

<cfset request.cars = request.storm.getMany(table='cars', returnType="struct")>

<cfdump var="#request.cars#" abort="false" label="request.cars">
