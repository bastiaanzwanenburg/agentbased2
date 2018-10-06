%% step2_moveAircraft.m description
% In this file dummy flights will be assigned to two engaged flights that
% have reached their joining point. This dummy flight will then lead the
% formation of these two flights. This file updates the location of the
% solo flights, formation leaders, and followers that are released due to
% the fact that their formation leader has arrived at its destination.
% Relevant properties of each flight will be updated. After this, the
% location of each follower is updated. Additionally, this file checks
% whether there are flights that have not moved but should have, and
% whether there are flights that have overshot their destination.
% Ultimately, these errors are corrected.

% It contains no functions or files.

%% Move the solo flights, formation leaders, and released followers. 
% Dummy flights will be assigned here to two engaged flights that have
% reached their joining point. The dummy flight will lead the formation of
% these two flights. Accordingly, the heading, speed, and other properties
% of the two flights and the dummy flight will be updated.

% The location of each flight in one of the above mentioned flights is
% updated for this time step. Checked here is when a flight has reached its
% destination. Accordingly, relevant properties of the flight will be
% updated. If a formation leader has reached its destination, its followers
% will be released and relevant properties of these followers will be
% updated.

% Check for all flights if it falls into one of the above mentioned
% categories. This for-loop covers both real flights and dummy flights.
for a = 1:length(flightsData(:,1)) 

    % Filter out the followers and move just solo flights and formation
    % leaders (always dummy flights).
    if flightsData(a,21) == 1 || flightsData(a,21) == 2 

        % If two flights are engaged and have reached their joining point a
        % dummy flight will be assigned at this point that will lead the
        % formation. That is, if a flight has reached its joining point and
        % not yet its splitting point.
        if flightsData(a,2) == 0 && flightsData(a,14) >= ...
                flightsData(a,9) && flightsData(a,14) < flightsData(a,11)   

            % Restore the flight to the default speed.
            flightsData(a,7) = Vmax;                            
            % Insert the heading to the splitting point from the current
            % location such that the overshoot from the joining point will
            % be reduced.
            flightsData(a,8) = (flightsData(a,12)-flightsData(a,15))/ ...
                (flightsData(a,11)-flightsData(a,14));      
            % Mark the flight as being in formation.
            flightsData(a,17) = 1;                                                                   
            
            % 'Activate' the next available dummy flight and determine its
            % followers. Keep track of how many dummy flights have been
            % used.
            dummyCounter = dummyCounter + 1;                            
            % nAircraft+n is the flight number of the dummy flight that is
            % activated at this point.
            n = dummyCounter;                                              
            % The flight number of the dummy flight is restored from -1 to
            % the next in the list. Dummies need a unique callsign too.
            flightsData(nAircraft+n,1) = nAircraft+n;  
            % Set formation status of dummy flight to 'formation leader'.
            flightsData(nAircraft+n,21) = 2;                                                

            % Assign appropriate information to the dummy flight. The
            % second property (engaged or not engaged) is not to be copied,
            % as the dummy flight is not engaged from the start. Property
            % 14 and 15 (current location) are copied from flight a. So are
            % property 16 (flight status) and 18 (arrival status).
            flightsData(nAircraft+n,3:18) = flightsData(a,3:18);   
            % Current location of flight a becomes the origin of the dummy
            % flight (property 3 and 4). 
            flightsData(nAircraft+n,3:4) = flightsData(a,14:15);                                
            % The splitting point of flight a becomes the destination
            % of the dummy flight.
            flightsData(nAircraft+n,5:6) = flightsData(a,11:12);                                
            % Property 9 to 12 (joining- and splitting point) of the dummy
            % flight are reset. Property 13 (the M-value) is set to 0, as
            % it is irrelevant for dummy flights.
            flightsData(nAircraft+n,9:13) = [-99999,-99999,-99999,-99999,0];               
            % Property 17 (formation status) is set to 0, the dummy flight
            % is not in formation itself when called upon for the first
            % time.
            flightsData(nAircraft+n,17) = 0;
            % property 19 (weight factor of the formation which the dummy
            % flight represents) is equal to the sum of the engaged
            % flights' weights.
            flightsData(nAircraft+n,19) = flightsData(a,19) + ...
                flightsData(flightsData(a,20),19);
            % Property 26 (max. delay) is equal to the minimum max. delay
            % that either flight a or its engaged partner can accept.
            flightsData(nAircraft+n,26) = min(flightsData(a,26), ...
                flightsData(flightsData(a,20),26));

            % Make the two engaged flights followers by setting property 21
            % (in-formation status) to 0, indicating it to be a follower.
            % Flight a is now a follower.
            flightsData(a,21) = 0;
            % Flight a's engaged partner is now also a follower.
            flightsData(flightsData(a,20),21) = 0;
            % Set property 17 (formation status) of flight a's engaged
            % partner to 1, indicating it to be in formation.
            flightsData(flightsData(a,20),17) = 1;                                     

            % Assign the two engaged flights to be followers to the dummy
            % flight by setting property 22 (flight ID of the flight that a
            % flight is following) to the flight ID of the dummy flight.
            flightsData(a,22) = nAircraft+n;                                               
            flightsData(flightsData(a,20),22) = nAircraft+n;

        end

        % Update aircraft locations of solo flights and formation leaders
        % (always dummy flights). Only move those flights with property 16
        % (flight status) of 1, indicating a flight is flying. Double check
        % for only solo- and dummy flights.
        if flightsData(a,16) == 1 && ...
                (flightsData(a,21) == 1 || flightsData(a,21) == 2) 
            % Determine the travelled distance in km in one time step. 
            travelledDistance = (flightsData(a,7)/1000).*dt;                    
            travelledDistanceX = cosd(atand(flightsData(a,8))).* ...
                travelledDistance;  
            travelledDistanceY = sind(atand(flightsData(a,8))).* ...
                travelledDistance;
            % Update the current location of flight a.
            flightsData(a,14) = flightsData(a,14) + travelledDistanceX;                  
            flightsData(a,15) = flightsData(a,15) + travelledDistanceY; 

            % Check if flight a has arrived. This is still done within the
            % if-statement covering only solo- and dummy flights, so
            % followers are not covered.
            if flightsData(a,14) > flightsData(a,5) 
                % Mark the flight status as "not flying".
                flightsData(a,16) = 0;       
                % Mark the arrival status as "has arrived". Seems similar
                % to above, but we need two booleans. Otherwise, to check
                % whether a flight has arrived it would have to be moved
                % forward and backward once.
                flightsData(a,18) = 1;    
                % Reverse the last movement. 
                flightsData(a,14) = flightsData(a,14) - travelledDistanceX;                  
                flightsData(a,15) = flightsData(a,15) - travelledDistanceY;
                % Set the M-value to zero, for clarity and security.
                flightsData(a,13) = 0;                                                
                % Set property 22 (flight ID of the flight that a flight is
                % following) to 0, as flight a is not following anyone
                % anymore.
                flightsData(a,22) = 0;                                                

                % Within this if-statement followers of flight a are
                % released when it has arrived at its destination. This
                % is only if flight a is a dummy flight. Note that there
                % are two followers per dummy flight, that of course may be
                % dummy flights themselves. 
                if flightsData(a,21) == 2  
                    % Determine the flights that where following flight a.  
                    followersOfFlightA = find(flightsData(:,22)== a); 
                    % These flights are no longer engaged to each other.
                    % Set property 2 (communication status) to 1,
                    % "available for communication".
                    flightsData(followersOfFlightA,2) = 1;  
                    % Set property 17 (formation status) of the followers
                    % to 0, indicating them to no longer be in formation.
                    flightsData(followersOfFlightA,17) = 0;   
                    % Set property 20 (flight ID for the flight to which it
                    % is engaged) to 0, as the followers are no longer
                    % engaged to each other.
                    flightsData(followersOfFlightA,20) = 0;  
                    % Set property 22 (flight ID of the flight that a
                    % flight is following) to 0, as these flights are not
                    % following flight a anymore.
                    flightsData(followersOfFlightA,22) = 0;                          

                    % Move the released followers to the point beyond the
                    % just arrived flight a's destination, otherwise they
                    % do not move in this time step.
                    flightsData(followersOfFlightA,14) = ...
                        flightsData(followersOfFlightA,14) + ...
                        travelledDistanceX;
                    flightsData(followersOfFlightA,15) = ...
                        flightsData(followersOfFlightA,15) + ...
                        travelledDistanceY;

                    % Reverse the last movement of the released followers
                    % if they themselves have arrived at their destination.
                    % Note that if these followers are dummy flights (and
                    % thus have followers themselves), these will be
                    % released in the next code section.
                    % The first follower.
                    if flightsData(followersOfFlightA(1),14) > ...
                            flightsData(followersOfFlightA(1),5)
                        % Mark the flight status as "not flying".
                        flightsData(followersOfFlightA(1),16) = 0;
                        % Mark the arrival status as "has arrived". Seems
                        % similar to above, but we need two booleans.
                        % Otherwise, to check whether a flight has arrived
                        % it would have to be moved forward and backward
                        % once.
                        flightsData(followersOfFlightA(1),18) = 1;
                        % Reverse the last movement. 
                        flightsData(followersOfFlightA(1),14) = ...
                            flightsData(followersOfFlightA(1),14) - ...
                            travelledDistanceX;      
                        flightsData(followersOfFlightA(1),15) = ...
                            flightsData(followersOfFlightA(1),15) - ...
                            travelledDistanceY;
                        % Set the M-value to zero, for clarity and
                        % security.
                        flightsData(followersOfFlightA(1),13) = 0; 
                    end
                    % The second follower.
                    if flightsData(followersOfFlightA(2),14) > ...
                            flightsData(followersOfFlightA(2),5)
                        % Mark the flight status as "not flying".
                        flightsData(followersOfFlightA(2),16) = 0;
                        % Mark the arrival status as "has arrived". Seems
                        % similar to above, but we need two booleans.
                        % Otherwise, to check whether a flight has arrived
                        % it would have to be moved forward and backward
                        % once.
                        flightsData(followersOfFlightA(2),18) = 1;  
                        % Reverse the last movement.
                        flightsData(followersOfFlightA(2),14) = ...
                            flightsData(followersOfFlightA(2),14) - ...
                            travelledDistanceX;      
                        flightsData(followersOfFlightA(2),15) = ...
                            flightsData(followersOfFlightA(2),15) - ...
                            travelledDistanceY;
                        % Set the M-value to zero, for clarity and
                        % security.
                        flightsData(followersOfFlightA(2),13) = 0;
                    end

                    % Update property 21 (in-formation status) and property
                    % 13 (M-value) of the two released flights. Determine
                    % from the flight ID if the first follower is a real,
                    % or dummy flight.
                    if flightsData(followersOfFlightA(1),1)> nAircraft
                        % A released dummy flight remains a dummy after
                        % release.
                        flightsData(followersOfFlightA(1),21) = 2;                   
                    else
                        % A real flight is released as a solo flight.
                        flightsData(followersOfFlightA(1),21) = 1;
                        % Reset the M-value to the solo flight value.
                        flightsData(followersOfFlightA(1),13) = MFuelSolo;         
                    end
                    % Determine from the flight ID if the second follower
                    % is a real, or dummy flight.
                    if flightsData(followersOfFlightA(2),1)> nAircraft
                        % A released dummy flight remains a dummy after
                        % release.
                        flightsData(followersOfFlightA(2),21) = 2;                  
                    else
                        % A real flight is released as a solo flight.                        
                        flightsData(followersOfFlightA(2),21) = 1;
                        % Reset the M-value to the solo flight value.
                        flightsData(followersOfFlightA(2),13) = MFuelSolo;         
                    end

                    % Update the heading of the released followers. 
                    flightsData(followersOfFlightA(1),8) = ...
                        (flightsData(followersOfFlightA(1),15)- ...
                        flightsData(followersOfFlightA(1),6))/ ...
                        (flightsData(followersOfFlightA(1),14)- ...
                        flightsData(followersOfFlightA(1),5)); 
                    flightsData(followersOfFlightA(2),8) = ...
                        (flightsData(followersOfFlightA(2),15)- ...
                        flightsData(followersOfFlightA(2),6))/ ...
                        (flightsData(followersOfFlightA(2),14)- ...
                        flightsData(followersOfFlightA(2),5)); 
                end  
            end
        end
    end
