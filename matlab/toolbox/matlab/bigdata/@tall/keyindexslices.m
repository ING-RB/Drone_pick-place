function tY = keyindexslices(tX, tXKeys, tIdxKeys, varargin)
%KEYINDEXSLICES Perform a keyed indexing operation. This is similar to
% numeric subsref, but where you can replace 1:size(X,1) with sorted keys.
%
%   tY = keyindexslices(tX, tXKeys, tIdxKeys)
%   tY = keyindexslices(..,'XPartitionBoundaries',xPartitionBoundaries)
%   tY = keyindexslices(..,'MissingIdxError',missingIdxError)
%   tY = keyindexslices(..,'DuplicateIdxError',duplicateIdxError)
%
% See also matlab.bigdata.internal.lazyeval.keyindexslices

%   Copyright 2018-2019 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame; %#ok<NASGU>

try
    xAdaptor = tX.Adaptor;
    idxAdaptor = tIdxKeys.Adaptor;
    
    for ii = 1:numel(varargin)
        if istall(varargin{ii})
            varargin{ii} = hGetValueImpl(varargin{ii});
        end
    end
    tY = tall(matlab.bigdata.internal.lazyeval.keyindexslices(...
        hGetValueImpl(tX), hGetValueImpl(tXKeys), hGetValueImpl(tIdxKeys), varargin{:}));
    tY.Adaptor = copyTallSize(xAdaptor, idxAdaptor);
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    rethrow(err);
end
