classdef AppsPackaging
%

%   Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Static)
        
        %Find all files, products, and platforms on which the input is dependent
        function [depfileslist, products, platforms] = findDependencies(filesToAnalyze)
            [dependentfiles, depproducts, ~] = matlab.depfun.internal.requirements(filesToAnalyze, 'MATLAB');
            if(~isempty(dependentfiles))
                depfileslist = {dependentfiles(:).path};
            else
                depfileslist = {};
            end
            if(~isempty(depproducts.products))
                depproductname = cellfun(@(x) char(x), {depproducts.products(:).Name}, 'UniformOutput',false);
                depproductversion = cellfun(@(x) char(x), {depproducts.products(:).Version}, 'UniformOutput',false);
                depproductnumber = cellfun(@(x) mat2str(x), {depproducts.products(:).ProductNumber}, 'UniformOutput',false);
                platforms = depproducts.platforms;
            else
                depproductname = {};
                depproductversion = {};
                depproductnumber = {};
                platforms = {};
            end
            products = struct('Name', depproductname, 'Version', depproductversion, 'Number', depproductnumber);
        end
    end
    
end

