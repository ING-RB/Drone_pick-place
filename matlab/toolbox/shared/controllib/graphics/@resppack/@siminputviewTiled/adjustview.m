function adjustview(View,Data,Event,NormalRefresh)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'postlim') adjusts the HG object extent once the 
%  axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.

if strcmp(Event,'postlim') && strcmp(View.AxesGrid.YNormalization,'on')
    % Draw normalized data once X limits are finalized
    TimeData = Data.Time*tunitconv(Data.TimeUnits,View.AxesGrid.XUnits);

    if isequal(Data.Ts,0)
        if ~isempty(Data.Amplitude)
            Xlims = get(ancestor(View.Curves(1),'axes'),'Xlim');
            YData = normalize(Data,Data.Amplitude,Xlims*tunitconv(View.AxesGrid.XUnits,Data.TimeUnits));
            set(double(View.Curves),'XData',TimeData,'YData',YData)
        else
            set(double(View.Curves),'XData',[],'YData',[])
        end
    else
        switch View.Style
            case 'stairs'
                if ~isempty(Data.Amplitude)
                    Xlims = get(ancestor(View.Curves(1),'axes'),'Xlim');
                    [T,Y] = stairs(TimeData,Data.Amplitude);
                    Y = normalize(Data,Y,Xlims*tunitconv(View.AxesGrid.XUnits,Data.TimeUnits));
                    set(double(View.Curves),'XData',T,'YData',Y);
                else
                    set(double(View.Curves),'XData',[],'YData',[])
                end
            case 'stem'
                % REVISIT: Not implemented yet
                ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
                    'Stem plot is not currently implemented for this view type.')
        end
    end
end
