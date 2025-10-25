% Sends a peer event

% Copyright 2014-2023 The MathWorks, Inc.

function sendPeerEvent(peerNode, eventType, varargin)
    % Check for paired values
    if nargin<2 || rem(nargin-2, 2)~=0
        error(message('MATLAB:codetools:variableeditor:UseNameRowColTriplets'));
    end
    s = struct('type', eventType, 'source', 'server');
    for i=1:2:nargin-2
        s.(varargin{i}) = varargin{i+1};
    end
    if isa(peerNode, 'viewmodel.internal.ViewModel')
        payload = struct( ...
            'eventName', 'peerEvent', ...
            'eventDataStruct', s);
        peerNode.dispatchEvent('peerEvent', payload);
    else
        s.('type') = eventType;
        peerNode.dispatchEvent(s);
    end
end
