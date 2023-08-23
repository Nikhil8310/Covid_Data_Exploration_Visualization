-- Creating tables for impoting data from CSV files

CREATE table coviddeaths ( iso_code Varchar(2500),
continent VARCHAR(2500),location VARCHAR(2000),date VARCHAR(2500),total_cases BIGINT,population BIGINT,	
new_cases BIGINT,new_cases_smoothed	DOUBLE,total_deaths DOUBLE,	
new_deaths DOUBLE,new_deaths_smoothed DOUBLE,	
total_cases_per_million DOUBLE,new_cases_per_million DOUBLE,new_cases_smoothed_per_million DOUBLE,	
total_deaths_per_million DOUBLE,new_deaths_per_million DOUBLE,new_deaths_smoothed_per_million DOUBLE ,reproduction_rate DOUBLE,	
icu_patients DOUBLE,icu_patients_per_million DOUBLE,hosp_patients DOUBLE,hosp_patients_per_million DOUBLE,weekly_icu_admissions DOUBLE,	
weekly_icu_admissions_per_million DOUBLE,weekly_hosp_admissions DOUBLE,weekly_hosp_admissions_per_million DOUBLE);

CREATE table covidvaccinations (iso_code VARCHAR(2500),continent VARCHAR(2500),location	VARCHAR(2500),date VARCHAR(2500),new_tests BIGINT,
total_tests BIGINT,total_tests_per_thousand	Double,new_tests_per_thousand Double,	
new_tests_smoothed Double, new_tests_smoothed_per_thousand	Double,positive_rate Double,tests_per_case	Double,tests_units VARCHAR(2500),
total_vaccinations Double,	
people_vaccinated Double,people_fully_vaccinated Double,new_vaccinations Double,new_vaccinations_smoothed Double,	
total_vaccinations_per_hundred Double,people_vaccinated_per_hundred Double,	
people_fully_vaccinated_per_hundred Double,new_vaccinations_smoothed_per_million Double,stringency_index Double,	
population_density Double,median_age Double,aged_65_older Double,aged_70_older Double,gdp_per_capita Double,	
extreme_poverty Double,cardiovasc_death_rate Double,diabetes_prevalence Double,female_smokers Double,
male_smokers Double,handwashing_facilities Double,hospital_beds_per_thousand Double,	
life_expectancy	Double,human_development_index Double
);

-- Inserting values in tables from CSV files
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Coviddeaths.csv'
INTO TABLE coviddeaths
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Covidvaccinations.csv'
INTO TABLE covidvaccinations
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Selecting both tables and exploring data

SELECT * FROM coviddeaths;

SELECT * FROM covidvaccinations;

-- Total Cases vs Total Deaths

Select Location, date, total_cases,total_deaths, round((total_deaths/total_cases)*100,2) as DeathPercentage
From CovidDeaths
Where continent is not null;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths;

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc;


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(
Continent varchar(2500),
Location varchar(2500),
Date text,
Population BIGINT,
New_vaccinations BIGINT,
RollingPeopleVaccinated BIGINT
);

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--  where dea.continent is not null 
-- order by 2,3
;

Select *, (RollingPeopleVaccinated/Population)*100
From  PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinate as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;
