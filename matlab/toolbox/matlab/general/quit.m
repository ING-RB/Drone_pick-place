%QUIT Quit MATLAB session.
%   QUIT terminates MATLAB after running the script FINISH.M,
%   if it exists. The workspace information will not be saved
%   unless FINISH.M calls SAVE. If an error occurs while
%   executing FINISH.M, quitting is cancelled.
%
%   QUIT FORCE can be used to bypass an errant FINISH.M that
%   will not let you quit.
%
%   QUIT CANCEL can be used in FINISH.M to cancel quitting.
%   It has no effect anywhere else.
%
%   QUIT(CODE) can be used to specify the exit code returned by MATLAB.
%   MATLAB returns 0 for successful termination and non-zero otherwise.
%   Values for CODE must be integers although certain platforms may impose
%   stricter restriction and may have existing conventions for exit codes.
%
%   Examples:
%       quit("force");                  % Skip finish.m
%       quit(1);                        % Return exit code 1
%       quit(1, "force");               % Return exit code 1 AND skip finish.m
%
%   Put the following lines of code in your FINISH.M file to
%   display a dialog that allows you to cancel quitting.
%
%       button = questdlg('Ready to quit?', ...
%                             'Exit Dialog','Yes','No','No');
%       switch button
%           case 'Yes',
%               disp('Exiting MATLAB');
%               %Save variables to matlab.mat
%               save
%           case 'No',
%               quit cancel;
%       end
%
%   Note: When using Handle Graphics in FINISH.M make sure
%   to use UIWAIT, WAITFOR, or DRAWNOW so that figures are
%   visible.
%
%   See also EXIT.

%   Copyright 1984-2018 The MathWorks, Inc.
%   Built-in function.
