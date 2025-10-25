function draw(this,Data,NormalRefresh)
%DRAW  Draws uncertain view

%   Author(s): Craig Buhr
%   Copyright 1986-2016 The MathWorks, Inc.

% Input and output sizes
[Ny, Nu] = size(this.UncertainPatch);

if strcmpi(this.UncertainType,'Bounds')
   set(this.UncertainLines,'Visible','off');
   set(this.UncertainPatch,'Visible','on');
   % Redraw the patch
   if strcmp(this.AxesGrid.YNormalization,'on') || isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainPatch),'XData',[],'YData',[],'ZData',[])
   else
      % Map data to curves
      if isequal(Data.Ts,0) || any(strcmpi(this.Parent.Style,{'stem','line'}))
         % Plot data as a line
         for ct = 1:Ny*Nu
            ysd = Data.Data(ct).AmplitudeSD(:);
            if ~isempty(ysd)
               XData = [Data.Data(ct).Time;Data.Data(ct).Time(end:-1:1)]*tunitconv(Data.TimeUnits,this.AxesGrid.XUnits);
               ZData = -2 * ones(size(XData));
               TempData = Data.Data(ct).Amplitude(:)-ysd;
               YData = [Data.Data(ct).Amplitude(:)+ysd;TempData(end:-1:1)];
               set(double(this.UncertainPatch(ct)), 'XData', XData, ...
                  'YData',YData,'ZData',ZData);
            end
         end
      else
         % Discrete time system use style to determine stem or stair plot
         for ct = 1:Ny*Nu
            ysd = Data.Data(ct).AmplitudeSD(:);
            if ~isempty(ysd)
               [UpperT,UpperY] = stairs(...
                  Data.Data(ct).Time*tunitconv(Data.TimeUnits,this.AxesGrid.XUnits), ...
                  Data.Data(ct).Amplitude(:)+ysd);
               [LowerT,LowerY] = stairs(...
                  Data.Data(ct).Time*tunitconv(Data.TimeUnits,this.AxesGrid.XUnits), ...
                  Data.Data(ct).Amplitude(:)-ysd);
               
               RangeT = max(LowerT)-min(LowerT); % workaround for 1218771
               XData = [UpperT; LowerT(end:-1:1)-RangeT/1e4];
               ZData = -2 * ones(size(XData));
               YData = [UpperY;LowerY(end:-1:1)];
               
               set(double(this.UncertainPatch(ct)), 'XData', XData, ...
                  'YData',YData,'ZData',ZData);
            end
         end
         
      end
   end
else
   set(this.UncertainLines,'Visible','on');
   set(this.UncertainPatch,'Visible','off');
   if strcmp(this.AxesGrid.YNormalization,'on') || isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainLines),'XData',[],'YData',[],'ZData',[])
   else
      % Map data to curves
      if isequal(Data.Ts,0) || strcmpi(this.Parent.Style,'stem')
         for ct = 1:Ny*Nu
            % Plot data as a line
            YData = [Data.Data(ct).Amplitude(:)+Data.Data(ct).AmplitudeSD(:);...
               NaN;...
               Data.Data(ct).Amplitude(:)-Data.Data(ct).AmplitudeSD(:)];
            XData = [Data.Data(ct).Time(:);NaN;Data.Data(ct).Time(:)];
            set(double(this.UncertainLines(ct)),'XData',XData,'YData',YData,'ZData',-2 * ones(size(XData)))
         end
      else
         for ct = 1:Ny*Nu
            % Plot data as stair line
            YData = [Data.Data(ct).Amplitude(:)+Data.Data(ct).AmplitudeSD(:);...
               NaN;...
               Data.Data(ct).Amplitude(:)-Data.Data(ct).AmplitudeSD(:)];
            XData = [Data.Data(ct).Time(:);NaN;Data.Data(ct).Time(:)];
            [T,Y] = stairs(XData,YData);
            set(double(this.UncertainLines(ct)), 'XData', T, 'YData', Y,'ZData',-2 * ones(size(T)));
         end
      end
      
   end
end
end
