function [gotPreview, previewData] = getPreviewIfCheap(t)
% getPreviewIfCheap Check if we can preview the data without evaluating
% everything and if so return a sample of the data.
%
%   [gotPreview, previewData] = matlab.bigdata.internal.util.getPreviewIfCheap(T) 
%   for tall array T returns true false in gotPreview indicating whether the 
%   preview data was available and if true return a sample of the data in
%   previewData.
%
%   See also: matlab.bigdata.internal.util.isPreviewCheap

% Copyright 2023 The MathWorks, Inc.

N = matlab.bigdata.internal.util.defaultHeadTailRows();
gotPreview = false;
previewData = [];

% For in-memory arrays, just return a sample
if ~istall(t)
    previewData = head(t, N);
    gotPreview = true;
    return;
end

pa = hGetValueImpl(t);

% Make sure we are dealing with a simple partitioned array
if ~isa(pa,"matlab.bigdata.internal.lazyeval.LazyPartitionedArray")
    return;
end

% For tall arrays, check if we can access the preview either from the cache
% or without causing any evaluation. If so extract a sample. This logic is
% largely copied from getArrayInfo.
if hasCachedPreviewData(pa)
    previewData = head(getCachedPreviewData(pa),N);
    gotPreview = true;

elseif matlab.bigdata.internal.util.isPreviewCheap(pa)
    cheapPreviewGuard = matlab.bigdata.internal.lazyeval.CheapPreviewGuard(); %#ok
    % Gathering data can expose previous errors that we don't want to throw
    % here so put in a try...catch.
    try
        previewData = gather(matlab.bigdata.internal.lazyeval.extractHead(pa, N));
        gotPreview = true;
    catch err
        return;
    end

end

end