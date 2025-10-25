classdef TCPCustomClient < matlabshared.transportlib.internal.client.GenericClient
%TCPCUSTOMCLIENT Handles the read and write functionality for tcpclient.
% It allows access to the shared implementation for the tcpclient class.

%   Copyright 2020 The MathWorks, Inc

    %% Lifetime
    methods
        function obj = TCPCustomClient(clientProperties)
            obj@matlabshared.transportlib.internal.client.GenericClient(clientProperties);
        end
    end

    %% API
    methods
        function data = read(obj, varargin)
        %READ Reads data from the remote host.
        %
        %   DATA = READ(OBJ) reads values from the tcpclient object
        %   connected to the remote host, OBJ, and returns to DATA. The
        %   number of values read is given by the BytesAvailable property.
        %
        %   DATA = READ(OBJ,SIZE) reads the specified number of values,
        %   SIZE, from the tcpclient object connected to the remote host,
        %   OBJ, and returns to DATA.
        %
        %   DATA = READ(OBJ,SIZE,DATATYPE) reads the specified
        %   number of values, SIZE, with the specified precision,
        %   DATATYPE, from the tcpclient object connected to the
        %   remote host, OBJ, and returns to DATA.
        %
        % Inputs:
        %   SIZE indicates the number of items to read. SIZE cannot be
        %   set to INF. If SIZE is greater than the OBJ's
        %   BytesAvailable property, then this function will wait until
        %   the specified amount of data is read.
        %
        %   DATATYPE indicates the number of bits read for each value
        %   and the interpretation of those bits as a MATLAB data type.
        %   DATATYPE must be one of 'UINT8', 'INT8', 'UINT16',
        %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE',
        %   'DOUBLE','CHAR', or 'STRING'.
        %
        % Outputs:
        %   DATA is a 1xN matrix of numeric or ASCII data. If no data was
        %   returned this will be an empty array.
        %
        % Notes:
        %   READ will wait until the requested number of values are
        %   read from the remote host.
        %
        % Example:
        %      % Read data available in the input buffer as "uint8".
        %      data = read(t);
        %
        %      % Read 5 count of data "uint8".
        %      data = read(t,5);
        %
        %      % Read 5 count of data, or 20 bytes, as "uint32".
        %      % (5*4 = 20 bytes)
        %      data = read(t,5,"uint32");

            try
                narginchk(1, 3);
            catch
                ex = MException(message...
                    ('transportlib:client:IncorrectInputArgumentsPlural', ...
                    'read', message('MATLAB:networklib:tcpclient:readSyntax').getString));
                throw(ex);
            end

            numValuesToRead = getProperty(obj, "NumBytesAvailable");
            dataType = 'uint8';

            % convert to char in order to accept string datatype
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            switch nargin
              case 2
                numValuesToRead = varargin{1};
              case 3
                numValuesToRead = varargin{1};
                dataType = varargin{2};
            end

            try
                data = read(obj.Transport, numValuesToRead, dataType);
            catch receiveException
                if strcmpi(receiveException.identifier, 'transportlib:transport:invalidConnectionState')
                    delete(obj);
                    throwAsCaller(MException('MATLAB:networklib:tcpclient:connectTerminated', ...
                        message('MATLAB:networklib:tcpclient:connectTerminated').getString()));
                else
                    throwAsCaller(MException('MATLAB:networklib:tcpclient:readFailed', ...
                        receiveException.message));
                end
            end
        end

        function write(obj, varargin)
        %WRITE Writes data to the remote host.
        %
        %   WRITE(OBJ,DATA) sends the N dimensional matrix of data to
        %   the remote host.
        %
        %   WRITE(OBJ,DATA,PRECISION) sends the 1xN matrix of data to
        %   the remote host. The data is cast to the specified
        %   precision PRECISION regardless of the actual precision.
        %
        % Inputs:
        %   DATA is a 1xN matrix of numeric or ASCII data. ASCII data is
        %   applicable only when precision is specified.
        %
        %   PRECISION controls the number of bits written for each value
        %   and the interpretation of those bits as integer, floating-point,
        %   or character values.
        %   PRECISION must be one of 'CHAR','STRING','UINT8', 'INT8', 'UINT16',
        %   'INT16', 'UINT32', 'INT32', 'UINT64', 'INT64', 'SINGLE', or
        %   'DOUBLE'.
        %
        % Notes:
        %   WRITE will wait until the requested number of values are
        %   written to the remote host.
        %
        % Example:
        %      % Writes 1, 2, 3, 4, 5 as "double". (5*8 = 40 bytes total)
        %      % to the remote host.
        %      write(t,1:5);
        %
        %      % Writes 1, 2, 3, 4, 5 as "uint8". (5*1 = 5 bytes total)
        %      % to the remote host.
        %      write(t,1:5,"uint8");

            try
                narginchk(2, 3);
            catch
                obj.UserNotificationHandler.throwNarginErrorPlural('write');
            end

            try
                varargin = instrument.internal.stringConversionHelpers.str2char(varargin);
                data = varargin{1};
                if nargin == 3
                    precision = varargin{2};
                    write(obj.Transport,data, precision);
                else
                    write(obj.Transport,data);
                end
            catch sendException
                if strcmpi(sendException.identifier, 'transportlib:transport:invalidConnectionState')
                    delete(obj);
                    throwAsCaller(MException('MATLAB:networklib:tcpclient:connectTerminated', ...
                        message('MATLAB:networklib:tcpclient:connectTerminated').getString()));
                else
                    throwAsCaller(MException('MATLAB:networklib:tcpclient:writeFailed', ...
                        sendException.message));
                end
            end
        end
    end
end
