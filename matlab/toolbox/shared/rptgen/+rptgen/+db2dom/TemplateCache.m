classdef TemplateCache < handle
    %db2dom.TemplateCache Cache of templates used to format DocBook reports
    %   The singleton instance of this class maintains a cache of Word, PDF
    %   and HTML templates for formatting DocBook XML reports. The constructor
    %   for this class adds the Report Generator's builtin templates to
    %   the cache. It then searches the current working directory and the
    %   MATLAB path for templates and adds any that it finds to the 
    %   template cache. The cache includes methods for subsequently adding
    %   and removing templates from the cache and other methods intended
    %   to be used by the Report Explorer to support template creation,
    %   move, and delete operations.
    %
    %   To get the cache, execute
    %
    %   cache = rptgen.db2dom.TemplateCache.getTheCache;
    %
    %   To rebuild the cache, execute
    %
    %   cache = rptgen.db2dom.TemplateCache.getTheCache(true);
    
    %   Copyright 2014-2024 The MathWorks, Inc.
    
    
    methods
        
        function cacheTemplate(this, templatePath)  
        %CACHETEMPLATE Caches a Word, HTML or PDF template
        %   cacheTemplate(cache, templatePath) caches the template
        %   specified by templatePath.
            [~,~, ext] = fileparts(templatePath);
            
            switch ext
                case {'.dotx', '.DOTX'}
                    cacheDOCXTemplate(this, templatePath);
                case {'.htmtx', '.HTMTX'}
                    cacheHTMLTemplate(this, templatePath);
                case {'.htmt', '.HTMT'}
                    cacheHTMLFileTemplate(this, templatePath);
                case {'.pdftx', '.PDFTX'}
                    cachePDFTemplate(this, templatePath);
            end           
        end
        
        function cacheDOCXTemplate(this, templatePath)
            %CACHEDOCXTEMPLATE Caches a Word template
            %   cacheDOCXTemplate(cache, templatePath) caches the template
            %   specified by templatePath.
            if rptgen.db2dom.TemplateCache.isTemplateReadable(templatePath)
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                if ~isempty(dir(templatePath))
                    if ~isempty(props.Identifier)
                        this.DOCXTemplateMap(props.Identifier) = templatePath;
                        templateInfo = this.makeTemplateInfo( ...
                            props.Identifier, templatePath, 'docx');
                        this.DOCXTemplateInfoMap(props.Identifier) = templateInfo;
                    end
                end
            end
        end
        
        function cacheHTMLTemplate(this, templatePath)
            %CACHEHTMLTEMPLATE Caches an HTML template
            %   cacheHTMLTemplate(cache, templatePath) caches the template
            %   specified by templatePath.
            if ~isempty(dir(templatePath))
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                if ~isempty(props.Identifier)
                    this.HTMLTemplateMap(props.Identifier) = templatePath;
                    templateInfo = this.makeTemplateInfo( ...
                        props.Identifier, templatePath, 'html');
                    this.HTMLTemplateInfoMap(props.Identifier) = templateInfo;
                end
            end
        end
        
        function cacheHTMLFileTemplate(this, templatePath)
            %CACHEHTMLFILETEMPLATE Caches an HTML template
            %   cacheHTMLFILETemplate(cache, templatePath) caches the template
            %   specified by templatePath.
            if ~isempty(dir(templatePath))
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                if ~isempty(props.Identifier)
                    this.HTMLFileTemplateMap(props.Identifier) = templatePath;
                    templateInfo = this.makeTemplateInfo( ...
                        props.Identifier, templatePath, 'html-file');
                    this.HTMLFileTemplateInfoMap(props.Identifier) = templateInfo;
                end
            end
        end
        
        function cachePDFTemplate(this, templatePath)
            %CACHEPDFTEMPLATE Caches a PDF template
            %   cachePDFTemplate(cache, templatePath) caches the template
            %   specified by templatePath.
            if ~isempty(dir(templatePath))
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                if ~isempty(props.Identifier)
                    this.PDFTemplateMap(props.Identifier) = templatePath;
                    templateInfo = this.makeTemplateInfo( ...
                        props.Identifier, templatePath, 'pdf');
                    this.PDFTemplateInfoMap(props.Identifier) = templateInfo;
                end
            end
        end
        
        function template = getTemplate(this, id)
            %GETTEMPLATE Gets a template specified by id
            %    getTemplate(cache, id) returns the template specified by
            %    id. If a Word and a HTML (or PDF) template have the same id,
            %    this method returns the Word template.
            template = getDOCXTemplate(this, id);
            if isempty(template)
                template = getHTMLTemplate(this, id);
                if isempty(template)
                    template = getPDFTemplate(this, id);
                    if isempty(template)
                        template = getHTMLFileTemplate(this, id);
                    end
                end
            end
        end
        
        function templateInfo = getTemplateInfo(this, id, format)
            %GETTEMPLATEINFO Gets a template info specified by id and
            %the output format
            %    getTemplateInfo(cache, id, format) returns the template  
            %    info specified by id and the format.
            %    The template info is a data struct with fields:
            %       Identifier         The template id
            %       TemplatePath       The template path
            %       Type               The template type ('docx','html','pdf','html-file')
            %       HolesInfo          Holes info returned by the template 
            %                          parser
            %       DocumentPartsInfo  DocumentParts info returned by the
            %                          template parser
            %       TimeStamp          Time stamp structure to check when 
            %                          is required to reparse the template.
            
            templateInfo = '';
            switch format
                case {'dom-docx', 'dom-pdf'}
                    templateInfo = getDOCXTemplateInfo(this, id);
                case 'dom-htmx'
                    templateInfo = getHTMLTemplateInfo(this, id);
                case {'dom-pdf-direct','dom-pdfa-direct'}
                    templateInfo = getPDFTemplateInfo(this, id);
                case 'dom-html-file'
                    templateInfo = getHTMLFileTemplateInfo(this, id);
            end
            
            if ~isempty(templateInfo)     
                % Get template filesystem info in an M-by-1 structure
                D = dir(templateInfo.TemplatePath);

                % Reset time stamp when it is different to D
                if ~isempty(templateInfo.TimeStamp)
                    if ~isequal(D, templateInfo.TimeStamp)
                        templateInfo.TimeStamp = [];
                    end
                end

                % If TimeStamp is empty, parse the template
                if isempty(templateInfo.TimeStamp)
                    tempPath = fullfile(tempdir, 'dummy');
                    dummy = mlreportgen.dom.Document(tempPath, ...
                        templateInfo.Type, templateInfo.TemplatePath);
                    parseTemplate(dummy);
                    templateInfo.HolesInfo = dummy.HolesInfo;
                    templateInfo.DocumentPartsInfo = dummy.DocumentPartsInfo;
                    % Set time stamp to D and update the template info maps
                    templateInfo.TimeStamp = D;
                    switch(templateInfo.Type)
                        case 'docx'
                            this.DOCXTemplateInfoMap(templateInfo.Identifier) = ...
                                templateInfo;
                        case 'html'
                            this.HTMLTemplateInfoMap(templateInfo.Identifier) = ...
                                templateInfo;
                        case 'html-file'
                            this.HTMLFileTemplateInfoMap(templateInfo.Identifier) = ...
                                templateInfo;
                        case 'pdf'
                            this.PDFTemplateInfoMap(templateInfo.Identifier) = ...
                                templateInfo;
                    end
                end
                
            end
        end
                
        function identifier = getCopiedUniqueId(this, id)
            %GETCOPIEDUNIQUEID Gets a unique copied template id
            %    getCopiedUniqueId(cache, id) returns the unique copied
            %    id. For example, If id value is 'default-rg-html' this
            %    function will return 'copy of default-rg-html'. If it was
            %    copied before, it will return 'copy 2 of default-rg-html'
            identifier = getString(message( ... 
                'rptgen:RptgenML_DB2DOMTemplateEditor:copyOfIdentifier', ...
                '', id));
            index = 1;
            template = getTemplate(this, identifier);
            while ~isempty(template)
                index = index + 1;
                identifier = getString(message( ... 
                    'rptgen:RptgenML_DB2DOMTemplateEditor:copyOfIdentifier', ...
                    [' ' num2str(index)], id));
                template = getTemplate(this, identifier);
            end
    
        end
        
        
        function template = getHTMLTemplate(this, id)
            %GETHTMLTEMPLATE Gets an HTML template specified by id
            %    getHTMLTemplate(cache, id) returns the HTML template
            %    specified by id.
            if isKey(this.HTMLTemplateMap, id)
                template = this.HTMLTemplateMap(id);
            else
                template = [];
            end
        end
        
        function template = getHTMLFileTemplate(this, id)
            %GETHTMLFileTEMPLATE Gets an HTML template specified by id
            %    getHTMLFileTemplate(cache, id) returns the HTML template
            %    specified by id.
            if isKey(this.HTMLFileTemplateMap, id)
                template = this.HTMLFileTemplateMap(id);
            else
                template = [];
            end
        end
        
        function template = getDOCXTemplate(this, id)
            %GETDOCXTEMPLATE Gets a Word template specified by id
            %    getDOCXTemplate(cache, id) returns the HTML template
            %    specified by id.
            if isKey(this.DOCXTemplateMap, id)
                template = this.DOCXTemplateMap(id);
            else
                template = [];
            end
        end
        
        function template = getPDFTemplate(this, id)
            %GETPDFTEMPLATE Gets a PDF template specified by id
            %    getPDFTemplate(cache, id) returns the PDF template
            %    specified by id.
            if isKey(this.PDFTemplateMap, id)
                template = this.PDFTemplateMap(id);
            else
                template = [];
            end
        end
        
        function templateInfo = getHTMLTemplateInfo(this, id)
            %GETHTMLTEMPLATE Gets an HTML templateInfo specified by id
            %    getHTMLTemplateInfo(cache, id) returns the HTML templateInfo
            %    specified by id.
            if isKey(this.HTMLTemplateInfoMap, id)
                templateInfo = this.HTMLTemplateInfoMap(id);
            else
                templateInfo = [];
            end
        end
        
        function templateInfo = getHTMLFileTemplateInfo(this, id)
            %GETHTMLFILETEMPLATE Gets an HTML templateInfo specified by id
            %    getHTMLFileTemplateInfo(cache, id) returns the HTML templateInfo
            %    specified by id.
            if isKey(this.HTMLFileTemplateInfoMap, id)
                templateInfo = this.HTMLFileTemplateInfoMap(id);
            else
                templateInfo = [];
            end
        end
        
        function templateInfo = getDOCXTemplateInfo(this, id)
            %GETDOCXTEMPLATE Gets a Word templateInfo specified by id
            %    getDOCXTemplateInfo(cache, id) returns the HTML templateInfo
            %    specified by id.
            if isKey(this.DOCXTemplateInfoMap, id)
                templateInfo = this.DOCXTemplateInfoMap(id);
            else
                templateInfo = [];
            end
        end
        
        function templateInfo = getPDFTemplateInfo(this, id)
            %GETPDFTEMPLATE Gets a PDF templateInfo specified by id
            %    getPDFTemplateInfo(cache, id) returns the PDF templateInfo
            %    specified by id.
            if isKey(this.PDFTemplateInfoMap, id)
                templateInfo = this.PDFTemplateInfoMap(id);
            else
                templateInfo = [];
            end
        end       
        
        function uncacheTemplate(this, templatePath)
            %UNCACHETEMPLATE Removes a template from the cache
            %   uncacheTemplate(cache, templatePath) removes the template
            %   specified by templatePath from the cache.
            [~,~, ext] = fileparts(templatePath);
            
            switch ext
                case {'.dotx', '.DOTX'}
                    uncacheDOCXTemplate(this, templatePath);
                case {'.htmtx', '.HTMTX'}
                    uncacheHTMLTemplate(this, templatePath);
                case {'.htmt', '.HTMT'}
                    uncacheHTMLFileTemplate(this, templatePath);
                case {'.pdftx', '.PDFTX'}
                    uncachePDFTemplate(this, templatePath);
            end
        end
        
        function uncacheDOCXTemplate(this, templatePath)
            %UNCACHEDOCXTEMPLATE Removes a Word template from the cache
            %   uncacheDOCXTemplate(cache, templatePath) removes the Word
            %   template specified by templatePath from the cache.
            if rptgen.db2dom.TemplateCache.isTemplateReadable(templatePath)
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                remove(this.DOCXTemplateMap, props.Identifier);
                remove(this.DOCXTemplateInfoMap, props.Identifier);
            end
        end
        
        function uncacheDOCXTemplateById(this, id)
            %UNCACHEDOCXTEMPLATEBYID Removes a Word template from the cache
            %   uncacheDOCXTemplateById(cache, id) removes the Word
            %   template specified by id from the cache.
            remove(this.DOCXTemplateMap, id);
            remove(this.DOCXTemplateInfoMap, id);
        end
        
        function uncacheHTMLTemplate(this, templatePath)
            %UNCACHEHTMLTEMPLATE Removes an HTML template from the cache
            %   uncacheHTMLTemplate(cache, templatePath) removes the HTML
            %   template specified by templatePath from the cache.
            if rptgen.db2dom.TemplateCache.isTemplateReadable(templatePath)
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                remove(this.HTMLTemplateMap, props.Identifier);
                remove(this.HTMLTemplateInfoMap, props.Identifier);
            end
        end
        
        function uncacheHTMLTemplateById(this, id)
            %UNCACHEHTMLTEMPLATEBYID Removes an HTML template from the cache
            %   uncacheHTMLTemplateById(cache, id) removes the HTML
            %   template specified by id from the cache.
            remove(this.HTMLTemplateMap, id);
            remove(this.HTMLTemplateInfoMap, id);
        end
        
        function uncacheHTMLFileTemplate(this, templatePath)
            %UNCACHEHTMLFILETEMPLATE Removes an HTML template from the cache
            %   uncacheHTMLFileTemplate(cache, templatePath) removes the HTML
            %   template specified by templatePath from the cache.
            if rptgen.db2dom.TemplateCache.isTemplateReadable(templatePath)
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                remove(this.HTMLFileTemplateMap, props.Identifier);
                remove(this.HTMLFileTemplateInfoMap, props.Identifier);
            end
        end
        
         function uncacheHTMLFileTemplateById(this, id)
            %UNCACHEHTMLFILETEMPLATEBYID Removes an HTML template from the cache
            %   uncacheHTMLFileTemplateById(cache, id) removes the HTML
            %   template specified by id from the cache.
            remove(this.HTMLFileTemplateMap, id);
            remove(this.HTMLFileTemplateInfoMap, id);
        end
        
        function uncachePDFTemplate(this, templatePath)
            %UNCACHEPDFTEMPLATE Removes a PDF template from the cache
            %   uncachePDFTemplate(cache, templatePath) removes the PDF
            %   template specified by templatePath from the cache.
            if rptgen.db2dom.TemplateCache.isTemplateReadable(templatePath)
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                remove(this.PDFTemplateMap, props.Identifier);
                remove(this.PDFTemplateInfoMap, props.Identifier);
            end
        end
        
        function uncachePDFTemplateById(this, id)
            %UNCACHEPDFTEMPLATEBYID Removes a PDF template from the cache
            %   uncachePDFTemplateById(cache, id) removes the PDF
            %   template specified by id from the cache.
            remove(this.PDFTemplateMap, id);
            remove(this.PDFTemplateInfoMap, id);
        end
        
        function templates = getHTMLTemplates(this)
            %GETHTMLTEMPLATES Returns paths of HTML templates in the cache
            %   getHTMLTemplates(cache) returns a cell array of the paths
            %   of the HTML templates in the cache.
            templates = values(this.HTMLTemplateMap);
        end
        
         function templates = getHTMLFileTemplates(this)
            %GETHTMLFILETEMPLATES Returns paths of HTML templates in the cache
            %   getHTMLFileTemplates(cache) returns a cell array of the paths
            %   of the HTML templates in the cache.
            templates = values(this.HTMLFileTemplateMap);
        end
        
        function templates = getDOCXTemplates(this)
            %GETDOCXTEMPLATES Returns paths of Word templates in the cache
            %   getDOCXTemplates(cache) returns a cell array of the paths
            %   of the Word templates in the cache.
            templates = values(this.DOCXTemplateMap);
        end
        
        function templates = getPDFTemplates(this)
            %GETPDFTEMPLATES Returns paths of PDF templates in the cache
            %   getPDFTemplates(cache) returns a cell array of the paths
            %   of the PDF templates in the cache.
            templates = values(this.PDFTemplateMap);
        end
        
        function cacheDOCXTemplateCopy(this, templateCopy)
            %CACHEDOCXTEMPLATECOPY Caches a copy of a Word template
            %   cacheDOCXTemplateCopy(cache, templateCopyPath) caches
            %   a temporary copy of a Word template. This method is used
            %   by the Report Explorer's template editor to cache a
            %   temporary copy of an open Word template for use by the
            %   rpt_xml.db_output.convertReport method.
            this.DOCXTemplateCopy = templateCopy;
        end
        
        function discardDOCXTemplateCopy(this)
            %DISCARDDOCXTEMPLATECOPY Discards the temporary template copy
            %   discardDOCXTemplateCopy(cache) deletes the template copy
            %   file and removes the template from the cache. 
            %   See rpt_xml.db_output.convertReport for more information.
            delete(this.DOCXTemplateCopy);
            this.DOCXTemplateCopy = [];
        end
        
        function templateCopy = getDOCXTemplateCopy(this)
            %GETDOCXTEMPLATECOPY Gets the temporary template copy
            %   getDOCXTemplateCopy(cache) gets the temporarily cached Word
            %   template copy. See rpt_xml.db_output.convertReport for more
            %   information.
            templateCopy = this.DOCXTemplateCopy;
        end
        
        function yn = hasDOCXTemplateCopy(this)
            %HASDOCXTEMPLATECOPY Returns true if a template copy exists
            %   hasDOCXTemplateCopy(cache) returns true if the cache has a
            %   temporary copy of a Word template.  See
            %   rpt_xml.db_output.convertReport for more information.
            yn = ~isempty(this.DOCXTemplateCopy);
        end
                
    end
    
    methods (Access = protected)
        
        function this = TemplateCache()
            %TEMPLATECACHE Constructs an instance of the cache
            %    cache = TemplateCache creates an instance of the
            %    template cache. The cache initially contains the 
            %    Report Generator's builtin db2dom templates and any
            %    templates found in the current directory and on the
            %    MATLAB path.
            if ~isempty(this.DOCXTemplateMap)
                this.DOCXTemplateMap = containers.Map;
            end
            if ~isempty(this.HTMLTemplateMap)
                this.HTMLTemplateMap = containers.Map;
            end
            if ~isempty(this.HTMLFileTemplateMap)
                this.HTMLFileTemplateMap = containers.Map;
            end
            if ~isempty(this.PDFTemplateMap)
                this.PDFTemplateMap = containers.Map;
            end
            
            % Initialize TemplateInfo maps
            this.DOCXTemplateInfoMap = containers.Map;
            this.HTMLTemplateInfoMap = containers.Map;
            this.HTMLFileTemplateInfoMap = containers.Map;
            this.PDFTemplateInfoMap = containers.Map;
            
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/docx/docbook.dotx'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/docx/docbook-numbered.dotx'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/html/docbook.htmt'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/html/docbook-numbered.htmt'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/html/docbook.htmtx'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/html/docbook-numbered.htmtx'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/html/docbook-multipage.htmtx'));
            % cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
            %     'base/resources/templates/html/docbook-multipage-numbered.htmtx')); % Support in g3199589
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/pdf/docbook.pdftx'));
            cacheTemplate(this, fullfile(toolboxdir('shared/mlreportgen'), ...
                'base/resources/templates/pdf/docbook-numbered.pdftx'));
            findTemplates(this);
            this.hasCache(true);
        end
        
        function findTemplates(this)
            %FINDTEMPLATES Searches the filesystem for templates
            %   findTemplates(cache) searches the current working
            %   directory and the MATLAB path for Word and HTML templates
            %   and adds them to the cache.
            pSep=pathsep;
            if this.setgetShowProgressBar
                hWaitBar = waitbar(0, ...
                    getString(message('rptgen:RptgenML_DB2DOMTemplateBrowser:buildingTemplateLibraryLabel')), ....
                    'Name', getString(message('rptgen:RptgenML:ReportGeneratorLabel')));
            else
                hWaitBar = [];
            end
            % Search the current directory and the MATLAB path for
            % templates
            if ~contains(lower(path), [lower(pwd) pSep])
                pathString=[pSep pwd pSep path pSep];
            else
                pathString=[pSep path pSep];
            end
            
            breakIndex = strfind(pathString, pSep);
            
            lastIndex=length(breakIndex)-1;
            dirIdx=1;

            CONTINUE_SEARCH = true;
            
            templateExt = [".dotx"; ".htmtx"; ".htmt"; ".pdftx"];
            if ~ispc
                templateExtUpperCase = [".DOTX"; ".HTMTX"; ".HTMT"; ".PDFTX"];
                templateExt = vertcat(templateExt, templateExtUpperCase);
            end
            
            while dirIdx<=lastIndex && CONTINUE_SEARCH
                myDir=pathString(breakIndex(dirIdx)+1:breakIndex(dirIdx+1)-1);
                
                fileList = '';
                for i=1:numel(templateExt)
                    searchTerm = [filesep,'*',char(templateExt(i))];
                    fileList = [fileList; dir([myDir searchTerm])]; %#ok
                end
                
                if ~isempty(fileList)
                    for fileIdx=1:length(fileList)
                        fileName = fileList(fileIdx).name;
                        if strcmp(fileName(1:2), '~$') % Skip stray ~$NAME.dotx files
                            continue;
                        end
                        cacheTemplate(this, fullfile(myDir, fileName));
                    end
                end
                dirIdx=dirIdx+1;
                
                if (~isempty(hWaitBar) && ishandle(hWaitBar))
                    waitbar(dirIdx/lastIndex, hWaitBar);
                end
            end
            
            if ~isempty(hWaitBar)
                delete(hWaitBar);
            end
        end
    end
    
    methods (Static)
        
        function cache = getTheCache(varargin)
            %GETTHECACHE Gets the cache singleton.
            %    rptgen.db2dom.TemplateCache.getTheCache returns the 
            %    cache singleton if it exists. If the cache does not exist,
            %    this function first creates the cache.
            %    
            %    rptgen.db2dom.TemplateCache.getTheCache(true) creates
            %    and returns a new instance of the cache.
            
            persistent TheCache;
            
            if isempty(varargin)
                refresh = false;
            else
                refresh = varargin{1};
            end
            
            if isempty(TheCache) || refresh
                TheCache = rptgen.db2dom.TemplateCache();
            end
            
            cache = TheCache;
            
        end
        
        function yn = hasCache(varargin)
            %HASCACHE Has template cache
            %
            %    rptgen.db2dom.TemplateCache.hasCache()
            %    returns true if template cache has been built
            
            persistent hasCache
            
            if isempty(hasCache)
                hasCache = false;
            end
            if nargin
                hasCache = varargin{1};
            end
            yn = hasCache;
        end
        
        function yn = setgetShowProgressBar(varargin)
            %SETGETSHOWPROGRESSBAR Show progress bar while updating template cache
            %
            %    rptgen.db2dom.TemplateCache.setgetShowProgressBar(true)
            %    show progress bar while updating template cache
            %
            %    rptgen.db2dom.TemplateCache.setgetShowProgressBar(false)
            %    do not show progress bar while updating template cache
            
            persistent showProgressBar
            
            if isempty(showProgressBar)
                showProgressBar = false;
            end
            
            if nargin
                showProgressBar = varargin{1};
            end
            yn = showProgressBar;
        end
        
        
        function yn = isTemplateBuiltin(templPath)
            %ISTEMPLATEBUILTIN Determine whether a template is builtin
            %    rptgen.db2dom.TemplateCache.isTemplateBuiltin(templPath)
            %    returns true if the template specified by templPath
            %    resides in a MATLAB toolbox directory.
            %    
            [templateDirPath,~,~] = fileparts(fullfile(templPath));
            toolboxDir = toolboxdir('');
            yn = contains(templateDirPath, toolboxDir);
        end
        
        function yn = isTemplateReadable(templatePath)
            %ISTEMPLATEREADABLE Returns true if template is readable
            %    A template is considered to be always readable on a Unix
            %    system. On Windows, it is considered readable if it is in
            %    the MATLAB toolbox direcory, is read-only, or is not open
            %    in some other application.
            %
            %    Note: This method considers templates in the toolbox
            %    directory to be readable because the MATLAB installer
            %    installs them as writable but does not allow the MATLAB
            %    fopen command (used to test readability) to open them
            %    regardless of whether they are actually open.
            yn = true;
            if ~isdeployed && ispc
                yn = false;
                if rptgen.db2dom.TemplateCache.isTemplateBuiltin(templatePath)
                    yn = true;
                else
                    [~, attribs] = fileattrib(templatePath);
                    % if templatePath is not in the filesystem, attribs is
                    % not a valid struct and attribs.UserWrite property 
                    % throw an error
                    if isstruct(attribs)
                        if attribs.UserWrite
                            [fileID, ~] = fopen(templatePath, 'r+');
                            if fileID > 0
                                yn = true;
                                fclose(fileID); % Need to relinquish handle
                            end
                        else
                            % Template is read-only and hence readable even if it
                            % is open in another application.
                            yn = true;
                        end
                    else
                        % fileattrib does not return a valid struct and it
                        % is not possible to read
                        yn = false;
                    end
                end
            end
        end

        function identifier = getTemplateId(templatePath)
            %GETTEMPLATEID Returns the identifier stored in the
            %template core properties.
            identifier = [];
            if rptgen.db2dom.TemplateCache.isTemplateReadable(templatePath)
                props = mlreportgen.dom.Document.getCoreProperties(templatePath);
                identifier = props.Identifier;
            end            
        end
        
        function templateInfo = makeTemplateInfo(identifier, templatePath, type)
            templateInfo = struct();
            templateInfo.Identifier = identifier;
            templateInfo.TemplatePath = templatePath;
            templateInfo.Type = type;
            templateInfo.HolesInfo = [];
            templateInfo.DocumentPartsInfo = [];
            templateInfo.TimeStamp = [];
        end
        
    end
    
    properties (Access = private)
        
        DOCXTemplateMap = containers.Map;
        
        HTMLTemplateMap = containers.Map;
        
        HTMLFileTemplateMap = containers.Map;
        
        PDFTemplateMap = containers.Map;
        
        DOCXTemplateInfoMap = containers.Map;
        
        HTMLTemplateInfoMap = containers.Map;
        
        HTMLFileTemplateInfoMap = containers.Map;
        
        PDFTemplateInfoMap = containers.Map;
        
        
        DOCXTemplateCopy;
        
    end
    
end