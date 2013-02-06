<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource', 'examples.objects')>

<cfset request.user = request.storm.getOne('users')>

<cfdump var="#request.user#">
