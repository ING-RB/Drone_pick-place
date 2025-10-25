function D = getModelData(this,idxModel)
% Extracts low-level data representation of LTI model

%  Copyright 1986-2010 The MathWorks, Inc.
D = this.PlotLTIData;
if nargin>1
   D = D(idxModel);
end

