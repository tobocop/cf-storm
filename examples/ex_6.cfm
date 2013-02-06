<cfset request.storm = createObject('component', 'storm.storm').init('storm_datasource')>


<cfset request.usersCars = request.storm.getMany(
	table = "users",
	join = ['usersCars to users', 'cars to usersCars']
)>

<cfdump var="#request.usersCars#" abort="false" label="request.usersCars">

<cfset request.usersCars = request.storm.getMany(
	columns = 'users.firstName, cars.car',
	table = "users",
	join = ['usersCars to users', 'cars to usersCars']
)>

<cfdump var="#request.usersCars#" abort="false" label="request.usersCars">
