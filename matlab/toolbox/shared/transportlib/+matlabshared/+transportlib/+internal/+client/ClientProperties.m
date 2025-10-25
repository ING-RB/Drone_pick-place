classdef ClientProperties < handle
    %CLIENTPROPERTIES Base class for TransportProperties and ChannelProperties.

    % Copyright 2019-2023 The MathWorks, Inc.

    properties
        % Name for interfaces. For example,
        % "tcpclient", "serialport" and "udppport" (existing classes)
        % "visa", "bluetooth", etc (new interfaces)
        InterfaceName (1, :) string

        % Name displayed in place of the created customer interface object
        % when error/warning messages are thrown.
        % Example: if InterfaceObjectName = "t-name" the error message
        % would look as follows:
        % >> read(t,4,4,3)
        % error:
        % Invalid number of input arguments for 'read'. Valid syntaxes are
        % DATA = read(t-name,COUNT)
        % DATA = read(t-name,COUNT,PRECISION)
        InterfaceObjectName (1, 1) string

        % The handle to the customer facing interface object which is used
        % as the 'src' for the user specified BytesAvailableFcn. E.g. for
        % a user specified BytesAvailableFcn @callbackFcn(src, evt), the
        % 'src' needs to be the customer facing interface instance.
        CallbackSource

        % Sets read/write methods to have precision as
        % compulsory.
        PrecisionRequired (1, 1) logical = false

        % Contains error Ids and error messages defined by user
        ErrorRegistry

        % Contains error Ids and error messages defined by user
        WarningRegistry (1, 1) dictionary = dictionary("", "")
    end
end
