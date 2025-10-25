function [out, docTopic] = help(varargin)
    % Help is helpful!
    cleanup.cache = matlab.lang.internal.introspective.cache.enable; %#ok<STRNU>

    process = matlab.internal.help.helpProcess(nargout, nargin, varargin);
    if isnumeric(process.inputTopic)
        process.inputTopic = inputname(process.inputTopic);
    end

    try %#ok<TRYNC>
        % no need to tell customers about internal errors

        process.callerContext = matlab.lang.internal.introspective.IntrospectiveContext.caller;

        process.getHelpText;

        process.prepareHelpForDisplay;
    end

    if nargout > 0
        out = process.helpStr;
        if nargout > 1
            docTopic = process.docLinks.referencePage;
            if isempty(docTopic)
                docTopic = process.docLinks.productName;
            end
        end
    end
end

%   Copyright 1984-2023 The MathWorks, Inc.
