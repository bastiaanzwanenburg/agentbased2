%% step1a_doNegotiation_Dutch.m description
% Add your Dutch agent models and edit this file to create your Dutch
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
    nCandidates = nnz(communicationCandidates(i,2:end));
    %flightsData(i,29)==1 --> bidder, == 2 --> auctioneer
    
    %% Determine the number of communication candidates for flight i.
    if flightsData(acNr1,29) == 0
        
        nearbyAgents = communicationCandidates(i,2:end);
        nearbyAgents = nearbyAgents(find(nearbyAgents ~=0));
        n_nearbyAuctioneers = length(find(flightsData(nearbyAgents,29)==2));
        n_nearbyBidders = length(find(flightsData(nearbyAgents,29)==1));
        bidders_vs_auctioneers = n_nearbyBidders / (n_nearbyBidders + n_nearbyAuctioneers);
        
        if bidders_vs_auctioneers > 0.5
            %there are more bidders, so become auctioneer
            flightsData(acNr1,29) = 2;
        else
            flightsData(acNr1,29) = 1;
        end
    end
        
              
    %%IF AUCTIONEER%%
    %bidbook = received bids. bidbookID = sending agent. bidbook =
    %(auctioneer, fuelsavingsoffering)
    
    
    if flightsData(acNr1,29) == 2
        accept_deal = 0;
        minFuelSavingsOffer = 5000 - 500*flightsData(acNr1,30); %every timestep without deal, lower the bar
        if (exist('bidbook'))
            receivedBids = find(bidbook(:,1)==acNr1);
            if ~isempty(receivedBids)
                [~, idBestBid] = max(bidbook(receivedBids,2));
                acNr2 = receivedBids(idBestBid);
                if flightsData(acNr1,2) == 1 && flightsData(acNr2,2) == 1
                    fuelSavingsOffer = bidbook(acNr2,2);
                    if fuelSavingsOffer > minFuelSavingsOffer
                        step1b_routingSynchronizationFuelSavings %get all other relevant parameters. This is slower, but works for now.
                        divisionFutureSavings = flightsData(acNr1,19)/ ...
                                (flightsData(acNr1,19) + flightsData(acNr2,19));
                        accept_deal = 1;
                        step1c_updateProperties;
                        flightsData(acNr1,30)=0;                    
                    end
                end
            end
        end
        if accept_deal == 0
            flightsData(acNr1,30) = flightsData(acNr1,30)+1;
        end
    end
    
    if flightsData(acNr1,29) == 1 %if is bidder
        potentialAuctioneers = [];
        % Loop over all candidates of flight i.
        for j = 2:nCandidates+1
            % Store flight ID of candidate flight j in variable.
            acNr2 = communicationCandidates(i,j);  

            % Check whether the flights are still available for
            % communication and whether the other flight is auctioneer
            if flightsData(acNr1,2) == 1 && flightsData(acNr2,2) == 1 && flightsData(acNr2,29) == 2

                % This file contains code to perform the routing and
                % synchronization, and to determine the potential fuel savings.
                step1b_routingSynchronizationFuelSavings

                % If the involved flights can reduce their cumulative fuel burn
                % the formation route is accepted. This shows the greedy
                % algorithm, where the first formation with positive fuel
                % savings is accepted.
                if potentialFuelSavings > 0     
                    % In the greedy algorithm the fuel savings are divided
                    % equally between acNr1 and acNr2, according to the
                    % formation size of both flights. In the auction the value
                    % of fuelSavingsOffer is decided upon by the bidding agent.

                    potentialAuctioneers = [potentialAuctioneers; [acNr2, potentialFuelSavings]];

                end          
            end
        end
    
        %after looping through candidates, find the highest
        if ~isempty(potentialAuctioneers)   

            [~,idBestAuctioneer] = max(potentialAuctioneers(:,2));
            idAuctioneer = potentialAuctioneers(idBestAuctioneer,1);
            potentialFuelSavings = potentialAuctioneers(idBestAuctioneer,2);

            fuelSavingsOffer = min((0.1+0.05*flightsData(acNr1,30)),0.95)*potentialFuelSavings; %avoid bids higher than 95%
            
            bidbook(acNr1,1) = idAuctioneer;
            bidbook(acNr1,2) = fuelSavingsOffer;
            flightsData(acNr1,30) = flightsData(acNr1,30) + 1;
        end
    end          
    
end