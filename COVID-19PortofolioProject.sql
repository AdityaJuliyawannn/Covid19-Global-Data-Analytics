USE PortofolioProject;

SELECT * FROM dbo.CovidDeaths$
ORDER BY 3,4

SELECT * FROM dbo.CovidVaccinations$
ORDER BY 3,4

EXEC sp_help 'dbo.CovidDeaths$';

ALTER TABLE dbo.CovidDeaths$
ALTER COLUMN total_deaths INT;
ALTER TABLE dbo.CovidDeaths$
ALTER COLUMN new_deaths INT;

--Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths$
ORDER BY 1,2

--Hapus Duplikasi Data
WITH CTE_HapusDuplikat AS (
	SELECT *, 
		ROW_NUMBER () OVER (
		PARTITION BY location, date, total_cases, new_cases, total_deaths, population
		ORDER BY (SELECT NULL)
		) AS NoUrut
	FROM dbo.CovidDeaths$
)
DELETE FROM CTE_HapusDuplikat
WHERE NoUrut > 1;

-- Loking at Total Cases vs Total Deaths & Population

-- Kemungkinan meninggal jika tertular di Indonesia
SELECT * FROM dbo.CovidDeaths$
WHERE location = 'Indonesia';

SELECT location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases) * 100 AS DeathPrecentage
FROM dbo.CovidDeaths$
WHERE location = 'Indonesia'
ORDER BY 1,2;

-- Kemungkinan tertular covid di Indonesia
SELECT location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases) * 100 AS DeathPrecentage, (total_cases/population) * 100 AS casesPrecentage
FROM dbo.CovidDeaths$
WHERE location = 'Indonesia'
ORDER BY 1,2;

-- Mencari negara dengan kemungkinan tertular covid tertinggi dikompare dengan Populasi
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_deaths/total_cases) * 100) AS DeathPrecentage, MAX((total_cases/population) * 100) AS CasesPrecentage
FROM dbo.CovidDeaths$
GROUP BY location, population
ORDER BY CasesPrecentage DESC;

-- Mencari negara dengan Kematian Tertinggi per Populasi
SELECT location, population, MAX(total_deaths) as TotalDeathCount, MAX((total_cases/population) * 100) AS CasesPrecentage
FROM dbo.CovidDeaths$
GROUP BY location, population
ORDER BY TotalDeathCount DESC;


-- Benua dengan kematian tertinggi per populasi
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT * FROM dbo.CovidDeaths$
WHERE location like '%states%';


-- Angka Global
SELECT  date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,SUM(new_cases)/SUM(new_deaths) * 100 as DeathPercentage--, total_deaths, (total_deaths/total_cases) * 100 AS DeathPrecentage
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT location, continent, new_cases, total_cases 
FROM dbo.CovidDeaths$ 
WHERE date = '2020-01-22 00:00:00.000';


-- USE CTE

WITH CTE_PopvsVac
As (
-- Menggabungkan Tabel Death dan Vaksinasi
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/Population) * 100 as VaccinationPercentage
FROM dbo.CovidDeaths$ AS Dea
JOIN dbo.CovidVaccinations$ AS Vac
ON Dea.location = Vac.location
AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 as VaccinationPercentage
FROM CTE_PopvsVac 


-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations INT,
RollingPeopleVaccinated INT
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/Population) * 100 as VaccinationPercentage
FROM dbo.CovidDeaths$ AS Dea
JOIN dbo.CovidVaccinations$ AS Vac
ON Dea.location = Vac.location
AND Dea.date = Vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population) * 100 FROM #PercentPopulationVaccinated



-- Membuat view untuk visualisasi


CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/Population) * 100 as VaccinationPercentage
FROM dbo.CovidDeaths$ AS Dea
JOIN dbo.CovidVaccinations$ AS Vac
ON Dea.location = Vac.location
AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * FROM PercentagePopulationVaccinated