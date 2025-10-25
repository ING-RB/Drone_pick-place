classdef (Abstract) LegacyQueryMixin < matlabshared.transportlib.internal.compatibility.LegacyNullMixin
    %LEGACYQUERYMIXIN Shared implementation of legacy support for the query
    %operation.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2021-2022 The MathWorks, Inc.

    %#codegen

    % Query
    methods (Sealed, Hidden)
        function varargout = query(obj, varargin)
            % QUERY will be removed in a future release. Use writeread
            % instead.
            %            
            %QUERY Write and read formatted data from instrument.
            %
            %   A=QUERY(OBJ,'CMD') writes the string, CMD, to the
            %   instrument connected to interface object, OBJ and reads the
            %   data available from the instrument as a result of CMD. OBJ
            %   must be a 1-by-1 interface object. QUERY is equivalent to
            %   using the FPRINTF and FGETS functions.
            %
            %   A connected interface object has a Status property value of
            %   open.
            %
            %   A=QUERY(OBJ,'CMD','WFORMAT') writes the string CMD, to the
            %   instrument connected to interface object, OBJ, with the
            %   format, WFORMAT (this is always set to %s\n, irrespective
            %   of the format string provided).
            %
            %   A=QUERY(OBJ,'CMD','WFORMAT','RFORMAT') writes the string,
            %   CMD, with WFORMAT "%s\n" (irrespective of setting) and
            %   reads data from the instrument connected to interface
            %   object, OBJ, and converts it according to the specified
            %   format string, RFORMAT. By default, the %c format string is
            %   used.
            %
            %   RFORMAT is a string containing C language
            %   conversion specifications. Conversion specifications
            %   involve the character % and conversion characters d, i, o,
            %   u, x, X, f, e, E, g, G, c, and s. See the SPRINTF file I/O
            %   format specifications or a C manual for complete details.
            %
            %   [A,COUNT]=QUERY(OBJ,...) returns the number of values read to COUNT.
            %
            %   [A,COUNT,MSG]=QUERY(OBJ,...) returns a message, MSG, if QUERY did
            %   not complete successfully. If MSG is not specified a warning is
            %   displayed to the command line.
            %
            %   Example:
            %       vd = visadev("GPIB0::11::INSTR"); 
            %       idn = query(vd, "*IDN?");
            %
            %   See also WRITEREAD, READLINE, WRITELINE

            obj.respondToLegacyCall()
            varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

            narginchk(2, 4)
            nargoutchk(0, 3);

            % Parse the input.
            switch nargin
                case 2
                    cmd = varargin{1};
                    % wformat = '%s\n';
                    rformat = '%c';
                case 3
                    % [cmd, wformat] = deal(varargin{1:2});
                    cmd = varargin{1};
                    rformat = '%c';
                case 4
                    % [cmd, wformat, rformat] = deal(varargin{1:3});
                    cmd = varargin{1};
                    rformat = varargin{3};
            end

            if ~isa(cmd, 'char')
                error(message('instrument:query:invalidCMD'));
            end

            % validate read format
            obj.Format = rformat;

            t = obj.getTerminator();

            switch char(t)
                case 'off'
                    % If EOSMode is none or write, then there is no
                    % terminator defined for read operations. In this case,
                    % fgets completes execution and returns control to the
                    % command line when another criterion, such as a
                    % timeout, is met.
                    data = writeread(obj, cmd);
                case 'LF'
                    data = sprintf('%s\n', writeread(obj, cmd));
                case 'CR'
                    data = sprintf('%s\r', writeread(obj, cmd));
                case 'CR/LF'
                    data = sprintf('%s\r\n', writeread(obj, cmd));
                otherwise
                    data = sprintf('%s%c', writeread(obj, cmd), char(t));
            end

            [result, numRead, err] = sscanf(data, rformat);

            if isempty(err)
                varargout = {result, numRead, ''};
            else
                varargout = {data, numel(data), err};

                % Warn if the MSG output variable is not specified.
                if nargout ~= 3
                    warnState = warning('backtrace', 'off');
                    warning(message('instrument:query:unsuccessfulRead', err));
                    warning(warnState);
                end
            end
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyQueryMixin
            coder.allowpcode('plain');
        end
    end
end