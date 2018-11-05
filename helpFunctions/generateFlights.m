function flightsInitialData = generateFlights(nAircraft,Vmax,MFuelSolo, ...
    Wfinal,muOriginX,stddevOriginX,muOriginY,stddevOriginY,muDestX, ...
    stddevDestX,muDestY,stddevDestY,flightsPerAirportAmericas, ...
    flightsPerAirportEuro,percentageAlliance,minInitialDelay, ...
    maxInitialDelay)
%% generateFlights.m description
% This function generates the initial properties for each real flight. You
% are free to add additional properties and can predefine them in this
% function. This function also creates the random flight schedules. In
% addition, this function generates the dummy flights that will represent
% two flights in formation and act as their formation leader.

% inputs: 
% nAircraft (number of real aircraft),
% Vmax (Vmax [m/s]),
% MFuelSolo (M-value solo/leader aircraft at Vmax),
% Wfinal (Zero Fuel Weight (ZFW) + Maximum Payload Weight of every aircraft
% after a complete solo flight [kg]),
% muOriginX (means and standard deviations of x- and y-coordinates for the
% creation of normally distributed random origin and destination airports),
% stddevOriginX,
% muOriginY,
% stddevOriginY,
% muDestX,
% stddevDestX,
% muDestY,
% stddevDestY,
% flightsPerAirportAmericas (average flights per airport, used to determine
% the number of airports in the random flight schedule),
% flightsPerAirportEuro,
% percentageAlliance (percentage of flights that are part of the alliance),
% minInitialDelay (minimum initial delay [min.]),
% maxInitialDelay (maximum initial delay [min.]).

% outputs: 
% flightsInitialData (contains the initial data of each real flight and
% 2*nAircraft predefined dummy flights)

% When two engaged flights reach their joining point, a dummy flight is
% generated that represents the two flights in the simulation, and leads
% them. The dummy flight will handle the communication with other flights
% to commit to a new formation. Note that dummy flights can become
% followers of yet another dummy flight. Through this process, formations
% can grow to essentially any size. For more information on dummy flights,
% see Ch. 6.4 of Verhagen's thesis.

% flightsInitialData rows have 28 columns. Each row indicates the following
% properties for a (dummy) flight:
% 1: Flight ID (starting from 1 to nAircraft for real flights, then from
% nAircraft+1 for dummy flights)
% 2: Communication status (0: engaged and not available for comm., 1:
% available for comm.)
% 3: X-coordinate of origin
% 4: Y-coordinate of origin
% 5: X-coordinate of destination
% 6: Y-coordinate of destination
% 7: Current speed [m/s]
% 8: Current heading [dy/dx]
% 9: X-coordinate of joining point of formation
% 10: Y-coordinate of joining point of formation
% 11: X-coordinate of splitting point of formation
% 12: Y-coordinate of splitting point of formation
% 13: Current M-value. During flight, the fuel consumption of an aircraft
% is governed by this M-value.
% 14: X-coordinate of current location
% 15: Y-coordinate of current location
% 16: Flight status (0: not flying, 1: is flying)
% 17: Formation status (0: not in formation, 1: in formation)
% 18: Arrival status (0: not arrived, 1: has arrived)
% 19: Formation size/weight factor of solo aircraft, or the formation which
% a dummy flight represents. Used for geometric routing.
% 20: Flight ID of the flight to which it is engaged. Engaged refers to
% two flights having committed to a formation flight strategy, that have
% not reached each other yet (0: if not engaged to any flight).
% 21: In-formation status (0: follower, 1: solo, 2: formation leader
% (always a dummy flight)). 
% 22: Flight ID of the flight that this flight is following. (0: if not
% following any flight).
% 23: Starting weight of the flight [kg].
% 24: Departure time of the flight [min. after 17:00].
% 25: Alliance member (0: dummy flight, 1: non-alliance, 2: alliance).
% 26: Max. delay that can be accepted for future formations [min.]. This
% property is updated after a formation partner is found. For dummy flights
% it is equal to the minimum max. delay of the two flights the dummy flight
% represents.
% 27: This holds how much fuel savings the flight received from its latest
% formation [kg]. The default code distributes the fuel savings between the
% flights of the formation based on property 19 (weight factor).
% 28: Division of future fuel savings [%]. Indicates how fuel savings from
% future formations will be distributed between the two flights of the
% current formation. The default code distributes the future fuel savings
% between the flights of the formation based on property 19 (weight
% factor).
% 29: Column that indicates if this flight (agent) is a Manager or
% Auctioneer, if 1 = manager / auctioneer if 0 = contractor (so agents are
% contractors by default)
% 31: Has the agent been in a formation at all?


% special cases: 
% * More dummy flights may be required to cover aircraft that switch
% formation when one breaks up and a new one forms.
% * flightsInitialData may not change size during the simulation.
% * Dummy flight rows may not be moved/used until they are needed.