end

%% Move the followers.

% The location of each follower is updated for this time step. Checked here
% is when a flight has reached its destination. Accordingly, relevant
% properties of the flight will be updated. If flight c's formation leader
% has been released as follower itself in the previous code section, and
% this formation leader has arrived at its destination, flight c will be
% released here. Accordingly, relevant properties of the flight will be
% updated.

% Check for all flights if it is a follower. This for-loop covers both real
% flights and dummy flights, as all flights can be followers. 
for c = 1:length(flightsData(:,1))                                            
    % Filter out the solo flights and formation leaders. Only consider
    % flights with property 21 (in-formation status) of 0, indicating a
    % flight is following. Only consider flights with property 16 (flight
    % status) of 1, indicating a flight is flying.
    if flightsData(c,16) == 1 && flightsData(c,21) == 0                        
        % Check whether the formation leader of flight c (found in property
        % 22 of flight c) has arrived at its destination (then property 18
        % (arrival status) is set to 1). This can occur when flight c's
        % formation leader has been released as follower in the previous
        % code section, and has arrived at its destination. If this is the
        % case, flight c is released at this point.
        if flightsData(flightsData(c,22),18) == 1                   
            % Flight c is no longer engaged. Set property 2
            % (communication status) to 1, "available for communication"
            flightsData(c,2) = 1;                                  
            % Set property 17 (formation status) to 0, indicating it to no
            % longer be in formation.
            flightsData(c,17) = 0;  
            % Set property 20 (flight ID for the flight to which it is
            % engaged) to 0, as flight c is no longer engaged to any
            % flight.
            flightsData(c,20) = 0;                       
            % Set property 22 (flight ID of the flight that a flight is
            % following) to 0, as flight c is not following any flight.
            flightsData(c,22) = 0;                                                               
            % Update property 21 (in-formation status) and property 13
            % (M-value) of flight c. Determine from the flight ID if it is
            % a real or dummy flight.
            if flightsData(c,1)> nAircraft
                % A released dummy flight remains a dummy after release.
                flightsData(c,21) = 2;                           
            else
                % A real flight is released as a solo flight.                        
                flightsData(c,21) = 1;
                % Reset the M-value to the solo flight value.
                flightsData(c,13) = MFuelSolo;                
            end

            % Update aircraft locations of the released follower. Determine
            % the travelled distance in km in one time step.
            travelledDistance = (flightsData(c,7)/1000).*dt;       
            travelledDistanceX = cosd(atand(flightsData(c,8))).* ...
                travelledDistance;
            travelledDistanceY = sind(atand(flightsData(c,8))).* ...
                travelledDistance;
            % Update the current location.
            flightsData(c,14) = flightsData(c,14) + travelledDistanceX;
            flightsData(c,15) = flightsData(c,15) + travelledDistanceY;
            % Update the heading.
            flightsData(c,8) = (flightsData(c,15)-flightsData(c,6))/ ...
                (flightsData(c,14)-flightsData(c,5)); 
            flightsData(c,8) = (flightsData(c,15)-flightsData(c,6))/ ...
                (flightsData(c,14)-flightsData(c,5)); 
        % If flight c is not to be released in this time step.
        else
            % The speed needs to be retrieved from the formation leader
            % here, otherwise the M-value of the follower is not determined
            % correctly in this time step.
            flightsData(c,7) = flightsData(flightsData(c,22),7);              
        end
    end

    % Adjust M-values for speed variations. Calculate it here in the
    % for-loop where followers are moved. This is because the M-value
    % calculation is dependent on the speed, which depends on the speed of
    % the formation leader. Note that this is only done for real flights,
    % as the M-value is irrelevant for dummy flights. 
    % For followers:
    if flightsData(c,21) == 0 && c <= nAircraft                                        
        flightsData(c,13) = MFuelTrail - fuelPenalty*MFuelTrail* ...
            (Vmax - flightsData(c,7))/(Vmax-Vmin);
    end
    % For solo flights:
    if flightsData(c,21) == 1 && c <= nAircraft                                       
        flightsData(c,13) = MFuelSolo - fuelPenalty*MFuelSolo* ...
            (Vmax - flightsData(c,7))/(Vmax-Vmin);           
    end
