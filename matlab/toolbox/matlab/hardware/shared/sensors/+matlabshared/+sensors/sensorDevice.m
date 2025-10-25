classdef sensorDevice < matlab.System

    %  Copyright 2023 The MathWorks, Inc.

%#codegen
    methods(Abstract, Access = protected)
        writeRegisterImpl(obj, registerAddress, data, precision);
        writeImpl(obj, registerAddress);
        data = readRegisterImpl(obj, registerAddress, count, precision);
        [readValue,status,timestamp] = readRegisterDataImpl(obj, registerAddress);
    end

    methods
        function write(obj,registerAddress)
            if (nargin < 2)
                error(message('MATLAB:minrhs'));
            end
            writeImpl(obj, registerAddress);
        end

        function writeRegister(obj, registerAddress, data)
            % Sensor object calls this method directly.
            if (nargin < 3)
                error(message('MATLAB:minrhs'));
            end
            writeRegisterImpl(obj, registerAddress, data);
        end

        function data = readRegister(obj, registerAddress, varargin)
            % Sensor object calls this method directly.
            narginchk(2, 4);
            if nargin < 3
                count = 1;
                precision = "uint8";
            end
            if nargin == 3
                if ischar(varargin{1}) || isstring(varargin{1})
                    precision = varargin{1};
                    count = 1;
                elseif isnumeric(varargin{1})
                    count = varargin{1};
                    precision = "uint8";
                else
                    error(message('MATLAB:maxrhs'));
                end
            end
            if nargin == 4
                count = varargin{1};
                precision = varargin{2};
            end
            data = readRegisterImpl(obj, registerAddress, count, precision);
        end

        function [readValue,status,timestamp] = readRegisterData(obj, registerAddress, varargin)
            if nargin == 5
                count = varargin{1};
                precision = varargin{2};
                multiByteReadValue = varargin{3};
            elseif nargin == 4
                count = varargin{1};
                precision = varargin{2};
                multiByteReadValue = [];
            else
                count = varargin{1};
                precision = 'uint8';
                multiByteReadValue = [];
            end

            [readValue,status,timestamp] = readRegisterDataImpl(obj, registerAddress, count, precision,multiByteReadValue);
        end
    end

end