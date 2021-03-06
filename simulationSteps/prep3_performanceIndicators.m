%% prep3_performanceIndicators.m description
% This file predefines the variables that will be used to track performance
% indicators over the simulation runs.

% Add the code for your own performance indicators to this file. 

%% Performance indicators.

% Actual fuel savings, comparing the actual fuel use to the total fuel use
% if of only solo flights were flown.
fuelSavingsTotalPerRun = zeros(nSimulations,1); % [kg]

% Percentual fuel savings, comparing the actual fuel use to the total fuel
% use if of only solo flights were flown.
fuelSavingsTotalPctPerRun = zeros(nSimulations,1); % [%]

% Percentage of the total fuel savings that went to the alliance.
fuelSavingsAlliancePctPerRun = zeros(nSimulations,1); % [%] 
fuelSavingsPerDeal = zeros(nAircraft,1);

% Percentage of the total fuel savings that went to the non-alliance
% flights.
fuelSavingsNonAlliancePctPerRun = zeros(nSimulations,1); % [%] 

% Percentual change in total distance, comparing the actual total distance
% to the total distance if only solo flights were flown.
extraDistancePctPerRun = zeros(nSimulations,1); % [%]

% Percentual change in total flight, comparing the actual flight time to
% the total flight time of only solo flights were flown.
extraFlightTimePctPerRun = zeros(nSimulations,1); % [%] 

% Number of aircraft that have been in a formation at all
flightsInFormation = zeros(nSimulations,1);
flightsInFormationAlliance = zeros(nSimulations,1);
flightsInFormationNonAlliance = zeros(nSimulations,1);

totalFuelSavedManagers = zeros(nSimulations,1);

totalFuelSaved = zeros(nSimulations,1);

totalFuelSavedContractors = zeros(nSimulations,1);

distanceBetweenDeal = [];

pctDealsAbove250 = zeros(nSimulations,1);
pctDealsAbove500 = zeros(nSimulations,1);
pctDealsAbove750 = zeros(nSimulations,1);


pctDeals = zeros(nSimulations,200); %so we can have max t=2
pctDeals(find(pctDeals==0)) = 1;

heatMapLocations = [];

