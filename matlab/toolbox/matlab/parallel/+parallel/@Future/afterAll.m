%AFTERALL Specify function to invoke after all Futures complete
%   F2 = AFTERALL(F,FCN,NOUT) creates parallel.Future F2 which will
%   produce the result of evaluating FCN on the output arguments of
%   all the futures in the array F. FCN is evaluated on the MATLAB
%   client, not on the parallel pool workers. FCN will be invoked
%   with NOUT output arguments. If the number of output arguments
%   of the elements in F differ, the minimum will be used.
%
%   Evaluating:
%   F2 = afterAll(F, FCN, NOUT);
%   [X, Y, Z] = fetchOutputs(F2);
%   Is equivalent to evaluating:
%   [A, B] = fetchOutputs(F);
%   [X, Y, Z] = FCN(A, B);
%   Except that in the former case, FCN is invoked automatically
%   when all elements of F are complete.
%
%   If any element of F encounters an error, then FCN is not
%   invoked, and F2 completes with an error.
%
%   Cancelling an element of F will result in the same behavior as
%   if the element encountered an error.
%
%   F2 = AFTERALL(F,FCN,NOUT,'PassFuture',PASS_FUTURE) will, if
%   PASS_FUTURE is true, evaluate FCN on the array of futures F
%   directly. FCN is always evaluated, even if an element of F
%   encountered an error. If PASS_FUTURE is false, the behavior is
%   the same as for afterAll(F,FCN,NOUT)
%
%   If PASS_FUTURE is true, it is expected that FCN will call
%   fetchOutputs on F to extract the results. Note that
%   fetchOutputs will throw an error if any element of F
%   encountered an error, and in this way FCN can handle underlying
%   errors.
%
%   Examples:
%   % Display histogram of random values created with parfeval
%   for idx = 1:10
%       f(idx) = parfeval(@rand, 1, 1000, 1); % build rand(1000, 1)
%   end
%   futureToHandle = afterAll(f, @histogram, 1);
%   % Once all elements of 'f' are complete,
%   % out = histogram(fetchOutputs(f)) is invoked, and 'out'
%   % is available via fetchOutputs(futureToHandle).
%
%   See also parallel.Future.afterEach, parfeval, parfevalOnAll

% Copyright 2013-2021 The MathWorks, Inc.
