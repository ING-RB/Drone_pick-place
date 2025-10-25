function draw(this, Data,NormalRefresh)
%DRAW  Draws time response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Copyright 1986-2010 The MathWorks, Inc.

%  Time:      Ns x 1
%	Amplitude: Ns x 1

% Redraw the curves
if isempty(Data.Time) || strcmp(this.AxesGrid.YNormalization,'on')
   % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
   set(this.Curves,'XData',[],'YData',[])
else
    TimeData = Data.Time*tunitconv(Data.TimeUnits,this.AxesGrid.XUnits);
    % Map data to curves
    if isequal(Data.Ts,0)
        % Continuous case
        set(double(this.Curves), 'XData', TimeData,'YData', Data.Amplitude);
    else
        % Discrete Case
        switch this.Style
            case 'stairs'
                [T,Y] = stairs(TimeData,Data.Amplitude);
                set(double(this.Curves), 'XData', T, 'YData', Y);
            case 'stem'
                % REVISIT: Not implemented yet
                ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
                    'Stem plot is not currently implemented for this view type.')
        end
    end
end

for ct = 1:numel(this.Curves)
    hasbehavior(this.Curves(ct),'legend',false);
end