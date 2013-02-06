create table users (
	userID int not null primary key identity(1,1),
	firstName varchar(250) null,
	lastName varchar(250) null,
	createdOn datetime not null,
	active bit not null
);

insert
	into users(
	firstname,
	lastname,
createdon,
	active)
values
	(
	'carUser',
	'user',
	'2013-02-05 19:27:57.877',
	0);



insert
	into users(
	firstname,
	lastname,
createdon,
	active)
values
	(
	'inactive user!',
	'wontshow',
	'2013-02-05 19:27:57.877',
	0);



create table usersCars (
	usersCarID int not null primary key identity(1,1),
	userID int not null,
	carID int not null
);


create table cars(
	carID int not null primary key identity(1,1),
	car varchar(250) not null
)



insert into cars (car) values('Bently');
insert into cars (car) values('Ford Escort');
insert into cars (car) values('Lambo');
insert into cars (car) values('Donkey Cart');

insert into usersCars (userID, carID) values(3,1)
insert into usersCars (userID, carID) values(3,2)
insert into usersCars (userID, carID) values(5,4)
insert into usersCars (userID, carID) values(4,1)
insert into usersCars (userID, carID) values(4,2)
insert into usersCars (userID, carID) values(4,3)




create table usersDrinks(
	usersDrinkID int not null primary key identity(1,1),
	userID int not null,
	drinkID int not null
)

create table drinks (
	drinkID int not null primary key identity(1,1),
	drink varchar(250) not null
)


insert into drinks(drink)values('whiskey')
insert into drinks(drink)values('vodka')
insert into drinks(drink)values('beer')
insert into drinks(drink)values('water')

select * from users
select * from drinks

insert into usersDrinks(userID, drinkID) values (3,1)

insert into usersDrinks(userID, drinkID) values (4,2)
insert into usersDrinks(userID, drinkID) values (4,3)

insert into usersDrinks(userID, drinkID) values (5,4)
insert into usersDrinks(userID, drinkID) values (5,1)


