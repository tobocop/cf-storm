<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource', 'examples.objects')>

<cfset request.user = request.storm.getOne('users', 3)>

<cfdump var="#request.user#">

<cfdump var="#request.user.getFullName()#">

<cfset request.user.lastname = 'From an object! #now()#'>
<cfset request.user.save()>

<cfset request.user = request.storm.getOne('users', 3)>
<cfdump var="#request.user#">

<cfset request.user.getUsersCars()>
<cfdump var="#request.user#">

