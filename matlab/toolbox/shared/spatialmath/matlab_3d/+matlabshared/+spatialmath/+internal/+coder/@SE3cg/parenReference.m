function outObj = parenReference(obj, varargin)
%This method is for internal use only. It may be removed in the future.

%parenReference Invoked when indexing into the object array
%   If A inherits from matlab.mixin.internal.indexing.Paren, then a(....)
%   is rewritten as a.parenReference(...).

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Find indices to retrieve
    indices = obj.MInd(varargin{:});
    M = obj.M(:,:,indices);

    outObj = obj.fromMatrix(M,size(indices));

end
