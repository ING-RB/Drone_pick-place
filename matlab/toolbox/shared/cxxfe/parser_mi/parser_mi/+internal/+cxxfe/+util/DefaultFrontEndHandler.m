classdef DefaultFrontEndHandler < internal.cxxfe.FrontEndHandler
    %DEFAULTFRONTENDHANDLER default front-end handler for quickly wrapping
    %   the call to user supplied callback handler without having to
    %   inherit from internal.cxxfe.FrontEndHandler
    %
    %   See also
    %
    %   This is an undocumented class. Its methods and properties are likely to
    %   change without warning from one release to the next.
    
    %   Copyright 2013-2018 The MathWorks, Inc.
    
    properties (GetAccess=public, SetAccess=private)
        FcnHandle
        FcnArgs
    end
    
    methods
        %% Public Method: DefaultFrontEndHandler --------------------------
        %  Abstract:
        %    Constructor.
        function this = DefaultFrontEndHandler(varargin)
            if nargin < 1
                this.FcnHandle = [];
                this.FcnArgs = {};
            else
                [varargin{:}] = convertStringsToChars(varargin{:});
                if ischar(varargin{1})
                    this.FcnHandle = str2func(varargin{1});
                    
                elseif isa(varargin{1}, 'function_handle')
                    this.FcnHandle = varargin{1};
                    
                else
                    % TODO(eroy): throw an error!
                    this.FcnHandle = [];
                end
                
                this.FcnArgs = varargin(2:end);
                if isempty(this.FcnArgs)
                    this.FcnArgs = {};
                end
            end
        end
        
        %% Public Method: afterPreprocessing ------------------------------
        %  Abstract:
        %
        function afterPreprocessing(this, ilPtr, feOptions, fName, feMsgs)
            if isempty(this.FcnHandle)
                return
            end
            
            this.dispatch('afterPreprocessing', ilPtr, feOptions, fName, feMsgs);
        end
        
        %% Public Method: afterParsing ------------------------------------
        %  Abstract:
        %
        function afterParsing(this, ilPtr, feOptions, fName, feMsgs)
            
            if isempty(this.FcnHandle)
                return
            end
            
            this.dispatch('afterParsing', ilPtr, feOptions, fName, feMsgs);
            
        end
    end
    
    methods (Access=private)
        %% Private Method: dispatch ---------------------------------------
        %  Abstract:
        %    Dispatch the callback to the registered function.
        function dispatch(this, cbStr, ilPtr, feOptions, fName, feMsgs)
            
            fcnArgs = this.FcnArgs;
            for ii = 1:numel(fcnArgs)
                if ischar(fcnArgs{ii}) || isStringScalar(fcnArgs{ii})
                    switch fcnArgs{ii}
                      case "%stage"
                        fcnArgs{ii} = cbStr;
                      case "%ilptr"
                        fcnArgs{ii} = ilPtr;
                      case "%options"
                        fcnArgs{ii} = feOptions;
                      case "%file"
                        fcnArgs{ii} = fName;
                      case "%msgs"
                        fcnArgs{ii} = feMsgs;
                      otherwise
                    end
                end
            end
            
            this.FcnHandle(fcnArgs{:});
            
        end
    end
end

% LocalWords:  ilptr cxxfe eroy Preprocessing
