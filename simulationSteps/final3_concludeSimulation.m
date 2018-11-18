%% final3_concludeSimulation.m description
% This file calculates the realized fuel savings (percentual and absolute),
% the extra flight time due to formation flying, and the extra distance
% flown due to formation flying. Some additional performance indicators are
% calculated in this file.

% It contains one function: calculateResults.m.

%% Concluding data.

% This function determines the realized fuel savings, the extra flight time
% due to formation flying, and the extra distance flown due to formation
% flying.
[fuelSavingsTotalPct,fuelSavingsAlliancePct,fuelSavingsNonAlliancePct, ...
    extraDistancePct,extraFlightTimePct] = ...
    calculateResults(nAircraft,flightsDataRecordings,Wfinal,Vmax, ...
    fuelSavingsTotal);

% Actual fuel savings, comparing the actual fuel use to the total fuel
% use if of only solo flights were flown.
fuelSavingsTotalPerRun(simrun) = fuelSavingsTotal; % [kg]

% Percentual fuel savings, comparing the actual fuel use to the total fuel
% use if of only solo flights were flown.
fuelSavingsTotalPctPerRun(simrun) = fuelSavingsTotalPct; % [%]

% Percentage of the total fuel savings that went to the alliance.
fuelSavingsAlliancePctPerRun(simrun) = fuelSavingsAlliancePct; % [%]

% Percentage of the total fuel savings that went to the non-alliance
% flights.
fuelSavingsNonAlliancePctPerRun(simrun) = fuelSavingsNonAlliancePct; % [%]

% Percentual change in total distance, comparing the actual total distance
% to the total distance if only solo flights were flown.
extraDistancePctPerRun(simrun) = extraDistancePct; % [%]

% Percentual change in total flight, comparing the actual flight time to
% the total flight time of only solo flights were flown.
extraFlightTimePctPerRun(simrun) = extraFlightTimePct; % [%]

% Total number of deals, percentage of deals with a distance more than ...
% 250,500 or 750km.
nDeals = length(dealLog(:,9));
pctDealsAbove250(simrun) = length(find(dealLog(:,9)>=250))/length(dealLog(:,9))*100;
pctDealsAbove500(simrun) = length(find(dealLog(:,9)>=500))/length(dealLog(:,9))*100;
pctDealsAbove750(simrun) = length(find(dealLog(:,9)>=750))/length(dealLog(:,9))*100;

% A log containing all deals that have been made.
dealLogRecordings = [dealLogRecordings; dealLog]; 


% Percentage of all and (non)alliance aircraft that have been in a
% formation at least once during the simulation.
flightsInFormation(simrun) = length(find(flightsData([1:nAircraft],27)>0))/nAircraft;

flightsInAlliance = find(flightsData([1:nAircraft],25)==2);
flightsNotInAlliance = find(flightsData([1:nAircraft],25)==1);
flightsInFormationAlliance(simrun) = length(find(flightsData(flightsInAlliance,27)>0))/length(flightsInAlliance);
flightsInFormationNonAlliance(simrun) = length(find(flightsData(flightsNotInAlliance,27)>0))/length(flightsNotInAlliance);

% For the CNP: Fuel saving per manager and contractor / auctioneer and
% bidder
totalFuelSavedManagers(simrun) = sum(dealLog(:,4));
totalFuelSaved(simrun) = sum(dealLog(:,5));
totalFuelSavedContractors(simrun) = totalFuelSaved(simrun) - totalFuelSavedManagers(simrun);


pctFuelSavedManagers(simrun) = totalFuelSavedManagers(simrun) / totalFuelSaved(simrun);
pctFuelSavedContractors(simrun) = totalFuelSavedContractors(simrun) / totalFuelSaved(simrun);
%end

% A CDF of all deals that were made in a specific simulation.    
TlastDeal = max(dealLog(:,6));
Ndeals = length(dealLog(:,6));
for i=1:TlastDeal
    pctDeals(simrun,i) = length(find(dealLog(:,6)<=i))/Ndeals;
end

% Log the average CDF of how many deals are made at every time-interval.
avgTimeToDeal = mean(pctDeals(:,[1:120]),1);




%% Clear some variables.

clearvars a acNr1 acNr2 c communicationCandidates divisionFutureSavings ...
    flightIDsFollowers flightsArrived flightsAtCurrentLocation ...
    flightsDeparted flightsNotMovedYet flightsOvershot followersOfFlightA ...
    fuelSavingsOffer i j m n nCandidates potentialFuelSavings s ...
    syncPossible timeAdded_acNr1 timeAdded_acNr2 timeWithinLimits ...
    travelledDistance travelledDistanceX travelledDistanceY ...
    uniqueFormationCurrentLocations VsegmentAJ_acNr1 VsegmentBJ_acNr2 ...
    wAC wBD wDuo Xjoining Xordes Xsplitting Yjoining Yordes Ysplitting ...
    extraDistancePct extraFlightTimePct fuelSavingsAlliancePct ...
    fuelSavingsNonAlliancePct fuelSavingsTotal fuelSavingsTotalPct 