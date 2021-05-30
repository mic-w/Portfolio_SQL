---------------------------------------------------------------------------------------------------------------------------------------------------
-- Thanks to the inspiration of Alex the Analyst.
-- This is a SQL project that aims to improve my SQL Querying skill.
---------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * 
FROM PortfolioProject..CovidDeaths

SELECT *
FROM PortfolioProject..CovidVaccinations


-- Start from population and total confirmed cases
-- Results: In terms of number of cases, the U.S still has the highest number of total cases as of 5/23, followed by India and Brazil

SELECT location, MAX(population) AS TotalPopulation, SUM(new_cases) AS TotalCases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalCases DESC

-- Let's find out the percent of population infected
-- Results: In terms of percent of population confirmed, the U.S. still ranks no.1, followed by Seychelles and Lithuania

SELECT location, MAX(population) AS TotalPopulation, SUM(new_cases) AS TotalCases, 
CASE WHEN 
	SUM(new_cases) IS NOT NULL THEN CONCAT(ROUND((SUM(new_cases) / MAX(population)) * 100, 5), '%') 
ELSE 
	NULL
END AS PercentConfirmed
FROM PortfolioProject..CovidDeaths
WHERE continent	IS NOT NULL
GROUP BY location
ORDER BY PercentConfirmed DESC

-- How about the total death?
-- Results: Hungary has the highest percent of total death; As of 5/23, the U.S. ranks no.17. 

SELECT location, MAX(population) AS TotalPopulation, SUM(CAST(new_deaths AS INT)) AS TotalDeath, 
CASE WHEN
	SUM(new_cases) IS NOT NULL THEN SUM(CAST(new_deaths AS INT)) / MAX(population)
ELSE
	NULL
END AS PercentDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY PercentDeath DESC


--- What is the death rate for each country?
--- Results: Vanuatu has the highest death rate among those who infected, followed by Yemen, Mexico, Syria,. etc

SELECT location, (SUM(CAST(new_deaths AS INT)) / (SUM(new_cases)) * 100) AS DeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathRate DESC


-- Which 3 locations in Asia have the highest percent of confirmed cases?
-- Results: Bahrain, Israel, and Maldives

SELECT location, MAX(population) AS TotalPopulation, sum(new_cases) AS TotalCases, (SUM(new_cases) / MAX(population)) * 100 AS PercentConfirmed
FROM PortfolioProject..CovidDeaths
WHERE continent = 'Asia'
GROUP BY location
ORDER BY PercentConfirmed DESC

-- Which 3 locations in North America have the highest percent of confirmed cases?
-- Results: U.S., Panama, and Costa Rica

SELECT location, MAX(population) AS TotalPopulation, sum(new_cases) AS TotalCases, (SUM(new_cases) / MAX(population)) * 100 AS PercentConfirmed
FROM PortfolioProject..CovidDeaths
WHERE continent = 'North America'
GROUP BY location
ORDER BY PercentConfirmed DESC

-- Looking at total population vs vaccinations

SELECT D.location, D.date, D.population, V.total_vaccinations
FROM PortfolioProject..CovidDeaths AS D
INNER JOIN PortfolioProject..CovidVaccinations AS V
ON D.date = V.date AND
D.location = V.location 
WHERE D.continent IS NOT NULL

-- Looking at the total population, new vaccinations, and rolling vaccination by regions

SELECT D.location, D.date, D.population, V.new_vaccinations, 
SUM(CAST(V.new_vaccinations AS INT)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS D
INNER JOIN PortfolioProject..CovidVaccinations AS V
ON D.location = V.location AND
D.date = V.date 
WHERE D.continent IS NOT NULL

-- Build a CTE (Common Table Expression, works like a table, except that it is not stored anywhere. Only exists when you run the code.)

WITH PopvsVAC (Continent, Location, Date, Population, new_vaccination, RollingPeopleVaccinated)
AS (
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths AS D
	INNER JOIN PortfolioProject..CovidVaccinations AS V
	ON D.location = V.location AND
	D.date = V.date
	WHERE d.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVAc


-- Temp table (Actually stored in the database)

DROP TABLE IF EXISTS #PercentVaccinated

CREATE TABLE #PercentVaccinated 
(
Continent VARCHAR(255),
Location VARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentVaccinated 
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths AS d
	INNER JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location AND
	d.date = v.date	
	WHERE d.continent IS NOT NULL

SELECT *, (RollingPeopleVAccinated / Population) * 100
FROM #PercentVaccinated


-- Create a view

CREATE VIEW PercentPopulationVaccinated AS
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.date) AS RollingPeopleVaccinated	
	FROM PortfolioProject..CovidDeaths AS d
	INNER JOIN PortfolioProject..CovidVaccinations AS V
	ON d.location = v.location AND
	d.date = v.date
	WHERE d.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated



