step1b_routingSynchronizationFuelSavings


maxDelay_acNr1 = flightsData(acNr1,26);
maxDelay_acNr2 = flightsData(acNr2,26); %this is unknown for acNr1

pctDelay_acNr1 = timeAdded_acNr1/maxDelay_acNr1;
pctDelay_acNr2 = timeAdded_acNr2/maxDelay_acNr2; %this is unkown for acNr1

time_without_deal_acNr1 = flightsData(acNr1,30); %dit is unknown voor acNr2

%It can never be more than potentialFuelSavings

time_constant_dealless = 4;
time_constant_delay = 9;

factor_no_deal = 1-exp(-time_without_deal_acNr1/time_constant_dealless);
factor_delay = exp(-pctDelay_acNr1/time_constant_delay);

bothAlliance = (flightsData(acNr1,25)==flightsData(acNr1,25));

if potentialFuelSavings==0
    trueValue = 0;
elseif valueForBidder==1 && bothAlliance
    trueValue = potentialFuelSavings;
elseif valueForBidder==0 && bothAlliance
    trueValue = 0;
elseif valueForBidder==1
    trueValue = potentialFuelSavings*factor_no_deal*factor_delay;
else
    trueValue = potentialFuelSavings*(1-factor_no_deal); %auctinoeer neemt geen delay mee; arbitrarily
end

pctTrueValueAuctioneer = factor_no_deal*factor_delay;
