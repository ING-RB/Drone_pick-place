classdef ProductComponentModuleNavigator < handle
% matlab.depfun.internal.ProductComponentModuleNavigator provides APIs to
% access the product-component-module (PCM) database.

%   Copyright 2015-2023 The MathWorks, Inc.

    properties (Access = private)
        SqlDBConnObj
        db_path
        builtinToRequiredComponentMap
    end

    properties
        sourceToComponentMap
        productDependencyMap
        undeployableMatlabModule
        builtinRegistry
    end

    properties (Access = private, Hidden)
        env
        pathUtil
    end

    % Constructor and destructor
    methods
        function obj = ProductComponentModuleNavigator(varargin)
        % Create an instance of the navigator class.
        %     The input 'pcm_db' can be
        %         (1) the full path of the database;
        %         (2) the path of the database relative to 
        %             the current working directory.
        %     The output 'obj' is the instantiated object.
        % Connect to the given database if it is valid. 
        % Otherwise, it errors the given database cannot be found or opened.
            
            narginchk(0,1);
            
            % Create a database connector object.
            obj.SqlDBConnObj = matlab.depfun.internal.database.SqlDbConnector;
            
            obj.env = matlab.depfun.internal.reqenv;
            obj.pathUtil = matlab.depfun.internal.PathUtility;
            % connect to the database
            if nargin == 0
                dbFile = obj.env.PcmPath;
            else
                dbFile =  varargin{1};
            end
            obj.connect(dbFile);
        end

        function delete(obj)
        %?Destroy the instance of the navigator class.
        %  The destructor will be 
        %      (1) explicitly called when the object is deleted;
        %      (2) implicitly called when the object goes out of scope.
        %?Disconnecting to the database in the destructor can conveniently allow the client 
        %  not to write onCleanup(@()obj.disconnect()), which is pretty boring.
            obj.disconnect();
        end
    end
    
    methods
        function connect(obj, pcm_db)
        % (1) The class constructor calls it when initializing the instance.
        % (2) After the instance is created, it can be reset to connect to a different database.
        % connect() sets the database path, which is a private property, and then connects to it.
        % connect() errors if it fails to open the given database.
            obj.db_path = pcm_db;
            
            % disconnect the currently connected database
            if ~isempty(obj.SqlDBConnObj)
                obj.disconnect();
            end
            
            % The ProductComponentModuleNavigator supports only read operations
            % Connect read only
            obj.SqlDBConnObj.connectReadOnly(obj.db_path);
            
            % we're never going to try to recover the DB if something goes wrong
            % just shut all this stuff off
            obj.SqlDBConnObj.doSql('PRAGMA synchronous=OFF;', false);
            obj.SqlDBConnObj.doSql('PRAGMA journal_mode=OFF;', false);
            obj.SqlDBConnObj.doSql('PRAGMA temp_store=MEMORY;', false);
        end
        
        function disconnect(obj)
        % Calls the disconnect method in the instance of class
        % matlab.depfun.internal.database.SqlDbConnector.
        % Called by the class destructor.
            obj.SqlDBConnObj.disconnect();
        end
    end
    
    % ----- Public methods for querying product information -----
    methods
        function pinfo = productShippingFile(obj, afullpath, target)
        % Provide detailed information of products shipping the given file.
        % Inputs: 
        %     'afullpath' is a string, which must be the full path of the file.
        %     'target' is a string of one of matlab.depfun.internal.Target.
        %
        % The output 'pinfo' is a struct array of product information. 
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPName - product external name
        %         extPID   - external product ID
        %         version  - product version
        %         LName    - product license name
        %         baseCode - product base code        
        % The output is an empty struct array, if no product ships the given file.
            requiresChar(afullpath);
            
            pinfo = struct([]);
            if exist(afullpath, 'file')
                cname = obj.componentOwningFile(afullpath);
                pinfo = obj.productShippingComponent(cname, target);
            end
        end

        function pinfo = productShippingBuiltin(obj, abuiltin, target)
        % Provide detailed information of products shipping the given built-in.
        % Inputs:
        %     'abuiltin' is a string of a built-in symbol.
        %     'target' is a string of one of matlab.depfun.internal.Target.
        % The output 'pinfo' is a struct array of product information. 
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPName - product external name
        %         extPID   - external product ID
        %         version  - product version
        %         LName    - product license name
        %         baseCode - product base code
        % The output is an empty struct array, if no product ships the given built-in.
            requiresChar(abuiltin);
        
            pinfo = struct([]);
            if isKey(obj.builtinRegistry, abuiltin)
                component = obj.builtinRegistry(abuiltin).component;
                pinfo = productShippingComponent(obj, component, target);
            end
        end
        
        function pinfo = productShippingSymbol(obj, asymbol, target)
        % Determine whether the given symbol is a file or a built-in,
        % then forward the call to productShippingFile() or productShippingBuilin().
        % Inputs:
        %     'asymbol' is a string of a symbol.
        %     'target' is a string of one of matlab.depfun.internal.Target.
        % Refer comments in productShippingFile() or productShippingBuilin() for the output 'pinfo'. 
        % The output is an empty struct array, if no product ships the given symbol.
            requiresChar(asymbol);
            
            w = which(asymbol);
            if ~isempty(strfind(w, ...
                    matlab.depfun.internal.requirementsConstants.BuiltInStr))
                pinfo = productShippingBuiltin(obj, asymbol, target);
            else
                pinfo = productShippingFile(obj, w, target);
            end
        end
        
        function pinfo = productShippingComponent(obj, acomponent, target)
        % Provide detailed information of products shipping the given component.
        % Inputs:
        %     'acomponent' is a string.
        %     'target' is a string of one of matlab.depfun.internal.Target.
        % The output 'pinfo' is a struct array of product information. 
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPName - product external name
        %         extPID   - external product ID
        %         version  - product version
        %         LName    - product license name
        %         baseCode - product base code
        % The output is an empty struct array, if no product ships the given component.
            requiresChar(acomponent);
            
            pinfo = struct([]);
            if ~isempty(acomponent)
                pid_filter = perTargetProductFilter(target);                                    
                query = sprintf( ...
                    ['SELECT Product.Internal_Name, ' ...
                     '       Product.External_Name, ' ...
                     '       Product.External_Product_ID, ' ...
                     '       Product.Version, ' ...
                     '       Product.License_Name, ' ...
                     '       Product.Base_Code, ' ...
                     '       Product.Is_Controlling_Product ' ...
                     'FROM Product, Component, Product_Component ' ...
                     'WHERE Component.Name = ''%s'' ' ...
                     '  AND Product_Component.Component = Component.ID ' ...
                     '  AND Product.ID = Product_Component.Product ' ...
                     pid_filter ';'], acomponent);
                obj.doSql(query);
                % More than one products may ship the same components
                result = obj.fetchRows();
                pinfo = obj.productList(result);
            end
        end
        
        function result = productShippingComponentWithLicenseTest(obj, components, target, test_license)
        % Return a list of products which ship the given components
        % Ignore components in the base product for performance
            if target == matlab.depfun.internal.Target.MCR
                ignoreList = matlab.depfun.internal.requirementsConstants.componentsInNumerics;
            else
                ignoreList = matlab.depfun.internal.requirementsConstants.componentsInMATLAB;
            end
            components = setdiff(components, ignoreList);

            result = cell(size(components));
            pid = cell(size(components));
            licenseAndInstallCache = containers.Map('KeyType','double','ValueType','logical');
            licenseAndInstallCache(1)=1; % MATLAB is always licensed.

            if ~isempty(components)
                warnOrgState = warning('off', 'MATLAB:ver:ProductNameDeprecated');
                restoreVerWarn = onCleanup(@()warning(warnOrgState));

                pinfo = cellfun(@(c)obj.productShippingComponent(c, target), ...
                                components, 'UniformOutput', false);

                if ~test_license
                    result = pinfo;
                    return;
                end

                for k = 1:numel(components)
                    if ~isempty(pinfo{k})
                        % Check if the retail product corresponding to the add-in
                        % is licensed and installed (only for deployment
                        % target).
                        pid{k} = [pinfo{k}.extPID];
                        % Retail product ID is runtime addin product id - 35100.
                        % If the value is <0, then it is either a
                        % core runtime or a language binding.
                        if target == matlab.depfun.internal.Target.MCR
                            pinfo_ml = get_retail_pid(pid{k});
                        else
                            pinfo_ml = pid{k};
                            % Replace Simulink pid with Simulink Compiler pid here,
                            % so Simulink components are not filtered at
                            % the step of filtering expected file list.
                            % Most of Simulink components will be ignored
                            % at a later step because they don't ship with
                            % any mcr product.
                            pinfo_ml(pinfo_ml==2) = 174;
                        end
                        % Only return the runtime addins for which
                        % the corresponding product is licensed and
                        % installed.
                        keep = false(size(pinfo_ml));
                        for ii=1:numel(pinfo_ml)
                            % Product numbers 80 and 94 do not return a value
                            % for ver. Hence, skip ver/install check for those products.
                            % Product 1 is always licensed.
                            if ~licenseAndInstallCache.isKey(pinfo_ml(ii))
                                lProd = obj.productInfo(pinfo_ml(ii));
                                allowed = isempty(lProd) || (license('test', lProd.LName) ...
                                                             && ~isempty(ver(lProd.intPName)));
                                licenseAndInstallCache(pinfo_ml(ii)) = allowed;
                            else
                                allowed = licenseAndInstallCache(pinfo_ml(ii));
                            end
                            keep(ii) = allowed;
                        end
                        result{k} = pinfo{k}(keep);
                    end
                end
            end
        end

        function pinfo = productInfo(obj, aproduct)
        % Provide detailed information of the given product.
        % Inputs:
        %     'aproduct' is a string (internal product name) 
        %                   or a number (external product id).
        % The output 'pinfo' is a struct of product information. 
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPName - product external name
        %         extPID   - external product ID
        %         version  - product version
        %         LName    - product license name
        %         baseCode - product base code
        % The output is an empty struct, if the given product is unknown.
            pinfo = struct([]);
            if ~isempty(aproduct)
                if ischar(aproduct)
                    query = sprintf( ...
                            ['SELECT Internal_Name, ' ...
                             '       External_Name, ' ...
                             '       External_Product_ID, ' ...
                             '       Version, ' ...
                             '       License_Name, ' ...
                             '       Base_Code, ' ...
                             '       Is_Controlling_Product ' ...
                             'FROM Product ' ...
                             'WHERE Product.Internal_Name = ''%s'' ' ...
                             '   OR Product.Base_Code = ''%s'';'], aproduct, aproduct);
                    obj.doSql(query);
                    % More than one products may ship the same components
                    result = obj.fetchRows();
                    pinfo = obj.productList(result);
                elseif isnumeric(aproduct)
                    query = sprintf( ...
                            ['SELECT Internal_Name, ' ...
                             '       External_Name, ' ...
                             '       External_Product_ID, ' ...
                             '       Version, ' ...
                             '       License_Name, ' ...
                             '       Base_Code, ' ...
                             '       Is_Controlling_Product ' ...
                             'FROM Product ' ...
                             'WHERE Product.External_Product_ID = %d;'], aproduct);
                    obj.doSql(query);
                    % More than one products may ship the same components
                    result = obj.fetchRows();
                    pinfo = obj.productList(result);
                end
            end
        end

        function platform = productReleasedPlatforms(obj, aproduct)
        % Provide released platform information of the given product.
        % Inputs:
        %     'aproduct' is a string (internal product name) 
        %                   or a number (external product id).
        % The output 'platform' is a cell array of platform names.
        %     The output is an empty cell, if the given product is unknown.
            platform = {};
            if ~isempty(aproduct)
                if ischar(aproduct)
                    query = sprintf( ...
                            ['SELECT Platform.Name ' ...
                             '  FROM Product, Product_Released_Platform, Platform ' ...
                             ' WHERE Product.Internal_Name = ''%s'' ' ...
                             '   AND Product.ID = Product_Released_Platform.Product ' ...
                             '   AND Product_Released_Platform.Released_Platform = Platform.ID;'], ...
                             aproduct);
                elseif isnumeric(aproduct)
                    query = sprintf( ...
                            ['SELECT Platform.Name ' ...
                             '  FROM Product, Product_Released_Platform, Platform ' ...
                             ' WHERE Product.External_Product_ID = %d ' ...
                             '   AND Product.ID = Product_Released_Platform.Product ' ...
                             '   AND Product_Released_Platform.Released_Platform = Platform.ID;'], ...
                             aproduct);
                end
                obj.doSql(query);
                result = obj.fetchRows();
                platform = cellfun(@(r)r{1},result,'UniformOutput',false);
            end
        end

        function pinfo = MatlabRuntimeProductsOnPlatform(obj, aplatform)
        % Provide detailed information of all MATLAB Runtime products on a given platform.
        % Inputs:
        %     'aplatform' is a string (internal platform name).
        % The output 'pinfo' is a struct of product information. 
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPID   - external product ID
        % The output is an empty struct, if the given platform is unknown.
            import matlab.depfun.internal.requirementsConstants

            pinfo = struct([]);
            if ~isempty(aplatform) && ischar(aplatform)
                query = sprintf( ...
                                ['SELECT Product.Internal_Name, ' ...
                                 '       Product.External_Product_ID ' ...
                                 '  FROM Product, Product_Released_Platform, Platform ' ...
                                 ' WHERE Platform.Name = ''%s'' ' ...
                                 '   AND Platform.ID = Product_Released_Platform.Released_Platform ' ...
                                 '   AND Product_Released_Platform.Product = Product.ID ' ...
                                 '   AND (Product.External_Product_ID >= %d ' ...
                                 '   AND  Product.External_Product_ID <= %d);'], ...
                                aplatform, requirementsConstants.mcr_pid_min, requirementsConstants.mcr_pid_max);
                obj.doSql(query);
                result = obj.fetchRows();
                pinfo = struct('intPName', cellfun(@(r)r{1},result,'UniformOutput',false), ...
                               'extPID', cellfun(@(r)double(r{2}),result,'UniformOutput',false));
            end
        end

        function pinfo = findProductWithIdentifyingComponent(obj, acomponent)
        % Find the product based on the given identifyingComponentName.
        % Inputs:
        %     'acomponent' is a string.
        % The output 'pinfo' is a struct of product information. 
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPName - product external name
        %         extPID   - external product ID
        %         version  - product version
        %         LName    - product license name
        %         baseCode - product base code
        % The output is an empty struct, if the given product is unknown.
        
            requiresChar(acomponent);
            
            pinfo = struct([]);
            if ~isempty(acomponent)
                query = sprintf( ...
                    ['SELECT Product.Internal_Name, ' ...
                     '       Product.External_Name, ' ...
                     '       Product.External_Product_ID, ' ...
                     '       Product.Version, ' ...
                     '       Product.License_Name, ' ...
                     '       Product.Base_Code, ' ...
                     '       Product.Is_Controlling_Product ' ...
                     'FROM Product, Component ' ...
                     'WHERE Component.Name = ''%s'' ' ...
                     '  AND Product.Identifying_Component = Component.ID;' ...
                    ], acomponent);
                obj.doSql(query);
                result = obj.fetchRows();
                pinfo = obj.productList(result);
            end
        end

        function result = getUndeployableMatlabModule(obj)
            if isempty(obj.undeployableMatlabModule)
                obj.doSql(['SELECT Path_Item.Location ' ...
                   'FROM Path_Item, Undeployable_MATLAB_Module ' ...
                   'WHERE Undeployable_MATLAB_Module.Path_Entry = Path_Item.ID;']);

                rawData = obj.fetchRows();
                result = cellfun(@(r)r{1},rawData,'UniformOutput',false);
                result = sort(result);
                result = fullfile(matlabroot, result);
                obj.undeployableMatlabModule = result;
            else
                result = obj.undeployableMatlabModule;
            end
        end

        function pinfo = requiredProducts(obj, aproduct)
        % Find the product-level dependencies based on the given product name.
        % Inputs:
        %     'aproduct' is a string.
        % The output 'pinfo' is a struct of product information.
        %     Each element contains the following information of a product:
        %         intPName - product internal name
        %         extPName - product external name
        %         extPID   - external product ID
        %         version  - product version
        %         LName    - product license name
        %         baseCode - product base code
        % The output is an empty struct, if the given product is unknown.

            requiresChar(aproduct);

            pinfo = struct([]);
            if ~isempty(aproduct)
                query = sprintf( ...
                    ['SELECT Product.Internal_Name, ' ...
                     '       Product.External_Name, ' ...
                     '       Product.External_Product_ID, ' ...
                     '       Product.Version, ' ...
                     '       Product.License_Name, ' ...
                     '       Product.Base_Code, ' ...
                     '       Product.Is_Controlling_Product ' ...                     
                     'FROM Product ' ...
                     'WHERE Product.ID IN ' ...
                     '  (SELECT Product_Dependency.Service ' ...
                     '   FROM Product, Product_Dependency ' ...
                     '   WHERE Product.Internal_Name = ''%s'' ' ...
                     '     AND Product_Dependency.Client = Product.ID);'], aproduct);
                obj.doSql(query);
                % More than one products may ship the same components
                result = obj.fetchRows();
                pinfo = obj.productList(result);
            end
        end

        function product_dependency_map = get.productDependencyMap(obj)
        % Generate a product-level dependency map
        % Key - product internal name
        % Value - cell array of required product internal name(s)

            if isempty(obj.productDependencyMap)
                obj.doSql(['SELECT Client, Service ' ...
                           'FROM Product_Dependency;']);
                result = obj.fetchRows();
                client_id = cell2mat(cellfun(@(r)r{1},result,'UniformOutput',false));
                service_id = cell2mat(cellfun(@(r)r{2},result,'UniformOutput',false));
                client_name = cell(size(client_id));
                service_name = cell(size(service_id));

                obj.doSql(['SELECT Internal_Name ' ...
                           'FROM Product;']);
                product_internal_name_list = obj.fetchRows();

                % replace id with product internal name
                for k = 1:numel(product_internal_name_list)
                    client_name(client_id==k) = product_internal_name_list{k};
                    service_name(service_id==k) = product_internal_name_list{k};
                end

                % generate a product dependency map
                obj.productDependencyMap = dictionary(string.empty, cell(0,0));
                unique_client = unique(client_name);
                for k = 1:numel(unique_client)
                    obj.productDependencyMap(unique_client{k}) = ...
                        {service_name(strcmp(client_name, unique_client{k}))};
                end
            end

            product_dependency_map = obj.productDependencyMap;
        end
    end

    % ----- Public methods for querying component information -----
    methods
        function cname = componentOwningFile(obj, afullpath)
        % Find the owning component of the given file.
        % The input 'afullpath' is a string, which must be the full path of the file.
        %
        % The output 'cname' is a string of the component name.
        % The output is empty, if no component owns the given file.
            requiresChar(afullpath);

            cname = '';
            if matlab.depfun.internal.PathUtility.underMatlabroot(afullpath) && exist(afullpath, 'file')
                relative_path = matlab.depfun.internal.PathUtility.stripMatlabroot(afullpath);
                while ~isempty(relative_path)
                    if isKey(obj.sourceToComponentMap, relative_path)
                        cname = obj.sourceToComponentMap{relative_path};
                        break;
                    else
                        % Trim off the last part.
                        relative_path = fileparts(relative_path);
                    end
                end
            end
        end

        function cname = componentOwningBuiltin(obj, abuiltin)
        % Find the owning component of the given built-in.
        % The input 'abuiltin' is a string of a built-in symbol.
        % The output 'cname' is a string of the component name.
        % The output is empty, if no component owns the given built-in.
            requiresChar(abuiltin);
            
            cname = '';
            if isKey(obj.builtinRegistry, abuiltin)
                cname = obj.builtinRegistry(abuiltin).component;
            end
        end
        
        function cname = componentOwningSymbol(obj, asymbol)
        % Determine whether the given symbol is a file or a built-in,
        % then forward the call to componentOwningFile() or componentOwningBuiltin().
        % The input 'asymbol' is a string of a symbol.
        % The output 'cname' is a string of the component name.
        % The output is empty, if no component owns the given symbol.
            requiresChar(asymbol);
            
            w = which(asymbol);
            if ~isempty(strfind(w, ...
                    matlab.depfun.internal.requirementsConstants.BuiltInStr))
                cname = componentOwningBuiltin(obj, asymbol);
            else
                cname = componentOwningFile(obj, w);
            end
        end
        
        function cinfo = componentInfo(obj, acomponent)
        % Provide detailed information of the given product.
        % Inputs:
        %     'acomponent' is a string.
        % The output 'cinfo' is a struct of component information. 
        %     Each element contains the following information of a component:
        %         Name         - component name
        %         Type         - component type
        %         IsPrincipal  - 1 (principal), 0 (not principal)
        %         IsThirdParty - 1 (3rd party), 0 (not 3rd party)
        %         BaseDir      - Based directory
        %         RetailMTF    - Retail MTF file
        %         SdkMTF       - SDK MTF file
        %         McrMTF       - MCR MTF file
        %         IsDeployable - 1 (yes), 0 (no)
        % The output is an empty struct, if the given component is unknown.
            requiresChar(acomponent);
            
            cinfo = struct([]);
            if ~isempty(acomponent)
                query = sprintf( ...
                        ['SELECT Component.ID, ' ...
                         '       Component_Type.Name, ' ...
                         '       Component.Is_Principal, ' ...
                         '       Component.Is_ThirdParty, ' ...
                         '       Component.Deployable ' ...
                         'FROM Component, Component_Type, Path_Item ' ...
                         'WHERE Component.Name = ''%s'' ' ...
                         '  AND Component.Type = Component_Type.ID;'], acomponent);
                obj.doSql(query);
                result = obj.fetchRows();
                if ~isempty(result)
                    comp_id = result{1}{1};
                    comp_type = result{1}{2};
                    comp_isprincipal = logical(result{1}{3});
                    comp_isthirdparty = logical(result{1}{4});
                    comp_isdeployable = logical(result{1}{5});
                    
                    query = sprintf( ...
                            ['SELECT Path_Item.Location ' ...
                             'FROM Component, Path_Item ' ...
                             'WHERE Component.ID = %d ' ...
                             '  AND Component.Base_Dir = Path_Item.ID;'], comp_id);
                    obj.doSql(query);
                    comp_base = obj.fetchRow();
                    
                    query = sprintf( ...
                            ['SELECT Path_Item.Location ' ...
                             'FROM Component, Path_Item ' ...
                             'WHERE Component.ID = %d ' ...
                             '  AND Component.Retail_MTF = Path_Item.ID;'], comp_id);
                    obj.doSql(query);
                    comp_retail_mtf = obj.fetchRow();
                    
                    query = sprintf( ...
                            ['SELECT Path_Item.Location ' ...
                             'FROM Component, Path_Item ' ...
                             'WHERE Component.ID = %d ' ...
                             '  AND Component.SDK_MTF = Path_Item.ID;'], comp_id);
                    obj.doSql(query);
                    comp_sdk_mtf = obj.fetchRow();
                    
                    query = sprintf( ...
                            ['SELECT Path_Item.Location ' ...
                             'FROM Component, Path_Item ' ...
                             'WHERE Component.ID = %d ' ...
                             '  AND Component.MCR_MTF = Path_Item.ID;'], comp_id);
                    obj.doSql(query);
                    comp_mcr_mtf = obj.fetchRow();
                    
                    cinfo = struct('Name', acomponent, ...
                                   'Type', comp_type, ...
                                   'BaseDir', fullfile(matlabroot, comp_base), ...
                                   'IsPrincipal', comp_isprincipal, ...
                                   'IsThirdParty', comp_isthirdparty, ...
                                   'RetailMTF', fullfile(matlabroot, comp_retail_mtf), ...
                                   'SdkMTF', fullfile(matlabroot, comp_sdk_mtf), ...
                                   'McrMTF', fullfile(matlabroot, comp_mcr_mtf),...
                                   'IsDeployable', comp_isdeployable);
                end
            end
        end
        
        function clist = componentShippedByProduct(obj, aproduct)
        % Provide the transitive closure of components shipped by the given product.
        % The input 'aproduct' is a string of a product's internal name.
        % The output 'clist' is a cell array of strings. Each string is the name of a component. 
        % The output is an empty cell array, if no component is shipped by the given product.
            clist = {};
            
            requiresChar(aproduct);
            
            query = sprintf([ ...
                    'SELECT Component.Name ' ...
                    'FROM Component, Product_Component, Product ' ...
                    'WHERE Product.Internal_Name = ''%s'' ' ...
                    '  AND Product.ID = Product_Component.Product ' ...
                    '  AND Product_Component.Component = Component.ID;'],...
                    aproduct);
            obj.doSql(query);
            result = obj.fetchRows();
            if ~isempty(result)
                clist = cellfun(@(r)r{1},result,'UniformOutput',false);
            end
        end
        
        function clist = componentShippedByMCRProducts(obj)
        % Provide the transitive closure of components shipped by MCR products.
        % The input 'aproduct' is a string of a product's internal name.
        % The output 'clist' is a cell array of strings. Each string is the name of a component. 
        % The output is an empty cell array, if no component is shipped by the given product.

            import matlab.depfun.internal.requirementsConstants
            
            clist = {};
            
            query = sprintf(...
                    ['SELECT External_Product_ID ' ...
                     'FROM Product ' ...
                     'WHERE External_Product_ID >= %d ' ...
                     '  AND External_Product_ID <= %d;'], ...
                     requirementsConstants.mcr_pid_min, ...
                     requirementsConstants.mcr_pid_max);
            obj.doSql(query);
            result = obj.fetchRows();
            if ~isempty(result)
                mcr_pid = cellfun(@(r)r{1},result,'UniformOutput',false);

                num_MCR_products = numel(mcr_pid);
                clist = cell(1,num_MCR_products);
                query_temp = ...
                    ['SELECT Component.Name ' ...
                     'FROM Component, Product, Product_Component ' ...
                     'WHERE Product.External_Product_ID = %d ' ...
                     '  AND Product.ID = Product_Component.Product ' ...
                     '  AND Product_Component.Component = Component.ID;' ];

                for k = 1:num_MCR_products
                    query = sprintf(query_temp, mcr_pid{k});
                    obj.doSql(query);
                    result = obj.fetchRows();
                    if ~isempty(result)
                        clist{k} = cellfun(@(r)r{1},result,'UniformOutput',false);
                    end
                end
            end
        end
        
        function m2c = MatlabModuleToComponentMap(obj)
        % The output 'm2c' is a dictionary object.
        %     Each key is the string of the path of a MATLAB module.
        %     Each value is the owning component of the correspondent key.
            m2c = dictionary(cell(0,0),cell(0,0));

            query = ['SELECT Path_Item.Location, Component.Name ' ...
                     'FROM Path_Item, Module_Type, Module, Component, Component_Module ' ...
                     'WHERE Module_Type.Name = ''MATLAB'' ' ...                     
                     '  AND Module_Type.ID = Module.Type ' ...
                     '  AND Module.Path = Path_Item.ID ' ...
                     '  AND Module.ID = Component_Module.Module ' ...
                     '  AND Component_Module.Component= Component.ID;'];
            obj.doSql(query);
            result = obj.fetchRows();
            if ~isempty(result)
                matlabModule = cellfun(@(r)r{1},result,'UniformOutput',false);
                owningComponent = cellfun(@(r)r{2},result,'UniformOutput',false);

                % Convert recorded canonical relative paths to platform-specific full path
                matlabModule = fullfile(matlabroot, matlabModule);

                % The map of MATLAB modules to their owning components
                m2c = dictionary(matlabModule, owningComponent);
            end
        end

        function s2c = get.sourceToComponentMap(obj)
        % The output 's2c' is a dictionary object.
        %     Each key is the string of the path of a source entry.
        %     Each value is the owning component of the correspondent key.
            if isempty(obj.sourceToComponentMap)
                thisFolder = fileparts(mfilename('fullpath'));
                s2c_fn = fullfile(thisFolder, ['pcm_db_static_caches_' computer('arch') '.mat']);
                s2c_struct = load(s2c_fn, 'sourceToComponentMap');
                obj.sourceToComponentMap = s2c_struct.sourceToComponentMap;
            end

            s2c = obj.sourceToComponentMap;

        end

        function b2c = builtinToComponentMap(obj)
        % The output 'b2c' is a dictionary object.
        %     Each key is the string of a CXX built-in symbol.
        %     Each value is the owning component of the correspondent key.

            builtinSymbol = keys(obj.builtinRegistry);
            tmp = values(obj.builtinRegistry);
            owningComponent = convertCharsToStrings({tmp.component})';
            b2c = dictionary(builtinSymbol, owningComponent);
        end
        
        function clist = componentRequiredForBuiltin(obj, blist)
            
            if isempty(obj.builtinToRequiredComponentMap)
                thisFolder = fileparts(mfilename('fullpath'));
                builtinAndMexDeps = fullfile(thisFolder, ...
                           ['builtin_and_mex_to_component_map_' computer('arch') '.mat']);
                if exist(builtinAndMexDeps, 'file') == 2
                    tmp = load(builtinAndMexDeps, 'builtin_to_component');
                    obj.builtinToRequiredComponentMap = tmp.builtin_to_component;
                else
                    b2c_dict = obj.builtinToComponentMap();
                    % Convert to string -> cell format
                    vals = convertStringsToChars(values(b2c_dict));
                    obj.builtinToRequiredComponentMap = dictionary(keys(b2c_dict), vals);
                end
            end
            
            if ischar(blist)
                blist = { blist };
            end
            
            keep = isKey(obj.builtinToRequiredComponentMap, blist);
            blist = blist(keep);
            clist = obj.builtinToRequiredComponentMap(blist);
            clist = unique([clist{:}])';
        end

        function clist = deployableComponentsWithMatlabModules(obj)
            query = ['SELECT DISTINCT Component.Name' ...
                     '  FROM Component, Component_Type, Component_Module, Module, Module_Type' ...
                     ' WHERE Module_Type.Name = ''MATLAB''' ...
                     '   AND Module_Type.ID = Module.Type' ...
                     '   AND Module.ID = Component_Module.Module' ...
                     '   AND Component_Module.Component = Component.ID' ...
                     '   AND Component.Deployable = 1' ...
                     '   AND Component.Type = Component_Type.ID' ...
                     '   AND Component_Type.Name = ''software'';'];
            obj.doSql(query);
            result = obj.fetchRows();
            clist = cellfun(@(r)r{1},result,'UniformOutput',false);
        end
    
    end
    
    % ----- Public methods for querying module information -----
    methods
        function mpath = moduleOwningFile(obj, afullpath)
        % Find the owning MATLAB module of the given file.
        % The input 'afullpath' is a string, which must be the full path of the file.
        %
        % The output 'mpath' is the full path of the MATLAB module directory.
        % The output is empty, if no module owns the given file.
            requiresChar(afullpath);
        
            mpath = '';
            if matlab.depfun.internal.PathUtility.underMatlabroot(afullpath) && exist(afullpath, 'file')
                apath = allowedPath(afullpath);
                apath = matlab.depfun.internal.PathUtility.stripMatlabroot(apath);
                apath = matlab.depfun.internal.PathNormalizer.processPathsForSql(apath);

                query = sprintf( ...
                    ['SELECT Path_Item.Location ' ...
                     'FROM Path_Item, Module ' ...
                     'WHERE Path_Item.Location = ''%s'' ' ...
                     '  AND Path_Item.ID = Module.Path;'], ...
                     apath);
                obj.doSql(query);
                % More than one products may ship the same file
                result = obj.fetchRow();
                if ~isempty(result)
                    mpath = fullfile(matlabroot, result);
                end
            end
        end
        
        function [mname, libfile] = moduleOwningBuiltin(obj, abuiltin)
        % Find the owning CXX module of the given CXX built-in.
        % The input 'abuiltin' is a string of a built-in symbol.
        % Outputs:   'mname' is the name of the CXX module and 
        %            'libfile' is the full path of the shared library file.
        % The outputs are empty, if no CXX module owns the given built-in.
            requiresChar(abuiltin);
            
            mname = '';
            if isKey(obj.builtinRegistry, abuiltin)
                mname = obj.builtinRegistry(abuiltin).module;
            end
            
            if nargout == 2
                libfile = '';
                if ~isempty(mname)
                    query = sprintf([ ...
                        'SELECT Path_Item.Location ' ...
                        'FROM Path_Item, Module, Module_Type ' ...
                        'WHERE Module.Name = ''%s'' ' ...
                        '  AND Module.Type = Module_Type.ID ' ...
                        '  AND Module_Type.Name = ''CXX'' ' ...
                        '  AND Module.Path = Path_Item.ID;'], ...
                        mname);
                    obj.doSql(query);                
                    result = obj.fetchRow();
                    if ~isempty(result)
                        libfile = fullfile(matlabroot, result);
                    end
                end
            end
        end
        
        function [mpath, mname] = moduleOwningSymbol(obj, asymbol)
        % Determine whether the given symbol is a file or a built-in,
        % then forward the call to moduleOwningFile() or moduleOwningBuiltin().
        % The input 'asymbol' is a string of a symbol.
        % Refer comments in moduleOwningFile() or moduleOwningBuiltin() for outputs. 
        % The outputs are empty, if no module owns the given symbol.

            requiresChar(asymbol);

            w = which(asymbol);
            if ~isempty(strfind(w, ...
                    matlab.depfun.internal.requirementsConstants.BuiltInStr))
                [mname, mpath] = moduleOwningBuiltin(obj, asymbol);
            else
                mname = '';
                mpath = moduleOwningFile(obj, w);
            end 
        end
        
        function dlist = directoryOwnedByComponent(obj, acomponent)
        % Provide a list of directories owned by the given component.
        % The input 'acomponent' is a string of component.
        % The output 'dlist' is a cell array of strings. Each string is full path of a directory. 
        % The output is an empty cell array, if no directory is owned by the given component.
            dlist = obj.moduleOwnedByComponent(acomponent, 'MATLAB');
        end
        
        function mlist = moduleOwnedByComponent(obj, acomponent, type)
        % Provide a list of modules of the given type owned by the given component.
        % Inputs: 'acomponent' is a string of component.
        %         'type' can be 'MATLAB', 'JAVA', or 'CXX'.  
        % The output 'mlist' is a cell array of strings. 
        %         For CXX, mlist is a list of CXX Module names.
        %         For MATLAB and JAVA, mlist is a list of paths.
        % The output is an empty cell array, 
        % if no module is owned by the given component or type is unknown.
            mlist = {};
            
            requiresChar(acomponent);
            
            module_types = { 'MATLAB' 'JAVA' 'CXX' };
            module_sig = { 'Path_Item.Location' 'Path_Item.Location' 'Module.Name' };
            
            typeIdx = strcmpi(type, module_types);
            goal = module_sig(typeIdx);
            if isempty(goal)
                return;
            else
                goal = goal{1};
            end
            
            query = sprintf( ...
                [ 'SELECT %s ' ...
                  'FROM Path_Item, Module, Module_Type, Component_Module, Component ' ...
                  'WHERE Module_Type.Name = ''%s'' ' ...
                  '  AND Module_Type.ID = Module.Type ' ...
                  '  AND Module.Path = Path_Item.ID ' ...
                  '  AND Module.ID = Component_Module.Module ' ...
                  '  AND Component_Module.Component = Component.ID ' ...
                  '  AND Component.Name = ''%s'';'], ...
                  goal, type, acomponent);
            obj.doSql(query);
            result = obj.fetchRows();
            if ~isempty(result)
                mlist = cellfun(@(r)r{1},result,'UniformOutput',false);
                if strcmp(goal, 'Path_Item.Location')
                    mlist = fullfile(matlabroot, mlist);
                end
            end
        end
		
		function mlist = MatlabModulesInSpecificRuntimeProducts(obj, runtimeProduct_IDs)
		% Provides a list of MATLAB Modules in the specified runtime 
		% products.
            mlist = {};
			if numel(runtimeProduct_IDs) < 1
				return;
			end
			pid_str = num2str(runtimeProduct_IDs{1});
			if numel(runtimeProduct_IDs) > 1
				pid_str = [pid_str sprintf(',%d', runtimeProduct_IDs{2:end})];
			end
    
            query = [ 'SELECT ID FROM Path_Item ' ...
                      'WHERE Location = ''N/A'' OR Location = ''N\A'';' ];
            obj.doSql(query);
            na_path_id = obj.fetchRow();
            
            query = [ 'SELECT DISTINCT Path_Item.Location ' ...
                      'FROM Path_Item, Module, Module_Type, Component_Module,' ...
                      '     Component, Product_Component, Product ' ...
                      'WHERE Module_Type.Name = ''MATLAB'' ' ...
                      '  AND Module_Type.ID = Module.Type ' ...
                      '  AND Module.Path = Path_Item.ID ' ...
                      '  AND Module.ID = Component_Module.Module ' ...
                      '  AND Component_Module.Component = Component.ID ' ...
                      '  AND Component.MCR_MTF != ' num2str(na_path_id) ...
                      '  AND Component.ID NOT IN ' ...
                      '      (SELECT Component FROM MCR_Exclude_List) ' ...
                      '  AND Product_Component.Component = Component.ID ' ...
                      '  AND Product_Component.Product = Product.ID ' ...
                      '  AND Product.External_Product_ID IN (' pid_str ');'];
            obj.doSql(query);
            result = obj.fetchRows();
            if ~isempty(result)
                result = cellfun(@(r)r{1},result,'UniformOutput',false)';
                mlist = [fullfile(matlabroot, 'toolbox/compiler/deploy'); fullfile(matlabroot, 'toolbox/compiler/runtime'); fullfile(matlabroot, result)];                
            end
            existIdx = isfolder(convertCharsToStrings(mlist));
            mlist(~existIdx) = [];
        end

        function mlist = MatlabModulesInBaseMatlabRuntime(obj)
        % Provide a list of MATLAB Modules in the base MATLAB Runtime.
        % Note that, this list must not be used as a scoped path, 
        % because the order of those modules is undefined here.
            import matlab.depfun.internal.requirementsConstants
            
            
            % Get the base runtime product list.
            try
                fid=fopen(fullfile(matlabroot,'standalone',...
                    'pcm_db','trunk_runtimes.txt'));
                base_mcr_product_list = textscan(fid,'%s', 'CommentStyle','#');
                base_mcr_product_list = base_mcr_product_list{1};
                fclose(fid);
            catch
                error(message('MATLAB:depfun:req:ErrorReadingTrunkInfoFile', ...
                    fullfile(matlabroot,'standalone','pcm_db','trunk_runtimes.txt')));
            end
            base_mcr_product_list_str = ['"',base_mcr_product_list{1},'"'...
                sprintf(',"%s"', base_mcr_product_list{2:end})];
            
            query = ['SELECT Product.External_Product_ID ' ...
                     'FROM Product ' ...
                     'WHERE Product.Internal_Name in (' ...
                     base_mcr_product_list_str ');'];
            obj.doSql(query);
            result = obj.fetchRows();
            result = cellfun(@(r)r{1},result,'UniformOutput',false);
            mlist = MatlabModulesInSpecificRuntimeProducts(obj, result);
        end
        
        function mlist = MatlabModulesInMatlabRuntime(obj)
        % Provide a list of MATLAB Modules in the monolithic MATLAB Runtime.
        % Note that, this list must not be used as a scoped path, 
        % because the order of those modules is undefined here.
            import matlab.depfun.internal.requirementsConstants
            
            mlist = {};

            % All mcr products depend on mcr_numerics    
            pid_mcr_numerics = num2str(requirementsConstants.mcr_numerics_pid);
            query = ['SELECT Product.External_Product_ID ' ...
                     'FROM Product ' ...
                     'WHERE Product.ID IN ' ...
                     '  (SELECT Product_Dependency.Client ' ...
                     '   FROM Product, Product_Dependency ' ...
                     '   WHERE Product.External_Product_ID = ' pid_mcr_numerics ...
                     '     AND Product_Dependency.Service = Product.ID);'];
            obj.doSql(query);
            result = obj.fetchRows();
            result = cellfun(@(r)r{1},result,'UniformOutput',false);
            result{end+1} = requirementsConstants.mcr_numerics_pid;
            mlist =	MatlabModulesInSpecificRuntimeProducts(obj, result);
        end
        
        function mlist = scopedMatlabModuleListForProduct(obj, aproduct)
        % Provide a list of MATLAB Modules owned by components shipped by 
        % a given product and its upstream product(s).
        %
        % mcr view is used for mcr products.
        % retail view is used for other products.
        %
        % Note that, this list must not be used as a scoped path for a 
        % given product, because the order of those modules is undefined here.
            import matlab.depfun.internal.requirementsConstants
            
            requiresChar(aproduct);
            mlist = {};
            
            query = ['SELECT External_Product_ID '...
                     'FROM Product '...
                     'WHERE Internal_Name = ''' aproduct ''';'];
            obj.doSql(query);
            pid = obj.fetchRow();
            if isempty(pid)
                return; % Unknown product name
            end
            
            if pid >= requirementsConstants.mcr_pid_min ...
                && pid <= requirementsConstants.mcr_pid_max
                package_view = 'MCR';
                % Special undefined MATLAB Module
                % owned by component compiler_toolbox 
                mlist = { fullfile(matlabroot, 'toolbox/compiler/deploy');fullfile(matlabroot, 'toolbox/compiler/runtime')};
            else
                package_view = 'Retail';
            end
            
            pid_str = ['''' num2str(pid) ''''];
            % Get upstream product(s)
            pinfo = requiredProducts(obj, aproduct);            
            if ~isempty(pinfo)
                upstream_pid = {pinfo.extPID};
                pid_str = [pid_str sprintf(',%d', upstream_pid{:})];
            end
            
            query = [ 'SELECT ID FROM Path_Item ' ...
                      'WHERE Location = ''N/A'' OR Location = ''N\A'';' ];
            obj.doSql(query);
            na_path_id = obj.fetchRow();
            
            query = [ 'SELECT Path_Item.Location ' ...
                      'FROM Path_Item, Module, Module_Type, Component_Module,' ...
                      '     Component, Product_Component, Product ' ...
                      'WHERE Module_Type.Name = ''MATLAB'' ' ...
                      '  AND Module_Type.ID = Module.Type ' ...
                      '  AND Module.Path = Path_Item.ID ' ...
                      '  AND Module.ID = Component_Module.Module ' ...
                      '  AND Component_Module.Component = Component.ID ' ...
                      '  AND Component.' package_view '_MTF != ' num2str(na_path_id) ...
                      '  AND Component.ID NOT IN ' ...
                      '      (SELECT Component FROM MCR_Exclude_List) ' ...
                      '  AND Product_Component.Component = Component.ID ' ...
                      '  AND Product_Component.Product = Product.ID ' ...
                      '  AND Product.External_Product_ID IN (' pid_str ');'];
            obj.doSql(query);
            result = obj.fetchRows();
            if ~isempty(result)
                result = cellfun(@(r)r{1},result,'UniformOutput',false)';
                mlist = [mlist; fullfile(matlabroot, result)];
            end
        end
        
        function mlist = scopedMatlabModuleListForDfdbComponent(obj, component)
        % Provide a list of MATLAB Modules owned by a given DFDB component.
            
            mlist = {};

            if ~iscell(component)
                component = {component};
            end
           
            query = sprintf('SELECT ID FROM Component WHERE DFDB=1 AND Name IN (%s);', ...
                            ['''' strjoin(component, ''',''') '''']);
            obj.doSql(query);
            result = obj.fetchRows();
            cid = cell2mat(cellfun(@(r)r{1},result,'UniformOutput',false));

            if ~isempty(cid)
                query = sprintf(...
                        ['SELECT DISTINCT Path_Item.Location' ...
                         '  FROM DFDB_Component_Path, Path_Item' ...
                         ' WHERE DFDB_Component_Path.Component IN (%s)' ...
                         '   AND DFDB_Component_Path.Path = Path_Item.ID;'], ...
                         strjoin(string(cid),','));
                obj.doSql(query);
                result = obj.fetchRows();
                mlist = cellfun(@(r)r{1},result,'UniformOutput',false)';
            end
        end
        
        function [blist, mname, liblist] = builtinOwnedByComponent(obj, acomponent)
        % Provide a list of built-ins owned by the given component.
        % The input 'acomponent' is a string of component.
        % Outputs:  'blist' is a cell array of strings. Each string is a built-in symbol.
        %           'mname' is the name of the CXX module that defines the
        %                   built-in.
        %           'liblist' is a cell array of strings. Each string is the full path of 
        %                     the library which defines the correspondent built-in. 
        % The output is an empty cell array, if no built-in is owned by the given component.
            requiresChar(acomponent);
            
            builtinSymbol = keys(obj.builtinRegistry);
            tmp = values(obj.builtinRegistry);
            owningComponent = {tmp.component};
            owningModule = {tmp.module};

            idx = strcmp(owningComponent, acomponent);                
            blist = builtinSymbol(idx);
            mname = owningModule(idx);
                
            if nargout == 3
                [~,liblist] = cellfun(@obj.moduleOwningBuiltin, blist, ...
                                      'UniformOutput', false);
            end
        end
        
        function [blist, mlist, clist, liblist] = builtinShippedByProduct(obj, aproduct)
        % Provide a list of built-ins owned by the given component.
        % The input 'aproduct' is a string of product.
        % Outputs:  'blist' is a cell array of strings. Each string is a built-in symbol.
        %           'mname' is the name of the CXX module that defines the
        %                   built-in.
        %           'liblist' is a cell array of strings. Each string is the full path of 
        %                     the library which defines the correspondent built-in. 
        % The output is an empty cell array, if no built-in is owned by the given component.
            requiresChar(aproduct);
            
            blist = {};
            mlist = {};
            clist = {};
            liblist = {};
            
            components = obj.componentShippedByProduct(aproduct);
            
            if ~isempty(components)
                builtinSymbol = cellstr(keys(obj.builtinRegistry))';
                tmp = values(obj.builtinRegistry);
                owningComponent = {tmp.component};
                owningModule = {tmp.module};
            
                for k = 1:numel(components)
                    idx = strcmp(owningComponent, components{k});
                    if any(idx)
                        sym = builtinSymbol(idx);
                        mod = owningModule(idx);
                        comp = owningComponent(idx);
                
                        blist = [blist sym]; %#ok
                        mlist = [mlist mod]; %#ok
                        clist = [clist comp]; %#ok
                    end
                end
                
                if nargout == 4
                    [~,liblist] = cellfun(@obj.moduleOwningBuiltin, blist, ...
                                          'UniformOutput', false); 
                end
            end
        end
        
    end
        
    % ----- Public methods for executing native SQLite commands -----
    methods
        function doSql(obj, SqlCmd)
        % Pass the native SQLite command to the instance of 
        % class matlab.depfun.internal.database.SqlDbConnector.
            obj.SqlDBConnObj.doSql(SqlCmd);
        end
        
        function result = fetchRow(obj)
        % Fetch a row of the result returned by the instance of 
        % class matlab.depfun.internal.database.SqlDbConnector.
            result = obj.SqlDBConnObj.fetchRow();
        end
            
        function result = fetchRows(obj)
        % Fetch the complete result returned by the instance of 
        % class matlab.depfun.internal.database.SqlDbConnector.
            result = obj.SqlDBConnObj.fetchRows();
        end
    end
            
    % ----- Getter for builtinRegistry ------
    methods
        function map = get.builtinRegistry(obj)
        % Key - built-in symbol names
        % Value - a struct contains built-in type, toolbox location, owning
        % component name, owning module name.
        % (Other info in raw_data is not used at this point.)
        % If thre are more than one built-ins with the same name, the first
        % one on the MATLAB search path is returned.
        
            % calling function filesep can be expensive, so cache the
            % result
            fsep = matlab.depfun.internal.requirementsConstants.FileSep;
            env = obj.env;
            
            if isempty(obj.builtinRegistry)
                % Built-in registry returned by MATLAB dispatcher.
                % It contains built-ins from products available to the
                % current MATLAB.
                % Currently, there is no C++ API to create containers.Map,
                % so the raw data is stored in a struct array.
                raw_data = matlab.depfun.internal.builtinInfo();
                attrs = [raw_data.attributes];
                names = convertCharsToStrings({raw_data.name});
                
                % We always want to overwrite empty locations, so add them first then
                % overwrite if we find the same name with another location
                emptyLocIdx = (convertCharsToStrings({attrs.toolbox_loc})=='');
                for i = 1:numel(attrs)
                    assembledSymData(i) = assembleSymData(attrs(i));
                end
                obj.builtinRegistry = dictionary(names(emptyLocIdx), assembledSymData(emptyLocIdx));
                
                srchPth = strsplit(path, pathsep);
                srchPthTbl = dictionary(string(srchPth), 1:numel(srchPth));
                
                for k = 1:numel(emptyLocIdx)
                    if ~emptyLocIdx(k)
                        symbol = names(k);
                        symbolAttributes = attrs(k);
                    
                        if isKey(obj.builtinRegistry, symbol)
                            curSymData = obj.builtinRegistry(symbol);
                            curPathEntry = curSymData.path_entry;
                            if isempty(curPathEntry)
                                obj.builtinRegistry(symbol) = assembledSymData(k);
                            elseif strcmp(symbolAttributes.class_type, ':all:') ... 
                                   && ~strcmp(curSymData.class_type, ':all:')
                                % G1878898: Built-in function proceeds 
                                % built-in class extension method. 
                                obj.builtinRegistry(symbol) = assembledSymData(k);
                            else
                                symData = assembleSymData(symbolAttributes);
                                path_entry = symData.path_entry;
                                idxCur = [];
                                if ~isempty(curPathEntry) && isKey(srchPthTbl, curPathEntry)
                                    idxCur = srchPthTbl(curPathEntry);
                                end
                                
                                idxNew = [];
                                if ~isempty(path_entry) && isKey(srchPthTbl, path_entry)
                                    idxNew = srchPthTbl(path_entry);
                                end
                    
                                % If current location is not on the path, or current
                                % location occurs AFTER new location on the path,
                                % replace the current location with the new one.
                                if isempty(idxCur) || (~isempty(idxNew) && ...
                                                       idxNew < idxCur)
                                    obj.builtinRegistry(symbol) = symData;
                                end
                            end
                        else
                            obj.builtinRegistry(symbol) = assembledSymData(k);
                        end
                    end
                end
            end

            map = obj.builtinRegistry;
            
            function symData = assembleSymData(symbolAttributes)
                fsep = matlab.depfun.internal.requirementsConstants.FileSep;
                switch symbolAttributes.builtin_type
                    case 0
                        type = matlab.depfun.internal.MatlabType.BuiltinFunction;
                    case 1
                        type = matlab.depfun.internal.MatlabType.BuiltinPackage;
                    case 2
                        type = matlab.depfun.internal.MatlabType.BuiltinClass;
                end

                if isempty(symbolAttributes.toolbox_loc)
                    path_entry = '';
                    loc = '';
                elseif ~isempty(symbolAttributes.class_type) && ~strcmp(symbolAttributes.class_type, ':all:')
                    path_entry = [env.FullToolboxRoot fsep symbolAttributes.toolbox_loc];
                    loc = [path_entry fsep '@' symbolAttributes.class_type];
                else
                    path_entry = [env.FullToolboxRoot fsep symbolAttributes.toolbox_loc];
                    loc=path_entry;
                end

                symData = struct('module',symbolAttributes.module,...
                            'component',symbolAttributes.component,...
                            'path_entry',path_entry,...
                            'class_type',symbolAttributes.class_type, ...
                            'type',type, 'loc',loc);
            end
        end
    end

    %------ Private helper functions -------------------------------
    methods (Access = private, Hidden)

        function product_list = productList(obj, rawData)
            product_list = struct([]);
            if ~isempty(rawData)
                internal_name = cellfun(@(r)r{1},rawData,'UniformOutput',false);
                external_name = cellfun(@(r)r{2},rawData,'UniformOutput',false);
                external_pid = cellfun(@(r)double(r{3}),rawData,'UniformOutput',false);
                version = cellfun(@(r)r{4},rawData,'UniformOutput',false);
                license_name = cellfun(@(r)r{5},rawData,'UniformOutput',false);
                base_code = cellfun(@(r)r{6},rawData,'UniformOutput',false);
                is_controlling_product = cellfun(@(r)logical(r{7}),rawData,'UniformOutput',false);
                released_platform = cellfun(@(p)obj.productReleasedPlatforms(p),internal_name,'UniformOutput',false);
        
                product_list = struct('intPName', internal_name, ...
                                      'extPName', external_name, ...
                                      'extPID', external_pid, ...
                                      'version', version, ...
                                      'LName', license_name, ...
                                      'baseCode', base_code, ...
                                      'controllingProduct', is_controlling_product, ...
                                      'rlsPlatform', released_platform);
            end
        end
    end
end

%--------------------------------------------------------------------------
% Local helper functions
%--------------------------------------------------------------------------
function filter = perTargetProductFilter(target)
    import matlab.depfun.internal.requirementsConstants
    import matlab.depfun.internal.Target
    
    if ischar(target)
        tgt = matlab.depfun.internal.Target.parse(target);
        if (tgt == matlab.depfun.internal.Target.Unknown)
            error(message('MATLAB:depfun:req:BadTarget', target));
        end
    elseif isa(target, 'matlab.depfun.internal.Target')
        tgt = target;
    else
        error(message('MATLAB:depfun:req:InvalidInputType',...
              1,class(target),'char or matlab.depfun.internal.Target'));
    end

    switch tgt
        case Target.MCR
            filter = sprintf( ...
                ['AND (Product.External_Product_ID >= %d ' ...
                 'AND Product.External_Product_ID <= %d)'], ...
                 requirementsConstants.mcr_pid_min, ...
                 requirementsConstants.mcr_pid_max );
        case {Target.MATLAB Target.PCTWorker Target.Deploytool}
            filter = sprintf( ...
                ['AND (Product.Is_Controlling_Product = 0 ' ... % g2872048 - Ignore other base products
                 ' OR  Product.External_Product_ID = 1) ' ... % for MATLAB target 
                 'AND Product.External_Product_ID != 94 ' ... % Temp workaround: 94 is parallel server 
                 'AND ((Product.External_Product_ID < %d ' ...
                 ' OR Product.External_Product_ID > %d) ' ...
                 'AND Product.External_Product_ID != %d)'], ...
                 requirementsConstants.mcr_pid_min, ...
                 requirementsConstants.mcr_pid_max, ...
                 requirementsConstants.full_mcr_pid );
        otherwise % NONE target, etc.
            filter = '';
    end
end

%--------------------------------------------------------------------------
function allowed_path = allowedPath(apath)
% This function turns a full path into a path prefix suitable for 
% the MATLAB path. Since @, +, and private directories cannot appear 
% directly on the MATLAB path, this function removes them from the 
% returned path prefix.

    At_Plus_Private_Idx = at_plus_private_idx(apath);
    if ~isempty(At_Plus_Private_Idx)
        allowed_path = apath(1:At_Plus_Private_Idx-1);
    else
        if exist(apath,'dir')
            allowed_path = apath;
        else
            [allowed_path,~,~] = fileparts(apath);
        end
    end
end

%--------------------------------------------------------------------------
function requiresChar(avariable)
    if ~ischar(avariable)
        error(message('MATLAB:depfun:req:InvalidInputType',...
                      1,class(avariable),'char'));
    end
end

% GET_RETAIL_PID returns retail product ID for the runtime
% addins passed as input.
%   If the runtime add-in is under 35100, then it either refers
%   to the base MATLAB runtimes or language bindings. Set the retail_id
%   for such cases to 1.
%   If the runtime add-in is between 35100 and 35300, substract
%   35100 to get the retail ID.
%   If the runtime add-in is greater than 35300, substract
%   35300 to get the retail ID.
% PID is the list of runtime addins
% RETAIL_ID is the

function retail_id = get_retail_pid(pid)
    retail_id = zeros(size(pid));
    for pid_i=1:numel(pid)
        if pid(pid_i) < matlab.depfun.internal.requirementsConstants.base_mcr_pid_max
            retail_id(pid_i) = 1;
        elseif pid(pid_i) > matlab.depfun.internal.requirementsConstants.base_toolbox_addin_pid_max
            retail_id(pid_i) = pid(pid_i) - matlab.depfun.internal.requirementsConstants.base_toolbox_addin_pid_max;
        else
            retail_id(pid_i) = pid(pid_i) - matlab.depfun.internal.requirementsConstants.base_mcr_pid_max;
        end
    end
end

% LocalWords:  PCM pcm Sql afullpath pinfo PName LName abuiltin Builin asymbol acomponent
