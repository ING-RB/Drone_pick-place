function run(scriptname)
%RUN Run script.
%   Typically, you just type the name of a script at the prompt to
%   execute it. This works when the script is on your path.  Use CD
%   or ADDPATH to make the script executable from the prompt.
%
%   RUN is a convenience function that runs scripts that are not
%   currently on the path.
%
%   RUN SCRIPTNAME runs the specified script. If SCRIPTNAME contains
%   the full pathname to the script, then RUN changes the current
%   directory to where the script lives, executes the script, and then
%   changes back to the original starting point. The script is run
%   within the caller's workspace.
%

%   NOTES:
%     * If SCRIPTNAME attempts to CD into its own folder, RUN cannot detect
%       this change. In this case, RUN will revert to the starting folder
%       on exit.
%     * If SCRIPTNAME is a MATLAB file and there is a P-file in the same
%       folder, RUN silently executes the P-file.
%
%   See also CD, ADDPATH.

%   Copyright 1984-2017 The MathWorks, Inc.

if isstring(scriptname) || iscellstr(scriptname)
    scriptname = char(scriptname);
end

if ~ischar(scriptname)
    error(message('MATLAB:run:NonScalarScriptname'));
end

if isempty(scriptname)
    return;
end

if ~isvector(scriptname)
    error(message('MATLAB:run:NonScalarScriptname'));
end

if ispc
    scriptname = strrep(scriptname,'/','\');
end
cleaner = onCleanup(@() ([]));
[dir,scriptStem,ext] = fileparts(scriptname);
startDir = pwd;

% If the input had a path, CD to that path if it exists
if ~isempty(dir)
    if ~exist(dir,'dir')
        error(message('MATLAB:run:FileNotFound',scriptname));
    end
    cd(dir);
    
    dir = pwd; % get the fully qualified path name
    cleaner = onCleanup(@() resetCD(startDir,dir));
end

% Look for executable 'script', ignoring variables in RUN's workspace.
foundScript = evalin('caller', strcat("which('", scriptStem, "')"));

%if it is a variable then 'script' cannot be run due to precedence
if strcmp(foundScript, 'variable')
    warning(message('MATLAB:persistentVariableAlreadyInWS', scriptStem));
    return;
end

% If not found .
if isempty(foundScript)  
    if isempty(dir) || isempty(ext)
        error(message('MATLAB:run:FileNotFound',scriptname));
    else
        error(message('MATLAB:run:CannotExecute',scriptname));
    end
end

[foundDir,~,foundExt] = fileparts(foundScript);

%If which doesn't find a script in the same location as the requested path,
% calling evalin will run the wrong script.
% In other words, the script at the requested path doesn't exist.
if isempty(foundDir) || (~isempty(dir) && ~strcmp(foundDir,pwd))
    error(message('MATLAB:run:FileNotFound',scriptname));
end

% Determine if the script that will run matches the script requested by the
% user.
foundFileMatchesRequestedFile = isempty(ext) || ... 
                            strcmp(ext,foundExt) || ...
                            (strcmp(ext,'.m') && strcmp(foundExt,'.p'));

% If the requested script is not the one being run, check if there is a
% matching script anywhere on the path. If there is, it is being shadowed.
if ~foundFileMatchesRequestedFile
    
    pathScripts = evalin('caller', ...
        strcat("which('", scriptStem, "','-all')"));
    [~,~,pathExts] = fileparts(pathScripts);
    isRequestedFileExecutable = any(strcmp(pathExts,ext));
    
    if isRequestedFileExecutable
        error(message('MATLAB:run:ShadowedFile', foundScript));
    else
        error(message('MATLAB:run:CannotExecute',scriptname));
    end
end

% Finally, evaluate the script if it exists and isn't a shadowed script.
evalin('caller', strcat(scriptStem, ';'));
delete(cleaner);
end

%on exit in case of an error.
function resetCD(returnDir,tempDir)
if strcmp(tempDir,pwd)
    cd(returnDir);
end
end