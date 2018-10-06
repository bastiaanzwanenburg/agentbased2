function [potentialFuelSavings] = ...
    calculateFuelSavings(fuelPenalty,t,flightsDataRecordings,nAircraft, ...
    acNr1,acNr2,flightsData,Xordes,Yordes,Xjoining,Yjoining,Xsplitting, ...
    Ysplitting,Vmin,Vmax,VsegmentAJ_acNr1,VsegmentBJ_acNr2,MFuelSolo, ...
    MFuelTrail)
%% calculateFuelSavings.m description
% This function calculates the cumulative fuel savings of acNr1, acNr2, and
% all their followers if the formation is accepted. It compares the fuel
% use for when the formation is not accepted, with the fuel use if it is
% accepted. This is done by first determining the followers with acNr1 and
% acNr2 (if any), what their current weight is at this time step, the
% segments they have to fly with and without the formation being accepted,
% and then the weight after reaching the destination of acNr1 and acNr2.
% The difference between this weight and the current weight is the fuel
% use.

% inputs:
% fuelPenalty (the fuel penalty ensures that slowing down to Vmin leads to
% an increase in fuel consumption),
% t (time-step iterator), 
% flightsDataRecordings (flight data recorder that contains the flightsData
% at every time t),
% nAircraft (number of aircraft),
% acNr1 (flight number 1 that is considered for this formation),
% acNr2 (flight number 2 that is considered for this formation),
% flightsData (matrix that contains all information of each (dummy) flight), 
% Xordes (current and destination x-coordinates of both aircraft),
% Yordes (current and destination y-coordinates of both aircraft),
% Xjoining (x-coordinate of the joining point),
% Yjoining,
% Xsplitting, 
% Ysplitting,
% Vmin,
% Vmax,
% VsegmentAJ_acNr1 (speed from current location to joining point),
% VsegmentBJ_acNr2 (speed from current location to joining point),
% MFuelSolo (M-value solo/leader aircraft at Vmax, the fuel consumption of
% an aircraft is governed by these M-values),
% MFuelTrail (M-value trailing aircraft at Vmax).

% outputs: 
% potentialFuelSavings (combined fuel savings of acNr1, acNr2, and all
% their followers if the formation is accepted).

% special cases: 
% * Flight with the lowest flight number is selected as formation leader.

%% Determine the flights in formation with acNr1 and acNr2 already.

% Find those flights that have the same location and heading. These are the
% flights already in formation with acNr1 or acNr2. Note that the result of
% this find function may include, and be limited to, i.e. acNr1.
flightsWithacNr1 = find(flightsData(1:nAircraft,8)==flightsData(acNr1,8) & ...
    flightsData(1:nAircraft,14)==flightsData(acNr1,14) & ...
    flightsData(1:nAircraft,15)==flightsData(acNr1,15) & ...
    flightsData(1:nAircraft,16)==flightsData(acNr1,16));
flightsWithacNr2 = find(flightsData(1:nAircraft,8)==flightsData(acNr2,8) & ...
    flightsData(1:nAircraft,14)==flightsData(acNr2,14) & ...
    flightsData(1:nAircraft,15)==flightsData(acNr2,15) & ...
    flightsData(1:nAircraft,16)==flightsData(acNr2,16));

%% Determine current weights of the flights with acNr1 and acNr2.
% For this we first find out which segments the considered flights have
% already flown.

% First, we need the history of the flights under consideration.
Flights_at_acNr1_loc = flightsDataRecordings(:,flightsWithacNr1,:); 
Flights_at_acNr2_loc = flightsDataRecordings(:,flightsWithacNr2,:);

% Predefine the following two variables. 
Current_weights_all_ac_with_acNr1 = 0;
Current_weights_all_ac_with_acNr2 = 0;

