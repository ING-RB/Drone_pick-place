classdef PropertiesFactory
    %PROPERTIESFACTORY Creates property class based on client type.

    % Copyright 2019 The MathWorks, Inc.

    methods(Static)
        function clientProps = getInstance(clientType)
            clientType = instrument.internal.stringConversionHelpers.str2char(clientType);
            switch clientType
                case 'transport'
                    clientProps = matlabshared.transportlib.internal.client.TransportProperties;
                case 'channel'
                    clientProps = matlabshared.transportlib.internal.client.ChannelProperties;
            end
        end
    end
end

