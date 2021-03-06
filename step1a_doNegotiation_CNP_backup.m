%% step1a_doNegotiation_CNP.m description
%GIT TEST
% Add your CNP agent models and edit this file to create your CNP.

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
%blalballa

%bidbook = zeros(nAircraft*3,12);
for i = 1:length(communicationCandidates(:,1))
    
    
    
    % Store flight ID of flight i in variable.
    acNr1 = communicationCandidates(i,1);
    
    % Determine the number of communication candidates for flight i.
    nCandidates = nnz(communicationCandidates(i,2:end));
    
    % determine if a flight should become manager
    n_managers = 0;
    n_contractors = 0;
    for j = 2:nCandidates+1
        %determine contractor/manager ratio
        acNr2 = communicationCandidates(i,j);
        
        if(flightsData(acNr2,29)) == 1
            n_managers = n_managers + 1;
        else
            n_contractors = n_contractors + 1;
        end
    end
    ratio_managers_contractors = n_managers / (n_contractors + n_managers);
    
     
    if coordination==1 && flightsData(acNr1,25)==2 %If coordiation, all alliance members become manager
        flightsData(acNr1,29)=1;
        bidbook(acNr1,:) = zeros(1,12); %managers cannot have outstanding bids, so ditch these

    elseif ratio_managers_contractors < 0.5
        %if there are only a few managers in the area, become manager
        flightsData(acNr1, 29) = 1;
        bidbook(acNr1,:) = zeros(1,12); %managers cannot have outstanding bids, so ditch these
    end
    
    % This is something that we used to have in the model, but worsened system performance by about 20%
    % If no deal for a long time;
    time_without_deal = flightsData(acNr1,30);
    if (time_without_deal > 7+8*rand) && coordination==0 %between 7 and 15s
        %Then change
        if flightsData(acNr1,29) == 0
            bidbook(acNr1,:) = zeros(1,12);
            flightsData(acNr1,30) = 1;
        else
            bidbook(find(bidbook(:,1)==acNr1),:)=0;
            
            flightsData(acNr1,30) = 0;
        end
    end
    
    
    %should change.
    
    %% START code for contractors
    if(flightsData(acNr1,29)==0)
        clear potentialManagers;
        flightsData(acNr1,30) = flightsData(acNr1,30)+1;
        
        
        potentialManagers = zeros(nCandidates,12); %acnr1, acnr2, potentialFuelSavings, divisionFutureSavings, Xjoining, ...
        %Yjoining, Xsplitting, Ysplitting, VsegmentAJ_acNr1, ...
        %VsegmentBJ_acNr2, timeAdded_acNr1, timeAdded_acNr2
        
        for j = 2:nCandidates+1
            % Store flight ID of candidate flight j in variable.
            acNr2 = communicationCandidates(i,j);
            
            % Check whether the flights are still available for communication.
            if flightsData(acNr1,2) == 1 && flightsData(acNr2,2) == 1
                % This file contains code to perform the routing and
                % synchronization, and to determine the potential fuel savings.
                step1b_routingSynchronizationFuelSavings
                
                
                
                if potentialFuelSavings > 0 && flightsData(acNr2,29)==1
                    % In the greedy algorithm the fuel savings are divided
                    % equally between acNr1 and acNr2, according to the
                    % formation size of both flights. In the CNP the value of
                    % fuelSavingsOffer is decided upon by the contractor agent.
                    
                    divisionFutureSavings = flightsData(acNr1,19)/ ...
                        (flightsData(acNr1,19) + flightsData(acNr2,19)); %This is the same as in the greedy
                    
                    potentialBid = [acNr1, acNr2, potentialFuelSavings, divisionFutureSavings, Xjoining, ...
                        Yjoining, Xsplitting, Ysplitting, VsegmentAJ_acNr1, ...
                        VsegmentBJ_acNr2, timeAdded_acNr1, timeAdded_acNr2]; %save these in the bid so we don't need to do routing-sync again
                    %acNr1 = bidding agent
                    %acNr2 = potential manager
                    potentialManagers = [potentialManagers; potentialBid];
                end
            end
        end
        
        %get manager with best fuelsaving and make bid
        if any(any(potentialManagers)) == 1 %Check if there are any potential managers
            [~, biddingID] = max(potentialManagers(:,3));
            acNr2 = potentialManagers(biddingID,2); %acNr2 = potential manager
            potentialFuelSavings = potentialManagers(biddingID,3); %potential Fuelsavings
            %depending on ratio, make a bid
            
            fuelSavingsOffer = min(0.99,(ratio_managers_contractors/2+flightsData(acNr1,30)/time_constant))*potentialFuelSavings; %so if there are more managers, bid lesss
            if (flightsData(acNr1,25) == 2 && flightsData(acNr2,25) == 2) %IF Both are alliance
                fuelSavingsOffer = potentialFuelSavings;
            end
            %make bid with all necessary info
            bid = [potentialManagers(biddingID,2:12), fuelSavingsOffer]; %bid = sync-info from the potentialBid + fuelsavingsoffer
            bidbook(acNr1,:) = bid; %add bid to bidbook
        end
    end %end contractor part
    
    %% MANAGER PART
    
    if(flightsData(acNr1, 29)==1)
        flightsData(acNr1,30) = flightsData(acNr1,30)+1; %one more timestep w/o deal
        
        %if manager
        % go through received bids
        % accept bids with highest fuel offering if it is viable
        
        %find bids that are sent to this contractor
        receivedBids = find(bidbook(:,1)==acNr1);
        
        if receivedBids > 0
            accept_deal = 0; %initially, don't accept a deal unless this is changed.
            %if have received bids, find bid with highest offered
            %fuelsaving
            [~, idWinner] = max(bidbook(receivedBids,12)); %get the best bid
            %acNr1 is manager and is already defined
            %acNr2 is contractor and follows from first column of table
            
            acNr2 = receivedBids(idWinner);
            
            fuelSavingsOffer = bidbook(acNr2,12);
            potentialFuelSavings = bidbook(acNr2,2);
            
            pctFuelSavingsOffer = fuelSavingsOffer / potentialFuelSavings;
            %if more managers than contractors, be greedy
            
            %if coordination is on, only accept good deals
            if pctFuelSavingsOffer > max(0.01,1-flightsData(acNr1,30)/25) && coordination==1
                accept_deal = 1;
            elseif pctFuelSavingsOffer > max(0.01,(1-ratio_managers_contractors/3-flightsData(acNr1,30)/15))
                accept_deal = 1;
            end
            
            %we stored all sync info in the bidbook, get that.
            divisionFutureSavings = bidbook(acNr2,3);
            if accept_deal == 1 && flightsData(acNr1, 1) == acNr1 && flightsData(acNr2,1) == acNr2
                step1b_routingSynchronizationFuelSavings
                step1c_updateProperties %do this only if a deal is made
                bidbook(acNr2,:) = 0; %ditch all bids made by acNr2
                bidbook(receivedBids,:) = 0; %ditch all bids made on me
                flightsData(acNr1,30) = 0;
                flightsData(acNr2,30) = 0;
                %Log that this aircraft has been in a formation
                %dealLog = [dealLog; [acNr1, acNr2,potentialFuelSavings,fuelSavingsOffer,potentialFuelSavings, t]];
            end
        end
        
    end
    
    
    
end
