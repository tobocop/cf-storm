<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource')>


<cfset request.users = request.storm.getMany(table = 'users')>
<cfdump var="#request.users#" abort="false" label="request.users">


<cfset request.users = request.storm.getMany(table = 'users', where="active = 1")>
<cfdump var="#request.users#" abort="false" label="request.users">


<cfset request.users = request.storm.getMany(table = 'users', where = 'active = 1, lastName = steve')>
<cfdump var="#request.users#" abort="false" label="request.users">

<cfset request.users = request.storm.getMany(table = 'users', order = 'userID desc')>
<cfdump var="#request.users#" abort="false" label="request.users">


<cfset request.users = request.storm.getMany(table = 'users', order = 'userID desc', limit=1)>
<cfdump var="#request.users#" abort="false" label="request.users">


<cfset request.users = request.storm.getMany(columns="userID", table = 'users', order = 'userID desc', limit=1)>
<cfdump var="#request.users#" abort="false" label="request.users">
