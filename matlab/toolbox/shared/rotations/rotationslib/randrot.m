function r = randrot(varargin)
%RANDROT Uniformly distributed random rotations
%   R = RANDROT(N) returns an N-by-N matrix of unit quaternions drawn
%   from a uniform distribution of random rotations. 
%
%   R = RANDROT(M,N) returns an M-by-N matrix.
%
%   R = RANDROT(M,N,P, ...) or RANDROT([M N P ...]) returns an
%   M-by-N-by-P-by-... array.
%
%   R = RANDROT returns a scalar.
%
%   EXAMPLE: Create a uniform distribution of points on the unit sphere 
%       q = randrot(500,1);
%       pt = rotatepoint(q, [1 0 0]);
%       scatter3(pt(:,1), pt(:,2), pt(:,3))
%       axis equal
%
%   See also QUATERNION 

%   Copyright 2018-2020 The MathWorks, Inc.    

%#codegen 

if nargin==0
    % randrot()
    dims = 1;

elseif nargin==1
    % randrot([1 2 3 ...]) or randrot(1)
    v1 = varargin{1};
    validateattributes(v1, {'numeric'}, ...
        {'integer', 'row', 'nonempty'}, ...
        'randrot');
    dims = v1;
else
    % randrot(1,2,3,...)
    for ii=1:nargin
        validateattributes(varargin{ii}, {'numeric'}, {'integer', ...
            'nonempty', 'scalar'}, ...
            'randrot', '', ii); 
    end
    dims = cat(2, varargin{:});
end

if isscalar(dims)
    outdims = [dims dims];
else
    outdims = dims;
end
% Approach: We want consecutive calls to randrot to return the same results
% as a single larger call. So :
% [randrot(1,1); randrot(1,1)] would be the same as randrot(2,1)
%
% This means we need to generate all the quaternion parts in one single
% call to randn, and for any single quaternion, the parts need to come from
% consecutive draws from the random stream (i.e. we cannot, for example,
% generate all the real parts of all the required quaternions
% consecutively).
%
% Generate a 4-by-prod(dims) randn matrix (so the parts are consecutive
% draws). Transpose, generate quaternions, normalize, and then reshape.

r = randn([4 outdims]);
r = reshape(r, 4, []).';
%r = randn(4,N).'; 
rUnnormalized = quaternion(r);
rUnitCol =  normalize(rUnnormalized);

outdims(outdims < 0) = 0;
r = reshape(rUnitCol, outdims);

