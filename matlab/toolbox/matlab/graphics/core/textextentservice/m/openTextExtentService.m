% Copyright 2022 The MathWorks, Inc.

connector.ensureServiceOn;
connector.newNonce;
url = connector.getUrl('toolbox/matlab/graphics/textextentservice/index.html');
window = matlab.internal.webwindow(url);
window.Title = 'TextExtentService';
window.show;
