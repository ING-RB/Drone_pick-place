function mustBeComplex(A)
    %CODER.MUSTBECOMPLEX Validate that value lies on the complex plane
    %
    %   coder.mustBeComplex validates that a function input can have a nonzero
    %   imaginary part. In MATLAB execution, this function does not throw any
    %   assertion because any numeric input can have a nonzero imaginary part.
    %
    %   In code generation, this validator asserts at compile time that a value
    %   has a complex type.
    %
    %   Example:
    %     function out = multiplyByThree(in)
    %         arguments
    %             in (3,4) single {coder.mustBeComplex(in)}
    %         end
    %         out = in*3;
    %     end
    %
    %   Copyright 2022 The MathWorks, Inc.

     %#codegen

        narginchk(1,1);
        if ~coder.target('MATLAB')
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;

            coder.internal.assert(isnumeric(A), 'MATLAB:validators:mustBeNumeric');
            coder.internal.assert(~isreal(A), 'MATLAB:validators:mustBeComplex');
        end
    end
