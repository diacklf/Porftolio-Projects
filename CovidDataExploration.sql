-- High level overview of dataset 

SELECT *
FROM CovidFatal
ORDER BY location,date



-- Total cases by country

SELECT DISTINCT(location),MAX(total_cases) as total_cases
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_cases DESC



-- Survival and Fatality Rate By Country as Percentage Values
-- Shows likelihood of death by country, if covid contracted

SELECT DISTINCT(location),MAX(total_cases) as total_cases,MAX(total_deaths) as total_deaths, 
				CAST((MAX(total_deaths)/MAX(total_cases)*100)AS decimal(10,2)) AS pct_infected_dead,
				CAST(100-(MAX(total_deaths)/MAX(total_cases)*100)AS DECIMAL(10,2)) as pct_infected_survive
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY pct_infected_dead DESC



-- Total Cases by Country
-- Shows percentage of population infected

SELECT DISTINCT(location),MAX(total_cases) as total_cases,population,
			CAST((MAX(total_cases)/population)*100 AS decimal(10,2)) AS pct_pop_infected
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY pct_pop_infected DESC



-- Total Deaths by Country
-- Shows total sum of deaths per country, and percentage of population deceased

SELECT location,population, MAX(CAST(total_deaths AS INT)) AS total_fatalities,
				CAST((MAX(CAST(total_deaths AS INT))/population)*100 AS DECIMAL(10,2)) as pct_fatality
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY pct_fatality DESC



-- GLOBAL FIGURES
-- Death Count by Continent

SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_deaths
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths DESC



-- Shows total cases, total deaths and percentage of cases resulting in death

Select date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
			CAST(SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DECIMAL(10,2)) AS death_pct
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



-- Shows total global population, cases and deaths

SELECT MAX(population) AS Population, MAX(total_cases) AS total_cases, MAX(CAST(total_deaths AS INT)) AS total_deaths, 
		MAX(CAST(total_deaths AS INT))/MAX(total_cases)*100 AS pct_cases_deceased, 
		CAST(MAX(CAST(total_deaths AS INT))/MAX(population)*100 AS DECIMAL(10,2)) AS pct_total_pop_deceased
FROM CovidFatal
WHERE location = 'World'



-- Shows herd immunity levels by date, per country

WITH PopVax (continent,location,date,population,new_vaccinations,total_vaccines_administered)
AS
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
			SUM(CAST(vax.new_vaccinations AS INT)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS total_vaccines_administered
	FROM CovidFatal deaths
	JOIN Vax vax
		on deaths.location = vax.location
		and deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
)
SELECT  *,CAST((total_vaccines_administered/population)*50 AS DECIMAL(10,2)) AS herd_immunity_pct
FROM PopVax



-- Current Percentage of Herd Immunity Reached by Each Country

WITH PopVax (continent,location,date,population,new_vaccinations,FullVax)

AS
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
			vax.new_vaccinations, vax.people_fully_vaccinated AS FullVax
	FROM CovidFatal deaths
	JOIN Vax vax
		on deaths.location = vax.location
		and deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
)

SELECT DISTINCT(location), CAST(MAX((FullVax/population)*100) AS DECIMAL(10,2)) AS pct_herd_immunity
FROM PopVax
GROUP BY location
ORDER BY 2 DESC

-- Notably, we see here that Gibraltars' herd immunity is described as being over 100%.
-- This is simply due to many cross-boarder Spanish workers living in the country.



-- Number of Countries in dataset

SELECT COUNT(DISTINCT(location))
FROM CovidFatal



-- Number of Countries That Have Reached Herd Immunity
-- Shows number and proportion of countries whose herd immunity is at or above 60%. The point at which, it is believed, effective herd immunity will be achieved

WITH PopVax (continent,location,date,population,new_vaccinations,FullVax,pct_herd_immunity)

AS
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
			vax.new_vaccinations, vax.people_fully_vaccinated AS FullVax, 
			CAST((vax.people_fully_vaccinated/deaths.population)*100 AS DECIMAL(10,2)) AS pct_herd_immunity
	FROM CovidFatal deaths
	JOIN Vax vax
		on deaths.location = vax.location
		and deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
)

SELECT COUNT(DISTINCT(location)) AS num_countries_herd_immunity, CAST((CAST(COUNT(DISTINCT(location)) as FLOAT)/233)*100 AS DECIMAL(10,2)) AS pct_countries_herd_immunity
FROM PopVax
WHERE pct_herd_immunity >= 60



-- TEMP TABLE

DROP TABLE IF EXISTS #PctPopVax
CREATE TABLE #PctPopVax
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
people_fully_vaccinated numeric,
pct_herd_immunity numeric
)

Insert into #PctPopVax

SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
		vax.people_fully_vaccinated, --AS FullVax,
		CAST((vax.people_fully_vaccinated/deaths.population)*100 AS DECIMAL(10,2)) AS pct_herd_immunity
	FROM CovidFatal deaths
	JOIN Vax vax
		on deaths.location = vax.location
		and deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL

SELECT AVG(pct_herd_immunity) AS mean_herd_immunity
FROM #PctPopVax


-- Creating Views to Use For Visualization

CREATE VIEW HerdImmunity AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
vax.new_vaccinations, vax.people_fully_vaccinated AS FullVax, 
CAST((vax.people_fully_vaccinated/deaths.population)*100 AS DECIMAL(10,2)) AS pct_heard_immunity
FROM CovidFatal deaths
JOIN Vax vax
on deaths.location = vax.location
and deaths.date = vax.date
WHERE deaths.continent IS NOT NULL



CREATE VIEW RollingVaccineCount AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS INT)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS rolling_vaccine_count		
FROM CovidFatal deaths
JOIN Vax vax
on deaths.location = vax.location
and deaths.date = vax.date
WHERE deaths.continent IS NOT NULL



CREATE VIEW TotalCaseByCountry AS
SELECT DISTINCT(location),MAX(total_cases) as total_cases
FROM CovidFatal
WHERE continent IS NOT NULL
GROUP BY location


