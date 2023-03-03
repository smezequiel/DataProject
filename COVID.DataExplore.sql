--		DATA EXPLORATION		---

-- Select Data that we are going to use
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
Order by 1, 2

-- Total cases vs Total Deaths (percentage)
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location = 'Argentina'
Order by 1, 2

-- Total cases vs Population in Argentina (percentage of people that got it)
SELECT Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
WHERE location = 'Argentina'
Order by 1, 2

-- Highest infection rate compared to population? 
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
--WHERE location = 'Argentina'
Group By Location, population
Order by PercentPopulationInfected desc


-- Highest Death count per Population
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location = 'Argentina'
Where continent is not null
Group By Location
Order by TotalDeathCount desc


-- LET BREAK THINGS DOWN BY CONTINENT
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location = 'Argentina'
Where continent is null
Group By location
Order by TotalDeathCount desc

-- Countries with highest death count by population
SELECT location, population, MAX(cast(total_deaths as int)) as TotalDeathCount, (MAX(cast(total_deaths as int))/population)*100 as Promedio
FROM EZEPROJECT.dbo.CovidDeaths
--WHERE location = 'Argentina'
Where continent is null
Group By location, population
Order by Promedio desc

-- Global Numbers:
-- Total cases per day and deaths with percentage
SELECT date, SUM(new_cases) as NewCasesPerDay, SUM(cast(new_deaths as int)) as NewDeathsPerDay, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage 
FROM EZEPROJECT.dbo.CovidDeaths
WHERE continent is not null 
GROUP BY date
ORDER BY 1, 2

-- Total casesand deaths with percentage
SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM EZEPROJECT.dbo.CovidDeaths
WHERE continent is not null 
ORDER BY 1, 2



-- Population vs Vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM EZEPROJECT.dbo.CovidDeaths as dea
Join EZEPROJECT..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER by 2, 3


-- Add Vaccinations per day as we go:

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location) 
FROM EZEPROJECT.dbo.CovidDeaths as dea
Join EZEPROJECT..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER by 2, 3


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollinPeopleVaccinated
FROM EZEPROJECT.dbo.CovidDeaths as dea
Join EZEPROJECT..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER by 2, 3


With PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollinPeopleVaccinated
FROM EZEPROJECT.dbo.CovidDeaths as dea
Join EZEPROJECT..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER by 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
FROM PopvsVac


-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccionations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollinPeopleVaccinated
FROM EZEPROJECT.dbo.CovidDeaths as dea
Join EZEPROJECT..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
--WHERE dea.continent is not null
--ORDER by 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
FROM #PercentPopulationVaccinated



-- Create Tables por Later Visualization

Create View PercentPeopleVaccinated2 as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollinPeopleVaccinated
-- Es otra forma de convertir en vez de usar cast
FROM EZEPROJECT.dbo.CovidDeaths as dea
Join EZEPROJECT..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER by 2, 3

Create View PercentPeopleInfected as
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
--WHERE location = 'Argentina'
Group By Location, population
--Order by PercentPopulationInfected desc

Create View TotalDeaths as
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE location = 'Argentina'
Where continent is not null
Group By Location
--Order by TotalDeathCount desc