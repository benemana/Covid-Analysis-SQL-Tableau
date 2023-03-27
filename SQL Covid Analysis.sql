-- Select data

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProjectCovid.dbo.CovidDeaths

-- Total Deaths vs Total Cases
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProjectCovid.dbo.CovidDeaths
order by 1,2

-- Total Cases vs Population
select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from PortfolioProjectCovid.dbo.CovidDeaths
order by 1,2

-- Countries with highest infection rates compared to Population
select location, population, max(total_cases) as HighestInfectionCount, 100*max(total_cases)/population as InfectionPercentage
from PortfolioProjectCovid.dbo.CovidDeaths
group by location, population
order by 4 desc

-- Countries with highest Death Count
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProjectCovid.dbo.CovidDeaths
where continent is not null
group by location
order by 2 desc

-- Continents with highest Death Count
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProjectCovid.dbo.CovidDeaths
where continent is not null
group by continent
order by 2 desc

-- Total cases, total deaths and death rate in the world, per date
select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeathCount, round(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) as DeathRate
from PortfolioProjectCovid.dbo.CovidDeaths
where continent is not null
group by date
order by 1

-- Total cases, total deaths and death rate in the world, cumulatively
select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeathCount, round(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) as DeathRate
from PortfolioProjectCovid.dbo.CovidDeaths
where continent is not null
order by 1

-- Daily vaccinations and cumulative vaccinations
with PopVsVac (Continent, Location, Date, Population, NewVaccinations, CumulativeVaccinations) as
(	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as cumulative_vaccinations
	from PortfolioProjectCovid.dbo.CovidDeaths dea join PortfolioProjectCovid.dbo.CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null
)

-- Vaccinations rate among population
select *, round((CumulativeVaccinations/Population)*100,4) as VaccinationsRate
from PopVsVac


-- Alternative solution with temp table
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric
)

insert into #PercentPopulationVaccinated
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as cumulative_vaccinations
	from PortfolioProjectCovid.dbo.CovidDeaths dea join PortfolioProjectCovid.dbo.CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null
	

select *, round((CumulativeVaccinations/Population)*100,4) as VaccinationsRate
from #PercentPopulationVaccinated
order by location, date

-- Vaccinations rate per location
select location, population, round(cast(max(CumulativeVaccinations/Population)*100 as float),4) as MaxVaccinationsRate
from #PercentPopulationVaccinated
group by location, population
order by location

-- Creating view to store data for later visualization
go
create view PercentPopulationVaccinated as
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as cumulative_vaccinations
	from PortfolioProjectCovid.dbo.CovidDeaths dea join PortfolioProjectCovid.dbo.CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null
go

-- check view
select * 
from PercentPopulationVaccinated

