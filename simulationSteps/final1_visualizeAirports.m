%% final1_visualizeAirports.m description
% This file is used to visualize the simulation. In this file the first
% frame is created using flightsDataRecordings, which contains the
% properties of all flights at every time step. Origin and destination
% airports are indicated in blue squares.

% It contains no functions or files.

%% Visualize the first frame with the origin and destination airports.

% Turn on custom data cursor mode.
fig = figure('DeleteFcn','datacursormode on');

% Visualize the origin and destination airports.
scatter([flightsDataRecordings(1,1:nAircraft,3), ...
    flightsDataRecordings(1,1:nAircraft,5)], ...
    [flightsDataRecordings(1,1:nAircraft,4), ...
    flightsDataRecordings(1,1:nAircraft,6)],'filled','s') 

% Set the limits of the plot. 
axis tight;
axis off
set(fig,'color','w')
yLimits=get(gca,'ylim');
xLimits=get(gca,'xlim');

% Plot the time step.
strTimestep = ['t = ',num2str(t)];
text(xLimits(1),yLimits(2),strTimestep)

% Plot the instruction on how to pause.
strPause = "Press 'space' to pause";
text(xLimits(1),yLimits(2)-100,char(strPause))

% Store the frame.
Movie(1) = getframe;  