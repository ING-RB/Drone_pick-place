function wsEndPoint = getWSEndPointForAddOnExplorer()
% GETWSENDPOINTFORADDONEXPLORER Get web service end point to be used for Add-on
%                               Explorer
%  

% Copyright 2020 The MathWorks, Inc.

urlManager = matlab.internal.UrlManager;
wsEndPoint = urlManager.ADD_ONS;

end

