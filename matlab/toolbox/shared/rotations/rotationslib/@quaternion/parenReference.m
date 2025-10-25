function obj = parenReference(obj,varargin)
%   This method is for internal use only. It may be removed in the future. 

%   Copyright 2018 The MathWorks, Inc.    

obj.a = obj.a(varargin{:});
obj.b = obj.b(varargin{:});
obj.c = obj.c(varargin{:});
obj.d = obj.d(varargin{:});
end
