classdef MessageHandler < matlabshared.asyncio.internal.MessageHandler
    % Message Handler to handle ayncio errors

    %   Copyright 2017-2024 The Mathworks, Inc

    properties(WeakHandle, GetAccess='private', SetAccess=?audiovideo.internal.writer.plugin.IPlugin)
        % Plugin property holds a reference to an IPlugin object.
        % 'WeakHandle' allows Plugin to be garbage collected when
        % no other references exist, avoiding memory leaks.
        % Initialized as an empty handle placeholder as it does not have constant type
        % and can be initialize later based on plugin type.
        Plugin handle = matlab.lang.HandlePlaceholder.empty
    end

    methods(Access='public')
        function onError(obj, data)
            obj.Plugin.onDeviceError(data);
        end
    end
end