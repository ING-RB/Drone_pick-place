function insCreateMotionModelTemplate(name)
%INSCREATEMOTIONMODELTEMPLATE creates a template file for a motion model
%   to be used with the insEKF. The template is opened in the MATLAB
%   Editor. The input NAME is the class name of the new motion model.
%
%   Example:
%       insCreateMotionModelTemplate("mymotion");
%
%   See also: insEKF, insCreateMotionModelTemplate

%   Copyright 2022 The MathWorks, Inc.    

% Validate name is a valid file name

% Code generation is not supported/needed for this. 
% So no codegen pragma, and using assert vs coder.internal.assert

narginchk(1,1);

s = isStringScalar(name) || ischar(name);
val = isvarname(name);
assert(s && val, message('insframework:insEKF:ExpectedValidClassName'));

writer = positioning.internal.MotionWriterPlugin;
writer.writeTemplate(name);
writer.writeContentsToEditor;
