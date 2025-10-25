function out = tocBytes(varargin)
% tocBytes Read how many bytes have been transferred since calling ticBytes
%
%     Use the ticBytes and tocBytes functions together to measure how much
%     data is transferred to and from the workers in the current parallel pool while
%     executing parallel language constructs and functions, such as parfor.
%
%     tocBytes() without an output argument displays the total number of
%     bytes transferred to and from each of the workers in the current parallel pool
%     since the most recent execution of ticBytes.
%
%     bytes = tocBytes() returns a matrix of size numWorkers x 2 containing
%     the bytes transferred to and from each of the workers in the current
%     parallel pool
%
%     tocBytes(startState) displays the total number of bytes transferred
%     in the current parallel pool since the ticBytes command that generated
%     startState.
%
%     Example: Measure the amount of data transferred while running a simple
%              parfor loop on a Parallel Computing Toolbox parallel pool.
%
%         a = 0;
%         b = rand(100);
%         startS = ticBytes();
%         parfor i = 1:100
%             a = a + sum(b(:, i));
%         end
%         tocBytes(startS)
%
%     See also ticBytes.

%   Copyright 2023 The MathWorks, Inc.

aPool = gcp("nocreate");
if nargout == 0
    tocBytes(aPool, varargin{:});
else
    out = tocBytes(aPool, varargin{:});
end

end
