%AFTEREACH Specify function to invoke after each Future completes
%   F2 = AFTEREACH(F,FCN,NOUT) creates parallel.Future F2 which
%   will produce the result of evaluating FCN on the output
%   arguments of each of the elements in F as they become complete.
%   FCN is evaluated on the MATLAB client, not on the parallel pool
%   workers. The OutputArguments property of F2 is a cell array
%   with numel(F) cells, where each cell contains NOUT output
%   arguments from a single invocation of FCN. Calling fetchOutputs
%   on F2 concatenates corresponding output arguments, as is the
%   case for a future returned by parfevalOnAll.
%
%   Evaluating:
%   F2 = afterEach(F, FCN, NOUT);
%   [X, Y, Z] = fetchOutputs(F2);
%   Is equivalent to evaluating:
%   X = []; Y = []; Z = [];
%   for idx = 1:numel(F)
%       [a, b] = fetchOutputs(F(idx));
%       [x, y, z] = FCN(a, b);
%       X = [X; x]; Y = [Y; y]; Z = [Z; z];
%   end
%   Except that in the former case, FCN is invoked automatically
%   each time an element of F becomes complete.
%
%   If an element of F encounters an error, FCN is not evaluated
%   for that element of F, but will be evaluated for other elements
%   of F which do not encounter errors. F2 has an Error property
%   that is an empty cell array if there are no errors. Otherwise
%   it is a cell array of length numel(F). A cell contains an error
%   if evaluating FCN for the corresponding element of F
%   encountered an error, and is otherwise empty.
%
%   Cancelling a element of F will result in the same behavior as
%   if the element encountered an error.
%
%   F2 = AFTEREACH(F,FCN,NOUT,'PassFuture',PASS_FUTURE) will, if
%   PASS_FUTURE is true, evaluate FCN on each element of F
%   directly, even if elements of F encountered errors. If
%   PASS_FUTURE is false, the behavior will be the same as for
%   afterEach(F,FCN,NOUT).
%
%   If PASS_FUTURE is true, it is expected that FCN will call
%   fetchOutputs on its element of F to extract the results. Note
%   that fetchOutputs will throw an error if any element of F
%   encountered an error, and in this way FCN can handle underlying
%   errors.
%
%   Examples:
%   % Compute random vectors, and display value largest in them as
%   % they become ready
%   for idx= 1:10
%       f(idx) = parfeval(@rand, 1, 1000, 1);
%   end
%   % 'r' will be the random vector
%   f2 = afterEach(f, @(r) disp(max(r)), 0);
%   % after each element f(idx) of 'f' becomes complete,
%   % disp(max(fetchOutputs(f(idx))) is invoked.
%
%   See also parallel.Future.afterAll, parfeval, parfevalOnAll

% Copyright 2013-2021 The MathWorks, Inc.
