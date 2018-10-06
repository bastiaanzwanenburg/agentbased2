%% step1b_routingSynchronizationFuelSavings.m description
% This file carries out the routing and synchronization of two flights, and
% determines the potential fuel savings.

% It contains four functions: determineRoutingAndSynchronization.m
% (determineGeometricRouting.m & synchronizeRouting.m),
% calculateFuelSavings.m.

%% Store current and destination coordinates and determine weight factors.

% Current and destination x- and y-coordinates are stored to be used to
% determine the optimal geometric routing.
Xordes = [flightsData(acNr1,14),flightsData(acNr2,14), ...
    flightsData(acNr1,5),flightsData(acNr2,5)]; 
Yordes = [flightsData(acNr1,15),flightsData(acNr2,15), ...
    flightsData(acNr1,6),flightsData(acNr2,6)]; 

% Weight factor of solo aircraft/formation of which the dummy flight is
% leader. Used for geometric routing. wAC is the weight factor for
% candidate flight 1, wBD for candidate flight 2. wDuo is the weight factor
% of the formation flight segment. For more information, see Ch.
% 6.1.1-6.1.3 of Verhagen's thesis.
wAC = flightsData(acNr1,19);
wBD = flightsData(acNr2,19);
wDuo = min(wAC+wBD-0.01,(wAC+wBD-1)*wTrail* ...
    (1+wMulti*(wAC+wBD-2))+1); 

%% Perform the routing and synchronization. 
% This determines the coordinates of the joining- and splitting point, and
% the speed profile for each flight.
[Xjoining,Yjoining,Xsplitting,Ysplitting,VsegmentAJ_acNr1, ...
    VsegmentBJ_acNr2,syncPossible,timeAdded_acNr1,timeAdded_acNr2] = ...
    determineRoutingAndSynchronization(wAC,wBD,wDuo,Xordes, ...
    Yordes,Vmin,Vmax);   

% Determine if the added time due to this formation is within the max.
% delay limits of acNr1 and acNr2.
timeWithinLimits = 1;
if (flightsData(acNr1,26) - timeAdded_acNr1 < 0) || ...
        (flightsData(acNr2,26) - timeAdded_acNr2 < 0)
    timeWithinLimits = 0;
end
%% Determine the potential fuel savings.
% Predefine the potential fuel savings to ensure code continuation if
% syncPossible or timeWithinLimits is 0 (false).
potentialFuelSavings = 0; 

% Only if synchronization is possible, and the added time is within the
% allowed limits, it makes sense to determine the potential fuel savings.
if syncPossible == 1 && timeWithinLimits == 1  
    % Calculate the cumulative fuel savings of this formation.
    [potentialFuelSavings] = calculateFuelSavings( ...
        fuelPenalty,t,flightsDataRecordings,nAircraft,acNr1,...
        acNr2,flightsData,Xordes,Yordes,Xjoining,Yjoining, ...
        Xsplitting,Ysplitting,Vmin,Vmax,VsegmentAJ_acNr1, ...
        VsegmentBJ_acNr2,MFuelSolo,MFuelTrail);
end