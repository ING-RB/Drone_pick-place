function warnOnceCannotSave(className)
%warnOnceCannotSave Warn about not being able to save object
%   warnOnceCannotSave(className) Warns only if we haven't previously warned for
%   this class.  This means that the warning won't appear multiple times if you
%   save an array of jobs.  It also gets round the fact that saveobj gets called
%   twice when you actually try to save an object (g1025440).
%
%   If the supplied className is empty, then this forgets all information about
%   which classes have previously had warnings.

% Copyright 2015-2021 The MathWorks, Inc.

persistent alreadyWarnedClassNames

if isempty( className )
    alreadyWarnedClassNames = {};
    return;
end

if isempty( alreadyWarnedClassNames ) && ~iscell( alreadyWarnedClassNames )
    alreadyWarnedClassNames = {};
end

if ismember( className, alreadyWarnedClassNames )
    return;
end

parallel.internal.warningNoBackTrace( ...
    message( 'MATLAB:parallel:loadsave:CannotSaveCorrectly', className ) );
alreadyWarnedClassNames = [alreadyWarnedClassNames, className];
end
