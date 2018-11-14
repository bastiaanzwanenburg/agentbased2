%% final3_concludeSimulation.m description
% This file calculates the realized fuel savings (percentual and absolute),
% the extra flight time due to formation flying, and the extra distance
% flown due to formation flying. Some additional performance indicators are
% calculated in this file.

% It contains one function: calculateResults.m.

%% Concluding data.

hold on
scatter(dealLog(:,7), dealLog(:,8));
hold off

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

nDeals = length(dealLog(:,9));
pctDealsAbove250(simrun) = length(find(dealLog(:,9)>=250*2))/nDeals*100;
pctDealsAbove500(simrun) = length(find(dealLog(:,9)>=500*2))/nDeals*100;
pctDealsAbove750(simrun) = length(find(dealLog(:,9)>=750*2))/nDeals*100;



% Percentage of normal aircraft that have been in a 
flightsInFormation(simrun) = length(find(flightsData([1:nAircraft],27)>0))/nAircraft;

% For the CNP: Fuel saving per manager and contractor
%if negotiationTechnique == 2
    totalFuelSavedManagers(simrun) = sum(dealLog(:,4));
    totalFuelSaved(simrun) = sum(dealLog(:,5));
    totalFuelSavedContractors(simrun) = totalFuelSaved(simrun) - totalFuelSavedManagers(simrun);


    pctFuelSavedManagers(simrun) = totalFuelSavedManagers(simrun) / totalFuelSaved(simrun);
    pctFuelSavedContractors(simrun) = totalFuelSavedContractors(simrun) / totalFuelSaved(simrun);
%end

    
TlastDeal = max(dealLog(:,6));
Ndeals = length(dealLog(:,6));
for i=1:TlastDeal
    pctDeals(simrun,i) = length(find(dealLog(:,6)<=i))/Ndeals;
end




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