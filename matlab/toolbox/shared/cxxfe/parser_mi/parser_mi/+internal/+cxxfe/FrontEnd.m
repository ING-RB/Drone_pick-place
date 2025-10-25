classdef FrontEnd < handle
    %FRONTEND helper class for calling the front-end.
    %
    %   See also
    %
    %   This is an undocumented class. Its methods and properties are likely to
    %   change without warning from one release to the next.
    
    %   Copyright 2013-2019 The MathWorks, Inc.
    
    properties (SetAccess=private, Hidden)
        Exceptions = []
    end
    
    methods (Access=protected)
        %% Protected Method: FrontEnd -------------------------------------
        %  Abstract:
        %
        function this = FrontEnd()
            this.Exceptions = [];
        end
    end
    
    methods (Hidden)
        %% Private Method: dispatchCallback -------------------------------
        %  Abstract:
        %
        function status = dispatchCallback(feObj, handler, cbStr, ilPtr, feOptions, fName, feMsgs)
            try
                % The mex clients are not ready for this wrapper to the IL
                % header
                if isa(ilPtr, 'polyspace.internal.util.PtrWrapper')
                    ilPtr = struct('ptr', ilPtr.getAddr());
                end
                feval(cbStr, handler, ilPtr, feOptions, fName, feMsgs);
                status = 0;
            catch Me
                feObj.Exceptions = Me;
                status = -1;
            end
        end
    end
    
    methods (Static)
        %% Public Static Method: parseFile --------------------------------
        %  Abstract:
        %
        function msgs = parseFile(fileName, feOpts, varargin)
            if nargin < 2 || isempty(feOpts)
                feOpts = internal.cxxfe.FrontEndOptions();
            end
            
            msgs = internal.cxxfe.FrontEnd.invoke(true, fileName, feOpts, varargin{:});
        end
        
        %% Public Static Method: parseText --------------------------------
        %  Abstract:
        %
        function msgs = parseText(textBuffer, feOpts, varargin)
            if nargin < 2 || isempty(feOpts)
                feOpts = internal.cxxfe.FrontEndOptions();
            end
            
            msgs = internal.cxxfe.FrontEnd.invoke(false, textBuffer, feOpts, varargin{:});
        end
    end
    
    methods (Static, Hidden)
        %% Static Method: getFrontEnd -------------------------------------
        %  Abstract:
        %
        function feObj = getFrontEnd()
            feObj = internal.cxxfe.FrontEnd();
        end        
    end
    
    methods (Static, Access=private)
        %% Private Static Method: invoke ----------------------------------
        %  Abstract:
        %
        function msgs = invoke(isFile, fileOrText, feOpts, varargin)
            
            if numel(varargin)==0
                handlers{1} = internal.cxxfe.util.DefaultFrontEndHandler;
            else
                handlers = cell(1, numel(varargin));
                for ii = 1:numel(varargin)
                    arg = varargin{ii};
                    if ischar(arg) || isStringScalar(arg) || isa(arg, 'function_handle')
                        handlers{ii} = internal.cxxfe.util.DefaultFrontEndHandler(arg);
                        
                    elseif iscell(arg)
                        handlers{ii} = internal.cxxfe.util.DefaultFrontEndHandler(arg{:});
                        
                    elseif isa(varargin{ii}, 'internal.cxxfe.FrontEndHandler')
                        handlers{ii} = arg;
                        
                    else
                        % TODO(eroy): throw an error!
                        handlers{ii} = internal.cxxfe.util.DefaultFrontEndHandler();
                    end
                end
            end
            
            feObj = internal.cxxfe.FrontEnd();
            try
                msgs = internal.cxxfe.invokeFrontEnd(feObj, feOpts, fileOrText, isFile, handlers);
                hasError = any(~strcmp({ msgs.kind }, 'warning'));
                if (~hasError || ((numel(msgs) == 1) && strcmp(msgs.kind, 'fatal') && isempty(msgs.detail))) && ...
                        feOpts.RethrowException && ~isempty(feObj.Exceptions)
                    rethrow(feObj.Exceptions);
                end
            catch Me
                if feOpts.RethrowException
                    rethrow(Me);
                end
            end
        end
    end
end

% LocalWords:  cxxfe eroy
