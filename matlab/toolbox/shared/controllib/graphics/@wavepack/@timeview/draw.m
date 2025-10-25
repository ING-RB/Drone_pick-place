function draw(this, Data,NormalRefresh)
%DRAW  Draws time response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Author(s): John Glass, Bora Eryilmaz
%  Copyright 1986-2010 The MathWorks, Inc.

% Time:      Ns x 1
% Amplitude: Ns x Ny x Nu

AxGrid = this.AxesGrid;

% Input and output sizes
[Ny, Nu] = size(this.Curves);

% Redraw the curves
if strcmp(this.AxesGrid.YNormalization,'on')
   % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
   set(double(this.Curves),'XData',[],'YData',[])
else
    TimeData = Data.Time*tunitconv(Data.TimeUnits,AxGrid.XUnits);
    % Map data to curves
    if isequal(Data.Ts,0)
        % Plot data as a line
        for ct = 1:Ny*Nu
            set(double(this.Curves(ct)), 'XData', TimeData, ...
                'YData', Data.Amplitude(:,ct));
        end
    else
        % Discrete time system use style to determine stem or stair plot
        switch this.Style
            case {'stairs','stem'}
                for ct = 1:Ny*Nu
                    [T,Y] = stairs(TimeData,Data.Amplitude(:,ct));
                    set(double(this.Curves(ct)), 'XData', T, 'YData', Y);
                end
%             case 'stem'
%                 for ct = 1:Ny*Nu
% 
%                     set(double(this.Curves(ct)), 'XData', TimeData, ...
%                         'YData', Data.Amplitude(:,ct));
%                     [T,Y] = localStems(TimeData,Data.Amplitude(:,ct));
%                     set(double(this.StemLines(ct)), 'XData', T, ...
%                         'YData', Y,'ZData',-0.05*ones(size(T)));
%                 end

        end
    end
end

end

function [X,Y] = localStems(X0,Y0)

[m,n] = size(X0(:));
X = NaN(3*m,n);
X(1:3:3*m,:) = X0;
X(2:3:3*m,:) = X0;

[m,n] = size(Y0(:));
Y = zeros(3*m,n);
Y(2:3:3*m,:) = Y0;
Y(3:3:3*m,:) = NaN;

end