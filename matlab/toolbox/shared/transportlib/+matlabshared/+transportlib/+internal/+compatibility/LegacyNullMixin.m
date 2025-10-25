classdef LegacyNullMixin < handle
    %LEGACYNULLMIXIN Default implementation of all supported legacy
    %operations. By default, operations are not assumed to be supported (a
    %mixin must explicitly inheriting from this class, override the
    %the method and seal it to provide a new implementation).
    %
    %    This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    %% Legacy Methods
    methods (Hidden)
        % FWRITE
        function fwrite(obj, varargin)
            unsupportedMethod(obj, "fwrite")
        end

        % FREAD
        function varargout = fread(obj, varargin) %#ok<STOUT>
            unsupportedMethod(obj, "fread")
        end

        % FPRINTF
        function fprintf(obj, varargin)
            unsupportedMethod(obj, "fprintf")
        end

        % FSCANF
        function varargout = fscanf(obj, varargin) %#ok<STOUT>
            unsupportedMethod(obj, "fscanf")
        end

        % FGETL
        function varargout = fgetl(obj) %#ok<STOUT>
            unsupportedMethod(obj, "fgetl")
        end

        % FGETS
        function varargout = fgets(obj) %#ok<STOUT>
            unsupportedMethod(obj, "fgets")
        end

        % SCANSTR
        function varargout = scanstr(obj, varargin) %#ok<STOUT>
            unsupportedMethod(obj, "scanstr")
        end

        % BINBLOCKWRITE
        function binblockwrite(obj, varargin)
            unsupportedMethod(obj, "binblockwrite")
        end

        % BINBLOCKREAD
        function varargout = binblockread(obj, varargin) %#ok<STOUT>
            unsupportedMethod(obj, "binblockread")
        end

        % QUERY
        function varargout = query(obj, varargin) %#ok<STOUT>
            unsupportedMethod(obj, "query")
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyNullMixin
            coder.allowpcode('plain');
        end
    end

    % Helper methods
    methods (Sealed, Hidden)
        function t = getTerminator(obj, terminatorType)
            % If terminatorType is:
            % - a single value, return it
            % - a cell-array, return the selected terminator type ("read"
            %   or "write"); by default, return "read".

            narginchk(1, 2)

            t = obj.Terminator;

            if ~iscell(t)                
                return
            end

            if nargin == 1
                terminatorType = "read";
            end
            
            switch lower(terminatorType)
                case "read"
                    t = t{1};                    
                case "write"
                    t = t{2};
                otherwise
                    t = t{1};
            end
        end
    end  

    methods (Sealed, Access = protected)
        function sendWarning(obj, id, varargin) %#ok<INUSL> 
            matlabshared.transportlib.internal.compatibility.Utility.sendWarning(id, varargin{:});
        end

        function respondToLegacyCall(obj)
            % The appropriate response, initially, to calling a legacy
            % method is to do nothing
            % (eventually, this should warn and then error)

            if obj.IssueResponsetoLegacyCall
                % react to call (initially, does nothing)
                obj.IssueResponsetoLegacyCall = false;
            end
        end

        function e = getInputBufferSizeExceededException(obj, id) %#ok<INUSL> 
            msg = message('transportlib:legacy:SizeExceedsInputBufferSize');
            e = MException(id, msg);
        end
    end    

    properties (Hidden, SetAccess = private)
        % If true, then calling respondToLegacyCall will respond (do
        % nothing, issue a warning, or issue an error, as appropriate).
        % If false, then calling respondToLegacyCall will do nothing
        IssueResponsetoLegacyCall = true
    end

    methods (Access = private)
        function unsupportedMethod(obj, methodName)
            % warn that this method is not supported (will eventually error
            % out)
            id = "transportlib:legacy:MethodNotSupported";
            obj.sendWarning(id, methodName)
        end
    end
end



