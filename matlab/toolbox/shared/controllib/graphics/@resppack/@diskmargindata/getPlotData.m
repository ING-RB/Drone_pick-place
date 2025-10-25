function [Freq,Mag,Phase] = getPlotData(Data,XSCALE)
% Prepares data for plotting.

%  Copyright 2021 The MathWorks, Inc.

% Note: Data object only stores w>=0 for real systems
Freq = Data.Frequency;
Mag = Data.Magnitude;
Phase = Data.Phase;

if strcmp(XSCALE,'log')
   % Log scale
   ixp = find(Freq>0);
   if Data.Real
      % Show only positive frequencies
      Freq = Freq(ixp,:);
      Mag = Mag(ixp,:,:);
      Phase = Phase(ixp,:,:);
   else
      % Complex: Fold w<0 onto w>0 with w=NaN as separator
      ixn = find(Freq<0);
      Freq = [Freq(ixn,:) ; NaN ; Freq(ixp,:)];
      Mag = [Mag(ixn,:) ; NaN ; Mag(ixp,:)];
      Phase = [Phase(ixn,:) ; NaN ; Phase(ixp,:)];
   end
else
   % Linear scale
   if Data.Real
      % Add w<0 by symmetry
      ixp = flipud(find(Freq>0));
      Freq = [-Freq(ixp,:) ; Freq];
      Mag = [Mag(ixp,:) ; Mag];
      % Note: Phase margin reflected for negative frequencies
      Phase = [Phase(ixp,:) ; Phase];
   end
end