end

%% Check if the are any flights that have not moved yet but should have.

% Determine this from the fact that property 14 (x-coordinate) is equal in
% this and the previous time step, property 16 (flight status) is 1
% ("flying"), and property 18 (arrival status) is 0 ("not arrived").
flightsNotMovedYet = find(flightsData(:,14) == ...
    flightsDataRecordings(t,:,14)' & flightsData(:,16) == 1 & ...
    flightsData(:,18) == 0);

% Check if there is at least one flight that has not moved yet.
if isempty(flightsNotMovedYet) == 0
    % The for-loop makes sure that all flights are eventually moved, moving
    % followers of followers requires iterations. The properties are copied
    % from a flight's formation leader.
    for s = 1:length(flightsNotMovedYet)                  
        % Property 14 and 15 (current location) are updated.
        flightsData(flightsNotMovedYet,14) = ...
            flightsData(flightsData(flightsNotMovedYet,22),14);
        flightsData(flightsNotMovedYet,15) = ...
            flightsData(flightsData(flightsNotMovedYet,22),15);
        % Property 8 (current heading) is updated.
        flightsData(flightsNotMovedYet,8) = ....
            flightsData(flightsData(flightsNotMovedYet,22),8);
        % Property 7 (speed) is updated.
        flightsData(flightsNotMovedYet,7) = ...
            flightsData(flightsData(flightsNotMovedYet,22),7);
        % Property 13 (M-value) is updated, as it is dependent on the speed
        % that may have changed.
        flightsData(flightsNotMovedYet(flightsNotMovedYet<=nAircraft),13)...
            = MFuelTrail - fuelPenalty.*MFuelTrail.* ...
            (Vmax - flightsData(flightsNotMovedYet ...
            (flightsNotMovedYet<=nAircraft),7))/(Vmax-Vmin);
    end
end

%% Ensure no flight overshoots its destination.
% Determine if there are flights of which the x-coordinate of its current
% location is larger than that of its destination.
flightsOvershot = find(flightsData(:,14) > flightsData(:,5));
% Set property 14 (current location's x-coordinate) to that of property 5
% (destination's x-coordinate)
flightsData(flightsOvershot,14) = flightsData(flightsOvershot,5);
% Set property 16 (flight status) to 0 ("not flying").
flightsData(flightsOvershot,16) = 0;
% Set property 18 (arrival status) to 1 ("has arrived").
flightsData(flightsOvershot,18) = 1;