%% Generate random airports if a random flight schedule is used.

% Determine the number of airports for the simulation, based on the number
% of flights in the simulation.
nOriginAirports = ceil(nAircraft/flightsPerAirportAmericas);
nDestAirports = ceil(nAircraft/flightsPerAirportEuro);

% Generate locations of origin airports.
originAirportsX = normrnd(muOriginX,stddevOriginX, ...
    [nOriginAirports,1]);
originAirportsY = normrnd(muOriginY,stddevOriginY, ...
    [nOriginAirports,1]);
originAirports = [originAirportsX originAirportsY];
% Generate locations of destination airports.
destinationAirportsX = normrnd(muDestX,stddevDestX,[nDestAirports,1]);
destinationAirportsY = normrnd(muDestY,stddevDestY,[nDestAirports,1]);
destinationAirports = [destinationAirportsX destinationAirportsY];

% Predefine for performance. 2*nAircraft additional rows are created as
% dummy flights. These dummy flights act as formation navigators.
flightsInitialData = zeros(3*nAircraft,31); 
bids = zeros(1,7);
bidbook = zeros(nAircraft, 12);

%% Generate the initial properties for all flights. 
% Each row indicates the properties for one flight.
for i = 1:nAircraft  
    flightsInitialData(i,1) = i;
    flightsInitialData(i,2) = 0;

    % Randomly assign an origin and departure airport to each flight.
    flightsInitialData(i,3:6) = [originAirports(randi([1, ...
        nOriginAirports]),:) destinationAirports(randi([1, ...
        nDestAirports]),:)];     
    % Create uniformly distributed pseudorandom integers between 0 and
    % nAircraft that indicate the departure time of a flight in number of
    % minutes after the start of the simulation. [0,nAircraft] since
    % approximately every 60 seconds one aircraft departs.
    flightsInitialData(i,24) = randi([1,nAircraft]);
    
    flightsInitialData(i,7) = Vmax;
    flightsInitialData(i,8) =  (flightsInitialData(i,6)- ...
        flightsInitialData(i,4))/(flightsInitialData(i,5)- ...
        flightsInitialData(i,3));
    % Joining and splitting point coordinates are predefined out of range
    % such that they will not be used before they are set to a new value.
    flightsInitialData(i,9:12) = [-99999,-99999,-99999,-99999]; 
    flightsInitialData(i,13) = MFuelSolo;
    % Initially the current location equals the origin location.
    flightsInitialData(i,14:15) = flightsInitialData(i,3:4); 
    flightsInitialData(i,16) = 0; 
    flightsInitialData(i,17) = 0; 
    flightsInitialData(i,18) = 0;
    flightsInitialData(i,19) = 1;
    flightsInitialData(i,20) = 0;
    flightsInitialData(i,21) = 1; 
    flightsInitialData(i,22) = 0;
end

%% Determine the starting weight of all real flights. 
% For more information, see Ch. 4.3 of Verhagen's thesis.
soloRouteDistances = sqrt((flightsInitialData(1:nAircraft,5)- ... 
    flightsInitialData(1:nAircraft,3)).^2 + ... 
    (flightsInitialData(1:nAircraft,6)- ...
    flightsInitialData(1:nAircraft,4)).^2);
startingWeights = (sqrt(Wfinal) + soloRouteDistances/MFuelSolo).^2;
% Fill in the starting weight for each flight. 
flightsInitialData(1:nAircraft,23) = startingWeights;                                                                     

%% Determine which flights are members of the alliance. 
% Generate a column vector containing a random permutation of integers from
% 1 to nAircraft inclusive. Concatenate a column vector of ones.
allianceFlights = [ones(nAircraft,1) randperm(nAircraft)'];
% Determine which rows have an integer equal to or smaller than
% percentageAlliance/100*nAircraft. Set the value of the first column for
% these rows to 2. 
allianceFlights(allianceFlights(:,2)<=percentageAlliance/100*nAircraft) = 2;
% Copy the first column, alliance members are the rows with value 2. 
flightsInitialData(1:nAircraft,25) = allianceFlights(:,1);

%% Generate the maximum delay every flight can accept.
% Uniformly distributed pseudorandom integers between 'minInitialDelay'
% minutes and 'maxInitialDelay' minutes are used.
flightsInitialData(1:nAircraft,26) = ...
    randi([minInitialDelay,maxInitialDelay],nAircraft,1);

%% Generate the dummy flights that will act as formation navigators.
% Initially set a dummy's flight ID to -1. When a dummy flight becomes
% active a unique flight ID will be given in step2_moveAircraft.m.
flightsInitialData(nAircraft+1:end,1) = -1; 
% When dummy flights become active they are available for communication.
flightsInitialData(nAircraft+1:end,2) = 1; 
end