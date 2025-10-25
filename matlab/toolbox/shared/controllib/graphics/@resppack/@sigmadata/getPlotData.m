function [Freq,SV] = getPlotData(Data,XSCALE)
% Prepares data for plotting (SIGMA, SECTORPLOT,...).

%  Copyright 2021 The MathWorks, Inc.

% Note: Data object only stores w>=0 for real systems
Freq = Data.Frequency;
SV = Data.SingularValues;
Ns = size(SV,2);

if strcmp(XSCALE,'log')
   % Log scale
   ixp = find(Freq>0);
   if Data.Real
      % Show only positive frequencies
      Freq = Freq(ixp,:);
      SV = SV(ixp,:);
   else
      % Complex: Fold w<0 onto w>0 with w=NaN as separator
      % Note: Always add w=NaN to ensure arrow(s) are drawn to help
      % distinguish w>0 from w<0
      ixn = find(Freq<0);
      Freq = [Freq(ixn,:) ; NaN ; Freq(ixp,:)];
      SV = [SV(ixn,:) ; NaN(1,Ns) ; SV(ixp,:)];
   end
else
   % Linear scale
   if Data.Real
      % Add w<0 by symmetry
      ixp = flipud(find(Freq>0));
      Freq = [-Freq(ixp,:) ; Freq];
      SV = [SV(ixp,:) ; SV];
   end
end

