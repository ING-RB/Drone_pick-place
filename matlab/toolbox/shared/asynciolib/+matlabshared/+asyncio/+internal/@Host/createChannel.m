function channel = createChannel(host, devicePluginPath, converterPluginPath, varargin)
% A communications channel to an out-of-process device that is a data source or sink.
%
% channel = CHANNELCHANNEL(HOST, DEVICEPLUGINPATH, CONVERTERPLUGINPATH,
%                           'Options', OPTIONS, ...
%                           'StreamLimits', STREAMLIMITS, ...
%                           'MessageHandler', MESSAGEHANDLER)
% Creates a communication channel to the given out-of-process device and
% sets up the appropriate input and output streams.
%
% Inputs:
% HOST - The matlabshared.asyncio.internal.Host object
%
% DEVICEPLUGINPATH - The full path and name of the device plug-in.
% The file extension of the plug-in should be omitted.
%
% CONVERTERPLUGINPATH - The full path and name of the converter
% plug-in. The file extension of the plug-in should be omitted.
%
% OPTIONS - A structure containing information that needs to be
% passed to the device plug-in during initialization. This parameter
% is optional unless STREAMLIMITS also needs to be specified.
% The default value for this parameter is an empty structure.
%
% STREAMLIMITS - An array of two doubles that indicate the maximum
% number of items to buffer in the input and output streams. Valid
% values for each limit are between 0 and Inf, inclusive. If Inf is
% used, buffering will be limited only by the amount of memory available
% to the application. If zero is used, the stream is unbuffered and all
% reads or writes are synchronous (i.e go directly to the device).
% This parameter is optional. The default value for this parameter
% is [Inf Inf].
%
% MESSAGEHANDLER - A subclass of matlabshared.asyncio.internal.MessageHandler used to
% override the default message handling behavior. This parameter
% is optional. The default value for this parameter is an instance
% of matlabshared.asyncio.internal.MessageHandler.
%
% LIBRARYLOADSEARCHPATH - Additional search path to look for upstream DLL dependencies for
% device plug-in.
%
% OPTIMIZEDSLEEP - Boolean; If true, polled streaming sleeps of duration less than that of
% a sleep(0) shall be replaced with yields.
%
% Example:
%
% pluginPath = fullfile(matlabroot, 'toolbox', 'shared', 'asynciolib', 'bin', computer('arch'));
% converter = fullfile (pluginPath, 'testmlconverterarrays.dll');
% device = fullfile(pluginPath, 'testdevicearrays.dll');
%
% options.CustomProperty = false;
% h = matlabshared.asyncio.internal.Host();
% ch = h.createChannel(device, converter, options, [inf, inf]);
% disp(ch);
% clear ch;
% clear h;
%
% Notes:
% During initialization, the device plug-in can specify custom
% properties and their initial values. These properties will be
% created as dynamic properties on the channel object and can be
% updated at any time by the device plug-in.
%
%   See also matlabshared.asyncio.internal.Channel, matlabshared.asyncio.internal.InputStream, matlabshared.asyncio.internal.OutputStream.

% Copyright 2018-2024 The MathWorks, Inc.

    try
        serverPluginPath = fullfile(matlabroot, 'toolbox', 'shared', 'asynciolib', 'bin', computer('arch'));
        switch computer
          case {'PCWIN64'}
            hostDevice = fullfile(serverPluginPath, 'libmwipasyncio_client_proxy_device.dll');
            hostConverter = fullfile (serverPluginPath, 'libmwipasyncio_client_proxy_converter.dll');
          case {'GLNXA64'}
            hostDevice = fullfile(serverPluginPath, 'libmwipasyncio_client_proxy_device.so');
            hostConverter = fullfile (serverPluginPath, 'libmwipasyncio_client_proxy_converter.so');
          case {'MACA64'}
            hostDevice = fullfile(serverPluginPath, 'libmwipasyncio_client_proxy_device.dylib');
            hostConverter = fullfile (serverPluginPath, 'libmwipasyncio_client_proxy_converter.dylib');
          case {'MACI64'}
            hostDevice = fullfile(serverPluginPath, 'libmwipasyncio_client_proxy_device.dylib');
            hostConverter = fullfile (serverPluginPath, 'libmwipasyncio_client_proxy_converter.dylib');
        end

        if (2 ~= exist(hostDevice, 'file'))
            error(message('asyncio:HostDevice:proxyDeviceNotFound', hostDevice));
        end

        if (2 ~= exist(hostConverter, 'file'))
            error(message('asyncio:HostDevice:proxyConverterNotFound', hostConverter));
        end

        defaultLoadSearchPath = string(fullfile(matlabroot, 'bin', computer('arch')));

        parser = matlabshared.asyncio.internal.util.ChannelArgumentParser;

        [clientOptions, hostStreamLimits, messageHandler, optimizedSleep] ...
            = parser.processChannelArgs(host.getHostID(), hostConverter, devicePluginPath, defaultLoadSearchPath, varargin{:});

        channel = matlabshared.asyncio.internal.Channel(hostDevice, converterPluginPath, ...
                                                        Option = clientOptions, ...
                                                        StreamLimits = hostStreamLimits, ...
                                                        MessageHandler = messageHandler, ...
                                                        LibraryLoadSearchPath = clientOptions.LibraryLoadSearchPath, ...
                                                        OptimizedSleep = optimizedSleep);

        channelID = host.registerChannel(channel);
        wpHost = matlab.internal.WeakHandle(host);

        [~] = addlistener(channel, 'ObjectBeingDestroyed', @(src, evt) matlabshared.asyncio.internal.handleObjectBeingDestroyed(wpHost, channelID));
    catch e
        throwAsCaller(e);
    end
end

% LocalWords:  CHANNELCHANNEL DEVICEPLUGINPATH CONVERTERPLUGINPATH STREAMLIMITS MESSAGEHANDLER
% LocalWords:  matlabshared LIBRARYLOADSEARCHPATH OPTIMIZEDSLEEP testmlconverterarrays
% LocalWords:  testdevicearrays libmwipasyncio MACA dylib MACI IO's
