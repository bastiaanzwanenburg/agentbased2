function communicationCandidates = ... 
    determineCommunicationCandidates(flightsData,communicationRange, coordination)
%% determineCommunicationCandidates.m description
% This function determines the different flights with which each flight is
% able to communicate. Each flight has its communication circle, if two
% intersect, these two flights are able to communicate. 

% Randomize the starting flight ID to ensure that not at every time step
% flights with lower flight IDs benefit from having first pick in
% determining whether to act as manager in the CNP, or auctioneer in the
% auctions.

% inputs: 
% flightsData (matrix that contains all properties on each flight), 
% communicationRange (maximum communication distance BETWEEN two aircraft).

% output: communicationCandidates (the first column of each row indicates a
% flight's ID, column two and on indicate the flight ID's of those
% flights the flight in the first column can communicate with).

%% Determine the different aircraft with which each aircraft is able to communicate.

% The communication radius of each flight is half of the maximum
% communicating distance BETWEEN two flights [km].
communicationRadius = communicationRange/2;

% Predefined the variable to guarantee output of this function when no
% candidates are found.
communicationCandidates = 0;

% Check if there is more than one flight, otherwise no communication
% possible anyhow.
if length(flightsData(:,1)) >= 2    
    % Find all the flights that are potentially able to communicate (i.e.
    % flying, available, and have not yet arrived).
    flightsAvailable = find(flightsData(:,16)==1 & ...
        flightsData(:,2)==1 & flightsData(:,18)==0);
   
    % If there are at least two flights potentially able, allow the code to
    % continue.
    if length(flightsAvailable) >= 2 
        % Create an array that combines all potentially able flights in
        % sets of two.
        combinationSets = nchoosek(flightsAvailable,2); 
        acNr1 = combinationSets(:,1);
        acNr2 = combinationSets(:,2);
        
        % Create an empty array that will be used to flag whether a
        % set is able to communicate.
        combinationAble = zeros(length(acNr1),1);

        % Set communication circles and determine whether they intersect.
        % If two intersect, the combination is able to communicate.
        for i = 1:length(acNr1)            
            % Determine current location of the two flights.
            currentX = [flightsData(acNr1(i),14),flightsData(acNr2(i),14)];
            currentY = [flightsData(acNr1(i),15),flightsData(acNr2(i),15)];
            
            
            % Determine (possible) intersection coordinates of two
            % communication circles.
            [intersectX,~] = circcirc(currentX(1),currentY(1), ...
                communicationRadius,currentX(2),currentY(2), ...
                communicationRadius);
            
            % If one or two intersection points exist (i.e. intersectX is
            % not NaN), the circles intersect and set is able to
            % communicate.
            if abs(intersectX) >= 0

                combinationAble(i) = 1;
            % If acNr1 and acNr2 have the same current location, the
            % combination is able to communicate.
            elseif abs(flightsData(acNr1(i),14)-flightsData(acNr2(i),14))...
                    < 1e-5 && abs(flightsData(acNr1(i),15)- ...
                    flightsData(acNr2(i),15)) < 1e-5 
                combinationAble(i) = 1;
            %Alliance flights can always communicate through relay,
            %which is provided by the alliance HQ.
            elseif flightsData(acNr1(i),25)==2 && flightsData(acNr2(i),25)==2 && coordination==1
                combinationAble(i) = 1;
            else
                combinationAble(i) = 0;
            end
        end

        % Combine all sets with the booleans with whether they are able to
        % communicate.
        Sets = [combinationSets combinationAble];

        % Remove the combinations of flights that are not allowed to
        % communicate. Temporarily store the combinations in the variable
        % commCandidatesTemp.
        commCandidatesTemp = removerows(Sets,'ind',find(Sets(:,3)<1));
        % Check if any combinations are left.
        if isempty(commCandidatesTemp) == 0       
            % Change how the communication candidates data is represented.
            % The first column of each row indicates a flight's ID, column
            % two and so on indicate the flight ID's of those flights the
            % flight in the first column can communicate with.

            % Remove the third column.
            commCandidatesTemp = commCandidatesTemp(:,1:2);        
            % Determine the unique flight IDs. 
            uniqueCandidates = unique(commCandidatesTemp)';         
            % Reverse the first and second column, and paste them under the
            % original matrix.
            commCandidatesTemp = [commCandidatesTemp ; ...
                commCandidatesTemp(:,2) commCandidatesTemp(:,1)];

            % Determine the flight ID that occurs most often.
            mostOccuringFlightID = mode(commCandidatesTemp(:,1));
            % Count how often this flight ID occurs.
            valueCount = histc(commCandidatesTemp(:,1),mostOccuringFlightID);        
            % Predefine the matrix that will contain all communication
            % candidates.
            communicationCandidates = zeros(length(uniqueCandidates), ...
                valueCount+1);
            % The first column of each row indicates a flight ID.
            communicationCandidates(:,1) = uniqueCandidates;

            % Column two and on indicate the flight ID's of those flights
            % the flight in the first column can communicate with.
            % Loop over all unique flight IDs.
            for i = 1:length(uniqueCandidates)
                % Determine the rows of flight i in the temporary matrix.
                rowsOfFlightI = find(commCandidatesTemp(:,1)== ...
                    uniqueCandidates(i));
                % Determine the flight IDs with which flight i is able to
                % communicate and paste them on column two and on.
                communicationCandidates(i,1:length(rowsOfFlightI)+1) = ...
                    [communicationCandidates(i) ...
                    commCandidatesTemp(rowsOfFlightI,2)'];
                % Sort column two and on in ascending order.
                communicationCandidates(i,2:length(rowsOfFlightI)+1) = ...
                    sort(communicationCandidates(i,2:length(rowsOfFlightI)+1));
            end
        end
    end
end
%% Randomize the starting flight ID in communicationCandidates. 

% This is to ensure that not at every time step flights with lower flight
% IDs benefit from having first pick in determining whether to act as
% manager in the CNP, or auctioneer in the auctions.

% Determine the starting row of communicationCandidates using a uniform
% distribution.
startingRow = randi([1 length(communicationCandidates(:,1))]);
communicationCandidates = [communicationCandidates(startingRow:end,:) ; ...
    communicationCandidates(1:startingRow-1,:)];
end
