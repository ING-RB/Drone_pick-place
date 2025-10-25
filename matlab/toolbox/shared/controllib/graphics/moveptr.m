function moveptr(Axes,action,X,Y)
%MOVEPTR  Adjusts pointer position when changing axes limits.
%
%   MOVEPTR(AXES,'init') initializes the move.
%
%   MOVEPTR(AXES,'move',X,Y) moves the pointer to the new position (X,Y) in
%   data units (axes coordinates).
%
%   Only for single axes.

%   Author(s): P. Gahinet
%   Copyright 1986-2020 The MathWorks, Inc.

persistent Transform isLogX isLogY

switch action(1)
case 'i'  % init
   % Compute the transformation from norm. axis position to screen position
   Transform = LocalAxis2Screen(Axes);   
   isLogX = strcmp(Axes.XScale,'log');
   isLogY = strcmp(Axes.YScale,'log');
   
case 'm'  % move pointer
   % Move pointer
   Xlim = Axes.XLim;      % X limits
   Ylim = Axes.YLim;      % Y limits
   
   % Compute normalized axis coordinates
   if isLogX,
       NormX = (log2(X) - log2(Xlim(1))) / (log2(Xlim(2))-log2(Xlim(1)));
   else
       NormX = (X-Xlim(1)) / (Xlim(2)-Xlim(1));
   end
   if isLogY,
       NormY = (log2(Y)-log2(Ylim(1))) / (log2(Ylim(2))-log2(Ylim(1)));
   else
       NormY = (Y-Ylim(1)) / (Ylim(2)-Ylim(1));
   end
   
   % Reset pointer location.
   % RE: When pointer is reset in each cycle, use dead zone to prevent drifting
   DeadZone = 0.02;
   NewLoc = Transform(1:2) + Transform(3:4) .* [NormX NormY];
   if any(abs(get(0,'PointerLocation')-NewLoc) > DeadZone*Transform(3:4))
      set(0,'PointerLocation',NewLoc)
   end
   
end


%----------------- Local functions -----------------


%%%%%%%%%%%%%%%%%%%%
% LocalAxis2Screen %
%%%%%%%%%%%%%%%%%%%%
function T = LocalAxis2Screen(ax)
% Axis to screen coordinate transformation.
%
%   T = AXIS2SCREEN(AX) computes a coordinate transformation 
%       T = [xo yo rx ry] 
%   that relates the normalized axes coordinates [xa;ya] of a 
%   given point to its screen coordinate [xs;ys] (in the root 
%   units) by
%       xs = xo + rx * xa
%       ys = yo + ry * ya
%
%   See also SISOTOOL.

Fig = ancestor(ax,'figure');

if strcmpi(Fig.WindowStyle,'docked') || contains(Fig.Tag,"CSDApp")
    % Special case to handle docked figures as the Position property is
    % with respect to container. We can not get the postion on the doc
    % container
    % 
    % For AppContainer, the 'docked' property is returned as false, so we
    % use the Tag of the figure to check if it belongs to the Control
    % System Designer App and is docked in the AppContainer
    
    isLogX = strcmp(ax.XScale,'log');
    isLogY = strcmp(ax.YScale,'log');
    X = ax.CurrentPoint(1,1);
    Y = ax.CurrentPoint(1,2);
    PL = get(0,'PointerLocation');
    
    Xlim = ax.XLim;      % X limits
    Ylim = ax.YLim;      % Y limits
    
    % Compute normalized axis coordinates
    if isLogX,
        NormX = (log2(X) - log2(Xlim(1))) / (log2(Xlim(2))-log2(Xlim(1)));
    else
        NormX = (X-Xlim(1)) / (Xlim(2)-Xlim(1));
    end
    if isLogY,
        NormY = (log2(Y)-log2(Ylim(1))) / (log2(Ylim(2))-log2(Ylim(1)));
    else
        NormY = (Y-Ylim(1)) / (Ylim(2)-Ylim(1));
    end
    
    AxisPos = hgconvertunits(Fig,get(ax,'position'),get(ax,'units'), ...
        'Pixels',Fig);
    
    T(1:2) =  PL - AxisPos(3:4).*[NormX,NormY];
    T(3:4) = AxisPos(3:4);
else
    % Get axes normalized position in figure
    AxisPos = hgconvertunits(Fig,get(ax,'position'),get(ax,'units'), ...
        'normalized',Fig);
    
    % Get figure's normalized position in screen
    FigPos = hgconvertunits(Fig,get(Fig,'position'),get(Fig,'units'), ...
        'normalized',get(Fig,'Parent'));
    
    
    % Transformation norm. axis coord -> norm. fig. coord.
    T = AxisPos;
    
    % Transformation norm. axis coord -> norm. screen coord.
    T(1:2) = FigPos(1:2) + FigPos(3:4) .* T(1:2);
    T(3:4) = FigPos(3:4) .* T(3:4);
    
    % Transform to screen units
    ScreenSize = get(0,'ScreenSize');
    T(1:2) = ScreenSize(1:2) + ScreenSize(3:4) .* T(1:2);
    T(3:4) = ScreenSize(3:4) .* T(3:4);
end




