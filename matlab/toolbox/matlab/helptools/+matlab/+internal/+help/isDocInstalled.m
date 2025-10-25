function b = isDocInstalled
%

%   Copyright 2008-2020 The MathWorks, Inc.

    b = isfile(fullfile(docroot, "docset.json")) || isfile(fullfile(docroot, "docset/docset.json"));
end
