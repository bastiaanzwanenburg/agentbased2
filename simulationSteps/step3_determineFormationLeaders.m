%% step3_determineFormationLeaders.m description
% In the code, a dummy flight represents a formation and leads it. In
% reality, one of the real flights in the formation is formation leader.
% This file determines the actual formation leader, which is by default set
% to be the flight with the lowest flight ID. Property 13 (M-value) of this
% flight is then adjusted to the solo value, such that the fuel
% calculations will be done correctly.

% It contains no functions or files.

%% For fuel calculations, determine which flight is actually formation leader.

% Determine all real flights that have property 21 (in-formation status) of
% 0 ("follower"). Note that this means all real flights in a formation have
% property 21 set to 0, as formations are lead by dummy flights in the
% code.
flightIDsFollowers = find(flightsData(1:nAircraft,21)==0);        
% Since formations of formations are possible, and all flights in such a
% formation share the same current location (property 14, 15), this
% statement looks for the unique combinations of property 14 and 15. For
% example: a formation of two real flights (represented by a dummy flight)
% forms a formation with another formation of two (represented by another
% dummy flight). This new formation will be represented by a new dummy
% flight, and all four real flights in this new formation share the same
% current location (property 14, 15). As such, each unique combination
% represents a top level formation.
uniqueFormationCurrentLocations = ...
    unique(flightsData(flightIDsFollowers,14:15),'rows');     
    
% Check if there are any formations at all.
if isempty(uniqueFormationCurrentLocations) == 0 
    % Loop over all the unique current locations.
    for m = 1:length(uniqueFormationCurrentLocations(:,1))                                      
        % Determine which real flights are all at unique current location
        % m.
        flightsAtCurrentLocation = find(flightsData(1:nAircraft,14)== ...
            uniqueFormationCurrentLocations(m,1) & ...
            flightsData(1:nAircraft,15)== ...
            uniqueFormationCurrentLocations(m,2)); 
        % Determine the real flight with the lowest flight ID, this flight
        % becomes the formation leader. Adjust property 13 (M-value) of
        % this flight to the solo value, as this flight is not saving fuel.
        flightsData(find(flightsData(:,1)== ...
            min(flightsAtCurrentLocation)),13) = MFuelSolo-fuelPenalty* ...
            MFuelSolo* ...
            (Vmax-flightsData(min(flightsAtCurrentLocation),7))/(Vmax-Vmin);
    end
end