function setTimeFocus(this,tspec,tunits)
% Sets user-defined x-range in time-domain plots like STEP. 
%
% TSPEC is a final time Tf, a time vector t, or [].
if nargin<3
   tunits = this.AxesGrid.XUnits;
end
if ~isempty(tspec)
   if isscalar(tspec)
      tfocus = [0 tspec];
   else
      tfocus = [tspec(1) tspec(end)];
   end
   this.TimeFocus = tfocus*tunitconv(tunits,'seconds');
end