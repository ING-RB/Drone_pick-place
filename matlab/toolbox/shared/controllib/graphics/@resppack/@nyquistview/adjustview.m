function adjustview(this,Data,Event,NormalRefresh)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'prelim') hides HG objects that might interfer with 
%  limit picking.
%
%  ADJUSTVIEW(VIEW,DATA,'critical') prepares view for zooming in around the
%  critical point (handled by NYQUISTPLOT:UPDATELIMS)
%
%  ADJUSTVIEW(VIEW,DATA,'postlimit') adjusts the HG object extent once the 
%  axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2021 The MathWorks, Inc.
set(double([this.PosArrows(:);this.NegArrows(:)]),'XData',[],'YData',[])
if NormalRefresh
   Curves = this.Curves;
   if isempty(Data.Response)
      % NaN model
      set(Curves(:), 'XData', [], 'YData', [])
   else
      switch Event
         case 'prelim'
            % Show frequency range in focus
            if Data.SoftFocus
               % Quasi integrator or pure gain: Show only data in small box 
               % centered at (-1,0)
               for ct=1:numel(Curves)
                  LocalShowCriticalRange(Curves(ct))
               end
            else
               % Other cases: show frequency range of interest (plus all data in
               % small disk centered at (-1,0))
               w = abs(this.Frequency);
               LocalShowFreqRange(Curves,(w>=Data.Focus(1) & w<=Data.Focus(2))')
            end
            
         case 'critical'
            % Zoom in region around critical point
            % Hide data outside ball of rho max(4,1.5 x min. distance to (-1,0))
            for ct=1:numel(Curves)
               h = Curves(ct);
               gap = 1+complex(h.XData,h.YData);
               if ~any(diff(gap))
                  % Pure gain
                  set(double(h),'marker','*')
               else
                  distcp = abs(gap);
                  InFocus = (distcp < max(4,1.5*min(distcp)));
                  LocalShowFreqRange(h,InFocus)
               end
            end
            
         case 'postlim'
            % Restore nyquist curves to their full extent
            draw(this,Data)
            % Position and adjust arrows
            localDrawArrow(this)
      end
   end
end


%---------------------------- Local Functions --------------------

function LocalShowFreqRange(Curves, Include)
% Clips response to a given frequency range. Expects row vector INCLUDE.
npts = numel(Include);
for ct = 1:numel(Curves)
   h = Curves(ct);
   ydata = get(h, 'YData');
   if numel(ydata) == npts  % watch for exceptions (ydata=NaN)
      xdata = get(h, 'XData');
      % Using freq. focus only can unduly squeeze y limits: 
      % nyquist(tf([1e-2 1],[1 1e-5]))
      idx = find(Include | abs(xdata)+abs(ydata)<10);
      set(double(h),'XData', xdata(idx), 'YData', ydata(idx))
   end
end


function LocalShowCriticalRange(h)
% Clips response to small box centered at (-1,0)
xdata = h.XData;
ydata = h.YData;
distcp = max(abs(xdata+1),abs(ydata));
rho = max(10,1.5 * min(distcp));
xdata = min(max(xdata,-1-rho,'includenan'),-1+rho,'includenan');
ydata = min(max(ydata,-rho,'includenan'),rho,'includenan');
set(double(h),'XData', xdata, 'YData', ydata)
            

function localDrawArrow(this)
% Draw arrows indicating direction of increasing frequencies
Curves = this.Curves;
[ny,nu] = size(Curves);
Freq = this.Frequency;     % matches XData/YData of Curves
isep = find(isnan(Freq));  % look for NaN separator between w<0 and w>0
if isempty(isep)
   ineg = [];  ipos = 1:numel(Freq);
else
   ineg = 1:isep-1;  ipos = isep+1:numel(Freq);
end
% Compute arrow size, 
RAS = (0.5+this.Curves(1).LineWidth)/150;  % max arrow size
for ct=1:ny*nu
   ax = ancestor(Curves(ct),'axes');
   Xlim = get(ax,'XLim');
   Ylim = get(ax,'YLim');
   X = Curves(ct).XData;
   Y = Curves(ct).YData;
   if ~isempty(ineg)
      localPositionArrow(this.NegArrows(ct),X(ineg),Y(ineg),Xlim,Ylim,RAS);
   end
   if ~isempty(ipos)
      localPositionArrow(this.PosArrows(ct),X(ipos),Y(ipos),Xlim,Ylim,RAS);
   end
end
   
   
function localPositionArrow(harrow,X,Y,Xlim,Ylim,RAS)
% Find longest visible portion of curve, put arrow halfway along arc
inScope = find(X>Xlim(1) & X<Xlim(2) & Y>Ylim(1) & Y<Ylim(2));
delta = diff(inScope,[],2);
if any(delta==1)
   is = [0 find(delta>1) numel(inScope)];
   narc = numel(is)-1;
   L = zeros(narc,1);
   im = zeros(narc,1);
   for ct=1:narc
      iarc = inScope(is(ct)+1:is(ct+1));
      [L(ct),rim] = localArcLength(X(iarc),Y(iarc));
      im(ct) = iarc(rim);
   end
   [Lmax,imax] = max(L);
   if Lmax>0
      % Found suitable arc
      ix = im(imax);  ix = [ix ix+1];
      % Take into account how big the Nyquist plot is relative to axis frame
      Xvis = X(inScope);
      Yvis = Y(inScope);
      RPS = max((max(Xvis)-min(Xvis))/(Xlim(2)-Xlim(1)),...
         (max(Yvis)-min(Yvis))/(Ylim(2)-Ylim(1)));
      resppack.drawArrow(harrow,X(ix),Y(ix),sqrt(RPS)*RAS)
   end
end

function [L,im] = localArcLength(X,Y)
% Compute arc length and index of midpoint
n = numel(X);
if n<2
   L = 0;  im = 1;
else
   cL = [0 cumsum(sqrt(diff(X).^2+diff(Y).^2))];
   L = cL(n);
   im = min(find(cL<=L/2,1,'last'),n-1);
   %[cL(im) L/2 cL(im+1)]
end
