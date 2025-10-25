% Copyright 2024 The MathWorks, Inc.

connector.ensureServiceOn;
connector.newNonce;
url = connector.getUrl('toolbox/deployment/share_window/web/share_window_common/index.html');
window = matlab.internal.webwindow(url);
window.Title = 'Share_window_common';
window.show;
