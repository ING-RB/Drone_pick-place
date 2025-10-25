function h = dataevent(hSrc,eventName,data)
%DATAEVENT  Subclass of EVENTDATA to handle mxArray-valued event data.

%   Author(s): P. Gahinet
%   Copyright 1986-2004 The MathWorks, Inc.


% Create class instance
h = ctrluis.dataevent(hSrc,eventName);
h.Data = data;