% Calculate the fuel consumption for each flight separately to determine
% the current weight of each flight with acNr1. An elaborate loop structure
% is required, as the number of segments as well as the number of to be
% evaluated flights varies here.
for p = 1:length(flightsWithacNr1)                                                         
    % This clearing of variables ensures that the correct data is used for
    % every iteration.
    clearvars segment_lengths Heading_changes_at_t segmentendX ...
       segmentendY Mvalue_after_heading_change ...
       segments_node_coordinates_X segments_node_coordinates_Y Weights_ac

    % Determine the time steps t of each flight p with acNr1 at which the
    % heading or the M-value changes.
    M_changes_at_t = find(abs(diff(Flights_at_acNr1_loc(:,p,8)))~=0 | ...
       abs(diff(Flights_at_acNr1_loc(:,p,13)))~=0)+1;
    % Determine the coordinates of flight p at that time step.
    segmentendX = Flights_at_acNr1_loc(M_changes_at_t,p,14);
    segmentendY = Flights_at_acNr1_loc(M_changes_at_t,p,15);
    % Determine the M-value at that time step.
    Mvalue_after_heading_change = Flights_at_acNr1_loc(M_changes_at_t,p,13);

    % Calculate the segment lengths. The origin and current location have
    % to be added to the coordinate sets.
    segments_node_coordinates_X = [Flights_at_acNr1_loc(1,p,3);segmentendX;...
       Flights_at_acNr1_loc(length(Flights_at_acNr1_loc(:,1,1)),p,14)]; 
    segments_node_coordinates_Y = [Flights_at_acNr1_loc(1,p,4);segmentendY;...
       Flights_at_acNr1_loc(length(Flights_at_acNr1_loc(:,1,1)),p,15)];
    % Store the M-value for each segment. 
    M_value_per_segment = [Flights_at_acNr1_loc(1,p,13); ...
       Mvalue_after_heading_change];              

    % These predefined vectors will temporarily hold information on one
    % flight. No need to store all data, just the results is faster.
    segment_lengths = zeros(length(segments_node_coordinates_X)-1,1);
    Weights_ac = zeros(length(segments_node_coordinates_X),1);

    % The starting weight in the vector that will hold all intermediate
    % weights.
    Weights_ac(1) = flightsData(flightsWithacNr1(p),23);                                           
   
    % Loop over the segments to determine the weight at the end of each
    % segment.
    for l = 1:length(segments_node_coordinates_X)-1                                            
        segment_lengths(l) = sqrt((segments_node_coordinates_X(l+1) - ...
            segments_node_coordinates_X(l))^2 + ...
            (segments_node_coordinates_Y(l+1) - ...
            segments_node_coordinates_Y(l))^2);
        Weights_ac(l+1) = (sqrt(Weights_ac(l)) - ...
            (segment_lengths(l)/M_value_per_segment(l))).^2; 
    end
    
    % Store the last weight as the current weight for fuel saving
    % calculations.
    Current_weights_all_ac_with_acNr1(p) = Weights_ac(length(Weights_ac));  
end

% Calculate the fuel burn for each flight separately to determine the
% current weight of each flight with acNr2. An elaborate loop structure is
% required, as the number of segments as well as the number of to be
% evaluated flights varies here.
for q = 1:length(flightsWithacNr2)  
    % This clearing of variables ensures that the correct data is used for
    % every iteration.
    clearvars segment_lengths Heading_changes_at_t segmentendX ...
        segmentendY Mvalue_after_heading_change ...
        segments_node_coordinates_X segments_node_coordinates_Y Weights_ac
    
    % Determine the time steps of each flight p with acNr1 at which the
    % heading or the M-value changes.    
    M_changes_at_t = find(abs(diff(Flights_at_acNr2_loc(:,q,8))~=0) | ...
        abs(diff(Flights_at_acNr2_loc(:,q,13))~=0))+1;
    % Determine the coordinates of flight p at that time step.
    segmentendX = Flights_at_acNr2_loc(M_changes_at_t,q,14);
    segmentendY = Flights_at_acNr2_loc(M_changes_at_t,q,15);
    % Determine the M-value at that time step.
    Mvalue_after_heading_change = Flights_at_acNr2_loc(M_changes_at_t,q,13);
   
    % Store the nodes of each segment. The origin and current location have
    % to be added to the coordinate sets.
    segments_node_coordinates_X = [Flights_at_acNr2_loc(1,q,3);segmentendX;...
        Flights_at_acNr2_loc(length(Flights_at_acNr2_loc(:,1,1)),q,14)]; 
    segments_node_coordinates_Y = [Flights_at_acNr2_loc(1,q,4);segmentendY;...
        Flights_at_acNr2_loc(length(Flights_at_acNr2_loc(:,1,1)),q,15)];
    % Store the M-value for each segment. 
    M_value_per_segment = [Flights_at_acNr2_loc(1,q,13); ...
        Mvalue_after_heading_change];
         
    % These predefined vectors will temporarily hold information on one
    % flight. No need to store all data, just the results is faster.
    segment_lengths = zeros(length(segments_node_coordinates_X)-1,1);
    Weights_ac = zeros(length(segments_node_coordinates_X),1);

    % The starting weight in the vector that will hold all intermediate
    % weights.
    Weights_ac(1) = flightsData(flightsWithacNr2(q),23);                                          

    % Loop over the segments to determine the weight at the end of each
    % segment.
    for l =1:length(segments_node_coordinates_X)-1                                           
        % Determine the length of each segment.
        segment_lengths(l) = sqrt((segments_node_coordinates_X(l+1) - ...
            segments_node_coordinates_X(l))^2 + ...
            (segments_node_coordinates_Y(l+1) - ...
            segments_node_coordinates_Y(l))^2);
        % Determine the weight at the end of each segment.
        Weights_ac(l+1) = (sqrt(Weights_ac(l)) - ...
            (segment_lengths(l)/M_value_per_segment(l))).^2; 
    end

    % Store the last weight as the current weight for fuel saving
    % calculations.
    Current_weights_all_ac_with_acNr2(q) = Weights_ac(length(Weights_ac));                      
