<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource')>
<cfdump var="#request.storm#">
