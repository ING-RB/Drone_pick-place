function obj = parenReference(obj, varargin)
%This method is for internal use only. It may be removed in the future.

%parenReference Invoked when indexing into the object array
%   If A inherits from matlab.mixin.internal.indexing.Paren, then a(....)
%   is rewritten as a.parenReference(...).
%
%   See also parenAssign.

%   Copyright 2022-2024 The MathWorks, Inc.

    indices = obj.MInd(varargin{:});
    obj.M = obj.M(:,:,indices);
    obj.MInd = obj.newIndices(size(indices));

end
