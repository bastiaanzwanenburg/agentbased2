function [Xjoining,Yjoining,VsegmentAJ_acNr1,VsegmentBJ_acNr2, ...
    syncPossible] = synchronizeRouting(Xjoining,Yjoining,Xsplitting, ...
    Ysplitting,Xordes,Yordes,Vmin,Vmax)
%% synchronizeRouting.m description
% The synchronization algorithm is able to change the speeds of the two
% (groups of) flights as well as the location of the joining point, in
% order to realize synchronization. It determines which flight has to be
% delayed to achieve synchronization. If synchronization is not possible,
% the boolean syncPossible will be set to 0 (false) and the formation
% flight option will no longer be considered.

% inputs:
% Xjoining (x-coordinate of the joining point),
% Yjoining,
% Xsplitting, 
% Ysplitting,
% Xordes (current and destination x-coordinates of both aircraft),
% Yordes (current and destination y-coordinates of both aircraft),
% Vmin,
% Vmax.

% outputs: 
% Xjoining (x-coordinate of the joining point),
% Yjoining,
% VsegmentAJ_acNr1 (speed from current location to joining point),
% VsegmentBJ_acNr2 (speed from current location to joining point),
% syncPossible (boolean whether synchronization is possible).

% special cases:
% * It has been decided that in this work, the new joining point has to be
% chosen on the original formation flight segment. Note that moving the
% joining point over the formation flight segment towards the splitting
% point may render the new formation route sub-optimal with respect to
% weighted distance. The major advantage of moving J over the formation
% flight segment towards S, is that an exact method allows for direct
% determination of the new joining point. It is compact and does not
% require any optimisation. These properties are desirable for the
% synchronization function, as it will be used to evaluate thousands of
% optional formation flight routes.
% * Only considered is delaying flights, as speeding up is unlikely to be
% fuel efficient at M0.85.


%%  Determine which flight should be delayed.

% Length of segment from current location of flight 1 to joining point.
segmentAJ = sqrt((Xordes(1)-Xjoining).^2 + (Yordes(1)-Yjoining).^2);
% Length of segment from current location of flight 2 to joining point.
segmentBJ = sqrt((Xordes(2)-Xjoining).^2 + (Yordes(2)-Yjoining).^2);

% Determine which flight should be delayed.
if segmentAJ>segmentBJ
    acNrRequiringDelay = 2;
else
    acNrRequiringDelay = 1;
end

% Determine the longest and shortest segment.
longestSegment = max(segmentAJ,segmentBJ);
shortestSegment = min(segmentAJ,segmentBJ);

%% Case 1: the joining point does not have to be relocated.

% Determine speed of the to be delayed aircraft.
if longestSegment/shortestSegment < Vmax/Vmin
    % Set synchronization possible boolean to 1. 
    syncPossible = 1;
     if acNrRequiringDelay == 1
         VsegmentAJ_acNr1 = min(segmentAJ,segmentBJ)/(max(segmentAJ,segmentBJ)/Vmax);
         VsegmentBJ_acNr2 = Vmax;
     end
     if acNrRequiringDelay == 2
         VsegmentBJ_acNr2 = min(segmentAJ,segmentBJ)/(max(segmentAJ,segmentBJ)/Vmax);
         VsegmentAJ_acNr1 = Vmax;
     end
end

%% Case 2 and 3: the joining point has to be relocated. 

% Length of segment from current location (A) of flight 1 to splitting
% point.
segmentAS = sqrt((Xordes(1)-Xsplitting ).^2 + (Yordes(1)-Ysplitting ).^2);
% Length of segment from current location (B) of flight 2 to splitting
% point.
segmentBS = sqrt((Xordes(2)-Xsplitting ).^2 + (Yordes(2)-Ysplitting ).^2);

