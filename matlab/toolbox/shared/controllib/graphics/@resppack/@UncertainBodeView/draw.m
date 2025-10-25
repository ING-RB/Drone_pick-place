function draw(this,Data,NormalRefresh)
%DRAW  Draws uncertain view

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.

% Time:      Ns x 1
% Amplitude: Ns x Ny x Nu

% Input and output sizes
[Ny, Nu] = size(this.UncertainMagPatch);

if strcmpi(this.UncertainType,'Bounds')
    % Redraw the patch
    set(this.UncertainMagLines,'Visible','off');
    set(this.UncertainPhaseLines,'Visible','off');
    set(this.UncertainMagPatch,'Visible','on');
    set(this.UncertainPhasePatch,'Visible','on');
    if (length(Data.Data)<2)
        % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
        set(double(this.UncertainMagPatch),'XData',[],'YData',[],'ZData',[])
        set(double(this.UncertainPhasePatch),'XData',[],'YData',[],'ZData',[])
    else
        % Map data to curves
            % Plot data as a line
            Bounds = getBounds(Data);
            XData = [Bounds.Frequency;Bounds.Frequency(end:-1:1)]*funitconv('rad/s',this.Parent.AxesGrid.xUnits);
            ZData = -2 * ones(size(XData));
            for ct = 1:Ny*Nu
                TempData = Bounds.LowerMagnitudeBound(:,ct);
                MagData = [Bounds.UpperMagnitudeBound(:,ct);TempData(end:-1:1)];
                set(double(this.UncertainMagPatch(ct)), 'XData', XData, ...
                    'YData',unitconv(MagData,'abs',this.Parent.AxesGrid.YUnits{1}),'ZData',ZData);
                
                TempData = Bounds.LowerPhaseBound(:,ct);
                PhaseData = [Bounds.UpperPhaseBound(:,ct);TempData(end:-1:1)];
                set(double(this.UncertainPhasePatch(ct)), 'XData', XData, ...
                    'YData',unitconv(PhaseData,'rad',this.Parent.AxesGrid.YUnits{2}),'ZData',ZData);
                
            end
    end
else
    set(this.UncertainMagLines,'Visible','on');
    set(this.UncertainPhaseLines,'Visible','on');
    set(this.UncertainMagPatch,'Visible','off');
    set(this.UncertainPhasePatch,'Visible','off');
    if (length(Data.Data)<2)
        % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
        set(double(this.UncertainMagLines),'XData',[],'YData',[],'ZData',[])
        set(double(this.UncertainPhaseLines),'XData',[],'YData',[],'ZData',[])
    else
        % Map data to curves
        Data.Ts = 0;
        RespData = Data.Data;
        if isequal(Data.Ts,0)
            for ct = 1:Ny*Nu
                % Plot data as a line
                PhaseData = [];
                MagData = [];
                XData = [];
                for ct1 = 1:length(RespData)
                    MagData = [MagData; RespData(ct1).Magnitude(:,ct);NaN];
                    PhaseData = [PhaseData; RespData(ct1).Phase(:,ct);NaN];
                    XData = [XData; RespData(ct1).Frequency(:);NaN];
                end
                XData = XData*funitconv('rad/s',this.Parent.AxesGrid.xUnits);
                set(this.UncertainMagLines(ct),'XData',XData,'YData',unitconv(MagData,'abs',this.Parent.AxesGrid.YUnits{1}),'ZData',-2 * ones(size(XData)))
                set(this.UncertainPhaseLines(ct),'XData',XData,'YData',unitconv(PhaseData,'rad',this.Parent.AxesGrid.YUnits{2}),'ZData',-2 * ones(size(XData)))
            end
        end

    end
end





