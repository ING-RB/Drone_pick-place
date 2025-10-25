classdef ChannelArgumentParser < handle
% Helper class to parse common arguments for Interprocess
% and Remote channels

% Copyright 2024 The MathWorks, Inc.

    methods(Access = public)
        function  [clientOptions, hostStreamLimits, messageHandler, optimizedSleep] ...
                = processChannelArgs(~, hostID, hostConverter, devicePluginPath, defaultLoadPath, varargin)

            try
                p = inputParser;
                p.PartialMatching = true;
                % empty struct default for options
                addParameter(p, 'Options', struct([]), @(o) validateOptions(o));
                % buffer data in both directions [inf, inf] until machine memory is available by default
                addParameter(p, 'StreamLimits', [inf, inf], @(s) validateStreamLimits(s));

                % A dedicated validation is not required for the following
                % parameters because they are validated in
                % matlabshared.asyncio.internal.Channel

                % AsyncIO's MessageHandler is the default
                addParameter(p, 'MessageHandler', matlabshared.asyncio.internal.MessageHandler);

                % User Search Directory to search out of process directories to
                % load device / converter plugin dependencies
                addParameter(p, 'LibraryLoadSearchPath', defaultLoadPath);

                % OptimizedSleep
                addParameter(p, 'OptimizedSleep', false);

                parse(p, varargin{:});
            catch e
                throwAsCaller(e);
            end

            options = p.Results.Options;
            streamLimits = p.Results.StreamLimits;
            messageHandler = p.Results.MessageHandler;
            libraryLoadSearchPath = p.Results.LibraryLoadSearchPath;
            optimizedSleep = p.Results.OptimizedSleep;

            if isempty(options)
                options = struct([]);
            end

            clientOptions.HostID = hostID;
            clientOptions.HostConverter = string(hostConverter);
            clientOptions.HostDevice = string(devicePluginPath);
            clientOptions.HostOptions = options;
            clientOptions.HostStreamLimits = streamLimits;
            clientOptions.LibraryLoadSearchPath = string(libraryLoadSearchPath);
            clientOptions.OptimizedSleep = optimizedSleep;

            % If user provided 0, make host stream limit 0.
            % If user provided >0, make host stream limit inf.
            hostStreamLimits = streamLimits;
            hostStreamLimits(hostStreamLimits > 0) = inf;
        end
    end
end

function validateStreamLimits(streamLimits)
    if ~isfloat(streamLimits) || ...
            length(streamLimits) ~= 2 || ...
            ~isrow(streamLimits) || ...
            any(isnan(streamLimits)) || ...
            streamLimits(1) < 0 || streamLimits(2) < 0

        error(message('asyncio:Channel:invalidStreamLimits'));
    end
end

function validateOptions(options)
    if ~(isstruct(options) || isempty(options))
        error(message('asyncio:Channel:invalidOptions'));
    end
end

% LocalWords:  IO's
