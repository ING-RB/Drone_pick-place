function out = ticBytes()
% ticBytes Start counting bytes transferred within the current parallel pool
%
%     Use the ticBytes and tocBytes functions together to measure how much
%     data is transferred to and from the workers in the current parallel pool while
%     executing parallel language constructs and functions, such as parfor.
%
%     ticBytes() saves the current number of bytes transferred to each worker
%     in the current pool, so that later tocBytes() can measure the amount of data
%     transferred to each worker between the two calls.
%
%     startState = ticBytes() saves the state to an output argument,
%     startState. Use the value of startState as an input argument for
%     a subsequent call to tocBytes.
%
%     Example: Measure the amount of data transferred while running a simple
%              parfor loop on a Parallel Computing Toolbox parallel pool.
%
%         a = 0;
%         b = rand(100);
%         ticBytes();
%         parfor i = 1:100
%             a = a + sum(b(:, i));
%         end
%         tocBytes()
%
%     See also tocBytes.

%   Copyright 2023 The MathWorks, Inc.

aPool = gcp("nocreate");
if nargout == 0
    ticBytes(aPool);
else
    out = ticBytes(aPool);
end

end
