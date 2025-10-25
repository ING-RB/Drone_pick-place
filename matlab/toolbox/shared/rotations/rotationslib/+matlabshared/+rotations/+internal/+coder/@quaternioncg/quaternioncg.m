classdef (Sealed) quaternioncg < matlabshared.rotations.internal.quaternionBase & ...
        coder.mixin.internal.indexing.ParenAssign
%QUATERNIONCG - Redirection class for MATLAB Coder support.
%  This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2024 The MathWorks, Inc.
  
%#codegen

    methods
       function obj = quaternioncg(varargin)
            obj@matlabshared.rotations.internal.quaternionBase(varargin{:});
       end

        function o = times(x,y)
        % .*  Quaternion multiplication of arrays 
        %   X.*Y denotes element-by-element quaternion multiplication of quaternion arrays. 
        %   Either X or Y may be a real array. In this case real x
        %   quaternion multiplication is performed.
        %
        %   X and Y must have compatible sizes. In the simplest cases,
        %   they can be the same size or one can be a scalar. Two inputs
        %   have compatible sizes if, for every dimension, the dimension
        %   sizes of the inputs are either the same or one of them is 1. 
            
            % Honor user request for implicit expansion
            coder.internal.implicitExpansionBuiltin;
            
            % Ensure compatible dims, else throw a proper error.
            quatAssertCompatibleDims(x,y);

            if isa(y, 'matlabshared.rotations.internal.quaternionBase') && isa(x, 'matlabshared.rotations.internal.quaternionBase')
                xa = x.a;
                xb = x.b;
                xc = x.c;
                xd = x.d;
                
                ya = y.a;
                yb = y.b;
                yc = y.c;
                yd = y.d;
                
                %Because one of x or y might be a scalar/singleton and the other a
                %matrix we may accidentally change sizes and break codegen.
                %For example if x is scalar and y is a matrix then the
                %first branch would inflate x. So we switch based on which
                %is a smaller.
                oa = xa.*ya - xb.*yb - xc.*yc - xd.*yd;
                ob = xa.*yb + xb.*ya + xc.*yd - xd.*yc;
                oc = xa.*yc - xb.*yd + xc.*ya + xd.*yb;
                od = xa.*yd + xb.*yc - xc.*yb + xd.*ya;
                o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
            elseif (isa(y, 'double') || isa(y, 'single')) && isreal(y) && isa(x, 'matlabshared.rotations.internal.quaternionBase')
                oa = y.*x.a;
                ob = y.*x.b;
                oc = y.*x.c;
                od = y.*x.d;
                o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
            elseif (isa(x, 'double') || isa(x, 'single')) && isreal(x) && isa(y, 'matlabshared.rotations.internal.quaternionBase')
                oa = x.*y.a;
                ob = x.*y.b;
                oc = x.*y.c;
                od = x.*y.d;
                o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
            else
                coder.internal.errorIf(true, 'shared_rotations:quaternion:QuatTimesReals');
            end
                
        end

       function o = transpose(obj)
       % .' Transpose of a quaternion array 
       %
       % See also ctranspose, permute
           oa = obj.a.';
           ob = obj.b.';
           oc = obj.c.';
           od = obj.d.';
           o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
       end

       function o = ctranspose(obj)
       % ' Transpose of a quaternion array 
       %
       % See also transpose, permute

           oa = obj.a.';
           ob = -obj.b.';
           oc = -obj.c.';
           od = -obj.d.';
           o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
       end

       function o = permute(obj, order)
       %PERMUTE Permute quaternion dimensions
       %
       % See also transpose
           oa = permute(obj.a, order);
           ob = permute(obj.b, order);
           oc = permute(obj.c, order);
           od = permute(obj.d, order);
           o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
       end
       
       function x = reshape(obj, varargin)

            a = reshape(obj.a, varargin{:});
            b = reshape(obj.b, varargin{:});
            c = reshape(obj.c, varargin{:});
            d = reshape(obj.d, varargin{:});
            x = matlabshared.rotations.internal.coder.quaternioncg(a,b,c,d);
       end

       function o = repmat(obj, varargin)
       %REPMAT Replicate and tile an array

       % Note there is no MATLAB (sim) implementation for this, it "just
       % works." 
           a = repmat(obj.a, varargin{:});
           b = repmat(obj.b, varargin{:});
           c = repmat(obj.c, varargin{:});
           d = repmat(obj.d, varargin{:});
           o = matlabshared.rotations.internal.coder.quaternioncg(a,b,c,d);
       end

       %%%%%%%%%%%%%%%%%%%%
       % Casting
       %%%%%%%%%%%%%%%%%%%%
       function o = double(q)
       %DOUBLE Convert quaternion to double precision
       %
       % See also single, cast

           oa = double(q.a);
           ob = double(q.b);
           oc = double(q.c);
           od = double(q.d);
           o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
       end   

       function o = single(q)
       %SINGLE Convert quaternion to single precision
       %
       % See also double, cast

           oa = single(q.a);
           ob = single(q.b);
           oc = single(q.c);
           od = single(q.d);
           o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
       end   
   end

    methods  % Public, externally defined
        o = rdivide(x,y);
        o = ldivide(x,y);
        r = power(q,n);
    end
    
    methods (Access = protected) % Private, externally defined
        qo = buildOutput(q,a,b,c,d)
    end

   methods (Hidden)
       function o = parenReference(obj, varargin)
           a = obj.a(varargin{:});
           b = obj.b(varargin{:});
           c = obj.c(varargin{:});
           d = obj.d(varargin{:});
           o = matlabshared.rotations.internal.coder.quaternioncg(a,b,c,d);
       end
       
       function o = parenAssign(obj, rhs, varargin)

            obj.a(varargin{:}) = rhs.a;
            obj.b(varargin{:}) = rhs.b;
            obj.c(varargin{:}) = rhs.c;
            obj.d(varargin{:}) = rhs.d;
            o = obj;
       end

    end
    
    methods (Static)
        function o = zeros(varargin)
        %D = QUATERNION.ZEROS(N) is an N-by-N quaternion array of zeros.
        %
        %D = QUATERNION.ZEROS(M,N) is an M-by-N quaternion array of zeros.
        %
        %D = QUATERNION.ZEROS(M,N,K,...) is an M-by-N-by-K-by-... quaternion array of zeros.
        %
        %D = QUATERNION.ZEROS(M,N,K,..., CLASSNAME) or 
        %QUATERNION.ZEROS([M,N,K,...], CLASSNAME) is an M-by-N-by-K-by-... 
        %quaternion of zeros of class specified by CLASSNAME.
        %
        %D = ZEROS(...,"like",P) for a quaternion argument P returns a quaternion of zeros of the
        %Same class as P and the requested size. P must be a double or
        %single precision element.

            x = zeros(varargin{:});
            coder.internal.assert(isa(x, 'float'), ...
                'shared_rotations:quaternion:SingleDouble', class(x));
            o = matlabshared.rotations.internal.coder.quaternioncg(x,x,x,x);
        end

        function o = ones(varargin)
        %D = QUATERNION.ONES(N) is an N-by-N quaternion array with the
        %real part set to 1 and the imaginary parts set to 0.
        %
        %D = QUATERNION.ONES(M,N) is an M-by-N quaternion array with the
        %real part set to 1 and the imaginary parts set to 0.
        %
        %D = QUATERNION.ONES(M,N,K,...) is an M-by-N-by-K-by-... quaternion array with the
        %real part set to 1 and the imaginary parts set to 0.
        %
        %D = QUATERNION.ONES(M,N,K,..., CLASSNAME) is an M-by-N-by-K-by-... 
        %quaternion array of ones of class specified by CLASSNAME.
        %
        %D = ONES(...,'LIKE',P) for a quaternion argument P returns a quaternion of ones of the
        %Same class as P and the requested size. P must be a double or
        %single precision element.
            x = zeros(varargin{:});
            coder.internal.assert(isa(x, 'float'), ...
                'shared_rotations:quaternion:SingleDouble', class(x));
            y = ones(varargin{:});
            o = matlabshared.rotations.internal.coder.quaternioncg(y,x,x,x);
        end

        function o = nan(varargin)
        %D = QUATERNION.NAN(N) is an N-by-N quaternion array with 
        %all parts set to NaN.
        %
        %D = QUATERNION.NAN(M,N) is an M-by-N quaternion array with
        %all parts set to NaN.
        %
        %D = QUATERNION.NAN(M,N,K,...) is an M-by-N-by-K-by-... quaternion array with
        %all parts set to NaN. 
        %
        %D = QUATERNION.NAN(M,N,K,..., CLASSNAME) is an M-by-N-by-K-by-... 
        %quaternion array of NaNs of class specified by CLASSNAME.
        %
        %D = NAN(...,'LIKE',P) for a quaternion argument P returns a quaternion array of NaNs of the
        %Same class as P and the requested size. P must be a double or
        %single precision element.
            x = nan(varargin{:});
            coder.internal.assert(isa(x, 'float'), ...
                'shared_rotations:quaternion:SingleDouble', class(x));
            o = matlabshared.rotations.internal.coder.quaternioncg(x,x,x,x);
        end
    end
    
    methods (Static)
        function out = matlabCodegenToRedirected(in)
            [a,b,c,d] = parts(in);
            out = matlabshared.rotations.internal.coder.quaternioncg(a,b,c,d);
        end
        
        function out = matlabCodegenFromRedirected(obj)
            [a,b,c,d] = parts(obj);
            out = quaternion(a,b,c,d);
        end
    end

    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            % Make this look like a quaternion in the codegen report
            name = 'quaternion';
        end
    end

    methods (Hidden)
        function o = ctor(~, varargin)
            o = matlabshared.rotations.internal.coder.quaternioncg(varargin{:});
        end
    end
end
