function [Xjoining,Yjoining,Xsplitting,Ysplitting] = ...
    determineGeometricRouting(wAC,wBD,wDuo,Xordes,Yordes,Vmax,dt)
%% determineGeometricRouting.m description
% Determines the joining- and splitting point for a flight formation route
% of flight 1 and 2. It is based on their current location, and their
% destination. The method used is the geometric routing method by Kent et
% al., based on the Fermat point problem. See Ch. 6.1.1-6.1.2 of Verhagen's
% thesis for more information.

% inputs: 
% wAC (weight factor of flight 1 from point A to C),
% wBD (weight factor of flight 2 from point B to D),
% wDuo (weight factor of the formation flight segment),
% Xordes (current and destination x-coordinates of both aircraft),
% Yordes (current and destination y-coordinates of both aircraft),
% Vmax,
% dt.

% outputs: 
% Xjoining (x-coordinate of the joining point),
% Yjoining,
% Xsplitting, 
% Ysplitting.

% special cases: 
% * The developed routing algorithm will never suggest an alternative route
% that requires a heading change of over 90 degrees of one or more of the
% involved aircraft. Accordingly, the result of the geometric method has to
% be occasionally overruled when this does occur. One can move the joining
% point to the most right origin, and one can move the splitting point to
% the most left destination.
% * One type of aircraft. Crucial, as w1=w2 is used to determine the back
% vertices.
% * Flights must be from left to right for the algorithm to work. This
% relates to the formation angle and circles.

% sources: 
% * http://maverick.inria.fr/~Xavier.Decoret/resources/maths/
% * http://de.mathworks.com/matlabcentral/newsreader/view_thread/141953

%%

