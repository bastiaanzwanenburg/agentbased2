%% step1a_doNegotiation_Vickrey.m description
% Add your Vickrey agent models and edit this file to create your English
% auction.

% This file uses the matrix generated in determineCommunicationCandidates.m
% (in step1_performCommunication.m) that contains every communication
% candidate for each flight. The function
% determineRoutingAndSynchronization.m then determines if formation is
% possible for a pair of flights, the optimal joining- and splitting point,
% and what their respective speeds should be towards the joining point to
% arrive at the same time. The function calculateFuelSavings.m then
% determines how much cumulative fuel is saved when accepting this
% formation flight. If accepted, the properties in flightsData (the matrix
% that contains all information of each flight) for both flights are
% updated in step1c_updateProperties.m.

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

% It contains two files: step1b_routingSynchronizationFuelSavings.m
% (determineRoutingAndSynchronization.m, calculateFuelSavings.m) and
% step1c_updateProperties.m.

%% Loop through the combinations of flights that are allowed to communicate.

for i = 1:length(communicationCandidates(:,1))
    % Store flight ID of flight i in variable.
    acNr1 = communicationCandidates(i,1);
    flightsData(acNr1,30)=flightsData(acNr1,30)+1;
    % Determine the number of communication candidates for flight i.
    nCandidates = nnz(communicationCandidates(i,2:end));
    
    n_auctioneers = 0;
    n_bidders = 0;
    
    for j = 2:nCandidates+1
        %determine auctioneer/bidder ratio
        acNr2 = communicationCandidates(i,j);
        
        if(flightsData(acNr2,29)) == 1
            n_auctioneers = n_auctioneers + 1;
        else
            n_bidders = n_bidders + 1;
        end
    end
    ratio_auctioneers_bidders = n_auctioneers / (n_auctioneers + n_bidders);

    
    if flightsData(acNr1,25)==2 && coordination==1
        flightsData(acNr1,29)=0; %always become bidder
    elseif ratio_auctioneers_bidders < 0.5
        flightsData(acNr1, 29) = 1; %so this can change every iteration
    end
    
    
    if flightsData(acNr1,29)==1 %if is auctioneer
        receivedBids = []; %bids: [acNr2, bid]
        
        % Loop over all candidates of flight i.
        for j = 2:nCandidates+1
            % Store flight ID of candidate flight j in variable.
            acNr2 = communicationCandidates(i,j);
            
            % Check whether the flights are still available for
            % communication and whether the other agent is bidder
            if flightsData(acNr1,2) == 1 && flightsData(acNr2,2) == 1 && flightsData(acNr2,29)==0
                % This file contains code to perform the routing and
                % synchronization, and to determine the potential fuel
                % savings.
                valueForBidder = 1;
                step1aa_calcTrueValue %acNr1 is auctioneer, acNr2 is bidder
                if trueValue > 0 %this is the truevalue that the bidder wants to pay to the auctioneer
                    bid = trueValue*exp(-(nCandidates)/10);
                    
                    if flightsData(acNr1,25)==2 && flightsData(acNr2,25)==2
                        bid = trueValue;
                    elseif flightsData(acNr1,29)==0 && coordination==1
                        bid = 0.75*bid;
                    end
                    receivedBids = [receivedBids; [acNr2, bid, potentialFuelSavings]];
                end
                % Update the relevant flight properties for the formation
                % that is accepted.
                %step1c_updateProperties
            end
        end
        %now do the auction itself. 
       
        if ~isempty(receivedBids)
            %bid continuously goes up, starting at the True Value of an
            %auctioneer
            valueForBidder = 0; %this is an input for calcTrueValue --> so it will see acnr1 as auctioneer
            step1aa_calcTrueValue
            reserveValue = trueValue;
            
            %It is not necessary to go through the loop: the highest bid,
            %that is higher than the minimum value, is the winner
            possible_bidders = find(receivedBids(:,2)>reserveValue);
            
            if ~isempty(possible_bidders) && length(receivedBids(:,1))>=2
                [~, idBestBid] = max(receivedBids(possible_bidders,2));
                acNrWinner = receivedBids(possible_bidders(idBestBid),1);
                bids = receivedBids(:,2);
                
                fuelSavingsOffer = max(bids(bids<max(bids))); %gets the second highest bid (https://nl.mathworks.com/matlabcentral/answers/78278-how-to-find-second-largest-value-in-an-array)
                if isempty(fuelSavingsOffer) && receivedBids(1,2)==receivedBids(2,2) %edge-case: if both bids are the same
                    fuelSavingsOffer = receivedBids(1,2); %doesnt matter which one you choose.
                end
                    
                    
                acNr2 = acNrWinner;
                step1b_routingSynchronizationFuelSavings
                divisionFutureSavings = flightsData(acNr1,19)/ ...
                    (flightsData(acNr1,19) + flightsData(acNr2,19));
                step1c_updateProperties
                flightsData(acNr1,30)=0;
                flightsData(acNr2,30)=0;
            end

        end
    end
end
