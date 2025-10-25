%CODER.HDL.LOOPSPEC Unroll or stream loops in generated HDL code
%
%   With loop optimization you can stream or unroll loops in generated
%   code. Loop streaming optimizes for area, and loop unrolling optimizes
%   for speed.
%
%   CODER.HDL.LOOPSPEC('unroll') fully unrolls a loop in the generated HDL
%   code. Instead of a loop statement, the generated code contains multiple
%   instances of the loop body, with one loop body instance per loop
%   iteration.
%
%   CODER.HDL.LOOPSPEC('unroll',unroll_factor) unrolls a loop by the
%   specified unrolling factor, unroll_factor, in the generated HDL code.
%
%   CODER.HDL.LOOPSPEC('stream') generates a single instance of the loop
%   body in the HDL code. Instead of using a loop statement, the generated
%   code implements local oversampling and added logic to match the
%   functionality of the original loop.
%
%   CODER.HDL.LOOPSPEC('stream',stream_factor) unrolls the loop with
%   unroll_factor set to original_loop_iterations / stream_factor rounded
%   down to the nearest integer, and also oversamples the loop. If
%   (original_loop_iterations / stream_factor) has a remainder, the
%   remainder loop body instances outside the loop are not oversampled, and
%   run at the original rate.
%
%   For SystemC Code Generation: CODER.HDL.LOOPSPEC('unroll') inserts the
%   pragma at the first line of the for-loop body in the generated SystemC
%   code. This pragma indicates that the loop should be completely unrolled
%   during synthesis.
%
%   For SystemC Code Generation: CODER.HDL.LOOPSPEC('unroll',unroll_factor)
%   inserts the pragma at the first line of the for-loop body in the generated
%   SystemC code. This pragma indicates that the loop should be unrolled by a
%   given unroll_factor during synthesis.
%
%   For SystemC Code Generation: CODER.HDL.LOOPSPEC('pipeline') inserts the
%   pragma at the first line of the for-loop body in the generated SystemC
%   code. This pragma indicates that the for-loop should be pipelined with
%   the default initiation interval of 1. Insert the pragma before the
%   for-loop to be pipelined.
%
%   For SystemC Code Generation: CODER.HDL.LOOPSPEC('pipeline',initiation_interval)
%   inserts the pragma at the first line of the for-loop body in the
%   generated SystemC code. This pragma indicates that the loop should be
%   pipelined by a given initiation_inteval during synthesis. Insert the
%   pragma before the for-loop to be pipelined. The initiation_interval
%   represents the number of clock cycles before the start of the next
%   iteration of the for-loop.
%
%   Example:
%     coder.hdl.loopspec('unroll');
%     for i = 1:10
%         y(i) = pv + i;
%     end
%
%   This is a code generation function.  It has no effect in MATLAB.

%#codegen
function loopspec(varargin)
%

%   Copyright 2014-2025 The MathWorks, Inc.

    coder.internal.prefer_const(varargin);
    coder.columnMajor;
    coder.internal.assert((nargin == 1) || (nargin == 2), 'hdlmllib:hdlmllib:PragmaBadNumArgs', 'coder.hdl.loopspec', nargin);
    if nargin == 2
        coder.internal.assert(~ischar(varargin{2}), 'hdlmllib:hdlmllib:PragmaInvalidArg', 'second', 'coder.hdl.loopspec');
    end
    if coder.target('hdl') && (nargin == 2)
        coder.ceval('-preservearraydims', '__hdl_loopspec', convertStringsToChars(varargin{1}), varargin{2});
    end
    if coder.target('hdl') && (nargin == 1)
        coder.ceval('-preservearraydims', '__hdl_loopspec', convertStringsToChars(varargin{1}));
    end
end

% LocalWords:  oversamples inteval pv hdlmllib