% Check if x-coordinate of current location is smaller than that of the
% destination for both flights.
if Xordes(1) < Xordes(3) && Xordes(2) < Xordes(4)

    % Determine optimal formation angle that minimizes the cumulative
    % distance of the segments. See Ch. 6.1.1 of Verhagen's thesis for more
    % information.
    formationAngle = acosd((-wAC^2-wBD^2+wDuo^2)/(2*wAC*wBD));

    %% Current location: Draw circle of joining points.   
    % Current location of flight 1.
    A = [Xordes(1),Yordes(1)];
    % Current location of flight 2. 
    B = [Xordes(2),Yordes(2)];
    % Distance between flight 1 and 2. 
    AB = sqrt((A(2)-B(2))^2+(A(1)-B(1))^2);
    % Only if flight 1 and 2 are not at the same current location.
    if AB > 1e-5
        % Distance between current location of flight 1 and a joining point
        % P to the right of the segment AB. Valid for when wAC = wBD.
        AP_symmetric = 0.5*AB/sind(0.5*formationAngle);
        % Distance between current location of flight 1 and a joining point
        % P' to the left of the segment AB. Valid for when wAC = wBD.
        APac_symmetric = 0.5*AB/sind(0.5*(180-formationAngle));
        % Determine the two possible locations of joining point P.
        [Px,Py] = circcirc(A(1),A(2),AP_symmetric,B(1),B(2),AP_symmetric); 
        % Determine the two possible locations of joining point P'.
        [Pacx,Pacy] = circcirc(A(1),A(2),APac_symmetric,B(1),B(2),APac_symmetric); 
        % Determine the radius of the circle on which the joining points
        % lie.
        Radius_Pcircle = sqrt((Px(1)-Pacx(2))^2+(Py(1)-Pacy(2))^2)/2;

        % Weighted back vertice determination.
        % Determine the two radii of back vertice determination circles.
        AXbv = (AB/wDuo)*wBD; 
        BXbv = (AB/wDuo)*wAC;
        % Determine the two possible weighted back vertices.
        [WBVxO,WBVyO] = circcirc(A(1),A(2),AXbv,B(1),B(2),BXbv); 

        % Determine center of circle on which the joining points lie.
        % Use the leftmost P' as center.
        if Pacx(2) > Pacx(1)
            center_Pcircle = [(Px(2)+Pacx(1))/2,(Py(2)+Pacy(1))/2]; 
        else
            center_Pcircle = [(Px(1)+Pacx(2))/2,(Py(1)+Pacy(2))/2];
        end
    % If flight 1 and 2 are at the same current location.    
    else
        % Determine the two possible weighted back vertices equal to the
        % current locations.
        WBVxO = [A(1) B(1)];
        WBVyO = [A(2) B(2)];
    end

    % Use the leftmost back vertice (X1) to determine the lefthand side of
    % the line that connects the joining and splitting point.
    if WBVxO(1) < WBVxO(2)
        froute_slope_O_x = WBVxO(1);
        froute_slope_O_y = WBVyO(1);
    else
        froute_slope_O_x = WBVxO(2);
        froute_slope_O_y = WBVyO(2); 
    end
   
    %% Destination: Draw circles of splitting points.
    % Destination coordinates of flight 1.
    C = [Xordes(3),Yordes(3)];
    % Destination coordinates of flight 2.
    D = [Xordes(4),Yordes(4)];
    % Distance between destination of flight 1 and 2. 
    CD = sqrt((C(2)-D(2))^2+(C(1)-D(1))^2);
    % Distance between destination of flight 1 and the splitting point P
    % to the right of the segment CD. Valid for when wAC = wBD.
    CP_symmetric = 0.5*CD/sind(0.5*formationAngle);
    % Distance between destination of flight 1 and the splitting point P'
    % to the left of the segment CD. Valid for when wAC = wBD.
    CPac_symmetric = 0.5*CD/sind(0.5*(180-formationAngle));

    % Allow for equal destination, then the routing method with circles
    % can not be used. Set the common destination as the splitting point.
    if CD < 1e-5
         % This is true if the destinations are identical.
        froute_slope_D_x = Xordes(3);
        froute_slope_D_y = Yordes(3);
    else
        % Determine the two possible locations of splitting point P.
        [PDx,PDy] = circcirc(C(1),C(2),CP_symmetric,D(1),D(2),CP_symmetric);
        % Determine the two possible locations of splitting point P'.
        [PDacx,PDacy] = circcirc(C(1),C(2),CPac_symmetric,D(1),D(2),CPac_symmetric);
        % Determine the radius of the circle on which the splitting points
        % lie.
        Radius_PDcircle = sqrt((PDx(1)-PDacx(2))^2+(PDy(1)-PDacy(2))^2)/2;

        % Weighted back vertice determination.
        % Determine the two radii of back vertice determination circles.
        CXbv = (CD/wDuo)*wBD; 
        DXbv = (CD/wDuo)*wAC;
        % Determine the two possible weighted back vertices.
        [WBVxD,WBVyD] = circcirc(C(1),C(2),CXbv,D(1),D(2),DXbv);

        % Determine center of circle origins.
        % Use the rightmost P' as center.
        % Use the rightmost back vertice (Y2) to determine the righthand
        % side of the line that connects the joining and splitting point.
        if PDacx(2) > PDacx(1)    
            center_PDcircle = [(PDx(1)+PDacx(2))/2,(PDy(1)+PDacy(2))/2]; 
            froute_slope_D_x = WBVxD(2); 
            froute_slope_D_y = WBVyD(2);
        else
            center_PDcircle = [(PDx(2)+PDacx(1))/2,(PDy(2)+PDacy(1))/2];
            froute_slope_D_x = WBVxD(1);
            froute_slope_D_y = WBVyD(1);
        end
    end
  
    %% Find the formation flight route.
    % Determine the slope between the back vertices of the current location
    % and of the destination.
    froute_slope = (froute_slope_D_y - froute_slope_O_y)/ ...
        (froute_slope_D_x - froute_slope_O_x);
    y_intercept_froute = froute_slope_D_y-froute_slope_D_x*froute_slope;

    % Find the formation flight route intersections with the circle on
    % which the joining points lie.
    if AB > 1e-5
        [xoutOr,youtOr] = linecirc(froute_slope,y_intercept_froute, ...
            center_Pcircle(1),center_Pcircle(2),Radius_Pcircle);
        % The x-coordinate of the joining point will be the rightmost
        % value.
        Xjoining = max(xoutOr);
        Yjoining = youtOr(find(xoutOr==Xjoining));
    else
        % The radius of the Pcircle is zero when two flights are exactly at
        % the same location when they communicate. In this case, the
        % joining point can be set at their current location.
        Xjoining = Xordes(1);
        Yjoining = Yordes(1);  
    end

    % Find the formation flight route intersections with the circle on
    % which the splitting points lie.  
    if CD < 1e-5
        % Again, account for the fact that the destinations may be the
        % same, in which case the radii used below will not be available.
        Xsplitting = Xordes(3);
        Ysplitting = Yordes(3);
    else
        [xoutDes,youtDes] = linecirc(froute_slope,y_intercept_froute, ...
            center_PDcircle(1),center_PDcircle(2),Radius_PDcircle);
        % The x-coordinate of the splitting point will be the leftmost
        % value.
        Xsplitting = min(xoutDes);
        Ysplitting = youtDes(find(xoutDes==Xsplitting));
    end

    %% Check joining point intersection.
    % Determine the intersection of the line between the current location
    % of flight 1 and 2, and the line that connects the back vertices.
    
    % Line between back vertices.
    x_bv_slope_O = [froute_slope_O_x, froute_slope_D_x]; 
    y_bv_slope_O = [froute_slope_O_y, froute_slope_D_y];
    % Line between A and B.
    x_or_slope = [A(1),B(1)]; 
    y_or_slope = [A(2),B(2)];
    % Determine the intersection point of the two lines.
    [xbv_or,~] = polyxpoly(x_bv_slope_O, y_bv_slope_O, x_or_slope, ...
        y_or_slope); 
    
    % If there is no intersection point, use the rightmost current location
    % as joining point. See Ch. 6.1.2 of Verhagen's thesis for more
    % information.
    if isempty(xbv_or) == 1
        Xjoining = max(Xordes(1),Xordes(2));
        Yjoining = Yordes(find(Xordes==Xjoining));
    end

    %% Check splitting point intersection.
    % Determine the intersection of the line between the destination of
    % flight 1 and 2, and the line that connects the joining point and the
    % splitting point's back vertice.
    
    % Line between joining point and splitting point's back vertice.
    x_bv_slope_D = [Xjoining, froute_slope_D_x];
    y_bv_slope_D = [Yjoining, froute_slope_D_y];
    % Line between C and D.
    x_des_slope = [C(1),D(1)];
    y_des_slope = [C(2),D(2)];
    % Determine the intersection point of the two lines.
    [xbv_des,~] = polyxpoly(x_bv_slope_D, y_bv_slope_D, ...
        x_des_slope, y_des_slope);
    
    % If there is no intersection point, use the leftmost destination as
    % splitting point. See Ch. 6.1.2 of Verhagen's thesis for more
    % information.
    if isempty(xbv_des) == 1
        Xsplitting = min(Xordes(3),Xordes(4));
        Ysplitting = min(Yordes(find(Xordes==Xsplitting))); 
    end
          
    %% Adjust joining- or splitting point if necessary.
    
    % If the joining point becomes the rightmost current location, and the
    % splitting point is valid, the splitting point still has to be moved.
    % This is not required if the destinations are identical.
    if isempty(xbv_or) == 1 && isempty(xbv_des) == 0 && CD > 1e-5
        % Determine the slope between the joining point, and the splitting
        % point's back vertice.
        froute_slope2 = (Yjoining - froute_slope_D_y)/ ...
            (Xjoining - froute_slope_D_x);
        y_intercept_froute2 = Yjoining-Xjoining*froute_slope2;
        % Find the new formation flight route intersections with the circle
        % on which the splitting points lie.
        [xoutDes2,youtDes2] = linecirc(froute_slope2, ...
            y_intercept_froute2,center_PDcircle(1), ...
            center_PDcircle(2),Radius_PDcircle);
        % The x-coordinate of the splitting point will be the leftmost
        % value.
        Xsplitting = min(xoutDes2);
        Ysplitting = youtDes2(find(xoutDes2==Xsplitting));
    end
    
    % If the splitting point becomes the leftmost destination, and the
    % joining point is valid, the joining point still has to be moved.
    % AP_symmetric
    if isempty(xbv_or) == 0 && isempty(xbv_des)== 1 && AB > 1e-5
        % Determine the slope between the joining point's back vertice, and
        % the splitting point.
        froute_slope3 = (Ysplitting - froute_slope_O_y)/ ...
            (Xsplitting - froute_slope_O_x);
        y_intercept_froute3 = Ysplitting-Xsplitting*froute_slope3;
        % Find the new formation flight route intersections with the circle
        % on which the joining points lie.
        [xoutOr2,youtOr2] = linecirc(froute_slope3, ...
            y_intercept_froute3,center_Pcircle(1), ...
            center_Pcircle(2),Radius_Pcircle);
        % The x-coordinate of the joining point will be the rightmost
        % value.
        Xjoining = max(xoutOr2);
        Yjoining = youtOr2(find(xoutOr2==Xjoining)); 
        
        % Check joining point intersection once more, as it may have moved
        % out of range.    
        % Line between joining point's back vertice and splitting point.
        x_SJ_slope_O = [froute_slope_O_x, Xsplitting]; 
        y_SJ_slope_O = [froute_slope_O_y, Ysplitting];
        % Determine the intersection point of the line above, and of the
        % line between A and B.
        [xSJ_or,~] = polyxpoly(x_SJ_slope_O, y_SJ_slope_O, ...
            x_or_slope, y_or_slope);  

        % If there is no intersection point, use the rightmost current
        % location as joining point. See Ch. 6.1.2 of Verhagen's thesis for
        % more information.
        if isempty(xSJ_or) == 1
            Xjoining = max(Xordes(1),Xordes(2));
            Yjoining = Yordes(find(Xordes==Xjoining));
        end
    end
    
    % If the current location of flight 1 and 2 are equal, shift forward
    % the joining point along the line segment from joining point to
    % splitting point one time step such that the aircraft can form the
    % formation.
    if AB < 1e-5
        % Heading from joining point to splitting point for the proposed
        % formation.
        proposedHeadingJS = (Ysplitting-Yjoining)/(Xsplitting-Xjoining); 
        % Determine the travelled distance in km in one time step. 
        travelledDistanceJS = Vmax/1000*dt;
        % Determine the horizontal travelled distance in km in one time
        % step.
        XtravelledDistanceJS = cosd(atand(proposedHeadingJS))* ...
            travelledDistanceJS;
        % Determine the vertical travelled distance in km in one time step.
        YtravelledDistanceJS = sind(atand(proposedHeadingJS))* ...
            travelledDistanceJS;
        % New x-coordinate joining point.
        Xjoining = Xjoining + XtravelledDistanceJS;
        % New y-coordinate joining point.
        Yjoining = Yjoining + YtravelledDistanceJS; 
    end
   
else  % Check if routes are from left to right.
    Xordes % Display for debugging purposes.
    Yordes % Display for debugging purposes.
    warning('Routes not from left to right')  
end
end