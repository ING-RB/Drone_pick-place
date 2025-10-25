function openWebSupportRequest
%

% Copyright 2024 The MathWorks, Inc.
    url = matlab.net.URI(matlab.internal.UrlManager().MATHWORKS_DOT_COM);
    url.Path = ["support", "contact_us.html"];
    url.Query = matlab.net.QueryParameter("s_tid", "hp_ff_s_support");
    web(string(url));
end