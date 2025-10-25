function ext = getExtension(filename)
%GETEXTENSION Returns the extension for a given filename.  If there is no
%extension, returns 'xlsx'.

% Copyright 2016-2024 The MathWorks, Inc.

[~,~,ext] = fileparts(filename);
if strlength(ext) > 0
    if isstring(filename)
        ext = ext{1}(2:end);
    else
        ext = ext(2:end);
    end
elseif matlab.io.internal.common.validators.isGoogleSheet(filename)
    ext = 'gsheet';
else
    ext = 'xlsx';
end
end

