function showBeamSpan(p, id1, id2, datasetIndex)
%showBeamSpan Display beamwidth span in a antenna pattern.
%   showBeamSpan(p, id1, id2) displays beamwidth for an antenna
%   radiation pattern expressed in dB.  Information is shown for the active
%   dataset if multiple datasets are present.
%
%   See also, showLobes(P,datasetIdx) shows lobes for the specified dataset.
%

hideLobesAndMarkers(p);
a = createAntennaObjOnce(p);
if nargin < 4 || isempty(datasetIndex)
    datasetIndex = p.pCurrentDataSetIndex;
end

L.BWIdx = [id1 id2];
showLobeSpan(a,'bw',datasetIndex, L);
end