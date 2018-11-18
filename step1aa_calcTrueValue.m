%% Start of step1aa_calcTrueValue.m
% This program calculates the true value for bidders, and the reserve
% price for auctioneers in the auctions. It calls on one function: step1b_routingSynchronizationFuelSavings
% and the program has two outputs: trueValue (for bidders) and
% pctTrueValueAuctioneer (for auctioneers).

step1b_routingSynchronizationFuelSavings


maxDelay_acNr1 = flightsData(acNr1,26);
maxDelay_acNr2 = flightsData(acNr2,26); %this is unknown for acNr1

pctDelay_acNr1 = timeAdded_acNr1/maxDelay_acNr1;
pctDelay_acNr2 = timeAdded_acNr2/maxDelay_acNr2; %this is unkown for acNr1

time_without_deal_acNr1 = flightsData(acNr1,30); %this is unknown voor acNr2

time_constant_dealless = 6;
time_constant_delay = 6;

factor_no_deal = 1-exp(-time_without_deal_acNr1/time_constant_dealless);
factor_delay = exp(-pctDelay_acNr1/time_constant_delay);

bothAlliance = (flightsData(acNr1,25)==2 && flightsData(acNr2,25) ==2);

if potentialFuelSavings==0
    trueValue = 0;
elseif bothAlliance
    trueValue = potentialFuelSavings;
else 
    trueValue = potentialFuelSavings*factor_no_deal*factor_delay;
end

pctTrueValueAuctioneer = max(0.01, 1-factor_no_deal*factor_delay);
