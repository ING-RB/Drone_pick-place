function aHostName = getHostName(varargin)
%

%   Copyright 2010-2019 The MathWorks, Inc.

%#codegen

coder.extrinsic('getenv');
coder.extrinsic('system');

if nargin < 1
  envHostName = '';
else
  % If environment variable is specified, use it to get the intended host
  % name.
  envHostName = coder.const(getenv(varargin{1}));
end

if ~isempty(envHostName)
  % Host name is available through an environment variable.  Return that.
  aHostName = envHostName;
else
  % Get the real host name from system
  [varStatus,varHostName] = system('hostname');
  status = coder.const(varStatus);
  tempHostName = coder.const(varHostName);
  if status
    aHostName = '';
  else
    aHostName = tempHostName(1:end-1);
  end
end

end
