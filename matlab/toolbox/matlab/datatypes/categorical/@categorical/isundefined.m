function tf = isundefined(a)
%

%   Copyright 2006-2024 The MathWorks, Inc.

tf = (a.codes == 0); % categorical.undefCode
