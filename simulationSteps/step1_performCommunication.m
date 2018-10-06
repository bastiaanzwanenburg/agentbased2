%% step1_performCommunication.m description
% This file determines the communication candidates for each flight with
% the function determineCommunicationCandidates.m. If communication is
% possible between any combination of two flights the code goes into the
% file step1a_doNegotiation.m to start the negotiation process and possibly
% pick a formation partner.

% It contains one function: determineCommunicationCandidates.m. 
% It contains one file: step1a_doNegotiation_*.m.

%% Determine the possible communication candidates for each flight.

% Determine flights that have departed according to the predefined flight
% schedules. Set property 16 (flight status) of this/these flight(s) to 1
% ("flying").
flightsDeparted = find(flightsData(:,1)>0 & ...
    (flightsData(:, 24)./(dt/60))<=t);      
flightsData(flightsDeparted, 16) = 1;                                           

% At the time step a flight has departed (i.e. has entered the cruise
% phase, and current location equals departure location), it becomes
% available for communication. Set property 2 (communication status) of
% this/these flight(s) to 1 ("available for communication").
flightsData(find(flightsData(:,16)==1 & ...
    flightsData(:,14)==flightsData(:,3)),2) = 1;        

% Determine flights that have arrived. Those have property 18 (arrival
% status) set to 1 ("has arrived"). Set property 16 (flight status) to 0
% ("not flying") for those flights.
flightsArrived = find(flightsData(:,18)==1);
flightsData(flightsArrived,16) = 0;

% Determine which flights are able to communicate.
communicationCandidates = determineCommunicationCandidates(flightsData, ...
    communicationRange);

%% Carry out the negotiation process.
% Only necessary if there are possible communication candidates.
if nnz(communicationCandidates) > 0                          
    step1a_doNegotiation();
end