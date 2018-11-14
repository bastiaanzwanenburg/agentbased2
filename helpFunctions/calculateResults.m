function [fuelSavingsTotalPct,fuelSavingsAlliancePct, ...
    fuelSavingsNonAlliancePct,extraDistancePct,extraFlightTimePct] = ...
    calculateResults(nAircraft,flightsDataRecordings,Wfinal,Vmax, ...
    fuelSavingsTotal)
%% calculateResults.m description
% NEW this function determines the realized fuel savings, the extra flight time
% due to formation flying, and the extra distance flown due to formation
% flying. It does this by first calculating the fuel consumption, flight
% distance, and flight time, if only solo flights were flown. Next, it
% calculates the actual fuel consumption, flight distance, and flight time,
% and compares the two.

% inputs: 
% nAircraft (number of real aircraft),
% flightsDataRecordings (flight data recorder that contains the flightsData
% at every time t),
% Wfinal (Zero Fuel Weight (ZFW) + Maximum Payload Weight of every aircraft
% after a complete solo flight [kg]),
% Vmax (Vmax [m/s]),
% fuelSavingsTotal (total fuel savings [kg]).

% outputs: 
% fuelSavingsTotalPct (percentual fuel savings, comparing the actual fuel
% use to the total fuel use if of only solo flights were flown),
% fuelSavingsAlliancePct (percentage of the total fuel savings that went to
% the alliance),
% fuelSavingsNonAlliancePct (percentage of the total fuel savings that went
% to the non-alliance flights),
% extraDistancePct (percentual change in total distance, comparing the
% actual total distance to the total distance if only solo flights were
% flown),
% extraFlightTimePct (percentual change in total flight, comparing the
% actual flight time to the total flight time of only solo flights were
% flown).

% special cases: 
% -

%% Calculate fuel consumption if all flights would have flown solo.

% Abbreviate flightsDataRecordings for shorter code.
FDR = flightsDataRecordings;

% Determine the solo route distances.
soloRouteDistances = [1:nAircraft ; sqrt((FDR(1,1:nAircraft,5)- ...
    FDR(1,1:nAircraft,3)).^2 + (FDR(1,1:nAircraft,6)- ...
    FDR(1,1:nAircraft,4)).^2)]';    
% Determine the fuel required for solo routes. Slot 23 (starting weight)
% has already been calculated in generateFlights.m. Wfinal is the ZFW +
% maximum payload weight.
soloFuelRequired = FDR(1,1:nAircraft,23) - Wfinal;                                                                % The solo fuel of each flight was already determined at the moment of generation
% Determine the flight time for solo routes.
soloFlightTimeSeconds = 1000.*soloRouteDistances(:,2)./Vmax;

%% Calculate extra distance and extra flight time for every flights.

% Predefine to later store actual mission length, and flight time for every
% flight.
missionLength = zeros(nAircraft,1);
formationFlightTimeSeconds = zeros(nAircraft,1);

% Calculate the extra distance and flight time for each flight separately.
for i = 1:nAircraft 
    % This clearing of variables ensures that the correct data is used for
    % every iteration.
    clearvars segment_lengths segmentendX segmentendY ...
        segments_node_coordinates_X segments_node_coordinates_Y
    
    % Determine the time steps t at which the heading or the M-value
    % changes.
    M_changes_at_t = find(abs(diff(FDR(:,i,8)))~=0 | ...
        abs(diff(FDR(:,i,13)))~=0)+1;  
    % Determine the coordinates of the flight at that time step.  
    segmentendX = FDR(M_changes_at_t,i,14);
    segmentendY = FDR(M_changes_at_t,i,15);
   
    % Store the nodes of each segment. The origin and current location have
    % to be added to the coordinate sets.
    segments_node_coordinates_X = [FDR(1,i,3);segmentendX;FDR(1,i,5)]; 
    segments_node_coordinates_Y = [FDR(1,i,4);segmentendY;FDR(1,i,6)];            
    
    % Determine the speeds after a heading change in order to obtain the
    % additional flight time.
    Speed_after_heading_change = FDR(M_changes_at_t,i,7);
    Speed_per_segment = [Vmax;Speed_after_heading_change];

    % These predefined vectors will temporarily hold information on one
    % flight. No need to store all data, just the results is faster.
    segment_lengths = zeros(length(segments_node_coordinates_X)-1,1); 
    segment_time_seconds = zeros(length(segments_node_coordinates_X)-1,1);                                               

    % Loop over the segments to determine the length and flight time at the
    % end of each segment.
    for l = 1:length(segments_node_coordinates_X)-1
        % Determine the length of each segment.
        segment_lengths(l) = sqrt((segments_node_coordinates_X(l+1) - ...
            segments_node_coordinates_X(l))^2 + ...
            (segments_node_coordinates_Y(l+1) - ...
            segments_node_coordinates_Y(l))^2);
        % Determine the time it takes to fly each segment.
        segment_time_seconds(l) = 1000.* ...
            segment_lengths(l)/Speed_per_segment(l);
    end

    % Determine the mission length.
    missionLength(i) = sum(segment_lengths);                 
    % Determine the flight time.
    formationFlightTimeSeconds(i) = sum(segment_time_seconds);
