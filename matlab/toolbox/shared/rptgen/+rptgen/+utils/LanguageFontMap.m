classdef LanguageFontMap < handle
	%LANGUAGEFONTMAP provides a way to map various languages to fonts that support 
    %   character sets for those languages.
            
    %   Copyright 2016-2022 The MathWorks, Inc.
    
    properties (SetAccess = private)
        % Default font map file location
        DefaultFontMapFile = fullfile(toolboxdir('shared/rptgen'), ...
            'resources', 'fontmap', 'lang_font_map.xml');
        FontDirs;
    end
    
    properties (Access = private)
        m_fontMap;
        m_fileMap;
    end
    
    methods (Static)
        function instance = getInstance()
            %GETINSTANCE  Get an instance of LanguageFontMap
            %   instance = rptgen.utils.LanguageFontMap.getInstance()
            
            persistent INSTANCE;
            if isempty(INSTANCE)
                INSTANCE = rptgen.utils.LanguageFontMap();
            end
            instance = INSTANCE;
        end
        
        function key = getPlatformKey()
            %GETPLATFORMKEY  Get platform key to get/set font map
            %   platformKey = rptgen.utils.LanguageFontMap.getPlatformKey()
            %
            %   On PC, this function returns win
            %   On mac, this function returns mac
            %   On linux, this function returns glnx
            
            if ispc()
                key = 'win';
            elseif ismac()
                key = 'mac';
            else % linux
                key = 'glnx';
            end
        end
        
        function fonts = getFontNamesForAllUsages(varargin)
            %GETFONTNAMES Computes basic fonts based on locale/language for all usage
            %    fonts = rptgen.utils.LanguageFontMap.getFontNames(locale) 
            % 
            %    Get fonts specified based on locale and platform.

            instance = rptgen.utils.LanguageFontMap.getInstance();
            fonts = struct( ...
                'body', getFontName(instance, 'body', varargin{:}), ...
                'monospace', getFontName(instance, 'monospace', varargin{:}), ...
                'sans', getFontName(instance, 'sans', varargin{:}), ...
                'title', getFontName(instance, 'title', varargin{:}));
        end
    end
    
    methods
        function reset(h, varargin)
            %RESET reset language font map
            %   reset(h)
            %   reset(h, fontMapFile)
            
            if (nargin == 2)
                fontMapFile = varargin{1};
            else
                fontMapFile = h.DefaultFontMapFile;
            end
            
            try
                docNode = h.parseXmlFile(fontMapFile);
            catch ME
                error(message('rptgen:rx_db_output:invalidFontMap', fontMapFile));
            end
            
            % Reset font search directories
            h.FontDirs = h.getFontDirectories();
            
            % Reset font map
            h.m_fontMap = containers.Map();
            
            % Read name_mapping elements
            nameMappingNodes = docNode.getElementsByTagName('name_mapping');
            nNameMappings = nameMappingNodes.getLength();

            % Go through name_mapping elements
            for i = 1:nNameMappings 
                nameMappingNode = nameMappingNodes.item(i-1);  % java list is zero-based
                
                lang = char(nameMappingNode.getAttribute('lang'));
                platform = char(nameMappingNode.getAttribute('platform'));
                usage = char(nameMappingNode.getAttribute('usage'));
                font = char(nameMappingNode.getTextContent());
                    
                fontMapKey = h.getFontMapKey(lang, platform, usage);
                h.m_fontMap(fontMapKey) = font;
            end
            
            % Reset font file map;
            h.m_fileMap = containers.Map();
            
            % Read file_mapping elements
            fileMappingNodes = docNode.getElementsByTagName('file_mapping');
            nFileMappings = fileMappingNodes.getLength();
            
            for i = 1:nFileMappings
                fileMappingNode = fileMappingNodes.item(i-1); % java list is zero-based
                platform = char(fileMappingNode.getAttribute('platform'));
                fontName = char(fileMappingNode.getAttribute('name'));
                
                fontNodes = fileMappingNode.getElementsByTagName('font');
                nFonts = fontNodes.getLength();
                if (nFonts == 0)
                    fontFiles = {char(fileMappingNode.getTextContent())};
                else
                    fontFiles = {};
                    for j = 1:nFonts
                        fontNode = fontNodes.item(j-1); % java list is zero-based
                        file = char(fontNode.getTextContent());
                        fontFiles = [fontFiles; file]; %#ok
                    end
                end
                
                fileMapKey = h.getFileMapKey(platform, fontName);
                h.m_fileMap(fileMapKey) = fontFiles;
            end
        end
        
        function fontName = getFontName(h, usage, varargin)
            %GETFONTNAME Returns the appropriate/default font name
            %   getFontName(h, usage) 
            %   getFontName(h, usage, lang) 
            %   getFontName(h, usage, lang, platform) 
            %
            %   Finds and returns font name given usage (e.g., title, body, 
            %   monospaced, etc.), language (optional) and platform (optional)
            
            fontName = getFontNameFromMap(h, usage, varargin{:});

            if isempty(fontName)
                % Default to english font, usually the noto fonts
                if numel(varargin) > 1
                    platform = varargin{2};
                else
                    platform = h.getPlatformKey();
                end
                fontName = getFontNameFromMap(h, usage, 'en', platform);

                % Use builtin FOP font, as last resort.  May happen if user
                % removes the english entries.
                if isempty(fontName)
                    switch usage
                        case 'body'
                            fontName = 'serif';
                        case 'monospace'
                            fontName = 'monospace';
                        otherwise %san, title
                            fontName = 'serif';
                    end
                end
            end
        end
        
        function fontFiles = getFontFiles(h, fontName, varargin)
            %GETFONTFILES  Return the appropriate/default font files 
            %   getFontFiles(h, fontName)
            %   getFontFiles(h, fontName, platform)
            %   Returns the appropriate/default font files for current platform or
            %   for a given platform
            
            fontFiles = {};
            if (nargin == 3)
                platform = varargin{1};
            else
                platform = h.getPlatformKey();
            end
            
            fileMapKey = h.getFileMapKey(platform, fontName);
            if isKey(h.m_fileMap, fileMapKey)
                fontFiles = h.m_fileMap(fileMapKey);
            end
        end
        
        function fontFullFiles = getFontFullFiles(h, fontName)
            %GETFONTFILES  Return the appropriate/default font full file names
            %   GETFONTFILES(H, FONTNAME)
            %   Return the appropriate/default font full file names for the current 
            %   platform

            fontFullFiles = {};
            nFontDirectories = numel(h.FontDirs);
            
            fontFiles = getFontFiles(h, fontName);
            nFontFiles = numel(fontFiles);

            % Go through each font file name and try to get its full file name
            for i = 1:nFontFiles
                fontFile = fontFiles{i};
                fPath = fileparts(fontFile);

                % If font file is not a full file name, then through platform 
                % specific font directories
                if isempty(fPath)
                    
                    % Go through each platform font directoies
                    for j = 1:nFontDirectories
                        fontDirectory = h.FontDirs{j};
                        
                        % Use DIR to search directory and its sub-directories
                        dirResults = dir(fullfile(fontDirectory, '**', fontFile));
                        if ~isempty(dirResults)
                            dirResult = dirResults(1);
                            fontFullFile = fullfile(dirResult.folder, fontFile);
                            
                            % Found, stop searching font directories
                            break;
                        end
                    end
                end
                
                fontFullFiles = [fontFullFiles fontFullFile]; %#ok
            end
        end
        
        function updateFont(h, fontName, fontFiles, usage, varargin)
            %UPDATEFONT Updates font
            %   updateFont(h, fontName, fontFile, usage)
            %   updateFont(h, fontName, fontFile, usage, lang)
            %   updateFont(h, fontName, fontFile, usage, lang, platform)
            
            if ischar(fontFiles)
                fontFiles = {fontFiles};
            end
            
            if (nargin > 4)
                lang = h.getLanguageKey(varargin{1});
            else
                lang = h.getLanguageKey();
            end
            
            if (nargin > 5)
                platform = varargin{2};
            else
                platform = h.getPlatformKey();
            end
            
            fontMapKey = h.getFontMapKey(lang, platform, usage);
            h.m_fontMap(fontMapKey) = fontName;
            
            fileMapKey = h.getFileMapKey(platform, fontName);
            h.m_fileMap(fileMapKey) = fontFiles;
        end
        
        function removeFont(h, usage, varargin)
            %REMOVEFONT  Removes font
            %   removeFont(h, usage)
            %   removeFont(h, usage, lang)
            %   removeFont(h, usage, lang, platform)
            %
            %   Removes font for a given usage usage (e.g., title, body, monospaced, 
            %   etc), language (optional), and platform (optional)

            if (nargin > 2)
                lang = h.getLanguageKey(varargin{1});
            else
                lang = h.getLanguageKey();
            end
            
            if (nargin > 3)
                platform = varargin{2};
            else
                platform = h.getPlatformKey();
            end
            
            fontMapKey = h.getFontMapKey(lang, platform, usage);
            if isKey(h.m_fontMap, fontMapKey)
                fontName = h.m_fontMap(fontMapKey);
                remove(h.m_fontMap, fontMapKey);
                
                fileMapKey = h.getFileMapKey(platform, fontName);
                if isKey(h.fileMap, fileMapKey)
                    remove(h.fileMap, fileMapKey);
                end
            end
        end
    end
    
    methods (Access = private)
        function h = LanguageFontMap()
            % LANGUAGEFONTMAP private constructor
            
            reset(h);
        end
        
        function fontName = getFontNameFromMap(h, usage, varargin)
            %GETFONTNAMEFROMMAP Returns the appropriate/default font name
            %   getFontName(h, usage) 
            %   getFontName(h, usage, lang) 
            %   getFontName(h, usage, lang, platform) 
            %
            %   Finds and returns font name given usage (e.g., title, body, 
            %   monospaced, etc.), language (optional) and platform (optional)
            
            if (nargin > 2)
                lang = h.getLanguageKey(varargin{1});
            else
                lang = h.getLanguageKey();
            end
            
            if (nargin > 3)
                platform = varargin{2};
            else
                platform = h.getPlatformKey();
            end
            
            fontName = '';
            fontMapKey =  h.getFontMapKey(lang, platform, usage);
            if isKey(h.m_fontMap, fontMapKey)
                fontName = h.m_fontMap(fontMapKey);
            end
        end        
    end
    
    methods (Static, Access = private)
        function fontMapKey = getFontMapKey(lang, platform, usage)
            assert(~isempty(lang) ...
                && ~isempty(platform) ...
                && ~isempty(usage));
            fontMapKey = [lang '+' platform '+' usage];
        end
        
        function fileMapKey = getFileMapKey(platform, fontName)
            assert(~isempty(fontName) && ~isempty(platform));
            fileMapKey = [platform '+' fontName];
        end
        
        function langKey = getLanguageKey(varargin)
            if (nargin > 0)
                locale = varargin{1};
            else
                locale = get(0, 'Language');
            end
            langKey = locale(1:2);
        end
        
        function fontDirectories = getFontDirectories()
            % Each platform (win, mac, linux) has a different set of font directories
            % to search
            if ispc()
                windir = getenv('windir');
                if (isempty(windir))
                    fontDirectories = {'C:\Windows\Fonts\'};
                else
                    fontDirectories = {fullfile(windir, 'Fonts\')};    
                end
            
            elseif ismac()
                fontDirectories = {
                    '~/Library/Fonts/' 
                    '/Library/Fonts/' 
                    '/Network/Library/Fonts/' 
                    '/System/Library/Fonts/' 
                    '/System/Folder/Fonts/'};
            
            else
                if isfile('/etc/fonts/fonts.conf')
                    fontConf = rptgen.utils.LanguageFontMap.parseXmlFile('/etc/fonts/fonts.conf');
                    dirs = fontConf.getElementsByTagName('dir');
                    nDirs = dirs.getLength();
                    fontDirectories = {};
                    for i = 0:nDirs-1
                        fontDirectories = [
                            fontDirectories  
                            {char(dirs.item(i).getFirstChild.getData())}
                            ]; %#ok<AGROW>
                    end
                else
                    % If no font.conf, use default Linux font search path
                    fontDirectories = {
                        '/.fonts/' 
                        '/usr/local/share/fonts/' 
                        '/usr/X11R6/lib/fonts/' 
                        '/usr/share/fonts/'};
                end
            end
        end
        
        function xmldoc = parseXmlFile(fileName)
            % Do not validate and load external DTD
            p = matlab.io.xml.dom.Parser();
            p.Configuration.AllowDoctype = true;
            p.Configuration.LoadExternalDTD = false;
            p.Configuration.SkipDTDValidation = true;
            p.Configuration.Validate = false;
            xmldoc = p.parseFile(fileName);
        end
    end
 end