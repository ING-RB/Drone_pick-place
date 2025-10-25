function tf = portableCodegenFeature(varargin)
% For internal testing use only

% This function is used for portable code generation to decide whether or not 
% auto-generated retargetable code should be used for portable targets.
%
% TF = portableCodegenFeature() Returns the previously stored state as a boolean 
% value. The default value is FALSE. Setting this feature to TRUE to enable 
% auto-generated retargetable code.

% TF = portableCodegenFeature(MODE) Returns the input boolean MODE value and also
% updates its state. 

% Copyright 2021 The MathWorks, Inc.

narginchk(0,1);

persistent useRetargetableCodegen

if isempty(useRetargetableCodegen)
    % By Default, use shared library.
    useRetargetableCodegen = false;
end

% Update state to new mode value.
if ~isempty(varargin)
    validateattributes(varargin{1}, {'logical'}, {}, mfilename);
    useRetargetableCodegen = varargin{1};
end

tf = useRetargetableCodegen;
