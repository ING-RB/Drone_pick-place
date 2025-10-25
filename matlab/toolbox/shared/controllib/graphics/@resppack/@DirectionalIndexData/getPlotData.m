function [Freq,Index] = getPlotData(Data,XSCALE)
% Prepares data for plotting.

%  Copyright 2021 The MathWorks, Inc.

% Note: Data object only stores w>=0 for real systems
Freq = Data.Frequency;
Index = Data.Index;  % nf-by-1

if strcmp(XSCALE,'log')
   % Log scale
   ixp = find(Freq>0);
   if Data.Real
      % Show only positive frequencies
      Freq = Freq(ixp,:);
      Index = Index(ixp,:);
   else
      % Complex: Fold w<0 onto w>0 with w=NaN as separator
      % Note: Always add w=NaN to ensure arrow(s) are drawn to help
      % distinguish w>0 from w<0
      ixn = find(Freq<0);
      Freq = [Freq(ixn,:) ; NaN ; Freq(ixp,:)];
      Index = [Index(ixn,:); NaN ; Index(ixp,:)];
   end
else
   % Linear scale
   if Data.Real
      % Add w<0 by symmetry
      ixp = flipud(find(Freq>0));
      Freq = [-Freq(ixp,:) ; Freq];
      Index = [Index(ixp,:) ; Index];
   end
end

