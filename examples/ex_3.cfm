<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource')>
<cfset request.user = request.storm.getOne('users')>

<cfset request.user.firstName = 'Totally'>
<cfset request.user.lastName = 'steve'>
<cfset request.user.createdOn = now()>
<cfset request.user.active = 1>

<cfset request.storm.save(request.user)>
<cfdump var="#request.user#">
