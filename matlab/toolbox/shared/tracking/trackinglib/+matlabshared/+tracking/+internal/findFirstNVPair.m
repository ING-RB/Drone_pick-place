%#codegen
    
% Copyright 2016-2020 The MathWorks, Inc.
    
function idx = findFirstNVPair(varargin)
  % The returned value is (nargin+1) if there is no name-value pair in the
  % inputs.
  idx = nargin+1;
  for k = coder.unroll(1:nargin)
    if ischar(varargin{k}) || isstruct(varargin{k}) || ...
            isStringScalar(varargin{k})
      idx = k;
      return
    end
  end
end