function iLoc = findNamesInList(A,B)
% Locates names A in the name list B. 
%
% Assumptions:
%   * A and B are columns vectors.
%   * Names in B appear only once.
%
% Fast version of ISMEMBER for LFT model manipulations.

%   Copyright 1986-2012 The MathWorks, Inc.
nA = numel(A);
nB = numel(B);
[BA,is] = sort([B;A]);
Jrepeat = find(strcmp(BA(1:end-1),BA(2:end)));
iLoc = [(1:nB).' ; zeros(nA,1)];
for ct=1:numel(Jrepeat)
   % Note: Relies on SORT preserving original order of repeated strings
   j = Jrepeat(ct);
   iLoc(is(j+1)) = iLoc(is(j));
end
iLoc = iLoc(nB+1:nB+nA,:);
