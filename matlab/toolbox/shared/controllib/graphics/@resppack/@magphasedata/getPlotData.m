function [Freq,Mag,Phase] = getPlotData(Data,XSCALE)
% Prepares data for plotting (BODE, NICHOLS).

%  Copyright 2021 The MathWorks, Inc.

% Note: Data object only stores w>=0 for real systems
Freq = Data.Frequency;
Mag = Data.Magnitude(:,:);
Phase = Data.Phase(:,:);
Nyu = size(Mag,2);

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
      Mag = cat(1,Mag(ixn,:),NaN(1,Nyu),Mag(ixp,:));
      Phase = cat(1,Phase(ixn,:),NaN(1,Nyu),Phase(ixp,:));
   end
else
   % Linear scale
   if Data.Real
      % Add w<0 by symmetry
      ixp = flipud(find(Freq>0));
      Freq = [-Freq(ixp,:) ; Freq];
      Mag = cat(1,Mag(ixp,:),Mag);
      PhaseCjg = -Phase(ixp,:);
      if ~isempty(PhaseCjg)
         % Eliminate phase jump across w=0
         TwoPi = unitconv(2*pi,'rad',Data.PhaseUnits);
         for ct=1:Nyu
            offset = TwoPi * round((Phase(1,ct)-PhaseCjg(end,ct))/TwoPi);
            PhaseCjg(:,ct) = PhaseCjg(:,ct) + offset;
         end
      end
      Phase = cat(1,PhaseCjg,Phase);
   end
end
