function sendDDUXTimingMarkerEvent(obj, appHandle, fieldName)
%SENDDDUXTIMINGMARKEREVENT Send DDUX timing marker event to
% AppDDUXTimingManager

%   Copyright 2024 The MathWorks, Inc.
    eventData = appdesigner.internal.ddux.CreateAppDDUXTimingMarkerEventData(appHandle, fieldName);
    notify(obj, 'AppDDUXTimingMarker', eventData);
end
