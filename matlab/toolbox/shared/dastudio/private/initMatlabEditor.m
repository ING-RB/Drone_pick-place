function url = initMatlabEditor(isDebug)

connector.ensureServiceOn;
if ~connector.isRunning
    warning(message('dastudio:util:FailedToStartConnector'));
    return;
end

if isDebug
    htmlPath = '/toolbox/shared/dastudio/web/matlabeditor/index-debug.html';
else
    htmlPath = '/toolbox/shared/dastudio/web/matlabeditor/index.html';

end

url = connector.getUrl(htmlPath);
