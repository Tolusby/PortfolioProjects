
SELECT * 
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3,4

-- Turning the blank values in Continent to Null
UPDATE CovidDeaths
SET continent = NULL
WHERE TRIM(continent) = ''



--SELECT * 
--FROM CovidVaccinations
--ORDER BY 3,4

--CHANGING DATE COLUMN TO DATE
SELECT * FROM CovidDeaths WHERE ISDATE(date) = 0;\

ALTER TABLE CovidDeaths
ALTER COLUMN date DATE

-- CHANGING OTHER COLUMNS TO FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN population FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN new_cases FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases_per_million FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN new_cases_per_million FLOAT


-- SELECTION OF USED DATA
SELECT location, date, total_cases,new_cases,total_deaths,population
FROM CovidDeaths
ORDER BY 1,2

-- TOTAL CASES PER DEATH IN % IN NIGERIA
SELECT location, date, total_cases,total_deaths, (total_deaths) / NULLIF(total_cases, 0)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null and location = 'Nigeria'
ORDER BY 1,2

-- TOTAL CASES VS POPULATION IN NIGERIA
-- Shows population that got covid
SELECT location, date, total_cases,total_deaths,population, (total_deaths) / NULLIF(population, 0)*100 as CasesPercentage
FROM CovidDeaths
WHERE continent is not null and location = 'Nigeria'
ORDER BY 1,2

-- Looking at countries with Highest infection rate to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, Max(total_cases/NULLIF(population,0))*100 as CasesPercentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY CasesPercentage DESC


--- Showing Continents with the highest Headcounts
SELECT iso_code,location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is null and location NOT LIKE '%income%'
GROUP BY location, iso_code
ORDER BY TotalDeathCount DESC

--Showing the countries with the highest Death Count per Population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Global Numbers
SELECT  date, SUM(new_cases) as TotalCases,SUM(new_deaths) as TotalDeaths, (NULLIF(SUM(new_deaths),0))/(NULLIF(SUM(new_cases),0))*100 AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date 
ORDER BY 1,2

SELECT  SUM(new_cases) as TotalCases,SUM(new_deaths) as TotalDeaths, (NULLIF(SUM(new_deaths),0))/(NULLIF(SUM(new_cases),0))*100 AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date 
ORDER BY 1,2


-- Joining both Databases together
Select *
FROM CovidVaccinations vac
Join CovidDeaths dea
    On dea.location =vac.location
	and dea.date = vac.date

--Looking at Total Population vs Vaccination
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations
FROM CovidVaccinations vac
Join CovidDeaths dea
    On dea.location =vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Rolling the new vaccination numbers

Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) Over (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedPeople
FROM CovidVaccinations vac
Join CovidDeaths dea
    On dea.location =vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE
With PopvsVac (Continent, Location,Date,Population,New_Vaccinations, RollingVaccinatedPeople)
as
(
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) Over (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedPeople
FROM CovidVaccinations vac
Join CovidDeaths dea
    On dea.location =vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingVaccinatedPeople/(Population))*100
FROM PopvsVac



-- Correcting the new vac error
SELECT new_vaccinations
FROM CovidVaccinations
WHERE ISNUMERIC(new_vaccinations) = 0
UPDATE CovidVaccinations
SET new_vaccinations = NULL
WHERE ISNUMERIC(new_vaccinations) = 0


--DROPPING THE TABLE
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
DROP TABLE #PercentPopulationVaccinated

-- TEMP TABLE

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinatedPeople numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations )) Over (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedPeople
FROM CovidVaccinations vac
Join CovidDeaths dea
    On dea.location =vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingVaccinatedPeople/(Population))*100
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations )) Over (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedPeople
FROM CovidVaccinations vac
Join CovidDeaths dea
    On dea.location =vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
