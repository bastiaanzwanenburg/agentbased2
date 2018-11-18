%% step1a_doNegotiation_Dutch.m description
% Add your Dutch agent models and edit this file to create your English
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
    %% Determine whether to become auctioneer or bidder
    n_auctioneers = 0;
    n_bidders = 0;

    for j = 2:nCandidates+1
        acNr2 = communicationCandidates(i,j);
        
        if(flightsData(acNr2,29)) == 1
            n_auctioneers = n_auctioneers + 1;
        else
            n_bidders = n_bidders + 1;
        end
    end
    
    ratio_auctioneers_bidders = n_auctioneers / (n_auctioneers + n_bidders);

    if flightsData(acNr1,25)==2 && coordination==1
        flightsData(acNr1,29)=0; %alliance agents always become bidders if coordination is on
    elseif ratio_auctioneers_bidders < 0.5
        flightsData(acNr1, 29) = 1; %otherwise, just look at other agents in communication range
    end
    
    %% Start deal-making process: so we only simulate the auctioneer, who ...
    % asks every bidder in his proximity what he wants to bid, and then
    % makes a deal.
    
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
                
                % Calculate true value for the bidder, and consecutively
                % the actual bid.
                step1aa_calcTrueValue %acNr1 is auctioneer, acNr2 is bidder
                if trueValue > 0 
                    bid = trueValue*exp(-(nCandidates)/10);
                    if flightsData(acNr1,25)==2 && flightsData(acNr2,25)==2
                        bid = trueValue;
                    end
                    if flightsData(acNr1,29)==0 && coordination==1
                        bid = 0.75*bid;
                    end
                    % store the bid
                    receivedBids = [receivedBids; [acNr2, bid, potentialFuelSavings]];
                end
                
            end
        end
        
        %now do the auction itself, but only if the auctioneer has received
        %any bids.
       
        if ~isempty(receivedBids)
            
            valueForBidder = 0; %this is an input for calcTrueValue --> so it will see acnr1 as auctioneer
            step1aa_calcTrueValue
            
            averageFuelSavings = mean(receivedBids(:,3));
            minimum_bid = averageFuelSavings*pctTrueValueAuctioneer;
            
            % the auction starts at 10x the time of the minimum bid
            auction_value = 10*minimum_bid;
            
            % and goes on until the auctioneer has reached its minimum
            % value. 
            
            while minimum_bid <= auction_value
                possible_bidders = find(receivedBids(:,2)>auction_value);
                
                if ~isempty(possible_bidders) %if there are bidders who've bid at least the auction value
                    winner = receivedBids(possible_bidders,1); %then the highest bid wins
                    acNr2 = winner(1); %in case of a tie, make an arbitrary split
                    fuelSavingsOffer = auction_value;
                    auction_value = -1; %to stop the auction (while loop)
                    
                    step1b_routingSynchronizationFuelSavings %once again find deal properties
                    divisionFutureSavings = flightsData(acNr1,19)/ ...
                        (flightsData(acNr1,19) + flightsData(acNr2,19)); 
                    step1c_updateProperties %and make the actual dela
                    flightsData(acNr1,30)=0; 
                    flightsData(acNr2,30)=0;
                    
                end
                auction_value = auction_value*0.95; %decrease the auction value by an increment.
            end
        end
        
       
      
    end
end
