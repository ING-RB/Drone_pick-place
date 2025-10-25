function update(cd,r)
%UPDATE  Data update method.

%  Author(s): Rajiv Singh
%  Copyright 2013-2015 The MathWorks, Inc.

% Get data of parent response
X = cd.Parent.Frequency;  
Mag = cd.Parent.Magnitude;
Ph = cd.Parent.Phase;
nrows = length(r.RowIndex);

% Compute Peak Response
Frequency = cell(nrows, 1);
PeakGain = cell(nrows, 1);
PeakPhase = num2cell(NaN(nrows,1));
for ct = 1:nrows
   Yabs = Mag{ct};
   if any(X{ct}<0)
      % so that value for w>0 is seen first in case of symmetrical data
      [PeakGain{ct}, indMax] = max(flipud(Yabs),[],1); 
      indMax = size(Yabs,1)-indMax+1;
   else
      [PeakGain{ct}, indMax] = max(Yabs,[],1);
   end
   Frequency{ct} = X{ct}(indMax).';
   if ~isempty(Ph{ct})
      for i = 1:numel(indMax)
         PeakPhase{ct}(i) = Ph{ct}(indMax(i));
      end
   end
end
cd.Frequency = Frequency;
cd.PeakGain = PeakGain;
cd.PeakPhase = PeakPhase;
