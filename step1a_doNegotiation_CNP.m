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
for i = 1:length(communicationCandidates(:,1))   
    %make new biddingcandidates list in which a contractor can store
    %potential bids
  
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
       
   if ratio_managers_contractors < 0.3
       %if there are only a few managers in the area, become manager
       %and ditch all bids made by me
       flightsData(acNr1, 29) = 1;
       bidbook(acNr1,:) = zeros(1,12);
   end
     
    %START code for contractors
    if(flightsData(acNr1,29)==0)
        clear potentialManagers;
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

                % If the involved flights can reduce their cumulative fuel burn
                % the formation route is accepted. This shows the greedy
                % algorithm, where the first formation with positive fuel
                % savings is accepted.
                if potentialFuelSavings > 0 && timeWithinLimits == 1    
                    % In the greedy algorithm the fuel savings are divided
                    % equally between acNr1 and acNr2, according to the
                    % formation size of both flights. In the CNP the value of
                    % fuelSavingsOffer is decided upon by the contractor agent.
                    divisionFutureSavings = flightsData(acNr1,19)/ ...
                    (flightsData(acNr1,19) + flightsData(acNr2,19));
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
        %but first determine if there are any biddingcandidates at all
        if any(any(potentialManagers)) == 1
            [~, biddingID] = max(potentialManagers(:,3));
            acNr2 = potentialManagers(biddingID,2); %acNr2 = potential manager
            potentialFuelSavings = potentialManagers(biddingID,3); %potential Fuelsavings
            %depending on ratio, make a bid
            if ratio_managers_contractors < 0.33333
                fuelSavingsOffer = potentialFuelSavings * 0.8;
            elseif ratio_managers_contractors < 0.7
                fuelSavingsOffer = potentialFuelSavings * 0.5;
            else
                fuelSavingsOffer = potentialFuelSavings * 0.25;
            end
   

            %make bid with all necessary info
            bid = [potentialManagers(biddingID,2:12), fuelSavingsOffer]; %bid = sync-info from the potentialBid + fuelsavingsoffer
            bidbook(acNr1,:) = bid; %add bid to bidbook
        end
    end %end contractor part
        
    if(flightsData(acNr1, 29)==1)
        %if manager
        % go through received bids
        % accept bids with highest fuel offering

        %find bids that are sent to this contractor
        receivedBids = find(bidbook(:,1)==acNr1);
        if receivedBids > 0 
            %if have received bids, find bid with highest offered
            %fuelsaving
            [~, idWinner] = max(bidbook(receivedBids,2)); %get the best bid
            %acNr1 is manager and is already defined
            %acNr2 is contractor and follows from first column of table
            
            
            acNr2 = receivedBids(idWinner);
            if not(bidbook(acNr2, 1) == acNr1) %acNr1 should be the same, otherwise error.
                fprintf("ERROR");
                break;
            end
            
            %we stored all sync info in the bidbook, get that.
            potentialFuelSavings = bidbook(acNr2,2);
            divisionFutureSavings = bidbook(acNr2,3); 
            Xjoining = bidbook(acNr2,4);
            Yjoining = bidbook(acNr2,5);
            Xsplitting = bidbook(acNr2,6);
            Ysplitting = bidbook(acNr2,7);
            VsegmentAJ_acNr1 = bidbook(acNr2,8);
            VsegmentBJ_acNr2 = bidbook(acNr2,9);
            timeAdded_acNr1 = bidbook(acNr2,10);
            timeAdded_acNr2 = bidbook(acNr2,11);
            fuelSavingsOffer = bidbook(acNr2,12);
         
            
            step1c_updateProperties %do this only if a deal is made

        end
                   
    end
            
    

end