classdef DeploymentPackaging
%

%   Copyright 2019-2020 The MathWorks, Inc.

    methods(Static)
         % Returns the list of files and support packages on which the input
        % files are dependent.
        function [depfileslist, depsupportpackagelist]=findDependencies (allInputs)
            warnstatus = warning('OFF','MATLAB:depfun:req:AllInputsExcluded');
            restoreWarnState = onCleanup(@()warning(warnstatus));

            % Convert JAVA String vector to MATLAB cell array
            mcc_settings.source_file = cell(allInputs{1});    % files to analyze (resources and entrypoints)
            mcc_settings.dash_p      = cell(allInputs{2});    % -p
            mcc_settings.dash_I      = cell(allInputs{3});    % -a
            mcc_settings.dash_a      = cell(allInputs{4});    % -I
            mcc_settings.dash_N      = logical(allInputs{5}); % -N
            mcc_settings.dash_X      = logical(allInputs{6}); % -X

            [parts, resources] = matlab.depfun.internal.deploytool_call_requirements(mcc_settings);

            depfileslist = {};
            if ~isempty(parts)
                depfileslist = {parts.path};
            end

            % Check possibly required support packages.
            depproductlist = {};
            if ~isempty(resources) && ~isempty(resources.products)
                depproductlist = {resources.products([resources.products.Certain]).Name};
            end
            depsupportpackagelist = matlab.depfun.internal.format.CommonUtilities.findSupportPackages(depfileslist, depproductlist);
        end
    %returns all the dependencies that are not within the toolbox folder
        function [ externalDependencies, productName, productVersion, productNumber, supportPackages] = findExternalDependenciesTopOnly(toolboxRoot,UseTopOnly,varargin)
            if UseTopOnly
                [depfileslist, products] = matlab.depfun.internal.format.ToolboxPackaging.getAllRequiredFilesAndProducts(varargin, 'toponly');
            else
                [depfileslist, products] = matlab.depfun.internal.format.ToolboxPackaging.getAllRequiredFilesAndProducts(varargin);
            end
            [supportPackages] =  matlab.depfun.internal.format.CommonUtilities.findSupportPackages(depfileslist, cellfun(@(x) char(x), {products(:).Name}, 'UniformOutput',false));
            isInToolbox = matlab.depfun.internal.format.ToolboxPackaging.areFilesInToolbox(depfileslist, toolboxRoot);
            externalDependencies = depfileslist(~cell2mat(isInToolbox));
            productName = cellfun(@(x) char(x), {products(:).Name}, 'UniformOutput',false);
            productVersion = cellfun(@(x) char(x), {products(:).Version}, 'UniformOutput',false);
            productNumber = cellfun(@(x) mat2str(x), {products(:).ProductNumber}, 'UniformOutput',false);
        end

    end
end

% LocalWords:  entrypoints toponly
