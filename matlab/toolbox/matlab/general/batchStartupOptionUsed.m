%BATCHSTARTUPOPTIONUSED Determines whether the -batch startup option was used.
%    X = BATCHSTARTUPOPTIONUSED returns true when -batch was used at MATLAB startup,
%    and false otherwise.
%
%    This function can be used to guard code from being executed when
%    MATLAB is running non-interactively under -batch and user input is
%    either not desired or not supported in this mode.
%
%    A sample use-case where interactive prompts may not be desired is automated
%    testing. Automated tests may hang or fail if they require user-intervention
%    when run using MATLAB -batch. BATCHSTARTUPOPTIONUSED can be used to provide
%    default values instead of prompting the user.
%
%   Example:
%       if ~batchStartupOptionUsed
%           answer = inputdlg("Enter a number");
%       else
%           answer = 10;
%       end
%
%    See also ISMCC, ISDEPLOYED

%    Copyright 2018 The MathWorks, Inc.
%    Built-in function.
