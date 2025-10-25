function [stepFcnArgs,initFcnArgs,termFcnArgs,argDeclStr,blockDataInitStr] = getFunctionPrototypeArguments(mdlName,buildDir)
% This function is for internal use only. It may be removed in the future.
%
% GETFUCNCTIONPROTOTYPEARGUMENTS Returns Simulink Coder generated model-step,
% model-initialize and model-terminate function call signatures with input
% argument declarations.
%
% Example:
%
%   [step, initFcn, termFcn, argDeclaration] = getFunctionPrototypeArguments('modelname',fullfile(pwd,'modelname_ert_rtw'))
%       returns the model-step, initialize, terminate function call
%       argument-strings and the argument-declaration string using
%       code-information from the code generation folder of Simulink model,
%       'modelname', in current working folder.


% Copyright 2023 The MathWorks, Inc.

arguments
    mdlName {mustBeNonzeroLengthText}
    buildDir {mustBeFolder}
end

mustBeFile(fullfile(buildDir,"codeInfo.mat"));
cInfo = load(fullfile(buildDir,"codeInfo.mat"));
codeInfo = cInfo.codeInfo;
stepFcnArgs = repmat({''},numel(codeInfo.OutputFunctions),1);

% Initialize function must declare all the arguments used by
% output-functions.
[initFcnArgs,argDeclStrObj] = getFcnArgsAndFcnCallFromCodeInfo(codeInfo.InitializeFunctions(1));
idx = arrayfun(@(x)isequal(x.GraphicalName,'RTModel'),codeInfo.InternalData);
argDeclStrObj = getRTModelInit(codeInfo.InternalData(idx),codeInfo.AllocationFunction,argDeclStrObj);

if isempty(codeInfo.AllocationFunction)
    blockDataInit = getBlockDataInitializations(codeInfo.InternalData,argDeclStrObj);
    blockDataInitStr = blockDataInit.string;
else
    blockDataInitStr = '';
end
argDeclStr = argDeclStrObj.string;
termFcnArgs = getFcnArgsAndFcnCallFromCodeInfo(codeInfo.TerminateFunctions(1));
for k=1:numel(codeInfo.OutputFunctions)
    stepFcnArgs{k} = getFcnArgsAndFcnCallFromCodeInfo(codeInfo.OutputFunctions(k));
end
if isempty(stepFcnArgs) || isempty(stepFcnArgs{1})
    % Set the step-function arguments to an empty-cell so the client of
    % this function can perform a simpler isempty() comparison instead of
    % looking for the first member of the cell as well
    stepFcnArgs = {};
end
end

function argDeclStrObj = getRTModelInit(rtModelData,allocFcn,argDeclStrObj)
arguments
    rtModelData {mustBeA(rtModelData,'RTW.DataInterface')}
    allocFcn {mustBeA(allocFcn,'RTW.FunctionInterface')}
    argDeclStrObj {mustBeA(argDeclStrObj,'StringWriter')}
end
baseArg = rtModelData.Implementation.Identifier;
baseType = rtModelData.Implementation.TargetVariable.Type.Identifier;
baseId = rtModelData.Implementation.TargetVariable.Identifier;
if isempty(allocFcn)
    argDeclStrObj.addcr(sprintf('static %s %s;',baseType, baseId));
    argDeclStrObj.addcr(sprintf('static %s *const %s = &(%s);',baseType,baseArg,baseId));
else
    argDeclStrObj.addcr(sprintf('static %s *const %s = %s();',baseType,baseArg,allocFcn.Prototype.Name));
end
end

function blockDataInit = getBlockDataInitializations(internalData,argDeclStrObj)
arguments
    internalData {mustBeA(internalData,'RTW.DataInterface')}
    argDeclStrObj {mustBeA(argDeclStrObj,'StringWriter')}
end
blockDataInit = StringWriter;
for k=1:numel(internalData)
    if ismember(internalData(k).GraphicalName,{'Block states','Block signals'})
        tgtRegion =  internalData(k).Implementation.TargetRegion;
        baseRegion = internalData(k).Implementation.BaseRegion;
        argDeclStrObj.addcr(sprintf('static %s %s;', ...
            tgtRegion.Type.Identifier,tgtRegion.Identifier));
        blockDataInit.addcr(sprintf('%s->%s = &(%s);',...
            baseRegion.Identifier,...
            internalData(k).Implementation.ElementIdentifier,...
            tgtRegion.Identifier));
    end
end
end

function [argStr,fcnArgsToDeclare] = getFcnArgsAndFcnCallFromCodeInfo(fcnInfo)
% GETFCNARGSANDFCNCALLFROMCODEINFO Parses the codeInfo objects for the
% function to return the function-call and arguments.
args = fcnInfo.ActualArgs;
protoArgs = fcnInfo.Prototype.Arguments;
fcnArgsToDeclare =  StringWriter;
fcnArgs = repmat({''},numel(args),1);
for k=1:numel(args)
    baseArg = args(k).Implementation.Identifier;
    if ~isequal(args(k).GraphicalName,'RTModel')
        % RTModel definition is dependent on the AllocationFunction
        if isa(args(k).Implementation,'RTW.PointerVariable')
            baseType = args(k).Implementation.TargetVariable.Type.Identifier;
            baseId = args(k).Implementation.TargetVariable.Identifier;
            fcnArgsToDeclare.addcr(sprintf('static %s %s;',baseType, baseId));
            if args(k).Implementation.Type.ReadOnly
                fcnArgsToDeclare.addcr(sprintf('static %s *const %sPtr = &(%s);',baseType,baseArg,baseId));
            else
                fcnArgsToDeclare.addcr(sprintf('static %s * %s = &(%s)',baseType,baseArg,baseId));
            end
        else
            baseType = args(k).Implementation.Type.Identifier;
            fcnArgsToDeclare.addcr(sprintf('static %s %s;',baseType,baseArg));
        end
    end
    if isa(protoArgs(k).Type,'coder.types.Pointer')
        if isequal('RTModel',args(k).GraphicalName)
            % RTModel argument is always a pointer
            fcnArgs{k} =  protoArgs(k).Name;
        else
            fcnArgs{k} = ['&',protoArgs(k).Name];
        end
    else
        fcnArgs{k} =  protoArgs(k).Name;
    end
end
if isempty(fcnArgs)
    argStr = '';
else
    argStr = strjoin(fcnArgs,', ');
end

end