% Determine if synchronization is possible at some point along the
% formation segment.
if longestSegment/shortestSegment > Vmax/Vmin && ...
        segmentAS/segmentBS < Vmax/Vmin 
    % Set synchronization possible boolean to 1. 
    syncPossible = 1;
    
    %% Case 2: relocation required, joining point not set on A or B. 
    % If the original joining point has to be relocated and is not set
    % on A or B, the joining point will be relocated on the formation
    % flight segment, closer to the splitting point. See Ch. 6.1.4 of
    % Verhagen's thesis for more information.
    if Xjoining ~= Xordes(1) && Xjoining ~= Xordes(2)       
        % Determine the slope of the formation route segment (in dy/dx
        % form).
        Slope_fs = (Ysplitting - Yjoining)/(Xsplitting - Xjoining);
        % Write the formation route segment in y=ax+b form.
        Y_intercept_fs = Yjoining - Xjoining*Slope_fs;

        % Determine the rightmost flight to determine the slope of the line
        % segment (AB) between the current locations of flight 1 and 2.
        if Xordes(1) <= Xordes(2)
            Slope_between_origins = (Yordes(2) - Yordes(1))/ ...
                (Xordes(2) - Xordes(1));
        end
        if Xordes(1) > Xordes(2)
            Slope_between_origins = (Yordes(1) - Yordes(2))/ ...
                (Xordes(1) - Xordes(2));
        end
        % Write the line segment between the current locations of flight 1
        % and 2 in y=ax+b form.
        Y_intercept_bo = Yordes(1) - Xordes(1)*Slope_between_origins;
        
        % X-coordinate of the intersection of the two previously defined
        % line segments.
        Xx = (Y_intercept_bo - Y_intercept_fs)/(Slope_fs - Slope_between_origins);   
        % Y-coordinate of the intersection of the two previously defined
        % line segments.
        Xy = Slope_fs*Xx + Y_intercept_fs;
        % Length of segment from current location (A) of flight 1 to
        % intersection point X.
        XA = sqrt((Xordes(1) - Xx)^2 + (Yordes(1) - Xy)^2);
        % Length of segment from current location (B) of flight 2 to
        % intersection point X.
        XB = sqrt((Xordes(2) - Xx)^2 + (Yordes(2) - Xy)^2);

        % Determine angle alpha between the XA and the formation route
        % segment. See Ch. 6.1.4 (Fig. 6.8) of Verhagen's thesis for more
        % information. Note that equal angles will not occur, only when J
        % is on A or B.
        if Slope_fs < Slope_between_origins
            angleAlpha = atand(Slope_between_origins) - atand(Slope_fs);
        end
        if Slope_fs > Slope_between_origins
            angleAlpha = 180 - atand(Slope_fs) + atand(Slope_between_origins);
        end
        % Determine angle beta between the XB and the formation route
        % segment.
        angleBeta = 180 - angleAlpha;

        % Apply abc-formula to solve quadratic equation for XJ. See Ch.
        % 6.1.4 (Eq. 6.8) of Verhagen's thesis for more information.
        % a-coefficient of abc-formula.
        a = ((Vmax/Vmin)^2)-1;

        % The relation between the angle alpha and beta determines which
        % triangle gets the factor Vmax/Vmin (i.e. which flight has to slow
        % down). Determine the b- and c-coefficients of the abc-formula.
        if angleAlpha <= angleBeta 
            % Current location A is "above" current location B.
            if  Yordes(1)>= Yordes(2) 
                b = (2*XB*cosd(angleBeta)) - ((2*XA*cosd(angleAlpha))* ...
                    ((Vmax/Vmin)^2));
                c = (XA^2)*((Vmax/Vmin)^2) - (XB^2); 
            % Current location B is "above" current location A.
            else % 
                b = (2*XA*cosd(angleBeta)) - ((2*XB*cosd(angleAlpha))* ...
                    ((Vmax/Vmin)^2));
                c = (XB^2)*((Vmax/Vmin)^2) - (XA^2);
            end
        end
        if angleAlpha > angleBeta
            % Current location A is "above" current location B.
            if Yordes(1) >=Yordes(2)
                b = (2*XA*cosd(angleAlpha)) - ((2*XB*cosd(angleBeta))* ...
                    ((Vmax/Vmin)^2)); 
                c = (XB^2)*((Vmax/Vmin)^2) - (XA^2);
            % Current location B is "above" current location A.
            else
                b = (2*XB*cosd(angleAlpha)) - ((2*XA*cosd(angleBeta))* ...
                    ((Vmax/Vmin)^2)); 
                c = (XA^2)*((Vmax/Vmin)^2) - (XB^2);  
            end
        end

        % Apply abc-formula to solve quadratic equation for XJ.
        Discriminant = (b^2)-(4*a*c);
        XJs = [((-b+sqrt(Discriminant))/(2*a)), ...
            ((-b-sqrt(Discriminant))/(2*a))]; 
        % XJnew is the segment length from the intersection of the
        % formation route line and the line between the current locations
        % of flight 1 and 2, to the relocated joining point.
        XJnew = max(XJs);
        % XJold is the segment length from that same intersection to the
        % original joining point.
        XJold = sqrt(((Xx-Xjoining)^2) + ((Xy - Yjoining)^2));
        % Change in joining point segment length.
        Joining_point_shift = XJnew - XJold;

        % With XJnew calculated, determine the new joining point.
        % Angle of the formation route segment. 
        Angle_fs_slope = atand(Slope_fs);
        % Shift in x-coordinate of the joining point.
        DxJ = cosd(Angle_fs_slope)*Joining_point_shift;
        % Shift in y-coordinate of the joining point.
        DyJ = sind(Angle_fs_slope)*Joining_point_shift;
        % X-coordinate of the relocated joining point.
        Xjoining = Xjoining + DxJ;
        % Y-coordinate of the relocated joining point.
        Yjoining = Yjoining + DyJ;

        % Set the required speeds for flight 1 and 2.
        if acNrRequiringDelay == 1
            VsegmentAJ_acNr1 = Vmin;
            VsegmentBJ_acNr2 = Vmax;
        end
        if acNrRequiringDelay == 2
            VsegmentBJ_acNr2 = Vmin;
            VsegmentAJ_acNr1 = Vmax;
        end
  
    %% Case 3: relocation required, joining point set on A or B. 
    % It may happen that the geometric routing algorithm generates a route
    % for which the joining point is located on one of the current
    % locations. For these cases, the location of a joining point that
    % allows for synchronization can be derived be means of a method that
    % is similar to the one presented in Ch. 6.1.4 of Verhagen's thesis.
    else
        % Determine the slope of the formation route segment (in dy/dx
        % form).
        Slope_fs = (Ysplitting - Yjoining)/(Xsplitting - Xjoining); 

        % Determine the rightmost flight to determine the slope of the line
        % segment (AB) between the current locations of flight 1 and 2.
        if Xordes(1) <= Xordes(2)
            Slope_between_origins = (Yordes(2) - Yordes(1))/ ...
                (Xordes(2) - Xordes(1));
        end
        if Xordes(1) > Xordes(2)
            Slope_between_origins = (Yordes(1) - Yordes(2))/ ...
                (Xordes(1) - Xordes(2));
        end

        % Find angle D, similar to angle alpha in case 2.
        Circle_angle_oo = 180 + atand(Slope_between_origins);
        Circle_angle_fs = atand(Slope_fs); 
        % The angle that is oriented upwards between the two slopes.
        Upper_angle = Circle_angle_oo - Circle_angle_fs;  
        if Upper_angle > 180
            Angle_D = 360 - Upper_angle;
        else
            Angle_D = Upper_angle; 
        end
        
        % Apply abc-formula to solve quadratic equation for XJ. See Ch.
        % 6.1.4 (Eq. 6.8) of Verhagen's thesis for more information.
        % a-coefficient of abc-formula.       
        % Corresponds to AB, but here AE is used to avoid confusion.
        AE = sqrt((Yordes(2) - Yordes(1))^2+(Xordes(2) - Xordes(1))^2); 
        a = ((Vmax/Vmin)^2)-1;
        b = 2*AE*cosd(Angle_D);
        c = -(AE^2);
        Discriminant = (b^2)-(4*a*c);
        JoldJs = [((-b+sqrt(Discriminant))/(2*a)), ((-b-sqrt(Discriminant))/(2*a))];
        % Jnew is the segment length from the intersection of the formation
        % route line and the line between the current locations of flight 1
        % and 2, to the relocated joining point.
        Jnew = max(JoldJs); 
        % Change in joining point segment length. Equal to XJnew- XJold in
        % case 2, yet XJold is 0 in case 3.
        Joining_point_shift = Jnew; 

        % With Jnew calculated, determine the new joining point.
        % Angle of the formation route segment. 
        Angle_fs_slope = atand(Slope_fs);
        % Shift in x-coordinate of the joining point.
        DxJ = cosd(Angle_fs_slope)*Joining_point_shift; 
        % Shift in y-coordinate of the joining point.
        DyJ = sind(Angle_fs_slope)*Joining_point_shift;
        % X-coordinate of the relocated joining point.
        Xjoining = Xjoining + DxJ;
        % Y-coordinate of the relocated joining point.
        Yjoining = Yjoining + DyJ;

        % Set the required speeds for flight 1 and 2.
        if acNrRequiringDelay == 1
            VsegmentAJ_acNr1 = Vmin;
            VsegmentBJ_acNr2 = Vmax;
        end
        if acNrRequiringDelay == 2
            VsegmentBJ_acNr2 = Vmin;
            VsegmentAJ_acNr1 = Vmax;
        end
    end    
end        
end