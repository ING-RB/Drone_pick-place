function adjustview(this,Data,Event,NormalRefresh)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2016 The MathWorks, Inc.

AxGrid = this.AxesGrid;
if strcmp(Event,'postlim') && ~isempty(Data.Data)
   Normalize = strcmp(AxGrid.YNormalization,'on');
   % Input and output sizes
   [Ny, Nu] = size(this.UncertainPatch);
   
   if strcmpi(this.UncertainType,'Bounds')
      set(this.UncertainLines,'Visible','off');
      set(this.UncertainPatch,'Visible','on');
      % Redraw the patch
      % Map data to curves
      if isequal(Data.Ts,0) || any(strcmpi(this.Parent.Style,{'stem','line'}))
         % Plot data as a line
         
         for ct = 1:Ny*Nu
            Xlims = get(ancestor(this.UncertainPatch(ct),'axes'),'Xlim');
            if Normalize
               YDataNom = normalize(Data.Parent,Data.Data(ct).Amplitude,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
            else
               YDataNom = Data.Data(ct).Amplitude;
            end
            
            TimeVec = Data.Data(ct).Time;
            SD = Data.Data(ct).AmplitudeSD(:);
            iLeft = find(~isnan(SD),1,'first');
            iRight = find(~isnan(SD),1,'last');
            SD = SD(iLeft:iRight);
            Nom = YDataNom(:); Nom = Nom(iLeft:iRight);
            TimeVec = TimeVec(iLeft:iRight);
            TempData = Nom-SD;
            YData = [Nom+SD; TempData(end:-1:1)];
            XData = [TimeVec; TimeVec(end:-1:1)]*tunitconv(Data.TimeUnits,this.AxesGrid.XUnits);
            ZData = -2 * ones(size(XData));
            set(double(this.UncertainPatch(ct)), 'XData', XData, ...
               'YData',YData,'ZData',ZData);
         end
      else
         % Discrete time system use style to determine stem or stair plot
         for ct = 1:Ny*Nu
            
            Xlims = get(ancestor(this.UncertainPatch(ct),'axes'),'Xlim');
            if Normalize
               YDataNom = normalize(Data.Parent,Data.Data(ct).Amplitude,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
            else
               YDataNom = Data.Data(ct).Amplitude;
            end
            
            SD = Data.Data(ct).AmplitudeSD(:);
            iLeft = find(~isnan(SD),1,'first');
            iRight = find(~isnan(SD),1,'last');
            SD = SD(iLeft:iRight);
            Nom = YDataNom(:); Nom = Nom(iLeft:iRight);
            TimeVec = Data.Data(ct).Time*tunitconv(Data.TimeUnits,this.AxesGrid.XUnits);
            TimeVec = TimeVec(iLeft:iRight);
            [UpperT,UpperY] = stairs(TimeVec,Nom+SD);
            [LowerT,LowerY] = stairs(TimeVec,Nom-SD);
            
            RangeT = max(LowerT)-min(LowerT); % workaround for 1218771
            XData = [UpperT;LowerT(end:-1:1)-RangeT/1e4];
            ZData = -2 * ones(size(XData));
            YData = [UpperY;LowerY(end:-1:1)];
            
            set(double(this.UncertainPatch(ct)), 'XData', XData, ...
               'YData',YData,'ZData',ZData);
         end
         
      end
   else
      set(this.UncertainLines,'Visible','on');
      set(this.UncertainPatch,'Visible','off');
      % Map data to curves
      if isequal(Data.Ts,0) || strcmpi(this.Parent.Style,'stem')
         for ct = 1:Ny*Nu
            % Plot data as a line
            Xlims = get(ancestor(this.UncertainPatch(ct),'axes'),'Xlim');
            YDataNom = normalize(Data.Parent,Data.Data(ct).Amplitude,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
            
            YData = [YDataNom(:)+Data.Data(ct).AmplitudeSD(:);...
               NaN;...
               YDataNom(:)-Data.Data(ct).AmplitudeSD(:)];
            XData = [Data.Data(ct).Time(:);NaN;Data.Data(ct).Time(:)];
            set(double(this.UncertainLines(ct)),'XData',XData,'YData',YData,'ZData',-2 * ones(size(XData)))
         end
      else
         for ct = 1:Ny*Nu
            % Plot data as stair line
            Xlims = get(ancestor(this.UncertainPatch(ct),'axes'),'Xlim');
            YDataNom = normalize(Data.Parent,Data.Data(ct).Amplitude,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
            YData = [YDataNom(:)+Data.Data(ct).AmplitudeSD(:);...
               NaN;...
               YDataNom-Data.Data(ct).AmplitudeSD(:)];
            XData = [Data.Data(ct).Time(:);NaN;Data.Data(ct).Time(:)];
            [T,Y] = stairs(XData,YData);
            set(double(this.UncertainLines(ct)), 'XData', T, 'YData', Y,'ZData',-2 * ones(size(T)));
         end
      end
      
   end
end
end