end

%% Evaluate the fuel requirements for the opted formation flight mission.

% Determine the weights of all the involved aircraft after the proposed
% formation route. Note the following: the required fuel for the final part
% of the mission is not relevant here. What matters is the formation route
% at hand and the corresponding solo routes. If the formation route turns
% out to be overall beneficial over the solo routes, an agent can consider
% bidding. If this is the basis for all formation flight decisions, only
% beneficial overall tracks will result. You can not use the same loop
% structure as above, since the determination of the current weight
% requires an undetermined amount of iterations. Since we know that there
% will be three iterations below, we can use vectors.

% Note how the starting weights that have to be used here are retrieved
% from the earlier calculated current weights. The M-value is not
% retrievable from the flightsData matrix, as the new required value is not
% available there yet. Only after a decision on formation flight, will the
% main file calculate the corresponding M-values.

% Note that, as an hypothesis, the flight that has the lowest flight ID in
% a formation, becomes leader of that formation. This rule should hold both
% in hypothetical tracks as well as accepted tracks, otherwise the
% evaluation of a potential track is worthless.

% Determine the to be flown segment distances.
segmentJS = sqrt((Xsplitting-Xjoining).^2 + (Ysplitting -Yjoining).^2);  
segmentAJ = sqrt((Xordes(1)-Xjoining).^2 + (Yordes(1)-Yjoining).^2);
segmentBJ = sqrt((Xordes(2)-Xjoining).^2 + (Yordes(2)-Yjoining).^2);
segmentSC = sqrt((Xordes(3)-Xsplitting).^2 + (Yordes(3)-Ysplitting).^2);
segmentSD = sqrt((Xordes(4)-Xsplitting).^2 + (Yordes(4)-Ysplitting).^2);
segmentAC = sqrt((Xordes(3)-Xordes(1))^2 + (Yordes(3)-Yordes(1))^2);
segmentBD = sqrt((Xordes(4)-Xordes(2))^2 + (Yordes(4)-Yordes(2))^2);

% M-matrices for the fuel requirement prediction of acNr1 and flights with
% acNr1 when formation is not accepted.
Mmatrix_all_flights_with_acNr1_loose = [flightsWithacNr1 ...
    ones(length(flightsWithacNr1),1)*MFuelTrail];
% The lowest flight number leads the formation towards the joining point.
% Set its M-value to MFuelSolo.
Mmatrix_all_flights_with_acNr1_loose( ...
    find(Mmatrix_all_flights_with_acNr1_loose(:,1) == ...
    min(flightsWithacNr1)),2) = MFuelSolo; 

% M-matrices for the fuel requirement prediction of acNr2 and flights with
% acNr2 when formation is not accepted.
Mmatrix_all_flights_with_acNr2_loose = [flightsWithacNr2 ...
    ones(length(flightsWithacNr2),1)*MFuelTrail];
% The lowest flight number leads the formation towards the joining point.
% Set its M-value to MFuelSolo.
Mmatrix_all_flights_with_acNr2_loose( ...
    find(Mmatrix_all_flights_with_acNr2_loose(:,1) == ...
    min(flightsWithacNr2)),2) = MFuelSolo;

% M-matrices for the fuel requirement prediction of acNr1 and acNr2 and
% flights with acNr1 and acNr2 when formation is accepted. Predefine to
% obtain correct formation matrix size.
Mmatrix_all_flights_with_acNr1_formation = Mmatrix_all_flights_with_acNr1_loose;                                                    
Mmatrix_all_flights_with_acNr2_formation = Mmatrix_all_flights_with_acNr2_loose;

% Determine the leading flight for the potential formation. This is the
% flight with the lowest flight number.
leading_ac = min([flightsWithacNr1;flightsWithacNr2]);                                                    

