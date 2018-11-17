%% prep1_setParameters.m description
% In this file you are able to set parameter values to run the
% simulation(s) in the correct set-up.

% It contains no functions or files.

%% Parameters.

% Number of simulation runs.
nSimulations = 5; 

% Value of the maximum communication distance BETWEEN two aircraft [km]. 
communicationRange = 500;                                             

% Percentage of aircraft in simulation that are part of the alliance [%].
percentageAlliance = 40;  

%Time constant (?)
time_constant = 8;

%Coordination
coordination=0;

% Number of aircraft (only for when creating random flight schedules).
nAircraft = 100;    

% Size of time step used in the simulation [s].
dt = 300;                                                   

% Negotiation technique (1: greedy algorithm, 2: CNP, 3: Dutch, 4: English,
% 5: Vickrey, 6: Japanese, 7: first-price sealed-bid).
negotiationTechnique = 2; 

% Visualize the results (0: no visualization, 1: visualization).
visualizationOption = 0;

% Fix the seed of the random number generator (RNG). If fixed, the same
% random flight schedules ('nSimulations' schedules in total) will be
% generated every time. (0: do not fix seed, different random flight
% schedules, 1: fix seed).
booleanFixSeedRng = 0;  