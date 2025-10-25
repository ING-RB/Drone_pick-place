classdef (Hidden) demoFilePatcher
    %  MATLAB.INTERNAL.DOC.PROJECT.DEMOFILEPATCHER Patch demos.xml file.
    %
    %  Patch a demos.xml file in folder helploc replacing charater data in
    %  the description with non-charater data.
    %
    %  Charaters '&lt;', '&gt;', '&apos;', '&quot;', and '&amp;' will be
    %  replaced with '<', '>', '''', '"', and '&' respectively.

    %   Copyright 2020 The MathWorks, Inc.
    
    properties (Access=private)
        FileHandler;
        ChatacterMap;
    end
        
    methods        
        function obj = demoFilePatcher(varargin)
            if nargin>1
                obj.FileHandler = varargin{2};            
            else
                obj.FileHandler = matlab.internal.doc.project.demoFileHandler(varargin{1});            
            end                        
            k = {'&lt;', '&gt;', '&apos;', '&quot;', '&amp;'};
            v = {'<', '>', '''', '"', '&'};
            obj.ChatacterMap = containers.Map(k, v);
        end
        
        function patched = patchDemoFile(this)             
            patched = 1;

            if ~this.FileHandler.locationExists
                error('MATLAB:doc:CannotPatchDemoXmlFile','%s',getString(message('MATLAB:doc:SpecifiedDirectoryDoesNotExist')));
            end

            if ~this.FileHandler.fileExists
                error('MATLAB:doc:CannotPatchDemoXmlFile','%s',getString(message('MATLAB:doc:FileDoesNotExist', this.FileHandler.DemoFile)));
            end

            str = this.FileHandler.readDemoFile;
            
            fixable = this.hasCharacterData(str);
            if ~fixable
                disp(getString(message('MATLAB:doc:NoCharDataInDemoXmlFile')));
                patched = 0;
                return;
            end

            this.FileHandler.backupDemoFile;            
            newStr = this.getPatchedContent(str);            
            this.FileHandler.writeDemoFile(newStr);            
        end                        
    end
    
    methods (Access=private)   
        function has_char_data = hasCharacterData(~,str) 
            % If the 'isCdata' attribute on the description field doesn't 
            % exist or it exists and the value is 'yes' then the field
            % contains character data.
            expression = '(?<=<description isCdata=)(.*)(?=>.*</description>)';
            tokens = regexp(str, expression, 'tokens');
            has_char_data = isempty(tokens) || contains(cell2mat(tokens{1}),'yes');
        end     
     
        function new_str = getPatchedContent(this, str)
            desc = this.getDescription(str);    
            newDesc = this.translateCharacters(desc);            
            % Add or set description attribute 'isCdata' to 'no'.
            % If the attribute exists it will be 'yes', set it to 'no'.
            % Otherwise, add it with value 'no'.
            if contains(str,'<description isCdata="yes">')
                new_str = strrep(str,'<description isCdata="yes">','<description isCdata="no">');
            elseif contains(str,'<description isCdata=''yes''>')
                new_str = strrep(str,'<description isCdata=''yes''>','<description isCdata=''no''>');
            else
                new_str = strrep(str,'<description>','<description isCdata="no">');
            end
            new_str = strrep(new_str,desc,newDesc);
        end
        
        function description = getDescription(~, str)
            expression = ['(?<=<description>)(.*)(?=</description>)|'...
                          '(?<=<description isCdata="yes">)(.*)(?=</description>)|'...
                          '(?<=<description isCdata=''yes''>)(.*)(?=</description>)'];           
            tokens = regexp(str, expression, 'tokens');
            description = cell2mat(tokens{1});        
        end

        function new_desc = translateCharacters(this, desc)
            key = keys(this.ChatacterMap);
            val = values(this.ChatacterMap);
            new_desc = desc;
            for i = 1:length(this.ChatacterMap)
                new_desc = regexprep(new_desc,key{i},val{i});
            end
        end
    end   
end

