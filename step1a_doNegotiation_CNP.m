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
for i = 1:length(communicationCandidates(:,1))   
    % Store flight ID of flight i in variable.
    acNr1 = communicationCandidates(i,1);

    %log that there has been another timestep in which the agent hasnt had a
    %formation
    time_without_deal = flightsData(acNr1,30);
    % Determine the number of communication candidates for flight i.
    nCandidates = nnz(communicationCandidates(i,2:end)); 
    
   %% Determine whether to become manager or contractor
   % So agents can change their type every iteration
    n_managers = 0;
    n_contractors = 0;
    
    %Determine how many managers & contractors there are already in an
    %agent's communication range.
    for j = 2:nCandidates+1
       acNr2 = communicationCandidates(i,j);  

       if(flightsData(acNr2,29)) == 1
           n_managers = n_managers + 1;
       else
           n_contractors = n_contractors + 1;
       end
    end
   
   ratio_managers_contractors = n_managers / (n_contractors + n_managers);
   
   if coordination==1 && flightsData(acNr1,25)==2 %If coordination, all alliance members become contractor
       flightsData(acNr1,29)=0;
       
       %There cant be any outstanding bids made to a contractor, so ditch
       %bids made to acNr1 (if any).
       bidbook(find(bidbook(:,1)==acNr1),:)=0;        
   elseif ratio_managers_contractors < 0.5
       flightsData(acNr1, 29) = 1;
       bidbook(acNr1,:) = zeros(1,12); %managers cannot have outstanding bids, so ditch these.
   end
     
    %% START code for contractors
    % The idea is that contractors go through the following steps:
    % 1) list all managers in the communication range
    % 2) find the manager with which the agent can obtain the best
    % fuelsavings
    % 3) make an offer to this manager, taking into account the amount of
    % competing contractors that the agent can see, and the time that the
    % agent hasnt had a deal.
    
    if(flightsData(acNr1,29)==0)
        clear potentialManagers;
        flightsData(acNr1,30) = flightsData(acNr1,30)+1; %one more timestep w/o deal
        
        
        potentialManagers = zeros(nCandidates,12); %acnr1, acnr2, potentialFuelSavings, divisionFutureSavings, Xjoining, ...
                                                    %Yjoining, Xsplitting, Ysplitting, VsegmentAJ_acNr1, ...
                                                    %VsegmentBJ_acNr2, timeAdded_acNr1, timeAdded_acNr2
        
        for j = 2:nCandidates+1
            % Store flight ID of candidate flight j in variable.
            acNr2 = communicationCandidates(i,j);

            % Check whether the flights are still available for communication.
            if flightsData(acNr1,2) == 1 && flightsData(acNr2,2) == 1             
                % Find if there are any fuelsavings
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
        if any(any(potentialManagers)) == 1 %Check if there are any potential managers at all
            [~, biddingID] = max(potentialManagers(:,3));
            acNr2 = potentialManagers(biddingID,2); %acNr2 = potential manager
            potentialFuelSavings = potentialManagers(biddingID,3); %potential Fuelsavings
            
            %depending on ratio between fuelsavings offered and total fuelsavings, make a bid
            if coordination==1 && flightsData(acNr1,25)==2 %if coordination & alliance
               fuelSavingsOffer = min(0.99,(ratio_managers_contractors/3+flightsData(acNr1,30)/15)-0.2)*potentialFuelSavings; 
            else
                fuelSavingsOffer = min(0.99,(ratio_managers_contractors/3+flightsData(acNr1,30)/15))*potentialFuelSavings; 
            end
            if (flightsData(acNr1,25) == 2 && flightsData(acNr2,25) == 2) %IF Both are alliance
                fuelSavingsOffer = potentialFuelSavings-1; %The program does not support a bid of 100% of potentialFuelSavings, so therefore the "-1".
            end
            
            %make bid with all necessary info
            bid = [potentialManagers(biddingID,2:12), fuelSavingsOffer]; %bid = sync-info from the potentialBid + fuelsavingsoffer
            bidbook(acNr1,:) = bid; %add bid to bidbook
        end
    end %end contractor part
    
    %% START Manager code
    % The manager goes through the following steps:
    % 1) List all bids that are made to me
    % 2) Find bid with the highest fuelsavings offer
    % 3) Analyse if the bid is high enough for me
    % 4) if yes: accept the bid.
    
    if(flightsData(acNr1, 29)==1)
        flightsData(acNr1,30) = flightsData(acNr1,30)+1; %one more timestep w/o deal

        %find bids that are sent to this manager
        receivedBids = find(bidbook(:,1)==acNr1);
        
        if receivedBids > 0 
            accept_deal = 0; %initially, don't accept a deal unless this is changed.
            
            %Step 2: find bid with highest fuelsavingsoffer
            [~, idWinner] = max(bidbook(receivedBids,12)); %get the best bid
            %acNr1 is manager and is already defined
            %acNr2 is contractor and follows from first column of table
            
            acNr2 = receivedBids(idWinner);
                       
            fuelSavingsOffer = bidbook(acNr2,12);
            potentialFuelSavings = bidbook(acNr2,2);

            pctFuelSavingsOffer = fuelSavingsOffer / potentialFuelSavings;

            %If enough fuelsavings are offered to me, accept the dedal.
            if pctFuelSavingsOffer > max(0.01,(1-ratio_managers_contractors-flightsData(acNr1,30)/10))
                accept_deal = 1;
            end
            
            %we stored all sync info in the bidbook, get that.
            divisionFutureSavings = bidbook(acNr2,3);   
            if accept_deal == 1
                step1b_routingSynchronizationFuelSavings %This is sloppy coding, as all data is already in the bidbook. However, removing this line would only lead to 5% less calls to this function, as many more potential bids are analysed, than actual bids. Therefore it is OK for now. 
                if potentialFuelSavings > 0
                    step1c_updateProperties %update the deal properties
                    bidbook(acNr2,:) = 0; %ditch all bids made by acNr2
                    bidbook(receivedBids,:) = 0; %ditch all bids made on me
                    flightsData(acNr1,30) = 0;
                    flightsData(acNr2,30) = 0;
                else
                    bidbook(acNr2,:)=0; %Apparently, this was a bad deal, so discard it.
                end
                %Log that this aircraft has been in a formation
            end
        end
                   
    end
            
    

end
