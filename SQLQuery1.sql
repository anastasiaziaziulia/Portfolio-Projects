SELECT *
FROM PortfolioProject..CovidDeaths
Where continent <>'' --similar to iS NOT NULL, but in this case the data has been deleted manually
order by 3,4

Select Location, date, population, total_cases, total_deaths
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent <>''
order by 1,2

---Looking at the Total Cases vs Total Deaths
---Show the likelihood of dying if you contract COVID in your country
SELECT Location, date, total_cases, total_deaths,
CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (CAST(total_deaths AS numeric) / CAST(total_cases AS numeric))*100
END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
Where continent <>''
ORDER BY 1;

---Looking at Total Cases vs Population
---Shows what percentage of population got Covid
SELECT Location, date, Population, total_cases,
CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (CAST(total_cases AS numeric) / CAST(population AS numeric))*100
END AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1;

--Looking at countries with highest Infection Rate vs Population
SELECT 
    Location, 
    CAST(Population AS BIGINT) AS Population,
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,
    MAX((CAST(total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE CAST(Population AS BIGINT) > 0 -- Avoid division by zero
GROUP BY Location, CAST(Population AS BIGINT)
ORDER BY PercentPopulationInfected DESC;

---Showing the countries with the highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent <>''
GROUP BY Location
ORDER BY TotalDeathCount DESC;

---Breaking down by continent CORRECT WAY
SELECT Location, MAX(CAST(new_deaths_smoothed AS FLOAT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent =''
AND location not in ('World', 'European Union (27)', 'International', 'Low%')
GROUP BY Location
ORDER BY TotalDeathCount DESC;
---NOT CORRECT number wise, but better for the visualization purposes
SELECT Continent, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent <>''
GROUP BY Continent
ORDER BY TotalDeathCount DESC;


---Showing continents with the highest death count per population


--GLOBAL NUMBERS
SELECT CONVERT(date, date) Date, SUM(CAST(new_cases_smoothed AS float)) AS Total_Cases, SUM(CAST(new_deaths_smoothed AS float)) AS Total_Deaths,
CASE 
        WHEN SUM(CAST(new_cases_smoothed AS float)) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths_smoothed AS float)) / SUM(CAST(new_cases_smoothed AS float))*100 
END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
Where continent <>''
GROUP BY date
ORDER BY 1;

--Looking at Total Population vs Total Vaccinations
--Use Common Table Expression (CTE)
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated) --if # of columns is not the same as after Select, it's gonna give an error
AS
(
Select dea.continent, dea.location, CONVERT(date, dea.date) Date, dea.population, vac.new_vaccinations_smoothed
, SUM(CAST(vac.new_vaccinations_smoothed AS float)) OVER (Partition by dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated--partition clause, always in OVER clause. Also called Window
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND
	dea.date = vac.date
Where dea.continent <>''
)
SELECT*, (RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM PopvsVac


--Creating View to store data for later visualizations

USE PortfolioProject
Go
CREATE View DeathPercentage AS
SELECT SUM(CAST(new_cases_smoothed AS float)) AS Total_Cases, SUM(CAST(new_deaths_smoothed AS float)) AS Total_Deaths,
CASE 
        WHEN SUM(CAST(new_cases_smoothed AS float)) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths_smoothed AS float)) / SUM(CAST(new_cases_smoothed AS float))*100 
END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
Where continent <>''
--------------------------

USE PortfolioProject
Go
CREATE View PercentPopulationInfected AS
SELECT 
    Location, 
    CAST(Population AS BIGINT) AS Population, date,
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,
    MAX((CAST(total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE CAST(Population AS BIGINT) > 0
GROUP BY Location, CAST(Population AS BIGINT), date
---------------------------
USE PortfolioProject
Go
CREATE View PercentPopulationInfected1 AS
SELECT 
    Location, 
    CAST(Population AS BIGINT) AS Population,
    MAX(CAST(total_cases AS BIGINT)) AS HighestInfectionCount,
    MAX((CAST(total_cases AS FLOAT) / CAST(Population AS FLOAT)) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE CAST(Population AS BIGINT) > 0
GROUP BY Location, CAST(Population AS BIGINT)
----------------------------


USE PortfolioProject
Go
CREATE View TotalDeathCountByCon AS
SELECT Continent, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
Where continent <>''
GROUP BY Continent
--------------------------------