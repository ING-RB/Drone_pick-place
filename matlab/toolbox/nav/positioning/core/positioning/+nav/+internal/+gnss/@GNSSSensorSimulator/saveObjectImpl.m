function s = saveObjectImpl(obj)
%SAVEOBJECTIMPL Save nav.internal.gnss.GNSSSensorSimulator object

%   Copyright 2022 The MathWorks, Inc.

% Save public properties.
s = saveObjectImpl@matlab.System(obj);

% Save private values of dependent properties.
s.pTimeZone = obj.pTimeZone;
s.pFormat = obj.pFormat;
s.pGPSWeek = obj.pGPSWeek;
s.pTimeOfWeek = obj.pTimeOfWeek;
    
% Save private properties.
if isLocked(obj)
    s.pInputPrototype = obj.pInputPrototype;
    s.pCurrTime = obj.pCurrTime;
    s.pRefFrame = obj.pRefFrame;
    
    if strcmp(obj.RandomStream, 'mt19937ar with seed')
        if ~isempty(obj.pStream)
            s.pStreamState = obj.pStream.State;
        end
    end
end
end
