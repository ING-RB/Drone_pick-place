function qpos = posangle(q)
%   This function is for internal use only. It may be removed in the future. 

%POSANGLE force quaternion to have a positive angle


%   Copyright 2020 The MathWorks, Inc.    

%#codegen 

% Assumes q contains unit quaternions. 
qvec = reshape(q, [], 1); % convert to a vector
a = (parts(qvec) < 0); % find negative real parts
adj = ones(size(q), classUnderlying(q)); % make +1 and -1 array
adj(a) = -1; % indexing on the left preserves the type of adj
qposvec = q.*adj; % make everything positive.
qpos = reshape(qposvec, size(q)); % back to original shape.
end
