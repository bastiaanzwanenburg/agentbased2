%% final2_visualizeFlights.m description
% This file is used to visualize the simulation. In this file the frame of
% every time step t is created using flightsDataRecordings, which contains
% the properties of all flights at every timestep t. Origin and destination
% airports are indicated in blue squares, solo flights in green. Cyan dots
% represent solo aircraft that are engaged (i.e. have accepted a formation
% flight and are flying towards the joining point). Cyan dots with a
% magenta edge represent formations that are engaged. Magenta dots
% represent two or more aircraft flying in formation. The size of the
% formation dots indicate the number of aircraft in that formation. The
% time step t is indicated in the upper-left corner. The simulation can be
% paused by pressing �space�.

% It contains no functions or files.

%% Visualize the flights at time step t.

% Visualize the origin and destination airports.
scatter([flightsDataRecordings(1,1:nAircraft,3), ...
    flightsDataRecordings(1,1:nAircraft,5)], ...
    [flightsDataRecordings(1,1:nAircraft,4), ...
    flightsDataRecordings(1,1:nAircraft,6)],'filled','s')

% Set the limits of the plot. 
axis tight
axis off
set(fig,'color','w')
yLimits=get(gca,'ylim');
xLimits=get(gca,'xlim');

hold on

% Visualize the flights  in the air at time step t.
% Loop through all the flights.
for b = 1:length(flightsDataRecordings(t,:,1))                           

    % Only plot flying aircraft. These are the flights with property 16
    % (flying status) set to 1 ("flying").
    if flightsDataRecordings(t,b,16) == 1                                     
        % Select only flights that are not in formation. These are the
        % flights with property 17 (formation status) set to 0 ("not in
        % formation").
        if flightsDataRecordings(t,b,17) == 0                                 
            % Select flights that are engaged. These are the
            % flights with property 2 (communication status) set to 0
            % ("engaged and not available for communication").
            if flightsDataRecordings(t,b,2) == 0                                
                % Differentiate the color of engaged and solo flights,
                % use cyan for engaged flights.
                plot(flightsDataRecordings(t,b,14), ...
                    flightsDataRecordings(t,b,15),'c.','MarkerSize',20)
            % Select flights that are not engaged. These are the
            % flights with property 2 (communication status) set to 1
            % ("available for communication").
            else
                % Differentiate the color of engaged and solo flights,
                % use green for solo flights.
                plot(flightsDataRecordings(t,b,14), ...
                    flightsDataRecordings(t,b,15),'g.','MarkerSize',20)
            end
        end

        % Plot formations of flights. Only plot the formation leader,
        % which are flights with property 21 (in-formation status) set to 2
        % ("formation leader"). Note that these are always dummy
        % flights, which represent the complete formation.           
        if flightsDataRecordings(t,b,21) == 2
            % Determine if the formation is engaged. Note that the marker
            % size is dependent on property 19 (weight factor of the
            % formation).
            if flightsDataRecordings(t,b,2) == 0
                % Use cyan with a magenta edge for formations that are
                % engaged.
                plot(flightsDataRecordings(t,b,14), ...
                flightsDataRecordings(t,b,15),'o','MarkerSize', ...
                7+1*(flightsDataRecordings(t,b,19)-1),'MarkerEdgeColor',...
                'm','MarkerFaceColor','c')          
            else    
                % Use magenta for formations that are not engaged. 
                plot(flightsDataRecordings(t,b,14), ...
                flightsDataRecordings(t,b,15),'o','MarkerSize', ...
                7+1*(flightsDataRecordings(t,b,19)-1),'MarkerEdgeColor',...
                'm','MarkerFaceColor','m')
            end
        end
    end
end

hold off

% Plot the time step.
strTimestep = ['t = ',num2str(t)];
text(xLimits(1),yLimits(2),strTimestep)

% Plot the instruction on how to pause.
strPause = "Press 'space' to pause";
text(xLimits(1),yLimits(2)-100,char(strPause))

% Store the properties of each flight.
currentProperties = squeeze(flightsDataRecordings(t,:,:));
% Add the flight ID to the data tip.
dcm_obj = datacursormode(fig);
set(dcm_obj,'UpdateFcn',{@myupdatefcn,currentProperties})

% Pausing the simulation if space bar is pressed.
hManager = uigetmodemanager(fig);
% Turn off warning when data tip mode is active when pausing.
[hManager.WindowListenerHandles.Enabled] = deal(false); 
set(fig, 'WindowKeyPressFcn', @keyPressCallback);

% Store the frame.
Movie(t) = getframe;

% Slow the visualization in the initial stage when few flights are active.
if t < 20
    pause(0.2);
end

% Customize the text of data tips. Adds properties to the data tip. 
function txt = myupdatefcn(~,event_obj,k)
pos = get(event_obj,'Position');
% Find the flight ID corresponding to the coordinates of the dot you
% clicked.
flightID = find(k(:,14) >= pos(1)-0.01 & k(:,14) < pos(1)+0.01 & ...
    k(:,15) >= pos(2)-0.01 & k(:,15) < pos(2)+0.01, 1, 'last' );
weight = k(:,19);
weight = weight(flightID);
engaged = k(:,20);
engaged = engaged(flightID);
alliance = k(:,25);
alliance = alliance(flightID);

if alliance == 1
    alliance = char(strcat(num2str(alliance), ' (non-alliance)'));
elseif alliance == 2
    alliance = char(strcat(num2str(alliance), ' (alliance)'));
else
    alliance = char(strcat(num2str(alliance), ' (dummy)'));
end
maxDelay = k(:,26);
maxDelay = maxDelay(flightID);
txt = {['ID: ',num2str(flightID)],...
       ['Engaged to: ',num2str(engaged)],...
       ['Form. size: ',num2str(weight)],...
       ['Alliance: ',alliance],...
       ['Max. delay: ',num2str(maxDelay)]};
end

% Pausing the simulation.
function keyPressCallback(source,eventdata)
  % Determine the key that is pressed.
  keyPressed = eventdata.Key;
  if strcmpi(keyPressed,'space')
      % If the key that is pressed is the space bar, pause the simulation
      % at line 151 of simulation_main.m.
      dbstop in simulation_main at 151
  end
end