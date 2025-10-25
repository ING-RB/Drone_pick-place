function this = marginsource(L,sigma,StableFlag)
% Constructor for @marginsource class

%   Copyright 1986-2020 The MathWorks, Inc.

% Convert L to SS or FRD
if ~isa(L,'FRDModel')
   % Convert to state-space representation, preserving USS for sampling
   L = makeStateSpace(L);
end

% Create class instance
this = resppack.marginsource;
this.Model = L;   % note: set function samples USS
this.Skew = sigma;

% Closed-loop stability flag
N = getNumResp(this);
if nargin>2
   if isscalar(StableFlag) && N>1
      StableFlag = repmat(StableFlag,[N 1]);
   end
   this.Cache = struct('Stable',num2cell(StableFlag));
else
   this.Cache = struct('Stable',cell(N,1));
end

% Add listeners
addlisteners(this)