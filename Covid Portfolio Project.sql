SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam'
ORDER BY 1,2;


--Chance of death after contracting covid
SELECT location, date, total_cases, total_deaths, total_deaths/total_cases*100
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam'
ORDER BY 1,2;



--Show chance of catching covid
SELECT location, DATEADD("m", DATEDIFF("m", 0, date),0),  SUM(new_cases), population, SUM(new_cases)/population*100
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam'
GROUP BY DATEADD("m", DATEDIFF("m", 0, date),0), location, population
ORDER BY 1,2;


--Temp Table for sum of new cases and deaths in Vietnam by month
DROP table if exists VietnamCase
CREATE TABLE VietnamCase (Month datetime, Vietnam_New_Cases float, Vietnam_New_Deaths float);
INSERT INTO VietnamCase
SELECT DATEADD("m", DATEDIFF("m", 0, date),0),  SUM(new_cases), SUM(CAST(new_deaths AS INT))
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam'
GROUP BY DATEADD("m", DATEDIFF("m", 0, date),0);

--Same for Asia
DROP table if exists AsiaCases
CREATE TABLE AsiaCases (Month datetime, AAVG float, AAVGD float);
INSERT INTO AsiaCases
SELECT Month, AVG(AsiaNewCases) AS AAVG, AVG(AsiaNewDeaths) AS AAVGD
FROM 
(SELECT location, DATEADD("m", DATEDIFF("m", 0, date),0) as Month, SUM(new_cases) as AsiaNewCases, SUM(CAST(new_deaths AS int)) AS AsiaNewDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent = 'Asia'
GROUP BY location, DATEADD("m", DATEDIFF("m", 0, date),0)) AS AC
GROUP BY Month;

--And Global
DROP table if exists WorldCases
CREATE TABLE WorldCases (Month datetime, WAVG float, WAVGD float);
INSERT INTO WorldCases
SELECT Month, AVG(WorldNewCases) AS WAVG, AVG(WorldNewDeaths) AS WAVGD
FROM
(SELECT location, DATEADD("m", DATEDIFF("m", 0, date),0) as Month, SUM(new_cases) as WorldNewCases, SUM(CAST(new_deaths AS int)) AS WorldNewDeaths
FROM PortfolioProject..CovidDeaths
GROUP BY location, DATEADD("m", DATEDIFF("m", 0, date),0)) AS WC
GROUP BY Month;

--Now we will compare Covid Deaths in Vietnam with Asia and the World
SELECT VietnamCase.Month, Vietnam_New_Deaths, ROUND(AAVGD,0) AS Asian_Average_New_Deaths, ROUND(WAVGD,0) AS World_Average_New_Deaths
FROM VietnamCase
INNER JOIN AsiaCases
ON VietnamCase.Month = AsiaCases.Month
INNER JOIN WorldCases
ON VietnamCase.Month = WorldCases.Month
ORDER BY VietnamCase.Month;


--Comparing Covid Cases in Vietnam with Asia and the World
SELECT VietnamCase.Month, Vietnam_New_Cases, ROUND(AAVG,0) AS Asian_Average_New_Case, ROUND(WAVG,0) AS World_Average_New_Case
FROM VietnamCase
INNER JOIN AsiaCases
ON VietnamCase.Month = AsiaCases.Month
INNER JOIN WorldCases
ON VietnamCase.Month = WorldCases.Month
ORDER BY VietnamCase.Month;

--Now we will get vaccination numbers in Vietnam
DROP table if exists vac_sum
CREATE TABLE vac_sum (continent nvarchar(255), location nvarchar(255), date datetime, population float, new_vaccinations float, RollingVaccinations float)
INSERT INTO vac_sum
SELECT vac.continent, vac.location, vac.date, population, new_vaccinations, SUM(CAST(new_vaccinations AS float)) OVER(PARTITION BY vac.location ORDER BY vac.date) AS RollingVaccinations
FROM PortfolioProject..CovidVaccination AS vac
INNER JOIN PortfolioProject..CovidDeaths AS dea
ON vac.location = dea.location AND vac.date = dea.date;

--vaccination numbers in Vietnam
SELECT date, population, new_vaccinations, RollingVaccinations, COALESCE((RollingVaccinations/population)*100,0) AS percentage_people_vaccinated
FROM vac_sum
WHERE location = 'Vietnam';





