function quatAssertCompatibleDims(x,y)
% This method is for internal use only. It may be removed in the
% future. 
%
% Check if dimensions are compatible for implicit expansion for codegen.
% x and y can be quaternions or builtin numerics.
% This is a check for codegen, but it's a method on the sim object so calls
% to it from shared sim/codegen methods will succeed.

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 

    if ~coder.target('MATLAB')
        if isa(x, 'quaternion')
            if isa(y, 'quaternion')
                coder.internal.assertCompatibleDims(x.a, y.a);
            else
                coder.internal.assertCompatibleDims(x.a, y);
            end 
        else
            if isa(y, 'quaternion')
                coder.internal.assertCompatibleDims(x, y.a);

                % No else branch. Why?
                % An else branch shouldn't happen. 
                % We can't get to this method if neither input is a
                % quaternion.
            end 
        end
    end
end
