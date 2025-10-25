classdef Viewmarker < handle
    properties (Access = private)
        number = 0;
        dialogTag = 'slsfviewmark_manager_ui';
        snapShot;
        snapShot_background;
        
        xmlDir = [];
        xmlFileName = [];
        xmlRoot = [];
        xmlDocNode = [];
        xmlFileExists = false;
        
        VMManagerDir;
        IconDir;
        cssfileloc;
        cssfileloc_new;
        jsfileloc;
        ddjsfileloc;
        jsfileloc_new;
        copyButton;
        deleteButton;
        reloadButton;
        annotationButton;
        spinner;
        closelink;
        takeviewmarkicon;
        viewmarkmanagericon;
        
        debugmode = false;
        
        currentEditorHandle = [];
        lastClosedTime;
        
        saveToModel = false;
        
        svgToDeleteInModel = [];
    end
    
    properties (Access = public)
        dlg;
        backgroundfile;
    end
    
    properties (Constant, Hidden)
        encodeKey = '11010011';
        encodedMarker = '?$%@!#~';
    end
    
    methods
        function delete(obj)
            % disp('DAStudio.Viewmarker is being destructed ...');
            obj.xmlDocNode = [];
        end
        
        function obj = Viewmarker()
            obj.resetXML();
        end
    end
    
    methods
        function diagram = getModelDiagram(~)
            editor = DAStudio.Viewmarker.getEditor();
            diagram = editor.getDiagram;
        end
        
        function resetXML(obj)
            % first get the doc root node the xml file
            vmXMLDir = fullfile(prefdir, 'sl_viewmark');
            if ~isdir(vmXMLDir)
                mkdir(vmXMLDir);
            end
            obj.xmlFileName = fullfile(vmXMLDir, 'Simulink_ViewMark.xml');
            obj.xmlDir = vmXMLDir;
            
            if exist(obj.xmlFileName, 'file')
                try
                    fileParser = matlab.io.xml.dom.Parser;
                    obj.xmlRoot = fileParser.parseFile(obj.xmlFileName);
                    obj.xmlDocNode = obj.xmlRoot.getDocumentElement;
                catch
                    error('Failed to read XML file %s.', obj.xmlFileName);
                end
            else
                docNode = matlab.io.xml.dom.Document('sl_viewmark'); %com.mathworks.xml.XMLUtils.createDocument('sl_viewmark');
                obj.xmlRoot = docNode;
                obj.xmlDocNode = docNode.getDocumentElement;
                mvElement = docNode.createElement('viewmark_sys');
                mvWatermark = docNode.createElement('viewmark_id_watermark');
                mvWatermark.appendChild(docNode.createTextNode('0'));
                mvElement.appendChild(mvWatermark);
                obj.xmlDocNode.appendChild(mvElement);
                obj.writeToXML();
            end
            
            % second, prepare GLUE2 snapshot for Simulink and SF
            obj.snapShot = GLUE2.Portal;
            obj.snapShot.suppressBadges = true;
            opts = obj.snapShot.exportOptions;
            opts.format = 'SVG';
            opts.backgroundColorMode='MatchCanvas';
            opts.sizeMode = 'UseSpecifiedSize';
            opts.size = [320 200];
            
            snapshot_background = GLUE2.Portal;
            snapshot_background.suppressBadges = true;
            opts = snapshot_background.exportOptions;
            opts.format = 'PNG';
            opts.backgroundColorMode='Transparent';
            
            snapshot_background.exportOptions.sizeMode = 'UseSpecifiedSize';
            snapshot_background.exportOptions.centerWithAspectRatioForSpecifiedSize = false;
            obj.snapShot_background = snapshot_background;
            
            obj.VMManagerDir     = fullfile(matlabroot, 'toolbox', 'shared','dastudio','+DAStudio','@ViewmarkManager');
            obj.IconDir          = fullfile(matlabroot, 'toolbox', 'shared','dastudio','resources','glue', 'Palette', '16px', 'general');
            
            % .css and .js files
            obj.cssfileloc       = fullfile(obj.VMManagerDir, 'viewmarker.css');
            obj.cssfileloc_new   = fullfile(obj.VMManagerDir, 'viewmarker_new.css');
            obj.jsfileloc        = fullfile(obj.VMManagerDir, 'viewmarker.js');
            obj.ddjsfileloc      = fullfile(obj.VMManagerDir, 'drag_drop.js');
            obj.jsfileloc_new        = fullfile(obj.VMManagerDir, 'viewmarker_new.js');
            
            obj.copyButton       = fullfile(obj.VMManagerDir, 'copy.png');

			% three buttons at the upper right corner of each viewmark
            obj.deleteButton     = fullfile(obj.VMManagerDir, 'delete.png');
            obj.reloadButton     = fullfile(obj.VMManagerDir, 'reload.png');
            obj.annotationButton = fullfile(obj.VMManagerDir, 'document.png');
            
            % spinner image
            obj.spinner          = fullfile(obj.VMManagerDir, 'spinner.gif');
            obj.closelink        = fullfile(obj.VMManagerDir, 'closelink.png');
            
            obj.takeviewmarkicon = fullfile(obj.IconDir, 'camera_16_2.png');
            obj.viewmarkmanagericon = fullfile(obj.IconDir, 'grid_layout_16.png');
            
        end
        
        function removeXML(~)
            vmXMLDir = fullfile(prefdir, 'sl_viewmark');
            if isdir(vmXMLDir)
                rmdir(vmXMLDir, 's');
            end
        end
        
        function background(obj, size)
            snapshot = obj.snapShot_background;
            editor = DAStudio.Viewmarker.getEditor();
            
            diagram = obj.getModelDiagram();
            if isa(diagram, 'StateflowDI.Subviewer')
                snapshot.setTarget('Stateflow', diagram);
            else
                snapshot.setTarget('Simulink', diagram);
            end
            canvas = editor.getCanvas;
            sceneRectInView = canvas.SceneRectInView;
            snapshot.targetSceneRect = [sceneRectInView(1)+2.5 sceneRectInView(2)+2, sceneRectInView(3) sceneRectInView(4)];
            obj.backgroundfile = ['background' num2str(round(rand(1)*1000)) '.png'];
            snapshot.exportOptions.fileName = fullfile(prefdir, 'sl_viewmark', obj.backgroundfile);
            snapshot.targetOutputRect = [0 0 size(1) size(2)];
            snapshot.exportOptions.size = size;
            snapshot.exportOptions.quality = 30;
            
            if ~exist(fullfile(prefdir, 'sl_viewmark'), 'dir')
                obj.resetXML();
            end
            
            snapshot.exportForViewMarks(canvas);
        end
        
        function [svgFileName, sceneRectInView] = takeSnapShot(obj, fullname, modelname)
            snapshot = obj.snapShot;
            
            editor = DAStudio.Viewmarker.getEditor();
            canvas = editor.getCanvas;
            sceneRectInView = canvas.SceneRectInView;
            
            svgFileName = [fullname '@' datestr(now, 'mmm-dd-yyyy-HH-MM-SS') num2str(round(rand(1)*1000000)) '.svg'];
            svgFileName = regexprep(svgFileName, '\s', '_'); % in case of whitespace in the name (g1266350)
            svgFileName = DAStudio.Viewmarker.getEligibleFileName(svgFileName); % truncate the file name if it is too long (g1359984)
            snapshot.exportOptions.fileName = [obj.xmlDir filesep svgFileName];
            snapshot.targetSceneRect = sceneRectInView;
            
            if ~exist(fullfile(prefdir, 'sl_viewmark'), 'dir')
                obj.resetXML();
            end
            
            diagram = editor.getDiagram();
            model = diagram.model;
            if (model.isvalid() && isa( model, 'StateflowDI.Model' ) && model.subviewer.isvalid()) % Truth Table special SVG
                subviewerId = double( model.subviewer.backendId );
                if subviewerId~=0
                    if sf( 'get', subviewerId, 'chart.isa' )
                        chartId = subviewerId;
                    else
                        chartId = sf( 'get', subviewerId, '.chart' );
                    end
                    
                    isTTFcn = sfprivate('is_truth_table_fcn', subviewerId);
                    isTTChart = sfprivate('is_truth_table_chart', chartId);

                    if isTTFcn 
                        fig = sfprivate('state_print_fig', subviewerId, 1);
                    elseif isTTChart
                        fig = sfprivate('state_print_fig', chartId, 1);
                    end

                    if isTTFcn || isTTChart
                        print(fig, '-dsvg', '-painters', [obj.xmlDir filesep svgFileName]);
                    else
                        snapshot.exportForViewMarks(canvas);
                    end
                end
            else                                                                                    % all other MG rendered graphs
                snapshot.exportForViewMarks(canvas);
            end            
            
            if obj.getSaveToModel
                slxpath = get_param(modelname,'UnpackedLocation');
                svgModelDir = fullfile(slxpath, 'simulink', 'viewmarks');
                filename = fullfile(slxpath, 'simulink', 'viewmarks', 'Simulink_ViewMark.xml');
                
                DAStudio.Viewmarker.ensureSLXExtracted(modelname, svgModelDir, filename);
                
                copyfile(snapshot.exportOptions.fileName, svgModelDir);
                set_param(modelname, 'dirty', 'on');
            end
        end
        
        function node = getXMLDocNode(obj)
            node = obj.xmlDocNode;
        end
        
        function snap(obj)
            editor = DAStudio.Viewmarker.getEditor();
            diagram = obj.getModelDiagram();
            snapshot = obj.snapShot;
            
            if isa(diagram, 'StateflowDI.Subviewer')
                isSimulink = false;
                snapshot.setTarget('Stateflow', diagram);
            else
                isSimulink = true;
                snapshot.setTarget('Simulink', diagram);
            end

            blockPath = DAStudio.Viewmarker.getBlockPath(editor);
                        
            if isempty(blockPath) || isa(blockPath, 'char')
                isModelReference = false;            
            elseif blockPath.getLength==1
                if strcmpi(get_param(blockPath.getBlock(1), 'blockType'),'ModelReference') 
                    isModelReference = true;
                else
                    isModelReference = false;
                end                    
            else
                isModelReference = true;
            end

            if ~isModelReference
                mdl_name = DAStudio.Viewmarker.getModelName(editor);
                [fullname, subsystemname, modelname] = DAStudio.Viewmarker.getFullModelName(mdl_name);
                
                if isSimulink
                    id = Simulink.ID.getSID(gcs);
                    filename = get_param(Simulink.ID.getModel(id), 'filename');
                else
                    backendId = diagram.backendId;
                    mdl = get_param(bdroot, 'Object');
                    chart = mdl.find('Id', double(backendId));
                    if isempty(chart)
                        rt = sfroot;
                        chart = rt.find('Id', double(backendId));     % linked subchart
                        SID = Simulink.ID.getSID(chart);
                        id = SID;
                        handle = Simulink.ID.getHandle(id);
                        if isa(handle, 'double')
                            chart = get_param(handle, 'Object');
                        else
                            chart = handle;
                        end
                        subsystemname = chart.Name;

                        app = SLM3I.SLDomain.getLastActiveStudioApp;
                        bdhandle = app.blockDiagramHandle;
                        bd = get_param(bdhandle, 'Object');
                        modelname = bd.getFullName;
                        filename = bd.filename;
                    else
                        SID = Simulink.ID.getSID(chart);
                        id = SID;
                        filename = mdl.filename;
                    end
                end
            else
                if isSimulink
                    blockPathC = blockPath.convertToCell();
                    id='';
                    for i=1:length(blockPathC)
                        if ~isempty(id)
                            id = [id, ';'];
                        end
                        
                        id = [id, blockPathC{i}];                            
                    end
                    filename = get_param(Simulink.ID.getModel(blockPath.getBlock(1)), 'filename');
                    mainBlock = blockPath.getBlock(1);
                    model = strsplit(mainBlock, '/');
                    model = model{1};                    
                    [fullname, subsystemname, modelname] = DAStudio.Viewmarker.getFullModelName(model);
                end
            end
            
            if isempty(filename)
                warndlgHandle = warndlg(DAStudio.message('Simulink:viewmarker:warningUnsavedMdl'));
				set(warndlgHandle,'Tag','warningUnsavedMdl'); % set warning dialog tag for testability
                return;
            end
			
            [svgFileName, sceneRectInView] = obj.takeSnapShot(fullname, modelname);
            
            sceneRectInViewStr = mat2str(sceneRectInView);
            
            meta.hasWebContent = SLM3I.SLCommonDomain.isWebContentLoadedForEditor(editor);
            meta.showingWebContent = SLM3I.SLCommonDomain.isWebContentShowingForEditor(editor);
            
            if obj.getSaveToModel
                [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
                
                if ~exist(xmlFileNameToModel, 'file')
                    docNode = matlab.io.xml.dom.Document('sl_viewmark');
                    xmlDocNode_model = docNode.getDocumentElement;
                    mvElement = docNode.createElement('viewmark_sys');
                    mvWatermark = docNode.createElement('viewmark_id_watermark');
                    mvWatermark.appendChild(docNode.createTextNode('0'));
                    mvElement.appendChild(mvWatermark);
                    xmlDocNode_model.appendChild(mvElement);
                    obj.writeToXMLModel(xmlFileNameToModel, xmlDocNode_model);
                end
                
                [~, ~, xmlDocNode_model_return] = obj.addNodeToXMLModel(subsystemname, modelname, id, filename, isSimulink, svgFileName, sceneRectInViewStr, meta);
                obj.writeToXMLModel(xmlFileNameToModel, xmlDocNode_model_return);
            end
            
            [~, newId] = obj.addNodeToXML(subsystemname, modelname, id, filename, isSimulink, svgFileName, sceneRectInViewStr, meta);
            obj.writeToXML();
            
            information.model = modelname;
            information.mode = 'creation';
            information.message = ['Viewmark created for ' fullname];
            information.isSimulink = isSimulink;
            information.id = newId;
            information.annotation = '';
            information.name = subsystemname;
            information.vm_path = [obj.xmlDir filesep svgFileName];
            information.showingWebContent = meta.showingWebContent;
            obj.dlg = slprivate('slOpenViewMarkDialog', information);
        end
        
        function hasError = open(obj, id, ignoreSavedSceneRect, view)
            if nargin<3
                ignoreSavedSceneRect = false;
            end
            
            hasError = false;
            
            if strcmp(view, 'global')
                node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            else
                [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
                
                if ~exist(xmlFileNameToModel, 'file')
                    return;
                end
                fileParser = matlab.io.xml.dom.Parser;
                xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
                parentNode = xmlRootModel.getDocumentElement;
                node = parentNode.getElementsByTagName('viewmark_node');
            end
            
            hasMatchingID = false;
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                hasMatchingID = true;
                vm_id = node_element.getElementsByTagName('viewmark_id');
                id_element = vm_id.item(0);
                isSimulink = str2double(char(id_element.getAttribute('isSimulink')));
                
                id_value = id_element.getFirstChild.getData;
                
                vm_model = node_element.getElementsByTagName('viewmark_model');
                model_element = vm_model.item(0);
                
                % get the model file name and decode it
                fullfilename = char(model_element.getAttribute('model_filename'));
                fullfilename = DAStudio.Viewmarker.decodeStr(fullfilename);
                [filepath, model_name] = fileparts(fullfilename);
                
                rt = slroot;
                modelloaded = ~isempty(rt.find('-isa', 'Simulink.BlockDiagram', 'name', model_name));                    
                
                if ~modelloaded
                    oldpath = pwd;
                    if exist(filepath, 'dir') <= 0
                        dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                        if ~isempty(dlgHandle)
                            dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                            hasError = true;
                        end
                        return;
                    else
                        cd(filepath);
                    end
                    if isfile(fullfilename)
                        open_system(model_name);
                    else
                        dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                        dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                        hasError = true;
                        return;
                    end
                end
                
                sceneRectInView = node_element.getElementsByTagName('viewmark_scenerectinview');
                sceneRectInView_element = sceneRectInView.item(0);
                sceneRectInView_value = sceneRectInView_element.getFirstChild.getData;
                
                id_value_str = char(id_value);
                blockPathC = strsplit(id_value_str, ';');
                
                if length(blockPathC)>1 
                    isModelReference = true;
                elseif ~isempty(strfind(blockPathC{1}, ':'))                    
                    isModelReference = false;
                else
                    handle = get_param(blockPathC{1}, 'handle');
                    type = get_param(handle, 'type');
                    if ~strcmpi(type, 'block')
                        isModelReference = false;
                    elseif strcmpi(get_param(blockPathC{1}, 'blockType'), 'ModelReference')
                        isModelReference = true;
                    else
                        isModelReference = false;
                    end
                end
                
                if ~isModelReference
                    if isSimulink
                        try
                            svg_value_handle = Simulink.ID.getHandle(id_value_str);

                            isMask = false;
                            try
                                isMask = strcmpi(get_param(svg_value_handle, 'Mask'), 'on');
                            catch
                            end

                            if isMask
                                open_system(svg_value_handle, 'force');
                            else
                                open_system(svg_value_handle);
                            end
                        catch  e1
                            if strcmp(e1.identifier, 'Simulink:utility:modelNotLoaded')
                                [model, ~] = strtok(id_value_str, ':');
                                try
                                    load_system([filepath, filesep, model]);
                                    svg_value_handle = Simulink.ID.getHandle(id_value_str);
                                catch

                                    % delete the model if it is loaded
                                    currentSystem = gcs;
                                    if strcmp(currentSystem,model)
                                        close_system(model,0);
                                    end

                                    dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                                    if ~isempty(dlgHandle)
                                        dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                                        hasError = true;
                                    end
                                    if exist('oldpath', 'dir')
                                        cd(oldpath);
                                    end
                                    return;
                                end

                                open_system([filepath, filesep, model]);
                                open_system(svg_value_handle);
                            else
                                pos = strfind(id_value_str, ':');

                                if isempty(pos)
                                    mdl = id_value_str;
                                else
                                    mdl = id_value_str(1:pos(1)-1);
                                end

                                try
                                    svg_value_handle = Simulink.ID.getHandle(id_value_str);
                                catch e
                                    if (strcmp(e.identifier, 'Simulink:utility:objectDestroyed')|| strcmp(e.identifier, 'Simulink:utility:invalidSID'))
                                        dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                                        if ~isempty(dlgHandle)
                                            dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                                            hasError = true;
                                        end
                                    end
                                    if exist('oldpath', 'dir')
                                        cd(oldpath);
                                    end
                                    return;
                                end

                                open_system([filepath, filesep, mdl]);
                                open_system(svg_value_handle);
                            end
                        end
                    else
                        try
                            handle = Simulink.ID.getHandle(id_value_str);
                            if isa(handle, 'double')
                                chart = get_param(handle, 'Object');
                            else
                                chart = handle;
                            end

                            isMask = false;
                            try
                                isMask = strcmpi(chart.Mask, 'on');
                            catch
                            end

                            if isMask
                                open_system(handle, 'force');
                            else
                                chart.view;
                            end
                        catch  e1
                            if strcmp(e1.identifier, 'Simulink:utility:modelNotLoaded')
                                [model, ~] = strtok(id_value_str, ':');
                                try
                                    load_system([filepath, filesep, model]);
                                    handle = Simulink.ID.getHandle(id_value_str);
                                    if isa(handle, 'double')
                                        chart = get_param(handle, 'Object');
                                    else
                                        chart = handle;
                                    end
                                    chart.view;
                                catch e2
                                    if strcmp(e2.identifier, 'Simulink:Commands:OpenSystemUnknownSystem')
                                        dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                                        if ~isempty(dlgHandle)
                                            dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                                        end
                                    end
                                end
                            else
                                try
                                    handle = Simulink.ID.getHandle(id_value_str);
                                    if isa(handle, 'double')
                                        chart = get_param(handle, 'Object');
                                    else
                                        chart = handle;
                                    end
                                    chart.view;
                                catch e3
                                    if strcmp(e3.identifier, 'Simulink:utility:objectDestroyed')
                                        dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                                        if ~isempty(dlgHandle)
                                            dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                                            hasError = true;
                                        end
                                        if ~modelloaded
                                            cd(oldpath);
                                        end
                                    elseif strcmp(e3.identifier, 'Simulink:utility:invalidSID')
                                        dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                                        if ~isempty(dlgHandle)
                                            dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                                            hasError = true;
                                        end                                    
                                    end
                                    return;
                                end
                            end
                        end
                    end
                else  % referenced model block
                    blockPath = Simulink.BlockPath(blockPathC);
                    blockPath.open();
                end
                
                if ~modelloaded
                    cd(oldpath);
                end
                
                if ~ignoreSavedSceneRect
                    editor = DAStudio.Viewmarker.getEditor();
                    editor.showSceneRect(eval(sceneRectInView_value));
                end
                
                % Handle meta info.
                %
                % web_content meta node
                %
                % If absent then it's assumed there's no web content to worry about.
                % If present and the model has web content then it will be
                % shown or not based on the value of the showingWebContent attribute.
                % This assumes the model loaded the web content for the editor on open.
                % If it did not then web content won't be shown in any case.
                web_content = node_element.getElementsByTagName('web_content');
                if web_content.getLength > 0
                    web_content_element = web_content.item(0);
                    hasWebContent = str2double(char(web_content_element.getAttribute('hasWebContent')));
                    showingWebContent = str2double(char(web_content_element.getAttribute('showingWebContent')));

                    if hasWebContent
                        pause(0.1); % paused because showSceneRect code above did so before getting editor; unsure of purpose
                        editor = DAStudio.Viewmarker.getEditor();
                        if showingWebContent
                            SLM3I.SLCommonDomain.showWebContentForEditor(editor);
                        else
                            SLM3I.SLCommonDomain.hideWebContentForEditor(editor);
                        end
                    end
                end
            end

            if ~hasMatchingID
                dlgHandle = findDDGByTag('slsfviewmark_manager_ui');
                if ~isempty(dlgHandle)
                    dlgHandle.evalBrowserJS('viewmarker_manager', ['cancelSpinner(''' id ''')']);
                end
            end
        end
        
        function list(obj)
            node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            
            disp('_________________________________________________________________');
            disp('The collection of all viewmarks');
            disp('-----------------------------------------------------------------');
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                name = node_element.getElementsByTagName('viewmark_name');
                name_element = name.item(0);
                if isempty(name_element) || isempty(name_element.getFirstChild)
                    name_value = '';
                else
                    name_value = name_element.getFirstChild.getData;
                end                
                
                viewmark = sprintf('name: %s, id: %s', char(name_value), char(node_element.getAttribute('id')));
                disp(viewmark);
            end
            disp('_________________________________________________________________');
            info = sprintf('Total number of viewmarks is: %d', node.getLength);
            disp(info);
            
        end
        
        function len = getLength(obj)
            node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            len = node.getLength;
        end
        
        function info = getInfo(obj)
            info = [];
            node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            rt = slroot;
            loadedModels = rt.find('-isa', 'Simulink.BlockDiagram');
            
            loadedModelNames = [];
            for i=1:length(loadedModels)
                loadedModelNames{i} = loadedModels(i).getFullName();  %#ok
            end
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                svg = node_element.getElementsByTagName('viewmark_svg');
                svg_element = svg.item(0);
                
                id = node_element.getAttribute('id');
                available = node_element.getAttribute('available');
                if isempty(char(available))
                    available = '1';
                    node_element.setAttribute('available', available);
                    obj.writeToXML();
                end
                
                if isempty(svg_element)
                    % disp('Thumbnail image is not available for this viewmark');
                    return;
                end
                svg_value = svg_element.getFirstChild.getData;
                
                info{end+1}.vm_path = [obj.xmlDir filesep char(svg_value)]; %#ok
                info{end}.id = char(id);
                info{end}.available = logical(str2double(char(available)));
                
                vid = node_element.getElementsByTagName('viewmark_id');
                vid_element = vid.item(0);
                isSimulink = vid_element.getAttribute('isSimulink');
                
                info{end}.isSimulink = logical(str2double(char(isSimulink)));
                
                name = node_element.getElementsByTagName('viewmark_name');
                name_element = name.item(0);
                if isempty(name_element) || isempty(name_element.getFirstChild)
                    name_value = '';
                else
                    name_value = name_element.getFirstChild.getData;
                end
                info{end}.name = char(name_value);
                
                model = node_element.getElementsByTagName('viewmark_model');
                model_element = model.item(0);
                model_value = model_element.getFirstChild.getData;
                model_name = char(model_value);
                info{end}.model = model_name;
                if isempty(loadedModelNames)
                    info{end}.modelLoaded = 1;
                else
                    info{end}.modelLoaded = sum(ismember(loadedModelNames, model_name));
                end
                
                model_idx = model_element.getAttributeNode('model_idx');
                model_idx_value = model_idx.getFirstChild.getData;
                info{end}.model_idx = char(model_idx_value);
                
                annotation = node_element.getElementsByTagName('viewmark_annotation');
                annotation_element = annotation.item(0);
                if isempty(annotation_element) || isempty(annotation_element.getFirstChild)
                    annotation_value = '';
                else
                    annotation_value = annotation_element.getFirstChild.getData;
                end
                info{end}.annotation = char(annotation_value);
                
                web_content = node_element.getElementsByTagName('web_content');
                if web_content.getLength > 0
                    web_content_element = web_content.item(0);
                    showing_web_content = str2double(char(web_content_element.getAttribute('showingWebContent')));
                else
                    showing_web_content = 0;
                end
                info{end}.showingWebContent = showing_web_content;
            end
        end
        
        function [info, modelNameChanged] = getInfoModel(obj)
            info = [];
            modelNameChanged = false;
            [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            xmlDocNodeModel = xmlRootModel.getDocumentElement;
            node = xmlDocNodeModel.getElementsByTagName('viewmark_node');
            
            rt = slroot;
            loadedModels = rt.find('-isa', 'Simulink.BlockDiagram');
            
            loadedModelNames = [];
            for i=1:length(loadedModels)
                loadedModelNames{i} = loadedModels(i).getFullName();  %#ok
            end
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                svg = node_element.getElementsByTagName('viewmark_svg');
                svg_element = svg.item(0);
                
                id = node_element.getAttribute('id');
                available = node_element.getAttribute('available');
                if isempty(char(available))
                    available = '1';
                    node_element.setAttribute('available', available);
                    obj.writeToXML();
                end
                
                if isempty(svg_element)
                    % disp('Thumbnail image is not available for this viewmark');
                    return;
                end
                svg_value = svg_element.getFirstChild.getData;
                
                info{end+1}.vm_path = [svgModelDir filesep char(svg_value)]; %#ok
                info{end}.id = char(id);
                info{end}.available = logical(str2double(char(available)));
                
                vid = node_element.getElementsByTagName('viewmark_id');
                vid_element = vid.item(0);
                isSimulink = vid_element.getAttribute('isSimulink');
                
                info{end}.isSimulink = logical(str2double(char(isSimulink)));
                
                name = node_element.getElementsByTagName('viewmark_name');
                name_element = name.item(0);
                if isempty(name_element) || isempty(name_element.getFirstChild)
                    name_value = '';
                else
                    name_value = name_element.getFirstChild.getData;
                end
                info{end}.name = char(name_value);
                
                model = node_element.getElementsByTagName('viewmark_model');
                model_element = model.item(0);
                model_value = model_element.getFirstChild.getData;
                model_name = char(model_value);
                info{end}.model = model_name;
                if isempty(loadedModelNames)
                    info{end}.modelLoaded = 1;
                else
                    info{end}.modelLoaded = sum(ismember(loadedModelNames, model_name));
                end
                
                model_idx = model_element.getAttributeNode('model_idx');
                model_idx_value = model_idx.getFirstChild.getData;
                info{end}.model_idx = char(model_idx_value);

                parent = node_element.getParentNode;
                selfie = parent.getAttribute('selfie');
                if strcmp(char(selfie), '1') 
                    if ~strcmp(model_name, bdroot)
                        modelNameChanged = true;
                    else
                        % decode the file name
                        filename = char(model_element.getAttribute('model_filename')); 
                        filename = DAStudio.Viewmarker.decodeStr(filename);
                        current_filename = get_param(bdroot, 'filename');
                        if ~strcmp(filename,  current_filename)
                            modelNameChanged = true;
                        end
                    end
                end
                
                annotation = node_element.getElementsByTagName('viewmark_annotation');
                annotation_element = annotation.item(0);
                if isempty(annotation_element) || isempty(annotation_element.getFirstChild)
                    annotation_value = '';
                else
                    annotation_value = annotation_element.getFirstChild.getData;
                end
                info{end}.annotation = char(annotation_value);
                
                web_content = node_element.getElementsByTagName('web_content');
                if web_content.getLength > 0
                    web_content_element = web_content.item(0);
                    showing_web_content = str2double(char(web_content_element.getAttribute('showingWebContent')));
                else
                    showing_web_content = 0;
                end
                info{end}.showingWebContent = showing_web_content;
            end
        end
        
        function info = getSysInfoModel(obj)
            info = [];
            [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            xmlDocNodeModel = xmlRootModel.getDocumentElement;
            node = xmlDocNodeModel.getElementsByTagName('viewmark_sys');
            
            node_element = node.item(0);
            watermark = node_element.getElementsByTagName('viewmark_id_watermark');
            watermark_element = watermark.item(0);
            watermark_value = str2double(char(watermark_element.getFirstChild.getData));
            info.watermark_value = watermark_value;
        end
        
        function modifyName(obj, id, newvalue, view)
            isGlobal = true;
            if strcmp(view, 'global')
                docNode = obj.xmlRoot;
                node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            else
                isGlobal = false;
                [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
                
                if ~exist(xmlFileNameToModel, 'file')
                    return;
                end
                
                fileParser = matlab.io.xml.dom.Parser;
                xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
                docNode = xmlRootModel;
                parentNode = xmlRootModel.getDocumentElement;
                node = parentNode.getElementsByTagName('viewmark_node');
            end
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                node_element = node.item(idx);
                
                name = node_element.getElementsByTagName('viewmark_name');
                name_element = name.item(0);
                if isempty(name_element) || isempty(name_element.getFirstChild)
                    name_element.appendChild(docNode.createTextNode(newvalue));
                else
                    name_element.getFirstChild.setData(newvalue);
                end
                
                if isGlobal
                    obj.writeToXML();
                else
                    obj.writeToXMLModel(xmlFileNameToModel, parentNode);
                    mdl_name = DAStudio.Viewmarker.getModelName(DAStudio.Viewmarker.getEditor());
                    set_param(bdroot(mdl_name), 'dirty', 'on');
                end
                
                break;
            end
        end
        
        function modifyAnnotation(obj, id, newvalue)
            node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            docNode = obj.xmlRoot;
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                node_element = node.item(idx);
                
                annotation = node_element.getElementsByTagName('viewmark_annotation');
                annotation_element = annotation.item(0);
                if isempty(annotation_element) || isempty(annotation_element.getFirstChild)
                    annotation_element.appendChild(docNode.createTextNode(newvalue));
                else
                    annotation_element.getFirstChild.setData(newvalue);
                end
                
                obj.writeToXML();
                break;
            end
        end
        
        function modifyAnnotation_model(obj, id, newvalue)
            [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            parentNode = xmlRootModel.getDocumentElement;
            node = parentNode.getElementsByTagName('viewmark_node');
            
            docNode = xmlRootModel;
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                node_element = node.item(idx);
                
                annotation = node_element.getElementsByTagName('viewmark_annotation');
                annotation_element = annotation.item(0);
                if isempty(annotation_element) || isempty(annotation_element.getFirstChild)
                    annotation_element.appendChild(docNode.createTextNode(newvalue));
                else
                    annotation_element.getFirstChild.setData(newvalue);
                end
                
                obj.writeToXMLModel(xmlFileNameToModel, parentNode);
                mdl_name = DAStudio.Viewmarker.getModelName(DAStudio.Viewmarker.getEditor());
                set_param(bdroot(mdl_name), 'dirty', 'on');
                break;
            end
        end
        
        function deleteViewmark(obj, id)
            node = obj.xmlRoot.getElementsByTagName('viewmark_node');
            parentNode = obj.xmlRoot.getDocumentElement;
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                svg = node_element.getElementsByTagName('viewmark_svg');
                svg_element = svg.item(0);
                
                if isempty(svg_element)
                    % disp('Thumnail image is not available for this viewmark');
                    return;
                end
                
                model = node_element.getElementsByTagName('viewmark_model');
                model_element = model.item(0);
                model_name_value = model_element.getFirstChild.getData;
                mdlIdx = model_element.getAttribute('model_idx');
                
                mvGroup = [];
                grouplist = obj.xmlDocNode.getElementsByTagName('viewmark_group');
                for i=0:grouplist.getLength-1
                    group = grouplist.item(i);
                    this_mdlname = group.getAttribute('name');
                    if ~strcmp(char(this_mdlname), model_name_value)
                        continue;
                    else
                        mvGroup = group;
                        break;
                    end
                end
                
                models = mvGroup.getElementsByTagName('viewmark_model');
                
                if models.getLength==1
                    node_sys = obj.xmlDocNode.getElementsByTagName('viewmark_sys');
                    node_sys_element = node_sys.item(0);
                    node_sys_model = node_sys_element.getElementsByTagName(model_name_value);
                    node_sys_element.removeChild(node_sys_model.item(0));
                else
                    node_sys = obj.xmlDocNode.getElementsByTagName('viewmark_sys');
                    node_sys_element = node_sys.item(0);
                    node_sys_model = node_sys_element.getElementsByTagName(model_name_value);
                    node_sys_model_element = node_sys_model.item(0);
                    node_sys_model_value = node_sys_model_element.getFirstChild.getData;
                    
                    node_sys_model_value_new = str2double(char(node_sys_model_value)) - 1;
                    node_sys_model_element.getFirstChild.setData(num2str(node_sys_model_value_new));
                    
                    if str2double(char(mdlIdx))==1
                        model_element = models.item(models.getLength-2);
                        if ~isempty(model_element)
                            model_idx = model_element.getAttributeNode('model_idx');
                            model_idx.getFirstChild.setData('1');
                        end
                    end
                end
                
                svg_value = svg_element.getFirstChild.getData;
                delete([obj.xmlDir filesep char(svg_value)]);
                
                mvGroup.removeChild(node_element);
                
                if mvGroup.getLength == 0
                    parentNode.removeChild(mvGroup);
                end
                
                obj.writeToXML();
                
                break;
            end
        end
        
        function deleteViewmark_model(obj, id)
            [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            parentNode = xmlRootModel.getDocumentElement;
            node = parentNode.getElementsByTagName('viewmark_node');
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                svg = node_element.getElementsByTagName('viewmark_svg');
                svg_element = svg.item(0);
                
                if isempty(svg_element)
                    % disp('Thumnail image is not available for this viewmark');
                    return;
                end
                
                model = node_element.getElementsByTagName('viewmark_model');
                model_element = model.item(0);
                model_name_value = model_element.getFirstChild.getData;
                mdlIdx = model_element.getAttribute('model_idx');
                
                mvGroup = [];
                grouplist = parentNode.getElementsByTagName('viewmark_group');
                for i=0:grouplist.getLength-1
                    group = grouplist.item(i);
                    this_mdlname = group.getAttribute('name');
                    if ~strcmp(char(this_mdlname), model_name_value)
                        continue;
                    else
                        mvGroup = group;
                        break;
                    end
                end
                
                models = mvGroup.getElementsByTagName('viewmark_model');
                
                if models.getLength==1
                    node_sys = parentNode.getElementsByTagName('viewmark_sys');
                    node_sys_element = node_sys.item(0);
                    node_sys_model = node_sys_element.getElementsByTagName(model_name_value);
                    node_sys_element.removeChild(node_sys_model.item(0));
                else
                    node_sys = parentNode.getElementsByTagName('viewmark_sys');
                    node_sys_element = node_sys.item(0);
                    node_sys_model = node_sys_element.getElementsByTagName(model_name_value);
                    node_sys_model_element = node_sys_model.item(0);
                    node_sys_model_value = node_sys_model_element.getFirstChild.getData;
                    
                    node_sys_model_value_new = str2double(char(node_sys_model_value)) - 1;
                    node_sys_model_element.getFirstChild.setData(num2str(node_sys_model_value_new));
                    
                    if str2double(char(mdlIdx))==1
                        model_element = models.item(models.getLength-2);
                        if ~isempty(model_element)
                            model_idx = model_element.getAttributeNode('model_idx');
                            model_idx.getFirstChild.setData('1');
                        end
                    end
                end
                
                svg_value = svg_element.getFirstChild.getData;
                delete([svgModelDir filesep char(svg_value)]);
                editor = DAStudio.Viewmarker.getEditor();
                mdl_name = bdroot(DAStudio.Viewmarker.getModelName(editor));
                obj.setSvgToDeleteInModel(mdl_name, char(svg_value));
                
                mvGroup.removeChild(node_element);
                
                if mvGroup.getLength == 0
                    % In old xerces parser, this length is still 2 but
                    % children are gone which we verify in test.
                    % parentNode.removeChild(mvGroup);
                end
                
                obj.writeToXMLModel(xmlFileNameToModel, parentNode);
                mdl_name = DAStudio.Viewmarker.getModelName(DAStudio.Viewmarker.getEditor());
                set_param(bdroot(mdl_name), 'dirty', 'on');
               
                break;
            end
        end
        
        function copyViewmark(obj, modelname, id)
            [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                docNode = matlab.io.xml.dom.Document('sl_viewmark');
                xmlDocNode_model = docNode.getDocumentElement;
                mvElement = docNode.createElement('viewmark_sys');
                mvWatermark = docNode.createElement('viewmark_id_watermark');
                mvWatermark.appendChild(docNode.createTextNode('0'));
                mvElement.appendChild(mvWatermark);
                xmlDocNode_model.appendChild(mvElement);
                obj.writeToXMLModel(xmlFileNameToModel, xmlDocNode_model);
            end
            
            [~, ~, xmlDocNode_model_return] = obj.copyNodeToXMLModel(modelname, id);
            if ~isempty(xmlDocNode_model_return)
                obj.writeToXMLModel(xmlFileNameToModel, xmlDocNode_model_return);
            end
        end
        
        function refresh(obj, id, view)
            hasError = obj.open(id, 'ignoreSavedSceneRect', view);
            if hasError
                return;
            end
            
            isGlobal = true;
            if strcmp(view, 'global')
                node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            else
                isGlobal = false;
                [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
                
                if ~exist(xmlFileNameToModel, 'file')
                    return;
                end
                
                fileParser = matlab.io.xml.dom.Parser;
                xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
                parentNode = xmlRootModel.getDocumentElement;
                node = parentNode.getElementsByTagName('viewmark_node');
            end
            
            editor = DAStudio.Viewmarker.getEditor();
            [fullname, ~, ~] = DAStudio.Viewmarker.getFullModelName(DAStudio.Viewmarker.getModelName(editor));
            
            snapshot = obj.snapShot;
            diagram = obj.getModelDiagram();
            if isa(diagram, 'StateflowDI.Subviewer')
                isSimulink = false;
                snapshot.setTarget('Stateflow', diagram);
            else
                isSimulink = true;
                snapshot.setTarget('Simulink', diagram);
            end
            snapshot.suppressBadges = true;
            opts = snapshot.exportOptions;
            opts.format = 'SVG';
            opts.backgroundColorMode='Transparent';
            
            canvas = editor.getCanvas;
            sceneRectInView = canvas.SceneRectInView;
            
            svgFileName = strrep([fullname '@' datestr(now, 'mmm-dd-yyyy-HH-MM-SS') '.svg'], '/', '-');
            svgFileName = DAStudio.Viewmarker.getEligibleFileName(svgFileName); % truncate the file name if it is too long (g1359984)
            if isGlobal
                snapshot.exportOptions.fileName = [obj.xmlDir filesep svgFileName];
            else
                snapshot.exportOptions.fileName = [svgModelDir filesep svgFileName];
            end
            snapshot.targetSceneRect = sceneRectInView;
            snapshot.exportForViewMarks(canvas);
            
            if isSimulink
                viewmark_id = Simulink.ID.getSID(gcs);
            else
                backendId = diagram.backendId;
                mdl = get_param(bdroot, 'Object');
                chart = mdl.find('Id', double(backendId));
                if isempty(chart)
                    rt = sfroot;
                    chart = rt.find('Id', double(backendId));     % linked subchart
                    SID = Simulink.ID.getSID(chart);
                    viewmark_id = SID;
                else
                    SID = Simulink.ID.getSID(chart);
                    viewmark_id = SID;
                end
            end
            
            % update the xml file: slViewMark.xml
            sceneRectInViewStr = mat2str(sceneRectInView);
            
            % update the web content meta info
            meta.hasWebContent = SLM3I.SLCommonDomain.isWebContentLoadedForEditor(editor);
            meta.showingWebContent = SLM3I.SLCommonDomain.isWebContentShowingForEditor(editor);
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                node_element.setAttribute('available', '1');
                
                svg = node_element.getElementsByTagName('viewmark_svg');
                svg_element = svg.item(0);
                
                if isempty(svg_element)
                    % disp('Thumnail image is not available for this viewmark');
                    return;
                end
                
                svg_value = svg_element.getFirstChild.getData;
                if isGlobal
                    delete([obj.xmlDir filesep char(svg_value)]);
                else
                    delete([svgModelDir filesep char(svg_value)]);
                end
                
                svg_element.getFirstChild.setData(svgFileName);
                
                name_node = node_element.getElementsByTagName('viewmark_name');
                name_element = name_node.item(0);
                if isempty(name_element) || isempty(name_element.getFirstChild)
                    viewmark_name = '';
                else
                    viewmark_name = name_element.getFirstChild.getData();
                end
                
                % position
                rect = node_element.getElementsByTagName('viewmark_scenerectinview');
                rect_element = rect.item(0);
                
                rect_element.getFirstChild.setData(sceneRectInViewStr);
                
                % id
                id_node = node_element.getElementsByTagName('viewmark_id');
                id_element = id_node.item(0);
                id_element.getFirstChild.setData(viewmark_id);
                
                id_element.setAttribute('isSimulink', num2str(isSimulink));
                
                % meta
                web_content = node_element.getElementsByTagName('web_content');
                if web_content.getLength > 0
                    web_content_element = web_content.item(0);
                    web_content_element.setAttribute('hasWebContent', num2str(meta.hasWebContent));
                    web_content_element.setAttribute('showingWebContent', num2str(meta.showingWebContent));
                end
                
                if isGlobal
                    obj.writeToXML();
                else
                    obj.writeToXMLModel(xmlFileNameToModel, parentNode);
                end
                
                break;
            end
            
            app = SLM3I.SLDomain.getLastActiveStudioApp;
            bdhandle = app.blockDiagramHandle;
            bd = get_param(bdhandle, 'Object');
            modelname = bd.getFullName;
            
            information.model = modelname;
            information.mode = 'creation';
            information.message = ['Viewmark created for ' fullname];
            information.isSimulink = isSimulink;
            information.id = char(this_id);
            information.annotation = ' ';
            information.name = char(viewmark_name);
            information.vm_path = [obj.xmlDir filesep svgFileName];

            %Update the watermark viewmark, this shall be used to display the pop-up
            xmlModelFile = fullfile(obj.xmlDir, 'Simulink_ViewMark.xml');
            fileParser = matlab.io.xml.dom.Parser;
            docNode = fileParser.parseFile(xmlModelFile);
            wms = docNode.getElementsByTagName('viewmark_id_watermark');
            wm = wms.item(0);
            wm.getFirstChild.setData(char(this_id));
            writer = matlab.io.xml.dom.DOMWriter;
            writer.writeToFile(docNode, xmlModelFile);
            
            information.showingWebContent = meta.showingWebContent;
            obj.dlg = slprivate('slOpenViewMarkDialog', information);
        end
        
        function markunavailable(obj, id)
            
            obj.changeAvailableState('global', id, '0');
            obj.changeAvailableState('model', id, '0');
        end
        
        function markavailable(obj, id)   
            
            obj.changeAvailableState('global', id, '1');
            obj.changeAvailableState('model', id, '1');
        end
        
        % change the available attribute of a node element
        function changeAvailableState(obj, mode, id, state)
            node = '';
            xmlFileNameToModel = '';
            parentNode = '';
            
            if strcmp(mode, 'model')
                % node in the model tab
                [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();                
                if ~exist(xmlFileNameToModel, 'file')
                    return;
                end               
                fileParser = matlab.io.xml.dom.Parser;
                xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
                parentNode = xmlRootModel.getDocumentElement;
                node = parentNode.getElementsByTagName('viewmark_node');
            else 
                % node in the personal tab
                node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            end
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                if isempty(node_element)
                    continue;
                end
                
                this_id = node_element.getAttribute('id');
                if str2double(char(this_id)) ~= str2double(id)
                    continue;
                end
                
                node_element.setAttribute('available', state);
                
                if strcmp(mode, 'model')
                    obj.writeToXMLModel(xmlFileNameToModel, parentNode);
                else
                    obj.writeToXML();
                end
                break;
            end
        end
        
        function unload(~)
            files = fullfile(prefdir, 'sl_viewmark', 'background*.png');
            delete(files);
        end
        
        function [watermark_newvalue, newId] = addNodeToXML(obj, viewmarkName, modelname, id, filename, isSimulink, svgName, sceneRectInView, meta)
            node = obj.xmlDocNode.getElementsByTagName('viewmark_sys');
            node_element = node.item(0);
            
            watermark = node_element.getElementsByTagName('viewmark_id_watermark');
            watermark_element = watermark.item(0);
            watermark_value = watermark_element.getFirstChild.getData;
            
            watermark_newvalue = str2double(char(watermark_value)) + 1;
            watermark_element.getFirstChild.setData(num2str(watermark_newvalue));
            
            model = node_element.getElementsByTagName(modelname);
            model_element = model.item(0);
            
            docNode = obj.xmlRoot;
            
            if ~isempty(model_element)
                model_value = model_element.getFirstChild.getData;
                model_newvalue = str2double(char(model_value)) + 1;
                model_element.getFirstChild.setData(num2str(model_newvalue));
                
                %modelCounter = model_element.getAttributeNode('model_counter');
                %modelCounter_value = modelCounter.getFirstChild.getData;
                %counter = str2num(char(modelCounter_value));
            else
                mvModel = docNode.createElement(modelname);
                mvModel.appendChild(docNode.createTextNode('1'));
                node_element.appendChild(mvModel);
                model_newvalue = 1;
                
                %modelCounterAttribute = docNode.createAttribute('model_counter');%viewmark_model(attribute: model_idx)
                %modelCounterAttribute.setNodeValue(num2str(0));
                
                %mvModel.setAttributeNode(modelCounterAttribute);
                %model = node_element.getElementsByTagName(modelname);
                %model_element = model.item(0);
                %counter = 0;
            end
            
            parentNode = docNode.getDocumentElement;
            
            grouplist = obj.xmlDocNode.getElementsByTagName('viewmark_group');
            
            mvGroup = [];
            
            if isempty(grouplist) || (grouplist.getLength == 0)
                mvGroup = docNode.createElement('viewmark_group');
                mvGroup.setAttribute('name', modelname);
                parentNode.appendChild(mvGroup);
            else
                for idx=0:grouplist.getLength-1
                    group = grouplist.item(idx);
                    this_mdlname = group.getAttribute('name');
                    if ~strcmp(char(this_mdlname), modelname)
                        continue;
                    else
                        mvGroup = group;
                        break;
                    end
                end
                
                if isempty(mvGroup)
                    mvGroup = docNode.createElement('viewmark_group');
                    mvGroup.setAttribute('name', modelname);
                    first_group = grouplist.item(0);
                    parentNode.insertBefore(mvGroup, first_group);
                end
            end
            
            nodelist = mvGroup.getElementsByTagName('viewmark_node');
            nodelist_len = nodelist.getLength();
            
            % CREATION of mvElement
            mvElement = docNode.createElement('viewmark_node');   % viewmark_node
            mvElement.setAttribute('id', num2str(watermark_newvalue));
            newId = num2str(watermark_newvalue);
            mvElement.setAttribute('available', '1');
            
            mvName = docNode.createElement('viewmark_name');      % viewmark_name
            mvName.appendChild(docNode.createTextNode(viewmarkName));
            mvElement.appendChild(mvName);
            mvModelName = docNode.createElement('viewmark_model');% viewmark_model
            mvModelName.appendChild(docNode.createTextNode(modelname));
            
            modelAttribute = docNode.createAttribute('model_idx');%viewmark_model(attribute: model_idx)
            modelAttribute.setNodeValue(num2str(model_newvalue));
            
            modelAttribute2 = docNode.createAttribute('model_filename');%viewmark_model(attribute: model_filename)
            modelAttribute2.setNodeValue(filename);
            
            mvModelName.setAttributeNode(modelAttribute);
            mvModelName.setAttributeNode(modelAttribute2);
            mvElement.appendChild(mvModelName);
            
            mvAnnotation = docNode.createElement('viewmark_annotation'); %viewmark_annotation
            mvAnnotation.appendChild(docNode.createTextNode(''));
            mvElement.appendChild(mvAnnotation);
            
            mvId = docNode.createElement('viewmark_id');          %viewmark_id
            mvId.appendChild(docNode.createTextNode(id));
            mvId.setAttribute('isSimulink', num2str(isSimulink));
            mvElement.appendChild(mvId);
            
            mvSVG = docNode.createElement('viewmark_svg');        %viewmakr_svg
            mvSVG.appendChild(docNode.createTextNode(svgName));
            mvElement.appendChild(mvSVG);
            
            mvSceneRectInView = docNode.createElement('viewmark_scenerectinview'); %viewmark_scenerectinview
            mvSceneRectInView.appendChild(docNode.createTextNode(sceneRectInView));
            mvElement.appendChild(mvSceneRectInView);
            % END of CREATION of mvElement
            
            % CREATION of metaElement (being metadata not present in the model)
            if (meta.hasWebContent)
                metaElement = docNode.createElement('viewmark_meta');        % viewmark_meta
                webContentElement = docNode.createElement('web_content'); % web_content
                webContentElement.setAttribute('hasWebContent', num2str(meta.hasWebContent));
                webContentElement.setAttribute('showingWebContent', num2str(meta.showingWebContent));
                metaElement.appendChild(webContentElement);
                mvElement.appendChild(metaElement);
            end
            % END of CREATION of metaElement
            
            if nodelist_len>0
                first_element = nodelist.item(0);
                mvGroup.insertBefore(mvElement, first_element);
            else
                mvGroup.appendChild(mvElement);
            end
        end
        
        function [watermark_newvalue, newId, xmlRootModel] = addNodeToXMLModel(~, viewmarkName, modelname, id, filename, isSimulink, svgName, sceneRectInView, meta)
            [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            parentNode = xmlRootModel.getDocumentElement;
            node = parentNode.getElementsByTagName('viewmark_sys');
            
            node_element = node.item(0);
            
            watermark = node_element.getElementsByTagName('viewmark_id_watermark');
            watermark_element = watermark.item(0);
            watermark_value = watermark_element.getFirstChild.getData;
            
            watermark_newvalue = str2double(char(watermark_value)) + 1;
            watermark_element.getFirstChild.setData(num2str(watermark_newvalue));
            
            model = node_element.getElementsByTagName(modelname);
            model_element = model.item(0);
            
            docNode = xmlRootModel;
            
            if ~isempty(model_element)
                model_value = model_element.getFirstChild.getData;
                
                model_newvalue = str2double(char(model_value)) + 1;
                model_element.getFirstChild.setData(num2str(model_newvalue));
            else
                mvModel = docNode.createElement(modelname);
                mvModel.appendChild(docNode.createTextNode('1'));
                node_element.appendChild(mvModel);
                model_newvalue = 1;
            end
            
            parentNode = docNode.getDocumentElement;
            
            grouplist = parentNode.getElementsByTagName('viewmark_group');
            
            mvGroup = [];
            
            if isempty(grouplist) || (grouplist.getLength == 0)
                mvGroup = docNode.createElement('viewmark_group');
                mvGroup.setAttribute('name', modelname);
                parentNode.appendChild(mvGroup);
            else
                for idx=0:grouplist.getLength-1
                    group = grouplist.item(idx);
                    this_mdlname = group.getAttribute('name');
                    if ~strcmp(char(this_mdlname), modelname)
                        continue;
                    else
                        mvGroup = group;
                        break;
                    end
                end
                
                if isempty(mvGroup)
                    mvGroup = docNode.createElement('viewmark_group');
                    mvGroup.setAttribute('name', modelname);
                    first_group = grouplist.item(0);
                    parentNode.insertBefore(mvGroup, first_group);
                end
            end
            
            nodelist = mvGroup.getElementsByTagName('viewmark_node');
            nodelist_len = nodelist.getLength();
            
            % CREATION of mvElement
            mvElement = docNode.createElement('viewmark_node');   % viewmark_node
            mvElement.setAttribute('id', num2str(watermark_newvalue));
            newId = num2str(watermark_newvalue);
            mvElement.setAttribute('available', '1');
            
            mvName = docNode.createElement('viewmark_name');      % viewmark_name
            mvName.appendChild(docNode.createTextNode(viewmarkName));
            mvElement.appendChild(mvName);
            mvModelName = docNode.createElement('viewmark_model');% viewmark_model
            mvModelName.appendChild(docNode.createTextNode(modelname));
            
            modelAttribute = docNode.createAttribute('model_idx');%viewmark_model(attribute: model_idx)
            modelAttribute.setNodeValue(num2str(model_newvalue));
            
            modelAttribute2 = docNode.createAttribute('model_filename');%viewmark_model(attribute: model_filename)
            modelAttribute2.setNodeValue(filename);
            
            mvModelName.setAttributeNode(modelAttribute);
            mvModelName.setAttributeNode(modelAttribute2);
            mvElement.appendChild(mvModelName);
            
            mvAnnotation = docNode.createElement('viewmark_annotation'); %viewmark_annotation
            mvAnnotation.appendChild(docNode.createTextNode(''));
            mvElement.appendChild(mvAnnotation);
            
            mvId = docNode.createElement('viewmark_id');          %viewmark_id
            mvId.appendChild(docNode.createTextNode(id));
            mvId.setAttribute('isSimulink', num2str(isSimulink));
            mvElement.appendChild(mvId);
            
            mvSVG = docNode.createElement('viewmark_svg');        %viewmakr_svg
            mvSVG.appendChild(docNode.createTextNode(svgName));
            mvElement.appendChild(mvSVG);
            
            mvSceneRectInView = docNode.createElement('viewmark_scenerectinview'); %viewmark_scenerectinview
            mvSceneRectInView.appendChild(docNode.createTextNode(sceneRectInView));
            mvElement.appendChild(mvSceneRectInView);
            % END of CREATION of mvElement
            
            % CREATION of metaElement (being metadata not present in the model)
            if (meta.hasWebContent)
                metaElement = docNode.createElement('viewmark_meta');        % viewmark_meta
                webContentElement = docNode.createElement('web_content'); % web_content
                webContentElement.setAttribute('hasWebContent', num2str(meta.hasWebContent));
                webContentElement.setAttribute('showingWebContent', num2str(meta.showingWebContent));
                metaElement.appendChild(webContentElement);
                mvElement.appendChild(metaElement);
            end
            % END of CREATION of metaElement
            
            if nodelist_len>0
                first_element = nodelist.item(0);
                mvGroup.insertBefore(mvElement, first_element);
            else
                mvGroup.appendChild(mvElement);
            end
        end
        
        function [watermark_newvalue, newId, xmlRootModel] = copyNodeToXMLModel(obj, modelname, id)
            node = obj.xmlDocNode.getElementsByTagName('viewmark_sys');
            node_element = node.item(0);
            
            watermark = node_element.getElementsByTagName('viewmark_id_watermark');
            watermark_element = watermark.item(0);
            watermark_value = watermark_element.getFirstChild.getData;
            
            watermark_newvalue = str2double(char(watermark_value)) + 1;
            watermark_element.getFirstChild.setData(num2str(watermark_newvalue));
            
            model = node_element.getElementsByTagName(modelname);
            model_element = model.item(0);
            
            docNode = obj.xmlRoot;
            
            if ~isempty(model_element)
                model_value = model_element.getFirstChild.getData;
                model_newvalue = str2double(char(model_value)) + 1;
                model_element.getFirstChild.setData(num2str(model_newvalue));
            else
                mvModel = docNode.createElement(modelname);
                mvModel.appendChild(docNode.createTextNode('1'));
                node_element.appendChild(mvModel);
            end
            
            grouplist = obj.xmlDocNode.getElementsByTagName('viewmark_group');
            mvGroup = [];
            
            for idx=0:grouplist.getLength-1
                group = grouplist.item(idx);
                this_mdlname = group.getAttribute('name');
                if ~strcmp(char(this_mdlname), modelname)
                    continue;
                else
                    mvGroup = group;
                    break;
                end
            end
            
            if isempty(mvGroup)
                disp('error: no group found in preference');
                return;
            end
            
            nodelist = mvGroup.getElementsByTagName('viewmark_node');
            nodelist_len = nodelist.getLength();
            
            for idx=0:nodelist_len-1
                node = nodelist.item(idx);
                this_id = node.getAttribute('id');
                if ~strcmp(char(this_id), id)
                    continue;
                else
                    mvNode = node;
                    break;
                end
            end
            
            mvName = mvNode.getElementsByTagName('viewmark_name');
            name_element = mvName.item(0);
            if isempty(name_element) || isempty(name_element.getFirstChild)
                name_value_pref = '';
            else
                name_value_pref = name_element.getFirstChild.getData;
            end
            
            mvModel = mvNode.getElementsByTagName('viewmark_model');
            model_element = mvModel.item(0);
            model_value_pref = model_element.getFirstChild.getData;
            model_filename_pref = char(model_element.getAttribute('model_filename'));
            
            mvAvailable = char(mvNode.getAttribute('available'));  % get the available attribute
            
            mvAnnotation = mvNode.getElementsByTagName('viewmark_annotation');
            annotation_element = mvAnnotation.item(0);
            if ~isempty(annotation_element.getFirstChild)
                annotation_value_pref = annotation_element.getFirstChild.getData;
            else
                annotation_value_pref = '';
            end
            
            mvId = mvNode.getElementsByTagName('viewmark_id');
            id_element = mvId.item(0);
            id_value_pref = id_element.getFirstChild.getData;
            id_issimulink_pref = char(id_element.getAttribute('isSimulink'));
            
            mvSvg = mvNode.getElementsByTagName('viewmark_svg');
            svg_element = mvSvg.item(0);
            svg_value_pref = char(svg_element.getFirstChild.getData);
            svg_value_pref_no_spaces = regexprep(svg_value_pref, '\s', '_'); % in case the viewmark was saved with whitespace in the name (g1266350)
            svg_value_pref_name_randomized = [strrep(svg_value_pref_no_spaces, '.svg', '')  '_' num2str(round(rand * 10000)) '.svg'];
            
            mvScenerectinview = mvNode.getElementsByTagName('viewmark_scenerectinview');
            scenerectinview_element = mvScenerectinview.item(0);
            scenerectinview_value_pref = scenerectinview_element.getFirstChild.getData;
            
            % web_content meta node is only sometimes necessary so may not be present
            has_web_content_pref = 0;
            web_content = mvNode.getElementsByTagName('web_content');
            if web_content.getLength > 0
                web_content_element = web_content.item(0);
                has_web_content_pref = str2double(char(web_content_element.getAttribute('hasWebContent')));
                showing_web_content_pref = str2double(char(web_content_element.getAttribute('showingWebContent')));
            end
            
            % write to the model XML file
            [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            parentNode = xmlRootModel.getDocumentElement;
            node = parentNode.getElementsByTagName('viewmark_sys');
            
            node_element = node.item(0);
            
            watermark = node_element.getElementsByTagName('viewmark_id_watermark');
            watermark_element = watermark.item(0);
            watermark_value = watermark_element.getFirstChild.getData;
            
            watermark_newvalue = str2double(char(watermark_value)) + 1;
            watermark_element.getFirstChild.setData(num2str(watermark_newvalue));
            
            model = node_element.getElementsByTagName(modelname);
            model_element = model.item(0);
            
            docNode = xmlRootModel;
            
            if ~isempty(model_element)
                model_value = model_element.getFirstChild.getData;
                
                model_newvalue = str2double(char(model_value)) + 1;
                model_element.getFirstChild.setData(num2str(model_newvalue));
            else
                mvModel = docNode.createElement(modelname);
                mvModel.appendChild(docNode.createTextNode('1'));
                node_element.appendChild(mvModel);
                model_newvalue = 1;
            end
            
            parentNode = docNode.getDocumentElement;
            
            grouplist = parentNode.getElementsByTagName('viewmark_group');
            
            mvGroup = [];
            
            if isempty(grouplist) || (grouplist.getLength == 0)
                mvGroup = docNode.createElement('viewmark_group');
                mvGroup.setAttribute('name', modelname);
                if strcmp(modelname, bdroot)
                    mvGroup.setAttribute('selfie', '1');
                end
                parentNode.appendChild(mvGroup);                
            else
                for idx=0:grouplist.getLength-1
                    group = grouplist.item(idx);
                    this_mdlname = group.getAttribute('name');
                    if ~strcmp(char(this_mdlname), modelname)
                        continue;
                    else
                        mvGroup = group;
                        break;
                    end
                end
                
                if isempty(mvGroup)
                    mvGroup = docNode.createElement('viewmark_group');
                    mvGroup.setAttribute('name', modelname);
                    if strcmp(modelname, bdroot)
                        mvGroup.setAttribute('selfie', '1');
                    end
                    first_group = grouplist.item(0);
                    parentNode.insertBefore(mvGroup, first_group);
                end
            end
            
            nodelist = mvGroup.getElementsByTagName('viewmark_node');
            nodelist_len = nodelist.getLength();
            
            % CREATION of mvElement
            mvElement = docNode.createElement('viewmark_node');   % viewmark_node
            mvElement.setAttribute('id', num2str(watermark_newvalue));
            newId = num2str(watermark_newvalue);
            mvElement.setAttribute('available', '1');
            
            mvName = docNode.createElement('viewmark_name');      % viewmark_name
            mvName.appendChild(docNode.createTextNode(name_value_pref));
            mvElement.appendChild(mvName);
            mvModelName = docNode.createElement('viewmark_model');% viewmark_model
            mvModelName.appendChild(docNode.createTextNode(model_value_pref));
            
            modelAttribute = docNode.createAttribute('model_idx');%viewmark_model(attribute: model_idx)
            modelAttribute.setNodeValue(num2str(model_newvalue));
            
            % encode the filename before write it to xml
            encodeFileName = DAStudio.Viewmarker.encodeStr(model_filename_pref);
            modelAttribute2 = docNode.createAttribute('model_filename');%viewmark_model(attribute: model_filename)
            modelAttribute2.setNodeValue(encodeFileName);
            
            mvModelName.setAttributeNode(modelAttribute);
            mvModelName.setAttributeNode(modelAttribute2);
            mvElement.appendChild(mvModelName);
            
            % set the available attribute
            mvElement.setAttribute('available', mvAvailable);
            
            mvAnnotation = docNode.createElement('viewmark_annotation'); %viewmark_annotation
            mvAnnotation.appendChild(docNode.createTextNode(annotation_value_pref));
            mvElement.appendChild(mvAnnotation);
            
            mvId = docNode.createElement('viewmark_id');          %viewmark_id
            mvId.appendChild(docNode.createTextNode(id_value_pref));
            mvId.setAttribute('isSimulink', id_issimulink_pref);
            mvElement.appendChild(mvId);
            
            mvSVG = docNode.createElement('viewmark_svg');        %viewmakr_svg
            mvSVG.appendChild(docNode.createTextNode(svg_value_pref_name_randomized));
            mvElement.appendChild(mvSVG);
            
            mvSceneRectInView = docNode.createElement('viewmark_scenerectinview'); %viewmark_scenerectinview
            mvSceneRectInView.appendChild(docNode.createTextNode(scenerectinview_value_pref));
            mvElement.appendChild(mvSceneRectInView);
            % END of CREATION of mvElement
            
            % CREATION of metaElement (being metadata not present in the model)
            if (has_web_content_pref)
                metaElement = docNode.createElement('viewmark_meta');        % viewmark_meta
                webContentElement = docNode.createElement('web_content'); % web_content
                webContentElement.setAttribute('hasWebContent', num2str(has_web_content_pref));
                webContentElement.setAttribute('showingWebContent', num2str(showing_web_content_pref));
                metaElement.appendChild(webContentElement);
                mvElement.appendChild(metaElement);
            end
            % END of CREATION of metaElement
            
            if nodelist_len>0
                first_element = nodelist.item(0);
                mvGroup.insertBefore(mvElement, first_element);
            else
                mvGroup.appendChild(mvElement);
            end
            
            editor = DAStudio.Viewmarker.getEditor();
            mdl_name = DAStudio.Viewmarker.getModelName(editor);
            [~, ~, model] = DAStudio.Viewmarker.getFullModelName(mdl_name);
            try
                set_param(model, 'dirty', 'on');
            catch ME
                warning(ME.identifier, '%s', ME.message);
                xmlRootModel = [];
                return;
            end
            
            svg_file_name = fullfile(prefdir, 'sl_viewmark', svg_value_pref);
            copyfile(svg_file_name, svgModelDir);

            svg_file_name_mdl = fullfile(svgModelDir, svg_value_pref);
            svg_file_name_mdl_name_randomized = fullfile(svgModelDir, svg_value_pref_name_randomized);

            movefile(svg_file_name_mdl, svg_file_name_mdl_name_randomized);
        end
        
        function index = findIndexForModelGroup(obj, modelname)
            index = 1;
            found = false;
            node = obj.xmlDocNode.getElementsByTagName('viewmark_node');
            
            for idx=0:node.getLength-1
                node_element = node.item(idx);
                
                this_model = node_element.getElementsByTagName('viewmark_model');
                model_element = this_model.item(0);
                model_value = model_element.getFirstChild.getData;
                
                if strcmpi(modelname, model_value)
                    found = true;
                    break;
                end
                
                index = index + 1;
            end
            
            if ~found
                index = 1;
            end
        end
        
        function writeToXML(obj)
            writer = matlab.io.xml.dom.DOMWriter;
            writer.writeToFile(obj.xmlDocNode, obj.xmlFileName);
        end
        
        function writeToXMLModel(~, xmlFileNameToModel, xmldocnode)
            writer = matlab.io.xml.dom.DOMWriter;
            writer.writeToFile(xmldocnode, xmlFileNameToModel);
        end
        
        function closeManagerUI(obj)
            dialogHandle = findDDGByTag(obj.dialogTag);
            if ~isempty(dialogHandle)
                dialogHandle.delete;
            end
        end
        
        function tag = getDialogTag(obj)
            tag = obj.dialogTag;
        end
        
        function dir = getVMManagerDir(obj)
            dir = obj.VMManagerDir;
        end
        
        function css = getCSSLoc(obj)
            css = obj.cssfileloc;
        end
        
        function css = getCSSLoc_new(obj)
            css = obj.cssfileloc_new;
        end
        
        function js = getJSLoc(obj)
            js = obj.jsfileloc;
        end
        
        function js = getDDJSLoc(obj)
            js = obj.ddjsfileloc;
        end
        
        function js = getJSLoc_new(obj)
            js = obj.jsfileloc_new;
        end
        
        function copybutton = getCopyButtonLoc(obj)
            copybutton = obj.copyButton;
        end
        
        function deletebutton = getDeleteButtonLoc(obj)
            deletebutton = obj.deleteButton;
        end
        
        function reloadbutton = getReloadButtonLoc(obj)
            reloadbutton = obj.reloadButton;
        end
        
        function annotationbutton = getAnnotationButton(obj)
            annotationbutton = obj.annotationButton;
        end
        
        function spinner = getSpinner(obj)
            spinner = obj.spinner;
        end
        
        function closelink = getCloseLink(obj)
            closelink = obj.closelink;
        end
        
        function takeviewmarkicon = getTakeviewmarkicon(obj)
            takeviewmarkicon = obj.takeviewmarkicon;
        end
        
        function viewmarkmanagericon = getViewmarkmanagericon(obj)
            viewmarkmanagericon = obj.viewmarkmanagericon;
        end
        
        function initialLoad(obj, dlg, initialLoadBegin, initialLoadEnd)
            dlg.evalBrowserJS('viewmarker_manager', ['loadSvgs(' num2str(initialLoadBegin) ',' num2str(initialLoadEnd) ' )']);
        end
        
        function initialLoadSingle(obj, dlg, index)
            dlg.evalBrowserJS('viewmarker_manager', ['loadSvgSingle(' num2str(index) ')']);
        end
        
        function deletegroup(obj, modelGroupName)
            parentNode = obj.xmlRoot.getDocumentElement;
            
            grouplist = obj.xmlDocNode.getElementsByTagName('viewmark_group');
            if isempty(grouplist) || (grouplist.getLength == 0)
                return;
            end
            
            for idx=0:grouplist.getLength-1
                group = grouplist.item(idx);
                this_mdlname = group.getAttribute('name');
                if strcmp(char(this_mdlname), modelGroupName)
                    nodelist = group.getElementsByTagName('viewmark_node');
                    for i =0:nodelist.getLength-1
                        node_element = nodelist.item(i);
                        svg = node_element.getElementsByTagName('viewmark_svg');
                        svg_element = svg.item(0);
                        svg_value = svg_element.getFirstChild.getData;
                        delete([obj.xmlDir filesep char(svg_value)]);
                    end
                    
                    parentNode.removeChild(group);
                    break;
                end
            end
            
            node_sys = obj.xmlDocNode.getElementsByTagName('viewmark_sys');
            node_sys_element = node_sys.item(0);
            node_sys_model = node_sys_element.getElementsByTagName(modelGroupName);
            if ~isempty(node_sys_model.item(0))
                node_sys_element.removeChild(node_sys_model.item(0));
            end
            
            obj.writeToXML();
        end
        
        function deletegroup_model(obj, modelGroupName)
            [xmlFileNameToModel, svgModelDir] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            parentNode = xmlRootModel.getDocumentElement;
            
            grouplist = parentNode.getElementsByTagName('viewmark_group');
            
            if isempty(grouplist) || (grouplist.getLength == 0)
                return;
            end
            
            for idx=0:grouplist.getLength-1
                group = grouplist.item(idx);
                this_mdlname = group.getAttribute('name');
                if strcmp(char(this_mdlname), modelGroupName)
                    nodelist = group.getElementsByTagName('viewmark_node');
                    for i =0:nodelist.getLength-1
                        node_element = nodelist.item(i);
                        svg = node_element.getElementsByTagName('viewmark_svg');
                        svg_element = svg.item(0);
                        svg_value = svg_element.getFirstChild.getData;
                        delete([svgModelDir filesep char(svg_value)]);
                        editor = DAStudio.Viewmarker.getEditor();
                        mdl_name = bdroot(DAStudio.Viewmarker.getModelName(editor));
                        obj.setSvgToDeleteInModel(mdl_name, char(svg_value));
                    end
                    
                    parentNode.removeChild(group);
                    break;
                end
            end
            
            node_sys = parentNode.getElementsByTagName('viewmark_sys');
            node_sys_element = node_sys.item(0);
            node_sys_model = node_sys_element.getElementsByTagName(modelGroupName);
            if ~isempty(node_sys_model.item(0))
                node_sys_element.removeChild(node_sys_model.item(0));
            end
            
            obj.writeToXMLModel(xmlFileNameToModel, parentNode);
            mdl_name = DAStudio.Viewmarker.getModelName(DAStudio.Viewmarker.getEditor());
            set_param(bdroot(mdl_name), 'dirty', 'on');
        end
        
        function setDebugMode(obj, val)
            obj.debugmode = val;
        end
        
        function val = getDebugMode(obj)
            val = obj.debugmode;
        end
        
        function setCurrentEditorHandle(obj, editor)
            obj.currentEditorHandle = editor;
        end
        
        function editor = getCurrentEditorHandle(obj)
            editor = obj.currentEditorHandle;
        end
        
        function setLastClosedTime(obj, time)
            obj.lastClosedTime = time;
        end
        
        function t = getLastClosedTime(obj)
            t = obj.lastClosedTime;
        end
        
        function save = getSaveToModel(obj)
            save = obj.saveToModel;
        end
        
        function setSaveToModel(obj, value)
            obj.saveToModel = value;
        end

        function svgs = getSvgToDeleteInModel(obj)
            svgs = obj.svgToDeleteInModel;
        end

        function setSvgToDeleteInModel(obj, modelname, svg_value)

            if isempty(svg_value)
                if ~isempty(obj.svgToDeleteInModel)
                    if obj.svgToDeleteInModel.models.isKey(modelname)
                        obj.svgToDeleteInModel.models.remove(modelname);
                    end
                end
                
                return;
            end
            
            info = obj.svgToDeleteInModel;
            
            if ~isfield(info, 'models')
                info.models = containers.Map;
                info.models(modelname) = {1};
                info.count = 1;
            else
                info.count = info.count + 1;

                if info.models.isKey(modelname)
                    val = info.models(modelname);
                    val{end+1} = info.count;
                    info.models(modelname) = val;
                else
                    val{1} = info.count;
                    info.models(modelname) = val;                    
                end
            end
            
            svgToDelete.modelname = modelname;
            svgToDelete.svg_value = svg_value;
            info.svgsToDelete{info.count} = svgToDelete;
            
            obj.svgToDeleteInModel = info;
        end
        
        function dragDropUpdate(obj, modelname, ids, globalOrModel)
            eval(['newOrder = {' ids '};']);

			isGlobal = true;
			if strcmp(globalOrModel, 'global') 
				isGlobal = true;
			else
				isGlobal = false;
			end
			
			if isGlobal
				grouplist = obj.xmlDocNode.getElementsByTagName('viewmark_group');
			else
				[xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
				
				if ~exist(xmlFileNameToModel, 'file')
					return;
				end

                fileParser = matlab.io.xml.dom.Parser;
                xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
				parentNode = xmlRootModel.getDocumentElement;
				grouplist = parentNode.getElementsByTagName('viewmark_group');
            end

			for i=0:grouplist.getLength-1
				group = grouplist.item(i);
				this_mdlname = group.getAttribute('name');
				if ~strcmp(char(this_mdlname), modelname)
					continue;
				else
					mvGroup = group;
					break;
				end
			end
			
			models = mvGroup.getElementsByTagName('viewmark_node');
            
            nodeList = [];
            idList = [];
            for i=models.getLength-1:-1:0
                nodeList{end+1}=models.item(i);  %#ok
                idList{end+1} = str2double(char(models.item(i).getAttribute('id')));  %#ok
                mvGroup.removeChild(models.item(i));
            end

            nodeList = fliplr(nodeList);
            idList = fliplr(idList);

            for i=1:length(newOrder)
                index = find([idList{:}] == newOrder{i});
                mvGroup.appendChild(nodeList{index});
            end

			models = mvGroup.getElementsByTagName('viewmark_node');

            needToSwap = false;
            for i=models.getLength-1:-1:0
				model = models.item(i).getElementsByTagName('viewmark_model');
				model_element_last = model.item(0);
				model_idx_last = model_element_last.getAttributeNode('model_idx');
				model_idx_value_last = model_idx_last.getFirstChild.getData;

                if strcmp(char(model_idx_value_last), '1') && i~= models.getLength-1
                    needToSwap = true;
                    indexOfFirst = i;
                end                
            end

            if needToSwap
				model_last = models.item(models.getLength-1).getElementsByTagName('viewmark_model');
				model_element_last = model_last.item(0);
				model_idx_last = model_element_last.getAttributeNode('model_idx');
				model_idx_value_last = model_idx_last.getFirstChild.getData;
				model_idx_last.getFirstChild.setData('1');

				model_1 = models.item(indexOfFirst).getElementsByTagName('viewmark_model');
				model_element_1 = model_1.item(0);
				model_idx_1 = model_element_1.getAttributeNode('model_idx');
				model_idx_1.getFirstChild.setData(model_idx_value_last);
            end

            if isGlobal
				obj.writeToXML();
			else
                obj.writeToXMLModel(xmlFileNameToModel, parentNode);				
				mdl_name = DAStudio.Viewmarker.getModelName(DAStudio.Viewmarker.getEditor());
				set_param(bdroot(mdl_name), 'dirty', 'on');
			end
        end
        
        function updateSelfie(obj, modelname)
            [xmlFileNameToModel, ~] = DAStudio.Viewmarker.getXMLFileNameToModel();
            
            if ~exist(xmlFileNameToModel, 'file')
                return;
            end
            
            fileParser = matlab.io.xml.dom.Parser;
            xmlRootModel = fileParser.parseFile(xmlFileNameToModel);
            parentNode = xmlRootModel.getDocumentElement;
            grouplist = parentNode.getElementsByTagName('viewmark_group');
            
            for i=0:grouplist.getLength-1
                group = grouplist.item(i);
                selfie = group.getAttribute('selfie');
                if strcmp(char(selfie), '1')
                    group.setAttribute('name', modelname);
                    nodes = group.getElementsByTagName('viewmark_node');
                    for j=0:nodes.getLength-1
                        node_element = nodes.item(j);

                        vm_model = node_element.getElementsByTagName('viewmark_model');
                        vm_model_element = vm_model.item(0);
                        oldModelName = vm_model_element.getFirstChild.getData;
                        vm_model_element.getFirstChild.setData(modelname);
                        
                        % encode the file name before update it in xml
                        encodeFileName = DAStudio.Viewmarker.encodeStr(get_param(bdroot, 'filename'));
                        vm_model_element.setAttribute('model_filename', encodeFileName);

                        vm_id = node_element.getElementsByTagName('viewmark_id');
                        vm_id_element = vm_id.item(0);
                        oldVM_id = char(vm_id_element.getFirstChild.getData);
                        vm_id_element.getFirstChild.setData(strrep(oldVM_id, char(oldModelName), modelname));
                    end
                    
                    sys = parentNode.getElementsByTagName('viewmark_sys');
                    sys_element = sys.item(0);
                    sysmodel = sys_element.getElementsByTagName(oldModelName);
                    sysmodel_element = sysmodel.item(0);
                    vm_id_watermark = sysmodel_element.getFirstChild.getData;

                    mvWatermark = xmlRootModel.createElement(modelname);
                    mvWatermark.appendChild(xmlRootModel.createTextNode(vm_id_watermark));
                    sys_element.appendChild(mvWatermark);
                    sys_element.removeChild(sysmodel_element);
                    
                    obj.writeToXMLModel(xmlFileNameToModel, parentNode);
                    %set_param(bdroot(modelname), 'dirty', 'on');

                    break;
                end
            end            
        end
    end
    
    methods (Static = true)
        function obj = getInstance()
            persistent uniqueInstance
            if isempty(uniqueInstance) || ~isvalid(uniqueInstance)
                obj = DAStudio.Viewmarker();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
        
        function editor = getEditor()
            studio = DAS.Studio.getAllStudiosSortedByMostRecentlyActive;   % get the handle of the studio
            app = studio.App;
            editor = app.getActiveEditor;
        end
        
        function model_name = getModelName(editor)
            if isempty(editor.getName)
                object = get_param(diagram.Model.SLGraphHandle, 'Object');
                model_name = object.getFullName;
            else
                model_name = editor.getName;
            end
        end
        
        function blockPath = getBlockPath(editor)
            hid = editor.getHierarchyId(); % The hierarchy in view can be root model, a subsystem, or a model block 
            if (GLUE2.HierarchyService.isTopLevel(hid)) % root model
                obj = GLUE2.HierarchyService.getM3IObject(hid).temporaryObject;
                blockPath = obj.getName(); % Return the root model name
            else
                hid = GLUE2.HierarchyService.getParent(hid); % Subsystem or model block
                obj = GLUE2.HierarchyService.getM3IObject(hid).temporaryObject;
                if isa(obj, 'SLM3I.Block')
                    handle = obj.handle; % Handle to the block
                    hid = GLUE2.HierarchyService.getParent(hid); % Diagram containing the block
                    blockPath = Simulink.BlockPath.fromHierarchyIdAndHandle(hid, handle);
                else
                    blockPath = {};
                end
            end
        end

        function [fullname, subsystemname, model] = getFullModelName(string)
            [model, sub] = strtok(string, '/');
            sub = strrep(sub, char(10), ' ');
            fullname = strrep([model sub], '/', '_');
            
            if ~isempty(sub)
                subsystemname = strtok(sub(end:-1:1), '/');
                subsystemname = subsystemname(end:-1:1);
            else
                subsystemname = model;
            end
        end
        
        function [filename, dirname] = getXMLFileNameToModel()
            [~, ~, model_name] = DAStudio.Viewmarker.getFullModelName(DAStudio.Viewmarker.getModelName(DAStudio.Viewmarker.getEditor()));
            slxpath = get_param(model_name,'UnpackedLocation');
            dirname = fullfile(slxpath, 'simulink', 'viewmarks');
            filename = fullfile(slxpath, 'simulink', 'viewmarks', 'Simulink_ViewMark.xml');
            
            DAStudio.Viewmarker.ensureSLXExtracted(model_name, dirname, filename);
        end
        
        function p = getPartInfoXML()
           persistent part_info_xml;
           if isempty(part_info_xml)
               target =  '/simulink/viewmarks/Simulink_ViewMark.xml';
               id = 'ViewMarkerXML';
               relationship_type = ...
                   'http://schemas.mathworks.com/simulink/2014/relationships/slViewMarksXML';
               content_type = 'application/vnd.mathworks.simulink.viewmarks+xml';

               part_info_xml = Simulink.loadsave.SLXPartDefinition(target,...
                                                  '',...
                                                  content_type,...
                                                  relationship_type,...
                                                  id);

            end
            p = part_info_xml;
        end

        function [svg_part_info, svg_id] = getPartInfoSVG(svg_value)
           svg_partname = ['/simulink/viewmarks/' svg_value];
           svg_id = strrep(strrep(svg_value, '@', '_'), '.', '_');
           relationship_type = 'http://schemas.mathworks.com/simulink/2014/relationships/slViewMarkImage';
           content_type = 'image/svg+xml';
           
           svg_part_info = Simulink.loadsave.SLXPartDefinition(svg_partname,...
                                              '',...
                                              content_type,...
                                              relationship_type,...
                                              svg_id);
        end

        function ensureSLXExtracted(model_name, dirname, filename)
            if ~isfolder(dirname)
                mkdir(dirname);
                
                opts = Simulink.internal.BDLoadOptions(model_name);
                reader = opts.readerHandle;
                
                part_name = '/simulink/viewmarks/Simulink_ViewMark.xml';
                
                if reader.hasPart(part_name) 
                    xml_part = DAStudio.Viewmarker.getPartInfoXML;
                    reader.readPartToFile(xml_part.name,filename);
                    fileParser = matlab.io.xml.dom.Parser;
                    xmlRootModel = fileParser.parseFile(filename);
                    parentNode = xmlRootModel.getDocumentElement;
                    node = parentNode.getElementsByTagName('viewmark_node');
                    
                    for idx=0:node.getLength-1
                        node_element = node.item(idx);
                        svg = node_element.getElementsByTagName('viewmark_svg');
                        svg_element = svg.item(0);
                        svg_value = char(svg_element.getFirstChild.getData);

                        svg_part_info = DAStudio.Viewmarker.getPartInfoSVG(svg_value);
                        svg_file = Simulink.slx.getUnpackedFileNameForPart(model_name,svg_part_info.name);
                        reader.readPartToFile(svg_part_info.name, svg_file);
                    end
                end
            end
        end
        
        function onClose(v, h)
            if strcmpi(h.option.mode, 'open')
                v.setLastClosedTime(clock());
            end
            
            backgroundpics = fullfile(prefdir, 'sl_viewmark', 'background*.png');
            if ~isempty(backgroundpics)
                delete(backgroundpics);
            end
        end
        
        % encode the string with a key
        function encodedStr = encodeStr(str)
            % get the encode key = 11010011
            key =  DAStudio.Viewmarker.encodeKey;
            
            % get the character number of string
            strNum = double(str);
            
            % do the 'XOR' operation with the character number and the key
            % to encode the string
            encodedStrNum = bitxor(strNum,bin2dec(key));
            
            % add the encodedMarker string to the encoded string
            % return the encoded string
            encodedStr = char(encodedStrNum);  
            encodedStr = strcat(DAStudio.Viewmarker.encodedMarker, encodedStr);
        end
        
        % decode the string
        function decodedStr = decodeStr(str)
            key =  DAStudio.Viewmarker.encodeKey;
            decodedStr = str;
            
            % check whether the string is encoded before decode it
            % delete the encodedMarker from the string if it is encoded
            substrIndex = strfind(str,DAStudio.Viewmarker.encodedMarker); 
            if (~isempty(substrIndex))
                if (substrIndex(1) == 1)  % the string is encoded, decode it
                    strLength = length(str);
                    encodedMarkerLength = length(DAStudio.Viewmarker.encodedMarker);
                    fullstr = str(encodedMarkerLength+1:strLength);
                    
                    % decode the string
                    % get the character number of the string to be decoded
                    strNum = double(fullstr);
            
                    % do the 'XOR' operation to decode the string
                    decodedStrNum = bitxor(strNum,bin2dec(key));
            
                    % return the decoded string
                    decodedStr = char(decodedStrNum);
                end
            end           
        end
        
        % get eligible file name (file name should less than 255 characters
        % on windows)
        function fileName = getEligibleFileName(nameString)
            MAX_LENGTH = 80;
            nameLength = length(nameString);
            if nameLength > MAX_LENGTH
                fileName = ['__' nameString(nameLength - MAX_LENGTH : nameLength)];
            else
                fileName = nameString;
            end
        end
        
        
    end
end
