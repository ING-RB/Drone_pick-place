function [javaRichDocument, webWindow] = createDocument(timeout,webWindow)
%

%   Copyright 2016-2024 The MathWorks, Inc.

if nargin < 1
    timeout = [];
end

if nargin < 2
    webWindow = [];
end

% Disable prewarming of embedded outputs
prewarmingSuppressor = matlab.internal.editor.PrewarmingSuppressor(); %#ok<NASGU>

% Create the rich document object
javaRichDocument = com.mathworks.mde.liveeditor.widget.rtc.RichDocument();

% Set up the web window
webpath = char(javaRichDocument.getWebPath());
url = connector.getUrl(webpath);
if ~isempty(webWindow)
    webWindow.URL = url;
else
    webWindow = matlab.internal.cef.webwindow(url, matlab.internal.getDebugPort);
    % Use a wider webwindow to prevent figures from shrinking when running the script
    % and remove horizontal scrollbar from the elements like live tasks.
    webWindow.Position = [0 0 1300 768];
end

try
    if ~isempty(timeout)
        com.mathworks.mde.liveeditor.widget.rtc.RichDocumentFactory.waitForDocumentToBeReady(javaRichDocument, timeout);
    else
        com.mathworks.mde.liveeditor.widget.rtc.RichDocumentFactory.waitForDocumentToBeReady(javaRichDocument);
    end
catch TimeOutException
    % Get some diagnostic information 
    handleTimeOutException(webWindow);
    rethrow(TimeOutException)
end

end

function handleTimeOutException(webWindow)
% Handle java exception thrown while waiting for the document to initialize

    timeout = 60; % 1 minute
    
    % Determine if the java script console is working/busy
    try
        result = webWindow.executeJS('true', timeout);
        if ~strcmp(result, 'true')
            warning('matlab:internal:liveeditor:jsnotworking', 'Unable to run javascript in the console.');
        end
    catch jsException
        % Get webwindow diagnostics here, when available
        
        rethrow(jsException)
    end
    
    %Add process list
    if isunix()
        %Print 1 iteration and sort by CPU usage
        if ismac()
            system('top -l 1 -o cpu');
        else
            system('top -o %CPU -n 1');
        end
    end
end

