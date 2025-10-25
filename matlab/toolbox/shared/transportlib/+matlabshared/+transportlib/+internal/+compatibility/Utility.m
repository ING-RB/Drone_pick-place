classdef (Hidden) Utility < handle
    %UTILITY Utility class used to wrap common utilities required by
    %multiple classes in the legacy compatibility layer.

    % Copyright 2021 The MathWorks, Inc.
    
    %#codegen

    methods (Static)
        function [precision, datasize] = convertLegacyPrecision(oldPrecision) 
            nargoutchk(1, 2)
            switch oldPrecision
                case {'uchar', 'char'}
                    precision = "uint8";
                    datasize = 1;
                case 'schar'
                    precision = "int8";
                    datasize = 1;
                case 'int8'
                    precision = "int8";
                    datasize = 1;
                case {'int16', 'short'}
                    precision = "int16";
                    datasize = 2;
                case {'int32', 'int', 'long'}
                    precision = "int32";
                    datasize = 4;
                case 'uint8'
                    precision = "uint8";
                    datasize = 1;
                case {'uint16', 'ushort'}
                    precision = "uint16";
                    datasize = 2;
                case {'uint32', 'uint', 'ulong'}
                    precision = "uint32";
                    datasize = 4;
                case {'single', 'float32', 'float'}
                    precision = "single";
                    datasize = 4;
                case {'double' ,'float64'}
                    precision = "double";
                    datasize = 8;
                otherwise
                    msg = 'MATLAB:serial:fread:invalidPRECISION';
                    e = matlabshared.transportlib.internal.compatibility.Utility.getException(msg);
                    throwAsCaller(e);
            end
        end

        function e = getException(id, varargin)
            % Create an exception using the provided ID and slot
            % parameters.
            e = MException(id, getString(message(id, varargin{:})));
        end

        function sendWarning(id, varargin)
            % Temporarily turn off the backtrace
            warningState = warning('off','backtrace');
            oc = onCleanup(@() warning(warningState));
            if coder.target("MATLAB")
                try
                    warning(message(id, varargin{:}));
                catch e
                    rethrow(e);
                end
            else
                warning(message(id, varargin{:}));
            end
        end
    end
end
