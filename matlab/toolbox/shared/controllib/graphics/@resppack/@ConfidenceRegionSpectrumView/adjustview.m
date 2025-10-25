function adjustview(this,Data,Event,NormalRefresh)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2011 The MathWorks, Inc.

if strcmp(Event,'prelim')
    this.draw(Data);
elseif strcmp(Event,'postlim')
    % Input and output sizes
    [Ny, Nu] = size(this.UncertainMagPatch);
    
    if strcmpi(this.UncertainType,'Bounds')
        % Redraw the patch
        set(this.UncertainMagLines,'Visible','off');
        set(this.UncertainMagPatch,'Visible','on');
        % Map data to curves
        % Plot data as a line
        if isempty(Data.Data)
            % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
            set(double(this.UncertainMagPatch),'XData',[],'YData',[],'ZData',[])
        else
            for ct = 1:Ny*Nu
                Freq = Data.Data(ct).Frequency*funitconv('rad/TimeUnit',this.Parent.AxesGrid.xUnits,Data.TimeUnits);
                XData = [Freq;Freq(end:-1:1)];
                ZData = -2 * ones(size(XData));
                LowerMagnitudeBound = idpack.specmagunitconv((Data.Data(ct).Magnitude(:) - Data.Data(ct).MagnitudeSD(:)),'abs',this.Parent.AxesGrid.YUnits);
                UpperMagnitudeBound = idpack.specmagunitconv((Data.Data(ct).Magnitude(:) + Data.Data(ct).MagnitudeSD(:)),'abs',this.Parent.AxesGrid.YUnits);
                
                YLims = get(ancestor(this.UncertainMagPatch(ct),'axes'),'Ylim');
                % Convert to axes units to determine elements that are not
                % finite.
                TempLowerData = LowerMagnitudeBound;
                TempLowerData(~isfinite(LowerMagnitudeBound)) = YLims(1);
                TempUpperData = UpperMagnitudeBound;
                TempUpperData(~isfinite(TempUpperData)) = YLims(2);
                
                MagData = [TempUpperData(:); TempLowerData(end:-1:1)];
                set(double(this.UncertainMagPatch(ct)), 'XData', XData, ...
                    'YData',MagData,'ZData',ZData);                
            end
        end
    end
end