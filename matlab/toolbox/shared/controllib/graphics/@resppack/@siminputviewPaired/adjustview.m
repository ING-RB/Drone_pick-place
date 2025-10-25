function adjustview(View,Data,Event,NormalRefresh)
% Adjusts view prior to and after picking the axes limits. 

%  Author(s): P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.

AxGrid = View.AxesGrid;

if strcmp(Event,'postlim') && strcmp(View.AxesGrid.YNormalization,'on')
    % Draw normalized data once X limits are finalized
    if isempty(Data.Amplitude)
        set(double(View.Curves),'XData',[],'YData',[])
    else
        TimeData = Data.Time*tunitconv(Data.TimeUnits,AxGrid.XUnits);
        Nu = size(Data.Amplitude,2);
        Xlims = get(ancestor(View.Curves(1),'axes'),'Xlim');

        if isequal(Data.Ts,0)
            YData = normalize(Data,Data.Amplitude,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits));
        else
            switch View.Style
                case 'stairs'
                    [T,Y] = stairs(TimeData,Data.Amplitude);
                    TimeData = T;
                    YData = normalize(Data,Y,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits));
                case 'stem'
                     % REVISIT: Not implemented yet
                     ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
                         'Stem plot is not currently implemented for this view type.')
            end
        end
        for ct=1:Nu
            set(double(View.Curves(ct)),'XData',TimeData,'YData',YData(:,ct))
        end
    end
end
