function url = getConnectorUrlForLogin()
    loginUrl = matlab.internal.login.getLoginFrameUrl( ...
        "channel", "__mlfpmc__", ...
        "external", true);
    url = connector.getUrl(loginUrl);
end

% Copyright 2022 The MathWorks, Inc.
