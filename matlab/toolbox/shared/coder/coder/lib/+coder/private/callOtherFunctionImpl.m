function varargout = callOtherFunctionImpl(varargin)
%

%   Copyright 2023 The MathWorks, Inc.
    try
        if nargin == 0
            error(message('Coder:common:NotEnoughInputs'));
        end
        if isa(varargin{1}, 'function_handle')
            % [A] = CODER.CONST(@FCN)
            if nargin == 1 && nargout <= 1
                varargout{1} = varargin{1};
                return
            end
        
            % Otherwise apply a function call
            f = varargin{1};
            [varargout{1:nargout}] = f(varargin{2:end});
        else
            if nargin > 1
                error(message('Coder:common:TooManyInputs'));
            end
            % A = CODER.CONST(<EXPR>);
            varargout{:} = varargin{1};
        end
    catch e
        throwAsCaller(e);
    end
end