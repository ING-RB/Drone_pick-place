function helpwinPage = helpwinDocPage(topic, helpCommandOption)
%


%   Copyright 2020-2021 The MathWorks, Inc.

arguments
    topic (1,1) string;
    helpCommandOption (1,1) string = "helpwin";
end

connector.ensureServiceOn;
connector.newNonce;
helpwinPage = matlab.internal.doc.url.HelpwinPage(topic, helpCommandOption);

end
