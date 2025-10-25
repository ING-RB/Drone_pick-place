%DASPRIVATE is a gateway for internal support functions used by 
%           DAStudio.
%   VARARGOUT = DASPRIVATE('FUNCTION_NAME', VARARGIN) 
%   
%   

%   Copyright 2011 The MathWorks, Inc.

function varargout = dasprivate(function_name, varargin)
  
   [varargout{1:nargout}] = feval(function_name, varargin{1:end});

