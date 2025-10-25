function reset(this,varargin)
%RESET  Clears dependent data when model changes.

%   Copyright 1986-2010 The MathWorks, Inc.

% REVISIT: Use direct assignments into struct when works
C = this.Cache;
for ct=1:numel(C)
   C(ct).Stable = [];
   C(ct).MStable = [];
   C(ct).DCGain = [];
   C(ct).Margins = [];
end
this.Cache = C;

