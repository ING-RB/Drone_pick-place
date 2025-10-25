classdef ErrorRegistry < handle
    %ERRORREGISTRY is a storage class for error Ids and messages to be used
    % by the UserNotificationHandler class.
    %
    % CommonErrorIDs:
    %     "transportlib:client:ReadOnlyProperty",
    %     (error thrown when setting BytesAvailableFcn, BytesAvailableFcnCount,
    %      BytesAvailableFcnMode, Terminator directly without using
    %      configureCallback, configureTerminator)
    %
    %     "transportlib:client:NotSupportedFunctionality",
    %     (eg. error thrown when calling execute, getCustomProperty on
    %      TransportClient object as it does not contain the AsyncIO Channel.
    %      The AsyncIO Channel exists inside the transport for the existing interface)
    %
    %     "transportlib:client:NoInterfaceObjectName",
    %     (error thrown when setting empty InterfaceObjectName)
    %
    %     "transportlib:client:NoInterfaceName",
    %     (error thrown when setting empty InterfaceName)
    %
    %     "transportlib:client:NoICTLicense",
    %     (error thrown when using readbinblock, writebinblock and writeread with no
    %      ICT license)
    %
    %     "transportlib:client:IncorrectInputArgumentsPlural",
    %     (error thrown when incorrect number input arguments are used in APIs
    %      that have multiple syntaxes - flush, read, write, configureCallback,
    %      configureTerminator, readbinblock)
    %
    %     "transportlib:client:IncorrectInputArgumentsSingular",
    %     (error thrown when incorrect number of input arguments are used in APIs
    %      with single syntax - read(precision required), write(precision
    %      required), readline, writeline, writebinblock, writeread)
    %
    %     "transportlib:client:IncorrectBytesAvailableModeSyntax",
    %     (error thrown when the BytesAvailableFcnMode is not in accordance
    %      with the number of input arguments for that mode in configureCallback)
    %
    %     "transportlib:client:InvalidErrorOccurredFcn",
    %     (error thrown when setting ErrorOccurredFcn with an invalid value)
    %
    %     "transportlib:client:InvalidBytesAvailableFcn",
    %     (error thrown when setting BytesAvailableFcn with an invalid value)
    %
    %     "transportlib:client:InvalidTerminator",
    %     (error thrown when setting Terminator with an invalid value)
    %
    %     "transportlib:client:InvalidClientProperties",
    %     (error thrown if the input to GenericClient constructor is not
    %      of type 'ClientProperties')
    %
    %     "transportlib:client:InvalidTransportType",
    %     (error thrown if the input 'clientProperties.Transport' to GenericClient
    %      constructor is not of type ITransport, ITokenReader and IFilterable)
    %
    %     "transportlib:client:InvalidClient",
    %     (error thrown if the created Client in GenericClient is not of
    %      type IClient)
    %
    %     "transportlib:client:EmptyPlugins",
    %     (error thrown if DevicePlugin and ConverterPlugin properties
    %      in ClientProperties are empty when creating a ChannelClient)

    % Copyright 2019 The MathWorks, Inc.

    properties (SetAccess = {?matlabshared.transportlib.internal.client.utility.UserNotificationHandler})
        ErrorMap containers.Map
    end

    %% Lifetime
    methods
        function obj = ErrorRegistry(varargin)
            narginchk(0, 1);
            if nargin == 1
                obj.ErrorMap = varargin{1};
                keyValues = keys(obj.ErrorMap);
                for i = 1 : length(keyValues)
                    key = keyValues{i};
                    obj.validateKeyValue(key, obj.ErrorMap(key));
                end
            end
        end
    end

    %% Helper functions
    methods
        function register(obj, key, value)
            % Helper function to add custom error Ids and messages as
            % entries to ErrorRegistry

            obj.validateKeyValue(key, value);
            obj.ErrorMap(key) = value;
        end
    end

    methods (Access = private)
        function validateKeyValue(~, key, value)
            key = instrument.internal.stringConversionHelpers.str2char(key);
            if ~ischar(key) || isempty(key)
                throwAsCaller(MException(message('transportlib:utils:KeyNotString')));
            end
            if ~isa(value, "matlabshared.transportlib.internal.client.utility.ErrorEntry")
                throwAsCaller(MException(message('transportlib:utils:InvalidErrorEntry')));
            end
        end
    end
end

