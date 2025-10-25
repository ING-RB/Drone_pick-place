function out = cast(in, varargin)
%CAST Cast a variable to a different data type or class.
%   B = cast(A,NEWCLASS)
%   B = cast(A,"like",Y)
%
%   See also CAST.

% Copyright 2019 The MathWorks, Inc.

narginchk(2,3);

% Use the in-memory version to check the arguments
tall.validateSyntax(@cast,[{in},varargin],'DefaultType','double');

% If we get here we know the syntax is valid, so the second input is either
% type string or "like".
if nargin==2
    % Value type cast. Output will be tall so can cast element-wise
    typeName = varargin{1};
    out = elementfun( @(x) cast(x,typeName), in );
    out.Adaptor = copySizeInformation(...
        matlab.bigdata.internal.adaptors.getAdaptorForType(typeName), ...
        in.Adaptor);
else
    % Cast like. We need to take care if we are casting to/from tall.
    prototype = varargin{2};
    if istall(prototype)
        % Result is going to be tall. Reduce prototype down to empty.
        prototype = head(prototype,0);
        if ~istall(in)
            in = tall(in);
        end
        out = elementfun( @(x,y) cast(x,"like",y), ...
            in, matlab.bigdata.internal.broadcast(prototype) );
        out.Adaptor = copySizeInformation(...
            prototype.Adaptor, ...
            in.Adaptor);
    else
        % Casting tall input to be in-memory! This requires us to evaluate
        % all pending calculations and bring the data into memory using
        % gather.
        in = gather(in);
        % Now just call the in-memory version to finish the job
        out = cast(in,"like",prototype);
    end
end
   
end