% Set the M-values for the JS segment (joining- to splitting point). Only
% one leader must be selected, this will be the aircraft with the
% lowest flight number.
if isempty(find(Mmatrix_all_flights_with_acNr1_loose(1,:)==leading_ac)) == 0 
    % If the leader is acNr1 or one of the flights with acNr1.
    % Set the M-values of all flights with acNr1 to MFuelTrail.
    Mmatrix_all_flights_with_acNr1_formation(:,2) = MFuelTrail;
    % Except for the leader.
    Mmatrix_all_flights_with_acNr1_formation( ...
        find(Mmatrix_all_flights_with_acNr1_formation(:,1)==leading_ac),2) ...
        = MFuelSolo;
    % Set the M-values of all flights with acNr2 to MFuelTrail.
    Mmatrix_all_flights_with_acNr2_formation(:,2) = MFuelTrail; 
else
    % If the leader is acNr2 or one of the flights with acNr2.
    % Set the M-values of all flights with acNr2 to MFuelTrail.
    Mmatrix_all_flights_with_acNr2_formation(:,2) = MFuelTrail;
    % Except for the leader.
    Mmatrix_all_flights_with_acNr2_formation( ...
        find(Mmatrix_all_flights_with_acNr2_formation(:,1)==leading_ac),2) ...
        = MFuelSolo;
    % Set the M-values of all flights with acNr1 to MFuelTrail.
    Mmatrix_all_flights_with_acNr1_formation(:,2) = MFuelTrail; 
end

% For acNr1 and his followers, determine the weights at point C, the
% destination of acNr1.
Weights_at_J_acNr1 = (sqrt(Current_weights_all_ac_with_acNr1') - ...
    (segmentAJ./(Mmatrix_all_flights_with_acNr1_loose(:,2) - ...
    fuelPenalty.*Mmatrix_all_flights_with_acNr1_loose(:,2).* ...
    (Vmax - VsegmentAJ_acNr1)./(Vmax-Vmin)))).^2;
Weights_at_S_acNr1 = (sqrt(Weights_at_J_acNr1) - ...
    (segmentJS./Mmatrix_all_flights_with_acNr1_formation(:,2))).^2;
Weights_at_C_acNr1 = (sqrt(Weights_at_S_acNr1) - ...
    (segmentSC./Mmatrix_all_flights_with_acNr1_loose(:,2))).^2;

% For acNr2 and his followers, determine the weights at point D, the
% destination of acNr2.
Weights_at_J_acNr2 = (sqrt(Current_weights_all_ac_with_acNr2') - ...
    (segmentBJ./(Mmatrix_all_flights_with_acNr2_loose(:,2) - ...
    fuelPenalty.*Mmatrix_all_flights_with_acNr2_loose(:,2).* ...
    (Vmax - VsegmentBJ_acNr2)./(Vmax-Vmin)))).^2;
Weights_at_S_acNr2 = (sqrt(Weights_at_J_acNr2) - ...
    (segmentJS./Mmatrix_all_flights_with_acNr2_formation(:,2))).^2;
Weights_at_D_acNr2 = (sqrt(Weights_at_S_acNr2) - ...
    (segmentSD./Mmatrix_all_flights_with_acNr2_loose(:,2))).^2;

%% Determine the overall potential fuel benefits/losses.
% For this we need the solo fuel uses over AC and BD. This means continuing
% with the M-values that are already present in the flightsData matrix.

% The final weights if acNr1 and acNr2 would continue to their destination
% solo and with current M-values for themselves and all their followers.
Weights_at_C_acNr1_SOLO = (sqrt(Current_weights_all_ac_with_acNr1') - ...
    (segmentAC./flightsDataRecordings(t,flightsWithacNr1,13)')).^2;
Weights_at_D_acNr2_SOLO = (sqrt(Current_weights_all_ac_with_acNr2') - ...
    (segmentBD./flightsDataRecordings(t,flightsWithacNr2,13)')).^2;

% Determine overall solo fuel, formation fuel, and the resulting potential
% savings.
Solo_fuel_for_all_involved_ac = sum(Current_weights_all_ac_with_acNr1) + ...
    sum(Current_weights_all_ac_with_acNr2) - sum(Weights_at_C_acNr1_SOLO) - ...
    sum(Weights_at_D_acNr2_SOLO);
Formation_fuel_for_all_involved_ac = sum(Current_weights_all_ac_with_acNr1) ...
    + sum(Current_weights_all_ac_with_acNr2) - sum(Weights_at_C_acNr1) - ...
    sum(Weights_at_D_acNr2);
potentialFuelSavings = Solo_fuel_for_all_involved_ac - ...
    Formation_fuel_for_all_involved_ac;
end