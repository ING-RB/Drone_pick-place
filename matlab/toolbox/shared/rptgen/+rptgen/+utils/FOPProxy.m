classdef FOPProxy < handle
    %FOPPROXY Configures and invokes Apache FOP
    %   This class provides methods for configuring and invoking Apache's
    %   FO processor to convert FO markup to PDF.
    %
    %   FOPProxy methods:
    %
    %   foToPDF           - Converts an FO file to PDF (static method)
    %   newFOP            - Chain content XML to FO XML to PDF conversion
    %   getLocaleFonts    - Computes basic fonts based on locale (static method)
    %
    
    %   Copyright 2015-2024 The MathWorks, Inc.
    
    properties (Constant, Access = private)
        ConfigurationFile = fullfile(toolboxdir('shared/rptgen'), ...
            '@rpt_xml/@db_output/fop_config.xml');
        HyphenationBasePath = fullfile(toolboxdir('shared/rptgen'), ...
            'resources/hyph');
        DefaultHyphenationFile = fullfile(toolboxdir('shared/rptgen'), ...
            'resources/hyph/default.xml');
        % Report Generator fonts are included by the MCR, so base path is 
        % MATLABROOT for normal and compiled mode.
        BaseFontPath = fullfile(matlabroot(), 'toolbox', 'shared', 'mlreportgen',...
            'dom/resources/fonts');
        UserFontPath = fullfile(prefdir(), 'fop_fonts');
    end
    
    properties (Access = private)
        m_fopFactory;
        m_transformerFactory;
        m_langFontMap;
    end
    
    methods (Static)
        function foToPDF(foPath, pdfPath, varargin)
            %FOTOPDF Convert an FO XML file to a PDF file
            %    foToPDF(foPath, pdfPath, locale) configures the FOP to 
            %    use the fonts specified by the Report Generator's font 
            %    mapping and FOP configuration files based on locale and 
            %    platform. 
            %    It next invokes FOP to convert the FO XML file located at 
            %    foPath to a PDF file located at pdfPath. Finally, it 
            %    deletes the directories created by font configuration.
            %
            %    foToPDF(foPath, pdfPath, locale, false) retains the 
            %    directories created by font configuration.
            %
            %    This method by default configures the FOP to minimize
            %    the logging messages that it produces. You can cause this
            %    method to configure the FOP to generate debug log messages
            %    by setting the DebugMode property of the Report
            %    Generator's rptgen.appdate_rg object to true.
            %
            %    Example
            %
            %    rptgen.utils.FOPProxy.foToPDF('myreport.fo', 'myreport.pdf', 'en');
            %    rptview('myreport.pdf');

            adRG = rptgen.appdata_rg();
            
            if isempty(getenv('USE_FOP'))
                mlreportgen.internal.fop.foToPDF( ...
                    foPath, ...
                    pdfPath, ...
                    'DebugMode', adRG.DebugMode);
                return;
            end
            
            h = rptgen.utils.FOPProxy.getInstance();
            
            % Get locale
            if ((nargin > 2) && ~isempty(varargin{1}))
                locale = varargin{1};
            else
                locale = adRG.Language;
            end
            
            % Fonts to include (not necessary if we turn on auto-detect)
            if (nargin > 3)
                extraFonts = varargin{2};
            else
                extraFonts = {};
            end
            
            % Cleanup fop font directories
            if (nargin > 4)
                cleanupFonts = varargin{3};
            else
                cleanupFonts = false;
            end
            
            foToPDFImpl(h, foPath, pdfPath, locale, extraFonts, cleanupFonts);
        end
        
        function [fop, fopOutputStream] = newFOP(pdfPath, locale)
            %NEWFOP Creates a FOP instance 
            %    newFOP(pdfPath, locale) creates a new FOP instance that is 
            %    configured to use the fonts specified by the Report Generator's 
            %    font mapping and FOP configuration files. It then configures 
            %    the FOP to generate PDF at the location specified pdfPath. 
            %    Finally, it returns the FOP and the pdf output stream.
            %
            %    This method is intended to be used to chain conversion
            %    from content XML to FO XML to PDF. 
            % 
            %    Example, see rpt_xml.db_output.convertReport
            
            % Check locale
            if isempty(locale)
                adRG = rptgen.appdata_rg();
                locale = adRG.Langage;
            end
            
            % Set base path to be the same as the PDF file.
            h = rptgen.utils.FOPProxy.getInstance();
            
            [basePath, pdfName, pdfExt] = fileparts(pdfPath);
            if isempty(basePath)
                basePath = pwd;
            end
            pdfFullPath = fullfile(basePath, [pdfName pdfExt]);
            
            fopOutputStream = java.io.BufferedOutputStream ...
                (java.io.FileOutputStream(pdfFullPath));
            fop = newFOPImpl(h, fopOutputStream, basePath, locale, {});
        end
        
        function fonts = getLocaleFonts(locale)
            % DEPRECATED, called by CSSParser.cpp
            fonts = rptgen.utils.LanguageFontMap.getFontNamesForAllUsages(locale);
        end
        
        function cleanupFontDirectory()
            h = rptgen.utils.FOPProxy.getInstance();
            cleanupFontDirectoryImpl(h);
        end
    end
    
    methods (Static, Access = private)
        function instance = getInstance()
            %GETINSTANCE  Get an instance of FOPProxy
            %   instance = rptgen.utils.FOPProxy.getInstance()
            
            persistent INSTANCE;
            if isempty(INSTANCE)
                INSTANCE = rptgen.utils.FOPProxy();
            end
            instance = INSTANCE;
        end        
    end
    
    methods (Access = private)
        function h = FOPProxy()
            % Create and initialize FopFactory
            fopFactory = com.mathworks.hg.print.MWFopFactory( ...
                com.mathworks.toolbox.rptgencore.tools.ResourceResolverRG());

            % Apply fop config, setting in here may be overriddent by the 
            % following calls to setup FOP
            fopFactory.applyConfigurationFile(h.ConfigurationFile);
            
            % Override base path to rptgen font directory to allow for font
            % substitution.
            origFontBasePath = fopFactory.getFontBasePath();
            fopFactory.setFontBasePath(h.BaseFontPath);
            fopFactory.addUserFontPath(origFontBasePath, true); % recurse
            
            fopFactory.setAutoDetectFonts(true);
            fopFactory.setFontCacheEnabled(true);
            fopFactory.setHyphenationBasePath(h.HyphenationBasePath);
            fopFactory.setDefaultHyphenationFile(h.DefaultHyphenationFile);
            
            h.m_fopFactory = fopFactory;
            h.m_transformerFactory = javax.xml.transform.TransformerFactory.newInstance();
            h.m_langFontMap = rptgen.utils.LanguageFontMap.getInstance();
        end

        function foToPDFImpl(h, foPath, pdfPath, locale, extraFonts, cleanupFontDirectory)
            % Set base path to be the same as the FO file.
            basePath = fileparts(foPath);
            if isempty(basePath)
                basePath = pwd;
                foFullPath = fullfile(pwd, foPath);
            else
                foFullPath = foPath;
            end
            % Setup listener we are not getting any FOP errors
            errorListener = com.mathworks.toolbox.rptgencore.tools.TransformErrorListenerRG();

            % Resolve pdfPath
            [pdfParentPath, pdfPathName, pdfPathExt] = fileparts(pdfPath);
            if isempty(pdfParentPath)
                pdfParentPath = pwd;
            end
            pdfFullPath = fullfile(pdfParentPath, [pdfPathName pdfPathExt]);
            
            % Create FOP
            fopOutputStream = java.io.BufferedOutputStream(java.io.FileOutputStream(pdfFullPath));
            fop = newFOPImpl(h, fopOutputStream, basePath, locale, extraFonts);
            
            % Setup input
            src = javax.xml.transform.stream.StreamSource(java.io.File(foFullPath));
            res = javax.xml.transform.sax.SAXResult(getDefaultHandler(fop));
            
            % Convert via XML transformation
            xform = h.m_transformerFactory.newTransformer();
            xform.setErrorListener(errorListener);
            xform.transform(src, res);
            
            % Close
            fopOutputStream.close();        
            
            % cleanup
            if cleanupFontDirectory
                cleanupFontDirectoryImpl(h);
            end
        end
        
        function fop = newFOPImpl(h, fopOutputStream, basePath, locale, extraFonts)
            if isempty(locale)
                locale = get(0, 'Language');
            end
        
            % Set base path to be the same as the PDF file.
            fopFactory = h.m_fopFactory;
            fopFactory.setBasePath(basePath);
            
            % Setup locale fonts
            fopFactory.setLocale(locale);
            % we don't really need to do this if we enable auto font detection
            if ~h.m_fopFactory.isAutoDetectFonts()
                copyLocaleFonts(h, locale, extraFonts);
            end

            
            % Set logger
            fopLogger = com.mathworks.hg.print.MWFopLogger();
            ap = rptgen.appdata_rg;
            if ap.DebugMode
                fopLogger.setLevel(fopLogger.LogLevelDebug);
            else
                fopLogger.setLevel(fopLogger.LogLevelError);
            end
            
            % Create FOP
            fop = fopFactory.newFop(fopOutputStream);
            
            % Add FOP event listener to push messages to rptgen message viewer.  If 
            % we don't add an event listener FOUserAgent push messages to the console.
            ua = fop.getUserAgent();
            ua.getEventBroadcaster().addEventListener( ...
                com.mathworks.toolbox.rptgencore.tools.FOPEventListener());
        end
        
        function cleanupFontDirectoryImpl(h)
            fontDir = h.UserFontPath;
            delete(fullfile(fontDir, '*.*'));
        end
        
        function copyLocaleFonts(h, locale, extraFonts)
            % Internal Font directory
            destFontDir = h.UserFontPath;
            
            % Get all fonts for a given given locale
            langFontMap = h.m_langFontMap;
            fontNames = unique(struct2cell( ...
                langFontMap.getFontNamesForAllUsages(locale)));
            fontNames = unique([fontNames(:)' extraFonts(:)']);
            
            % Copy all fonts to destination directory
            nFontNames = numel(fontNames);
            for i = 1:nFontNames
                fontName = fontNames{i};
                
                % Font names may be contained in multiple files.  For example, 
                % one for bold, one for italic.
                fontFullFiles = getFontFullFiles(langFontMap, fontName);
                nFontFullFiles = numel(fontFullFiles);
                for j = 1:nFontFullFiles
                    fontFullFile = fontFullFiles{j};

                    % Get font file name
                    [~, fontFileName, fontFileExt] = fileparts(fontFullFile);

                    % If font file does not exist in destination directory, copy it
                    destFontFullFile = fullfile(destFontDir, [fontFileName fontFileExt]);
                    if ~exist(destFontFullFile, 'file')
                        copyfile(fontFullFile, destFontFullFile, 'f');
                    end
                end
            end
        end
    end
end