end

%% Calculate how much of the total fuel savings went to the alliance and non-alliance flights.

% This code calculates how much of the total fuel savings went to the
% alliance, and how much went to the non-alliance flights. It makes use of
% property 27 and 28.     

% Determine the total number of flights (including dummy flights).
nTotal = max(max(FDR(:,:,1)));
% Predefine the array for fuel savings per flight.
fuelSavingsPerFlight = zeros(nTotal,1);
% Loop backwards through all flight IDs (including dummy flights).
for i = nTotal:-1:1
    
    % Determine the time steps when flight i engaged to another flight,
    % based on property 27 (fuel savings [kg] flight i received from this
    % new formation).
    M_changes_at_t = find(abs(diff(FDR(:,i,27)))~=0)+1;
             
    % Check if flight i is a real flight or dummy flight.
    if i <= nAircraft
        % Check if flight i has engaged to other flight(s).
        if isempty(M_changes_at_t) ~= 1
            for j = 1:size(M_changes_at_t,1)
                % Add the fuel savings due to this new formation.
                fuelSavingsPerFlight(i) = fuelSavingsPerFlight(i) + ...
                    FDR(M_changes_at_t(j),i,27);
            end
        end
    % Enter this code block if flight i is a dummy flight and has engaged
    % to other flight(s). This distributes the fuel savings from dummy
    % flights over their real followers ultimately.
    elseif isempty(M_changes_at_t) ~= 1
        % Determine the two followers of flight i.
        flightsWithFlightI = find(FDR(M_changes_at_t(1),1:nTotal,22)==i);
        % Store the two flight IDs.
        if isempty(flightsWithFlightI) ~= 1 %workaround
            acNr1 = flightsWithFlightI(1);
            acNr2 = flightsWithFlightI(2);
            % Loop through the time steps at which flight i forms a formation.
            for j = 1:size(M_changes_at_t,1)
                % Store the time step for shorter code.
                timeStep = M_changes_at_t(j);
                % Distribute the fuel savings due to formations formed by
                % flight i over the followers of flight i.
                fuelSavingsPerFlight(acNr1) = fuelSavingsPerFlight(acNr1) + ...
                    FDR(timeStep,i,27)*FDR(timeStep,acNr1,28);
                fuelSavingsPerFlight(acNr2) = fuelSavingsPerFlight(acNr2) + ...
                    FDR(timeStep,i,27)*FDR(timeStep,acNr2,28);
            end
            % Distribute the total fuel savings that flight i collected from
            % its own formation leader(s) over the followers of flight i.
            fuelSavingsPerFlight(acNr1) = fuelSavingsPerFlight(acNr1) + ...
                fuelSavingsPerFlight(i)*FDR(timeStep,acNr1,28);
            fuelSavingsPerFlight(acNr2) = fuelSavingsPerFlight(acNr2) + ...
                fuelSavingsPerFlight(i)*FDR(timeStep,acNr2,28);
        end
    end
end

%% Calulate results.

% Percentual change in total distance, comparing the actual total distance
% to the total distance if only solo flights were flown.
Total_solo_distance = sum(soloRouteDistances(:,2));
Total_covered_distance  = sum(missionLength);
extraDistancePct = (Total_covered_distance-Total_solo_distance)/ ...
    Total_solo_distance*100; 

% Percentual change in total flight, comparing the actual flight time to
% the total flight time of only solo flights were flown.
extraFlightTimePct = (sum(formationFlightTimeSeconds) - ...
    sum(soloFlightTimeSeconds))/sum(soloFlightTimeSeconds)*100;

% Percentual change in fuel use, comparing the actual fuel use to
% the total fuel use if of only solo flights were flown.
fuelSavingsTotalPct = fuelSavingsTotal/sum(soloFuelRequired)*100;

% Percentage of the total fuel savings that went to the alliance.
fuelSavingsAlliancePct = sum(fuelSavingsPerFlight(FDR(end,1:nAircraft,25)==2))/ ...
    fuelSavingsTotal*100;

% Percentage of the total fuel savings that went to the non-alliance
% flights.
fuelSavingsNonAlliancePct = sum(fuelSavingsPerFlight(FDR(end,1:nAircraft,25)==1))/ ...
    fuelSavingsTotal*100;
end