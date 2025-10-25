function close(~)
% Throwing a useful error in case users try to call close on a pool

%   Copyright 2019-2020 The MathWorks, Inc.

error(message('MATLAB:parallel:pool:UseDelete'));
end
