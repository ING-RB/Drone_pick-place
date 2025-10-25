function winId = webwindow(modelhash, modelName, cid)
    % Copyright 2022 The MathWorks, Inc.
    % open new simulink online web window
    modelstr = dec2hex(modelhash);
    url = strcat('/toolbox/simulink/online/web/slwindow.html?m=0x', modelstr);
    url = strcat(url, '&cid=', cid);
    w = matlab.internal.webwindow(url, 'WindowContainer', 'Tabbed');
    w.Title = modelName;
    w.MATLABWindowExitedCallback = @windowExitCallback;
    w.show;
    winId = w.WinID;
end

function windowExitCallback (w, ~)
    % Try to close the returnToMATLAB notification if it is open
    simulink.online.internal.closeReturnToMATLABNotification();

    % Parse url for modelId and re-add window.
    mIndex = strfind(w.URL, 'm=');
    cidIndex = strfind(w.URL, '&')';
    modelId = w.URL(mIndex+2:cidIndex-1);
    modelId = lower(modelId);

    channel = '/mg2web/eventChannel';
    msg = struct('type', 'command', 'message', 'indexIsInitialized', 'id', modelId, 'channel', 'main');
    message.publish(channel, msg);
end