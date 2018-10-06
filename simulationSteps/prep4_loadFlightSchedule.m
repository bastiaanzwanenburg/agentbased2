%% prep4_loadFlightSchedule.m description
% This function generates the initial properties for each real flight and
% creates the random flight schedule.

% It contains one function: generateFlights.m.

%% Generate initial properties, create random flight schedule.

% This function generates the initial properties for each real flight. This
% function also creates the random flight schedules.
[flightsInitialData] = generateFlights(nAircraft,Vmax,MFuelSolo, ...
    Wfinal,muOriginX,stddevOriginX,muOriginY,stddevOriginY,muDestX, ...
    stddevDestX,muDestY,stddevDestY,flightsPerAirportAmericas, ...
    flightsPerAirportEuro,percentageAlliance,minInitialDelay, ...
    maxInitialDelay);