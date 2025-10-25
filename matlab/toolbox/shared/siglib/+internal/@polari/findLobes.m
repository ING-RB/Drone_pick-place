function L = findLobes(p,datasetIndex,forceRecompute)
% L = FINDLOBES(p,datasetIndex) returns a structure defining
% main, back and side lobes identified in data, assuming polar
% data corresponding to an antenna radiation pattern expressed
% in dB.
%
% FINDLOBES(p) returns lobe structure for current dataset.
%
% See also polarpattern.

createAntennaObjOnce(p);
if nargin < 2 || isempty(datasetIndex)
    datasetIndex = p.pCurrentDataSetIndex;
end
if nargin < 3
    forceRecompute = false;
end
L = findLobes(p.hAntenna,datasetIndex,forceRecompute);
