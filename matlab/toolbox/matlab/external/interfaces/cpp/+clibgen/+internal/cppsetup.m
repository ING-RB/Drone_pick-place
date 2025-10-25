function cppsetup(parser)
%CPPSETUP configures the inputParser and the validation rules for each
% input argument
%
%   Input Arguments
%   -----------------
%
%   parser      --  inputParser object

%   Copyright 2018-2024 The MathWorks, Inc.

addParameter(parser,'Libraries',{},@clibgen.internal.validateLibName);
addParameter(parser,'IncludePath',[],@clibgen.internal.validateUserIncludePath);
addParameter(parser,'OutputFolder',pwd,@clibgen.internal.validateOutputDir);
addParameter(parser,'InterfaceName','',@clibgen.internal.validateInterfaceName);
addParameter(parser,'PackageName','',@clibgen.internal.validateInterfaceName);
addParameter(parser,'Logger',[], @(obj)(isa(obj, 'clibgen.internal.MessageLogger')));
addParameter(parser,'Verbose',false,@(opt)validateattributes(opt,{'logical'},{'scalar'}));
addParameter(parser,'TreatObjectPointerAsScalar',false,@(opt)validateattributes(opt,{'logical'},{'scalar'}));
addParameter(parser,'TreatConstCharPointerAsCString',false,@(opt)validateattributes(opt,{'logical'},{'scalar'}));
addParameter(parser,'DefinedMacros',[],@(val)clibgen.internal.validateMacro(val,true));
addParameter(parser,'UndefinedMacros',[],@(val)clibgen.internal.validateMacro(val,false));
addParameter(parser,'GenerateDocumentationFromHeaderFiles',true,@(opt)validateattributes(opt,{'logical'},{'scalar'}));
addParameter(parser,'ReturnCArrays',true,@(opt)validateattributes(opt,{'logical'},{'scalar'}));
addParameter(parser,'SupportingSourceFiles',[],@clibgen.internal.validateSourceFile);
addParameter(parser,'CLinkage',false,@(opt)validateattributes(opt,{'logical'},{'scalar'}));
if strcmp(parser.FunctionName, "generateLibraryDefinition")
    addParameter(parser,'OverwriteExistingDefinitionFiles',false,@(opt)validateattributes(opt,{'logical'},{'scalar'}));    
end
addParameter(parser,'AdditionalCompilerFlags',"",@(opt)clibgen.internal.validateBuildFlags(opt));
addParameter(parser,'AdditionalLinkerFlags',"",@(opt)clibgen.internal.validateBuildFlags(opt));
if strcmp(parser.FunctionName, "generateLibraryDefinition")
    addParameter(parser,'RootPaths',dictionary(string([]),string([])),@(obj)validateattributes(obj,{'dictionary'},{'scalar'}));
end

end
