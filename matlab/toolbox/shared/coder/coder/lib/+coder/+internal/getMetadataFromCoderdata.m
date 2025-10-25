function out = getMetadataFromCoderdata(fname)
%MATLAB Code Generation Private Method
%   Copyright 2021 The MathWorks, Inc.
[~,~,ext] = fileparts(fname);
coder.internal.errorIf(strcmp(ext, '.mat'), 'Coder:toolbox:CoderReadMATFile', fname);
cType = coder.internal.readTypeHeader(fname);
out = coder.internal.coderTypeToLoadInfo(cType, 'SkipWarnings');

end