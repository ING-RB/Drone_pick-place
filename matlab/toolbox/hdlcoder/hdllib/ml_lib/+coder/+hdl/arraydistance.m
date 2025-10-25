%CODER.HDL.ARRAYDISTANCE Specify the minumum or maximum array distance
%inside the pipelined for-loop
%
%   CODER.HDL.ARRAYDISTANCE(arr_name, 'min', arr_distance) enables you to
%   specify the minimum array distance inside a pipelined for-loop. This
%   pragma must be inserted at the start of the for-loop body.
%
%   CODER.HDL.ARRAYDISTANCE(arr_name, 'max', arr_distance) enables you to
%   specify the maximum array distance inside a pipelined for-loop. This
%   pragma must be inserted at the start of the for-loop body.
%
%   Example:
%     function out = myMin(in)
%         persistent arr1;
%         if isempty(arr1)
%             arr1 = int8(zeros(1,100));
%         end
%         coder.hdl.loopspec('pipeline',1);
%         for i = 4:100
%             coder.hdl.arraydistance('arr1','min',1);
%             y = arr1(i-3);
%             arr1(i) = in;
%         end
%         out = y;
%     end
%
%   This is a code generation function.  It has no effect in MATLAB.
%
%   See also coder.hdl.loopspec

%#codegen
function arraydistance(varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.
    coder.internal.prefer_const(varargin{:});
    coder.internal.assert((nargin == 3), 'hdlcoder:matlabhdlcoder:PragmaBadNumArgs', 'coder.hdl.arraydistance', 3, nargin);
    coder.columnMajor;
    if coder.target('hdl')
        coder.ceval('-preservearraydims', '__hdl_arraydistance', varargin{:});
    end
end

% LocalWords:  minumum loopspec
