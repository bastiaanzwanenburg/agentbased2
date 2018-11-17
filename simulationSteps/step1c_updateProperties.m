%% step1c_updateProperties.m description
% This file contains code to update the relevant properties of the two
% flights that have accepted a formation.

% Make sure that the following variables are assigned to those belonging to
% the combination of the manager/auctioneer agent (acNr1) and the winning
% contractor/bidding agent (acNr2): acNr2, fuelSavingsOffer,
% divisionFutureSavings. Also: Xjoining, Yjoining, Xsplitting, Ysplitting,
% VsegmentAJ_acNr1, VsegmentBJ_acNr2, timeAdded_acNr1, timeAdded_acNr2,
% potentialFuelSavings. These variables follow from
% step1b_routingSynchronizationFuelSavings.m and differ for every
% combination of acNr1 and acNr2.

% One way of doing this is storing them as part of the bid, and then
% defining them again when the manager awards the contract in the CNP/the
% winning bid is selected in the auctions.

%% Update the relevant flight properties if formation is accepted.
%LOG THE DEAL
distanceBetweenDealmakers = sqrt( (flightsData(acNr1,14)-flightsData(acNr2,14))^2 +(flightsData(acNr1,15)-flightsData(acNr2,15))^2);
dealLog = [dealLog; [acNr1, acNr2,potentialFuelSavings,fuelSavingsOffer,potentialFuelSavings, t, Xjoining, Yjoining, distanceBetweenDealmakers]];
if Xjoining < -5*10e3
    'pause'
end
if distanceBetweenDealmakers > 75.2 && distanceBetweenDealmakers < 75.4
    if flightsData(acNr1,3)==flightsData(acNr2,3) && flightsData(acNr1,4)==flightsData(acNr1,4)
    same = same+1;
    else
        different=different+1;
    end
end

% Add the potential fuel savings that are realized now the formation is
% accepted to the total fuel savings.
fuelSavingsTotal = fuelSavingsTotal + ...
    potentialFuelSavings;

% Store how much of the cumulative fuel savings go to acNr1 and acNr2.  
flightsData(acNr1,27) = fuelSavingsOffer; 
flightsData(acNr2,27) = potentialFuelSavings - fuelSavingsOffer;
% Store how fuel savings from future formations will be distributed
% between acNr1 and acNr2.
flightsData(acNr1,28) = divisionFutureSavings;
flightsData(acNr2,28) = 1 - divisionFutureSavings;

% Adopt the joining- and splitting point in the flight plans of both
% flights in the flightsData matrix.
flightsData(acNr1,9:12) = [Xjoining,Yjoining,Xsplitting, ...
    Ysplitting];                  
flightsData(acNr2,9:12) = [Xjoining,Yjoining,Xsplitting, ...
    Ysplitting];
% Both flights are marked as engaged and are not available for
% communication until they reach the joining point.
flightsData(acNr1,2) = 0;                                                          
flightsData(acNr2,2) = 0;
% Set the speed of the flights as determined in the synchronization
% algorithm.
flightsData(acNr1,7) = VsegmentAJ_acNr1;                                                                                   
flightsData(acNr2,7) = VsegmentBJ_acNr2;
% Set the new heading change for synchronization. Start flying from the
% current location to the joining point.
flightsData(acNr1,8) = (flightsData(acNr1,10)- ...
    flightsData(acNr1,15))/(flightsData(acNr1,9)- ...
    flightsData(acNr1,14)); 
flightsData(acNr2,8) = (flightsData(acNr2,10)- ...
    flightsData(acNr2,15))/(flightsData(acNr2,9)- ...
    flightsData(acNr2,14));
% Record the engagement between the two flights.
flightsData(acNr1,20) = acNr2;                                                                                 
flightsData(acNr2,20) = acNr1;
% Adjust the max. delay the flights can accept after this formation. 
flightsData(acNr1,26) = flightsData(acNr1,26) - timeAdded_acNr1;
flightsData(acNr2,26) = flightsData(acNr2,26) - timeAdded_acNr2;