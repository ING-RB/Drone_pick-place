function p = getParameterFromModel(mdl,names) 
%GETPARAMETERFROMMODEL Create design variables for optimization
%
%    Create an object from a Simulink model variable that you can tune to
%    satisfy design requirements. The variable must be of type double. Use
%    variable indexing to tune a double element of a complex structure.
%
%    p = sdo.getParameterFromModel(ModelName,[VarName]);
%
%    Inputs:
%       ModelName - The name of an open Simulink model where the variable
%                   is used. 
%       VarName   - The Simulink model variable name. Use a cell array of
%                   variables names to create multiple parameter objects.
%                   If omitted the function returns objects for all tunable
%                   variables in the model.
%
%    Outputs:
%       p - A param.Continuous object for the specified model variable. The
%           "Value" property of the parameter object is set to the current
%           variable value.
%
%    Examples:
%       p = sdo.getParameterFromModel('sdoAircraft','Ki');
%       p = sdo.getParameterFromModel('sdoAircraft',{'Ki','Kf'});
%
%    See also param.Continuous, sdo.optimize
%
 
% Copyright 2010-2022 The MathWorks, Inc.

%Check number of input arguments
if nargin < 1 || nargin > 2
    error(message('Controllib:gui:errGetParameterFromModel_NumArgs'))
end

%Check ModelName argument is an open Simulink model
if ~ischar(mdl) || ~any(strcmp(mdl,find_system('type','block_diagram')))
    error(message('Controllib:gui:errGetParameterFromModel_ModelName'))
end
%Check Parameter argument
if nargin < 2
    try
        [names,v] = lGetAllVariables(mdl);
    catch E
        throw(E)
    end
    if isempty(names)
        warning(message('Controllib:gui:warnGetParameterFromModel_NoModelVariables',mdl))
        p = [];
        return
    end    
else
    if ~(ischar(names) || iscellstr(names))
        error(message('Controllib:gui:errGetParameterFromModel_VarName'))
    end
    %Convert names to cell array
    if ~iscell(names), names = {names}; end
    v = cell(size(names));
end
   
%Get current variable values
if any(cellfun('isempty',v))
    try
        v = sdo.getValueFromModel(mdl,names);
    catch E
        throw(E)
    end
end

%Create parameter objects and set properties
for ctP=numel(names):-1:1
    val = v{ctP};
    if isnumeric(val)
        p(ctP,1) = param.Continuous(names{ctP},val);
        %Set the scale.  Use value from param.Continuous so non
        %floating-point values cast to floating-point, so that log can be
        %computed.
        val = p(ctP,1).Value;
        val = abs(val);
        val(val==0) = 1;  %Set scale to 1 for zero values
        s = 2.^ceil(log2(val));
        p(ctP,1).Scale = s;
    else
        error(message('Controllib:gui:errGetParameterFromModel_NumericVariable',names{ctP}))
    end
end
end

function [names,vals] = lGetAllVariables(mdl)
%Helper function to find all tunable model variables. 

names = {};
vals  = {};
vars  = ctrluis.paramtable.getModelVariables(mdl);
if isempty(vars)
    %Nothing to do
    return
end

%Filter out non-double variables
for ct=1:numel(vars)
    val = slResolve(vars(ct).Name,mdl);
    if isfloat(val)
        names = vertcat(names,vars(ct).Name); %#ok<AGROW>
        vals  = vertcat(vals,val); %#ok<AGROW>
    end
end
end