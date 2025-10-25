classdef TransportProperties < matlabshared.transportlib.internal.client.ClientProperties
    %TRANSPORTPROPERTIES is a class for setting options to create a TransportClient class. Gets passed
    % into GenericClient class.

    % Copyright 2019 The MathWorks, Inc.

    properties
        % Used for reading and writing binary, ASCII and token data from the AsyncIO Channel
        % ITransport, ITokenReader and IFilterable type
        Transport
    end
end