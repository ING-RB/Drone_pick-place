% findID Get MSLDiagnostics that have given IDs
% DIAGS = msld.findID(IDS)
% IDS - cell array that contains IDs needed to find in instances(MSLDiagnostic)
% findID looks through causes as well and returns cell array that contains MSLDiagnostics with given IDs
% 
% Example:
% diag = MSLDiagnostic([1, 2], 'my:msg:id', 'my message');
% d = diag.findID({'my:msg:id'});
% 
% See also MException, MESSAGE, ERROR, ASSERT, TRY, CATCH.

% Copyright 2015-2016 The MathWorks, Inc.
% Built-in function.
% 
