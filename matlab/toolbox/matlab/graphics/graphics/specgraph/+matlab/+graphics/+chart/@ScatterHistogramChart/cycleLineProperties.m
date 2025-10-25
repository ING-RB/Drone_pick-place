function varargout = cycleLineProperties(nG,varargin)
%Cycle through the line properties by expansion/shrinkage
%   varargout = CYCLELINEPROPERTIES(nG,varargin) expands/shrinks the values
%   in each line property given in varargin to the number of groups nG.

%   Copyright 2018 The MathWorks, Inc.
%   Based upon stats.internal.cycleLineProperties

narginchk(2,inf);
numProps = nargin-1;
nargoutchk(0,numProps);
varargout = varargin;

for i = 1:numProps 
    if isempty(varargout{i})
        continue;
    elseif isrow(varargout{i})
        varargout{i} = expandCol(varargout{i},nG);
    elseif iscolumn(varargout{i})
        varargout{i} = expandCol(transpose(varargout{i}),nG);
        varargout{i} = transpose(varargout{i});
    elseif ismatrix(varargout{i}) % Expand rows of a color matrix
        clrMat = varargout{i};
        clrMat = expandCol(clrMat',nG);
        varargout{i} = clrMat';
    end   
end

end

function B = expandCol(A,total)
%EXPANDMAT Expand the columns of an array by replicating

colA = size(A,2);
m = ceil(total/colA);
rowB = m*colA;

B = repmat(A,1,m);

if total <rowB
    B(:,total+1:rowB)=[];
end
end