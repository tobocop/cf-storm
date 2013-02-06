<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource')>
<cfset request.user = request.storm.getOne('users')>
<cfdump var="#request.user#">
