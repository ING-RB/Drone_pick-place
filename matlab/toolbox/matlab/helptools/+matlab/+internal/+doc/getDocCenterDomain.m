function domain = getDocCenterDomain()
%% This function used by  MATLAB Connector in support of Help Data Service
%  getting Doc Center web service endpoint. 
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2016-2020 The MathWorks, Inc.
    docSettings = matlab.internal.doc.services.DocSettings.instance;
    domain = char(docSettings.Domain);
end
