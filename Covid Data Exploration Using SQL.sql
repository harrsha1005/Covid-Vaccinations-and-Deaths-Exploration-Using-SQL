Select * from Project..CovidDeaths
WHERE continent IS NOT NULL
order by 3,4

Select Location,date,total_cases,new_cases,total_deaths,population 
FROM Project..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths 
--Shows likelihood of dying if you contract covid in your country
Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM Project..CovidDeaths
Where Location like '%India%'
order by 1,2

Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM Project..CovidDeaths
Where Location like '%States%'
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid 
Select Location,date,total_cases,population,(total_cases/population)*100 as PercentPopulationInfected
FROM Project..CovidDeaths
Where Location like '%India%'
order by 1,2

-- Looking at Countries with highest Infection Rate compared to Population
Select Location,Population,MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PercentPopulationInfected 
From Project..CovidDeaths
Group by Location,Population
Order by PercentPopulationInfected desc

--Showing Countries with Highest Death Count per population
Select Location,MAX(cast (Total_deaths as int)) as TotalDeathCount
From Project..CovidDeaths
WHERE continent IS NOT NULL
Group by Location 
order by TotalDeathCount desc

--BREAKING THINGS DOWN BASED ON CONTINENT

-- SHOW THE CONTINENT WITH HIGHEST DEATH COUNT PER POPULATION
Select continent,MAX(cast (Total_deaths as int)) as TotalDeathCount
From Project..CovidDeaths
where continent is not null
Group by continent 
order by TotalDeathCount desc


--GLOBAL NUMBERS
--Select date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
--FROM Project..CovidDeaths
--where continent is not null
--group by date
--order by 1,2


Select SUM(new_cases) as total_cases,SUM(cast(new_deaths as int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project..CovidDeaths
where continent is not null
order by 1,2

Select * 
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
on dea.location=vac.location and dea.date=vac.date

-- Looking at total population v/s vaccinations

SELECT dea.continent,dea.location,dea.date,population,vac.new_vaccinations
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac 
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent IS NOT null
order by 2,3

--To find total percentage of the population that has received atleast one dose of covid vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query to be able to use RollingPeopleVaccinated column values to calculate (RollingPeopleVaccinated/Population)*100
--Without using CTE, we cannot use RollingPeopleVaccinated which is calculated in the below query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentagePopulationVaccinatedPerDay
From PopvsVac

--Using Temp Table

DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View 
-- Views can be used to create visualizations in Tableau 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 