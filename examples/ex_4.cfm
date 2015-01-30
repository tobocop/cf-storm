<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource')>
<cfset request.user = request.storm.getOne('users', 3)>

<cfset request.user.firstName = 'asdTotally-#now()#'>

<cfset request.storm.save(request.user)>
<cfdump var="#request.user#">
