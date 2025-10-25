function xfocus = getfocus(this)
%GETFOCUS  Computes optimal X limits for wave plot 
%          by merging Focus of individual waveforms.

%  Copyright 1986-2021 The MathWorks, Inc.

% Merge individual focus of all visible responses
xfocus = NaN(1,2);
allResp = allwaves(this);
for ct=1:numel(allResp)
   % For each visible response...
   rct = allResp(ct);
   if rct.isvisible
      data = rct.Data;
      for k=1:numel(data)
         if strcmp(rct.View(k).Visible,'on')
            xfocus = ltipack.mrgfocus([xfocus;data(k).Focus]);
         end
      end
   end
end

if all(isnan(xfocus))
   xfocus = [0 1];
else
   % Round upper limit
   xfocus(2) = tchop(xfocus(2));
end
