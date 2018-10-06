%% prep2_fixedParameters.m description
% This file sets the values of simulation and parameter values that don't
% require change for the different exercises.

% It contains no functions or files.

%% Parameter values.

% Store negotiation technique file names.
negotiationFiles = ["step1a_doNegotiation_greedy";
    "step1a_doNegotiation_CNP";
    "step1a_doNegotiation_Dutch";
    "step1a_doNegotiation_English";
    "step1a_doNegotiation_Vickrey";
    "step1a_doNegotiation_Japanese";
    "step1a_doNegotiation_first"];

% Fuel parameters.
MFuelSolo = 140;                                                            % M-value solo/leader aircraft at Vmax. During flight, the fuel consumption of an aircraft is governed by these M-values. For more information, see Ch. 5.3.2 of Verhagen's thesis.
MFuelTrail = 158;                                                           % M-value trailing aircraft at Vmax. For more information, see Ch. 5.3.2 of Verhagen's thesis.
fuelPenalty = 0.09;                                                         % This fuel penalty ensures that slowing down to Vmin (maximum endurance speed) leads to an increase in fuel consumption of 10%. The code linearly interpolates less severe decelerations into M-values. For more information, see Ch. 5.3.2 of Verhagen's thesis.

% Formation flight parameters.
wTrail = 0.87;                                                              % Weight factor for the formation flying segment that represents the advantage of flying with a formation of two instead of solo. Used for routing of formation flight missions that leads to highest overall fuel savings. For more information, see Ch. 6.1.3 of Verhagen's thesis.
wMulti = 0.035;                                                             % This factor controls the increase in wDuo as the amount of followers increases. The reason for this is that it is relatively less rewarding to re-route larger formations. For more information, see Ch. 6.1.3 of Verhagen's thesis.                                                                        

% Aircraft parameters.
Wfinal = 171150;                                                            % Zero Fuel Weight (ZFW) + Maximum Payload Weight of every aircraft after a complete solo flight [kg].
Vmin = 207;                                                                 % Vmin, maximum endurance speed [m/s]. 
Vmax = 251;                                                                 % Vmax [m/s].   

% Random flight schedule parameters: Means and standard deviations of x-
% and y-coordinates for the creation of normally distributed random origin
% and destination airports [km].
muOriginX = -3550;
stddevOriginX = 750; 
muOriginY = -850;
stddevOriginY = 750;
muDestX = 3200;
stddevDestX = 500;
muDestY = 850;
stddevDestY = 500;

% Random flight schedule parameters: The initial maximum delay that a
% flight can accept for future formations is a random integer between 15
% and 45 [min.].
minInitialDelay = 15;
maxInitialDelay = 45;

% Random flight schedule parameters: Average flights per airport, based on
% a typical day of eastbound transatlantic flights. Used to determine the
% number of airports in the random flight schedule [flights/airport].
flightsPerAirportAmericas = 5.9;
flightsPerAirportEuro = 8.7;

% Check whether to fix the seed of the random number generator (RNG).
if booleanFixSeedRng == 1  
    % Set the seed for the RNG.
    rng(0);
end