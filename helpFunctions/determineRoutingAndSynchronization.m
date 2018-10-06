function [Xjoining,Yjoining,Xsplitting,Ysplitting,VsegmentAJ_acNr1, ...
    VsegmentBJ_acNr2,syncPossible,timeAdded_acNr1,timeAdded_acNr2] = ...
    determineRoutingAndSynchronization(wAC,wBD,wDuo,Xordes,Yordes,Vmin, ...
    Vmax)
%% determineRoutingAndSynchronization.m description
% Determines an initial joining and splitting point for a formation flight
% route of flight 1 and 2 in determineGeometricRouting.m. Then
% synchronizeRouting.m contains a synchronization algorithm that changes
% the speeds of the two (groups of) flights to ensure that they arrive at
% the joining point at the same time. This algorithm also may change the
% location of the joining point when speed changes alone are not
% sufficient. Lastly, the additional flight time due to this potential
% formation is calculated.

% inputs:
% wAC (weight factor of flight 1 from point A to C),
% wBD (weight factor of flight 2 from point B to D),
% wDuo (weight factor of the formation flight segment),
% Xordes (current and destination x-coordinates of both aircraft),
% Yordes (current and destination y-coordinates of both aircraft),
% Vmin,
% Vmax.

% outputs: 
% Xjoining (x-coordinate of the joining point),
% Yjoining,
% Xsplitting, 
% Ysplitting,
% VsegmentAJ_acNr1 (speed from current location to joining point),
% VsegmentBJ_acNr2 (speed from current location to joining point),
% syncPossible (boolean whether synchronization is possible),
% timeAdded_acNr1 (additional flight time due to this formation),
% timeAdded_acNr2 (additional flight time due to this formation).

% special cases: 
% -

% It contains two functions: determineGeometricRouting.m and
% synchronizeRouting.m.

%% Determine joining and splitting points, synchronize routing if possible.

% Determines the joining- and splitting point for a flight formation route
% of flight 1 and 2.
[Xjoining,Yjoining,Xsplitting,Ysplitting] = ...
    determineGeometricRouting(wAC,wBD,wDuo,Xordes,Yordes);      

% Determine if synchronization (joining of the two flights) is possible
% before the intended splitting point. See Ch. 6.1.4 of Verhagen's thesis
% for more information.

% Length of segment from current location of flight 1 to splitting point.
segmentAS = sqrt((Xordes(1)-Xsplitting).^2 + (Yordes(1)-Ysplitting).^2);
% Length of segment from current location of flight 2 to splitting point.
segmentBS = sqrt((Xordes(2)-Xsplitting).^2 + (Yordes(2)-Ysplitting).^2);

% Check if synchronization is possible before the intented splitting point.
% If so, calculate the required joining point, and the speed of each flight
% from its current location to that joining point.
if segmentAS/segmentBS > Vmax/Vmin || segmentAS/segmentBS < Vmin/Vmax
    % Synchronization not possible before the intended splitting point.
    syncPossible = 0;
    VsegmentAJ_acNr1 = Vmax;
    VsegmentBJ_acNr2 = Vmax;
    % Set the joining- and splitting point coordinates to impossible
    % values as a safeguard to prevent this route to be selected. 
    Xjoining = -99999; 
    Yjoining = -99999;
    Xsplitting = -99999;
    Ysplitting = -99999;
else
    % Calculate the required joining point, and the speed of each flight
    % from its current location to that joining point.
    [Xjoining,Yjoining,VsegmentAJ_acNr1,VsegmentBJ_acNr2,syncPossible] ...
        = synchronizeRouting(Xjoining,Yjoining,Xsplitting,Ysplitting, ...
        Xordes,Yordes,Vmin,Vmax);
end
   
%% Determine additional flight time due to this potential formation flight.

% Find the to be flown segment lengths.
% JS: joining point to splitting point.
segmentJS = sqrt((Xsplitting-Xjoining).^2 + (Ysplitting -Yjoining ).^2);  
% AJ: current location of flight 1 to joining point.
segmentAJ = sqrt((Xordes(1)-Xjoining ).^2 + (Yordes(1)-Yjoining ).^2);
% BJ: current location of flight 2 to joining point.
segmentBJ = sqrt((Xordes(2)-Xjoining ).^2 + (Yordes(2)-Yjoining ).^2);
% SC: splitting point to destination of flight 1.
segmentSC = sqrt((Xordes(3)-Xsplitting ).^2 + (Yordes(3)-Ysplitting ).^2);
% SD: splitting point to destination of flight 2.
segmentSD = sqrt((Xordes(4)-Xsplitting ).^2 + (Yordes(4)-Ysplitting ).^2);
% AC: Solo, current location of flight 1 to destination of flight 1.
segmentAC = sqrt((Xordes(3) - Xordes(1))^2 + (Yordes(3)-Yordes(1))^2);
% BD: Solo, current location of flight 2 to destination of flight 2.
segmentBD = sqrt((Xordes(4) - Xordes(2))^2 + (Yordes(4)-Yordes(2))^2);

% Determine the total solo flight time [s].                                        
timeSolo_acNr1 = 1000*segmentAC/Vmax;                                     
timeSolo_acNr2 = 1000*segmentBD/Vmax;                               

% Determine the total flight time when the formation is accepted [s].
timeFormation_acNr1 = 1000*segmentAJ/VsegmentAJ_acNr1 + ...
    1000*segmentJS/Vmax + 1000*segmentSC/Vmax;       
timeFormation_acNr2 = 1000*segmentBJ/VsegmentBJ_acNr2 + ...
    1000*segmentJS/Vmax + 1000*segmentSD/Vmax;       

% Determine the added flight time [min].
timeAdded_acNr1 = (timeFormation_acNr1 - timeSolo_acNr1)/60;            
timeAdded_acNr2 = (timeFormation_acNr2 - timeSolo_acNr2)/60;      

end