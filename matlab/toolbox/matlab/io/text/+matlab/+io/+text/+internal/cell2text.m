function text = cell2text(data,varargin)
%CELL2TEXT create CSV formatted text from cell array contents

% Copyright 2020-2022 The MathWorks, Inc.

opts.AllowedTypes = "text";
opts.ThisFcn = mfilename;
opts.WriteAsFcn = @writecell;

try
    text = matlab.io.text.internal.type2text(data, opts,varargin);
catch ME
    throw(ME)
end
end
