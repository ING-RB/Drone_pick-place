function adjustview(this,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): C Buhr
%   Copyright 1986-2013 The MathWorks, Inc.

if strcmp(Event,'prelim')
   this.draw(Data);
   
elseif strcmp(Event,'postlim')
   
   % Set ZLevel for bounds to be below the grid
   ZLevel = this.AxesGrid.GridOptions.Zlevel - 0.1;
   
   ax = getaxes(this.AxesGrid);
   hPlot = gcr(ax(1));
   Ts = Data.Ts;
   Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
   
   if Ts==0
      % Continuous time
      
      
      % MaxFrequency
      if isfinite(Data.MaxFrequency)
         R = Factor * Data.MaxFrequency;
         theta = (pi/50) * (-50:50);
         Circle =  R*exp(complex(0,theta));
         for ct = 1:numel(this.SpectralRadiusPatch)
            CurrentAx = ancestor(this.SpectralRadiusPatch(ct),'axes');
            YLims = get(CurrentAx,'Ylim');
            XLims = get(CurrentAx,'Xlim');
            Ymax = max(R,YLims(2));
            Xmax = max(R,XLims(2));
            Xmin = min(-R,XLims(1));
            XData = [Xmin real(Circle) Xmin Xmin Xmax Xmax Xmin];
            YData = [0 imag(Circle) 0 Ymax Ymax -Ymax -Ymax];
            set(this.SpectralRadiusPatch,'XData',XData,'YData',YData,'ZData',ZLevel*ones(size(XData)));
         end
      end
      
      % MinDecay and MinDamping
      MinDamping = Data.MinDamping;
      if ~isempty(MinDamping)
         tau = tan(acos(MinDamping));
         for ct = 1:numel(this.SpectralAbscissaPatch)
            CurrentAx = ancestor(this.SpectralAbscissaPatch(ct),'axes');
            YLims = get(CurrentAx,'Ylim');
            XLims = get(CurrentAx,'Xlim');
            Xmin = XLims(1);   Xmax = XLims(2)+1;   Ymax = YLims(2);
            X1 = -Factor * Data.MinDecay;  % abscissa of decay rate constraint
            X2 = -Ymax/tau;  % abscissa where damping ratio sector leaves box
            % NOTE: DRAW ensures that Xmin<=X1<=Xmax
            if X2<Xmin
               XData = [X1,X1,Xmin,Xmin,Xmax,Xmax,Xmin,Xmin,X1,X1];
               YData = [0,-tau*X1,-tau*Xmin,Ymax,Ymax,-Ymax,-Ymax,tau*Xmin,tau*X1,0];
            elseif X2<X1
               XData = [X1,X1,X2,Xmax,Xmax,X2,X1,X1];
               YData = [0,-tau*X1,Ymax,Ymax,-Ymax,-Ymax,tau*X1,0];
            else
               XData = [X1,X1,Xmax,Xmax,X1];
               YData = [-Ymax,Ymax,Ymax,-Ymax,-Ymax];
            end
            set(this.SpectralAbscissaPatch,'XData',XData,'YData',YData,'ZData',ZLevel*ones(size(XData)));
         end
      end
      
      
   else
      % Discrete time
      if ~isempty(Data.MaxFrequency)
         wnTs = Factor*Data.MaxFrequency * Ts;
         if wnTs<=pi
            theta = (wnTs / 50) * (0:50);
            rho = exp(-sqrt(wnTs^2-theta.^2));
            theta = [theta fliplr(theta)];
            rho = [rho fliplr(1./rho)];
            z = rho .* exp(complex(0,theta));
            z = [z fliplr(conj(z))];
            Zmax = exp(wnTs);
            for ct = 1:numel(this.SpectralRadiusPatch)
               CurrentAx = ancestor(this.SpectralAbscissaPatch(ct),'axes');
               XLims = get(CurrentAx,'Xlim');
               YLims = get(CurrentAx,'Ylim');
               Xmin = min(-1,XLims(1));  Xmax = max(Zmax,XLims(2));
               Ymax = max(1,YLims(2));
               XData = [Xmin real(z) Xmin Xmin Xmax Xmax Xmin];
               YData = [0 imag(z) 0 -Ymax -Ymax Ymax Ymax];
               set(this.SpectralRadiusPatch,'XData',XData,'YData',YData,'ZData',ZLevel*ones(size(XData)));
            end
         end
      end
      
      % MinDecay and MinDamping
      if ~isempty(Data.MinDamping)
         theta = (pi/50) * (-50:50);
         zeta = Data.MinDamping;
         rho = min(exp(-Factor*Data.MinDecay*Ts),exp(-zeta/sqrt(1-zeta^2)*abs(theta)));
         z = rho .* exp(complex(0,theta));
         z([1 end]) = real(z([1 end])); % workaround g1160409 (see g1160316)
         for ct = 1:numel(this.SpectralAbscissaPatch)
            CurrentAx = ancestor(this.SpectralAbscissaPatch(ct),'axes');
            YLims = get(CurrentAx,'Ylim');
            XLims = get(CurrentAx,'Xlim');
            Xmin = min(-1,XLims(1));  Xmax = max(1,XLims(2));
            Ymax = max(1,YLims(2));
            XData = [Xmin real(z) Xmin Xmin Xmax Xmax Xmin];
            YData = [0 imag(z) 0 Ymax Ymax -Ymax -Ymax];
            set(this.SpectralAbscissaPatch,'XData',XData,'YData',YData,'ZData',ZLevel*ones(size(XData)));
         end
      end
   end
   
   
end


end
