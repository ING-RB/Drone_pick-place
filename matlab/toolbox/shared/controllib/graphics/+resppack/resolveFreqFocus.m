function xfocus = resolveFreqFocus(h,xscale,xunits,FocusFcn)
%GETFOCUS  Computes optimal X limits for Bode plots.
% 
%   XFOCUS = resppack.resolveFreqFocus(HPLOT,XSCALE,XUNITS,FOCUSFCN)  
%   merges the user-defined focus with the frequency ranges of all visible 
%   responses and returns the plot focus XFOCUS in the current frequency 
%   units. XFOCUS controls which portion of the frequency response 
%   is displayed on the plot. FOCUSFCN is a function of the form
%      [xf,sf,ts] = FOCUSFCN(rData)
%   returning the dynamic range, SoftFocus flag, and sample time for
%   the responses with data rData.
%
%   This function is used by all frequency-domain plots with frequency on
%   the x-axis.

%   Author(s): P. Gahinet
%   Copyright 1986-2021 The MathWorks, Inc.
LOG = strcmp(xscale,'log');
% User-defined focus via BODE(SYS,W) or BODE(SYS,{WMIN,WMAX})
FreqFocus = h.FreqFocus;
if isempty(FreqFocus)
   FreqFocus = NaN(1,2);  % legacy, mostly ident
else
   FreqFocus = FreqFocus(1+LOG,:);  % 1x2, rad/s
end

% Resolve focus
UNRESOLVED = isnan(FreqFocus);
if any(UNRESOLVED)
   % Unspecified or partially specified focus.
   % Collect (log-scale) focus of all visible MIMO responses
   xfocus     = FreqFocus;
   softfocus  = false;
   sampletime = 0;
   for ct=1:numel(h.Responses)
      r = h.Responses(ct);
      % For each visible response...
      if r.isvisible
         [xf,sf,ts] = FocusFcn(r.Data(strcmp(get(r.View,'Visible'),'on')));
         xfocus = [xfocus ; xf]; %#ok<*AGROW>
         softfocus  = [softfocus ; sf];
         sampletime = [sampletime ; ts];
      end
   end
   
   % Collect focus for any requirements displayed on the plot
   xfocus    = [xfocus ; getconstrfocus(h,'rad/s')];
   softfocus = [softfocus ; false];
   
   % Merge into single focus (in rad/sec)
   xfocus = ltipack.mrgfocus(xfocus,softfocus);
   
   % Handle still unresolved focus
   if all(isnan(xfocus))
      if any(sampletime > 0)
         xfocus = [0.1 1] * pi / max(sampletime(sampletime>0));
      else
         xfocus = [1 10];
      end
   elseif isnan(xfocus(1))
      xfocus(1) = xfocus(2)/10;
   elseif isnan(xfocus(2))
      xfocus(2) = 10*xfocus(1);
   end
   
   % Unit conversion
   xfocus = xfocus*funitconv('rad/s',xunits);
   
   % Round up x-bounds to entire decades (in current units)
   if UNRESOLVED(1)
      xfocus(1) = 10^floor(log10(xfocus(1)));
   end
   if UNRESOLVED(2)
      xfocus(2) = 10^ceil(log10(xfocus(2)));
   end
else
   xfocus = FreqFocus*funitconv('rad/s',xunits);
end

% Protect against Xfocus = [a a] (g182099)
if xfocus(2)==xfocus(1)
   if xfocus(1)==0
      xfocus = [0 1];
   else
      xfocus = xfocus .* [0.1,10];
   end
end

% Finalize focus in linear scale
if ~LOG
   COMPLEX = false;  % true if systems with complex coefficients are present
   for ct=1:numel(h.Responses)
      r = h.Responses(ct);
      % For each visible response...
      if r.isvisible
         for k=1:numel(r.Data)
            if strcmp(r.View(k).Visible,'on') && ~r.Data(k).Real
               COMPLEX = true;  break
            end
         end
      end
   end
   if COMPLEX
      % Always show symmetric range when complex models are present
      xfocus = [-xfocus(2) xfocus(2)];
   elseif xfocus(1)<0.1*xfocus(2)
      % One-sided range: Round lower limit to zero when close to zero in linear scale
      xfocus(1) = 0;
   end
end