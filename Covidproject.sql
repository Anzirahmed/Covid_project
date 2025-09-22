--1 Infection rate of all countries
select location, population, Max(total_cases) as highestcount, round(max((total_cases/population))*100,3) as infectionrate
from coviddeaths
where total_cases is not null and population is not null
Group by location, population
order by 4 desc;


--2. Categorizing Countries By severity of Cases
select * from coviddeaths limit 5;
With latestcasestable (location, total_cases, population, infectionrate)
as
(select location, population, Max(total_cases) as casecount, round(max((total_cases/population))*100,2) as infectionrate
from coviddeaths
where total_cases is not null and population is not null
Group by location, population
)
select *,
case
when infectionrate < 1 then 'Low Impact'
when infectionrate between 1 and 10 then 'Moderate Impact'
else 'Severe Impact'
end as Severitycategory
from latestcasestable
order by 1;


--3 Ranking 5 highest deathcount days in each continent
with dailydeath 
as( 
select continent,date,location,new_deaths,row_number() over (partition by continent, date order by new_deaths desc) as r
from coviddeaths
where continent is not null and new_deaths is not null
),
deathcount as (
select continent,date,location,new_deaths,row_number() over (partition by continent order by new_deaths desc) as ranking
from dailydeath
where r = 1 
)
select *
from deathcount
where ranking <= 5
order by 1,5;


--4 Ranking the 10 highest mortality rates 
with mortality as (
select location, max(total_cases) as total_cases, max(total_deaths) as total_deaths
from coviddeaths
where continent is not null
group by location
),
rate as 
(
select location,total_cases,total_deaths, round((total_deaths/total_cases)*100,2)  as mortality_rate,row_number() over (order by total_deaths * 100.0 / total_cases desc) as ranking
from mortality
where total_cases > 0 and total_deaths is not null
)
select *
from rate
where ranking <= 10
order by 5;

--5 Trend of deathrate in countries against vaccination rate
select d.location,max(d.population) as deathcount, round(max(d.total_deaths/d.population)*100,3)as deathrate, max(v.people_fully_vaccinated)as Vaccinationcount, round(max(v.people_fully_vaccinated/d.population)*100,3)as vaccinationrate
from coviddeaths as d
Join covidvaccinations as v
on d.location = v.location and d.date = v.date
where d.total_deaths is not null and v.people_fully_vaccinated is not null
group by d.location, d.population 
order by 5 desc;


--6 Montly Growth rate of cases by continent
with monthly as 
(
select continent, date_trunc('month', date)::date as month, sum(new_cases) as monthly_cases,sum(new_deaths) as monthly_deaths
from coviddeaths
where continent is not null
group by continent, date_trunc('month', date)
)
select *
from monthly
order by 1,2;


--7 Count of daily new vaccinations and rolling count fot total vaccination
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(v.new_vaccinations)over(partition by d.location order by d.location,d.date)as rlp
from coviddeaths as d
join covidvaccinations as v
on d.location=v.location
and d.date=v.date
where d.continent is not null and new_vaccinations is not null
group by d.continent, d.location, d.date, d.population,v.new_vaccinations
order by 2,3;



--8 Comparing Deathcount vs Vaccination at Continent Level
select d.continent, round(max(d.total_deaths/d.population)*100,3)as deathpercentage, round(max(v.people_fully_vaccinated/d.population)*100,3) as vaccinatedpercentage
from coviddeaths as d
join covidvaccinations as v
on d.location = v.location and d.date=v.date
where d.continent is not null
group by d.continent
order by 3 desc;

--9 Ranking 5 highest deathcount days in each continent
with dailydeath as
( 
select continent,date,location,new_deaths,row_number() over (partition by continent, date order by new_deaths desc) as r
from coviddeaths
where continent is not null and new_deaths is not null
),
deathcount as
(
select continent,date,location,new_deaths,row_number() over (partition by continent order by new_deaths desc) as ranking
from dailydeath
where r = 1 
)
select *
from deathcount
where ranking <= 5
order by 1,5;


--10
with dailyvacc as 
(
select d.continent, d.location, v.date, v.new_vaccinations,
row_number() over (partition by d.continent order by v.new_vaccinations desc) as rank
from coviddeaths d
join covidvaccinations v
on d.location = v.location and d.date = v.date
where d.continent is not null and v.new_vaccinations is not null
)
select *,
case  
when new_vaccinations < 100000 then 'low rollout'
when new_vaccinations between 100000 and 1000000 then 'medium rollout'
else 'high rollout'
end as Vaccinationrollout
from dailyvacc
where rank = 1
order by 1;


--11 Availibity of Hospital beds vs infection rate
with infection as
(
select continent,max(total_cases)/sum(distinct population)*100 as infection_rate,avg(hospital_beds_per_thousand) as avg_hospital_beds
from coviddeaths
where continent is not null
group by continent
)
select continent, round(infection_rate,2) as infection_rate, round(avg_hospital_beds,2) as avg_hospital_beds
from infection
order by 2 desc;


