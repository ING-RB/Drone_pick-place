function warnOnBOMmismatch(BOM,actEnc)
% Warn on unexpected BOM

% Copyright 2018-2019 The MathWorks, Inc.
if  ~strcmpi(BOM.Encoding,actEnc)
    % We found a BOM, but it doesn't match the input encoding.
    warning(message('MATLAB:textio:textio:BOMEncodingMismatch',BOM.Encoding,actEnc));
end

