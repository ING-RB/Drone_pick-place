function y = cat(dim, varargin)
%CAT Concatenation of quaternion arrays
%   C = CAT(DIM, A,B,...) concatenates quaternion arrays A,B,...
%   along dimension DIM

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 
    
    %Validate
    coder.internal.assert(isa(dim, 'numeric'), 'shared_rotations:quaternion:CatQuat');
    validateattributes(dim, {'numeric'}, {'real', 'positive', ...
        'integer', 'scalar', 'finite'}, 'cat');  
    n = numel(varargin);
    
    for ii=1:n
        coder.internal.assert(isa(varargin{ii},'matlabshared.rotations.internal.quaternionBase'), ...
            'shared_rotations:quaternion:CatQuat'); 
    end
    %Get parts
    qa = cell(1,n);
    qb = cell(1,n);
    qc = cell(1,n);
    qd = cell(1,n);
    for ii=1:numel(varargin)
        qa{ii} = varargin{ii}.a;
        qb{ii} = varargin{ii}.b;
        qc{ii} = varargin{ii}.c;
        qd{ii} = varargin{ii}.d;
    end
    
    %Concat:
    cata = cat(dim, qa{:});
    catb = cat(dim, qb{:});
    catc = cat(dim, qc{:});
    catd = cat(dim, qd{:});
    
    y = quaternion(cata, catb, catc, catd);
end
