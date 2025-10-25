classdef AppAppendixParser < handle
    %APPAPPENDIXPARSER

    %   Copyright 2024 The MathWorks, Inc.

    properties (Access = private)
        LayoutRootElement matlab.io.xml.dom.Element
        GroupsRootElement matlab.io.xml.dom.Element
        RunConfigurationRootElement matlab.io.xml.dom.Element
        InternalDataRootElement matlab.io.xml.dom.Element
    end

    properties (Constant, Access = private)
        SectionInfo = appdesigner.internal.serialization.AppAppendixParser.getSectionDictionary();
        ComponentDataMap = appdesigner.internal.artifactgenerator.getComponentDataMap();
        XMLEvaluator = matlab.io.xml.xpath.Evaluator();
    end

    properties (Access = private)
        FileContent
        FileName
    end

    methods (Access = public)
        
        function obj = AppAppendixParser(fileName, fileContent)
            arguments
                fileName {mustBeFile}
                fileContent string
            end
            obj.FileName = fileName;
            obj.FileContent = fileContent;

            % TODO - to be replaced by Validators specific to plain-text Apdx and XSD validation
            obj.validate();
        end

        function startUpName = getStartUpName(obj)
            startUpName = '';

            try
                 % For new appendix layout
                startupEl = obj.XMLEvaluator.evaluate("//StartupFcn", obj.RunConfigurationRootElement, matlab.io.xml.xpath.EvalResultType.Node);
                
            catch
                % For old appendix layout - to remove when updated
                startupEl = obj.XMLEvaluator.evaluate("//StartupFcn", obj.LayoutRootElement, matlab.io.xml.xpath.EvalResultType.Node);
               
            end

            if ~isempty(startupEl)
                startUpName = appdesigner.internal.artifactgenerator.XMLUtil.getElementValue(startupEl);
            end

        end

        function singleton = isSingleton(obj)
            singleton = false;

            try
                % For new appendix layout
                singletonEl = obj.XMLEvaluator.evaluate("//SingleRunningInstance", obj.RunConfigurationRootElement, matlab.io.xml.xpath.EvalResultType.Node);
            catch
                % For old prototype appendix layout - to remove when updated
                singletonEl = obj.XMLEvaluator.evaluate("//SingleRunningInstance", obj.LayoutRootElement, matlab.io.xml.xpath.EvalResultType.Node);
            end

            if ~isempty(singletonEl)
                singletonValue = appdesigner.internal.artifactgenerator.XMLUtil.getElementValue(singletonEl);
                if strcmp(singletonValue, 'true')
                    singleton = true;
                end
            end
        end

        function appDesignerRunConfigData = getAppDesignerRunConfig(obj)
            % NOTE: TODO - Resolve potential confusion between "RunConfigurations" in the
            % plain-text file and "RunConfigurations" the App Designer construct

            % TODO
            arguments (Output)
                appDesignerRunConfigData
            end

            appDesignerRunConfigData = {''};
        end

        function groupData = getComponentGroupData(obj)
            % TODO - when component group data is added to plain-text file
            arguments (Output)
                groupData struct
            end

            groupData = struct();

        end

        function internalData = getInternalData(obj)
            % TODO - when internal data is added to plain-text file
            arguments (Output)
                internalData struct
            end

            internalData = struct();

        end
    end

    methods (Access = private)
    
        function validate(obj)
            % To be replaced with Validators

            obj.validateHasRequiredSections();
            
        end

        function hasRequired = validateHasRequiredSections(obj)
            hasRequired = true;

            keys = obj.SectionInfo.keys;
            numKeys = numel(keys);

            for m = 1:numKeys
                if obj.SectionInfo(keys(m)).Required
                    hasRequired = contains(obj.FileContent, obj.SectionInfo(keys(m)).Grammar);
                    if ~hasRequired
                        error(append("Required appendix section missing: ", obj.SectionInfo(keys(m)).Grammar));
                    end
                end
            end
        end

        function apdxDocument = getDocumentBySection(obj, sectionName)
            xmlText = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(obj.FileContent, obj.SectionInfo(sectionName).Grammar, obj.SectionInfo(sectionName).RootName);

            % XMLUtil APIs require filename and filecontent 
            % for error handling
            apdxDocument = appdesigner.internal.artifactgenerator.XMLUtil.parseAppXML(obj.FileName, obj.FileContent, xmlText);
        end
    end

    % Appendix Section Root Element getters
    methods
        function rootElement = get.LayoutRootElement(obj)
            arguments (Output)
                rootElement (1,:) matlab.io.xml.dom.Element
            end

            if isempty(obj.LayoutRootElement)
                obj.LayoutRootElement = obj.getDocumentBySection('Layout').getDocumentElement();
            end

            rootElement = obj.LayoutRootElement;
        end

        function rootElement = get.GroupsRootElement(obj)
            arguments (Output)
                rootElement (1,:) matlab.io.xml.dom.Element
            end

            if isempty(obj.GroupsRootElement)
                obj.GroupsRootElement = obj.getDocumentBySection('Groups').getDocumentElement();
            end

            rootElement = obj.GroupsRootElement;
        end

        function rootElement = get.RunConfigurationRootElement(obj)
            arguments (Output)
                rootElement (1,:) matlab.io.xml.dom.Element
            end

            if isempty(obj.RunConfigurationRootElement)
                obj.RunConfigurationRootElement = obj.getDocumentBySection('RunConfiguration').getDocumentElement();
            end

            rootElement = obj.RunConfigurationRootElement;
        end

        function rootElement = get.InternalDataRootElement(obj)
            arguments (Output)
                rootElement (1,:) matlab.io.xml.dom.Element
            end

            if isempty(obj.InternalDataRootElement)
                obj.InternalDataRootElement = obj.getDocumentBySection('InternalData').getDocumentElement();
            end

            rootElement = obj.InternalDataRootElement;
        end
    end

    methods (Static)
        function sectionDict = getSectionDictionary()
            sectionDict = dictionary();

            sectionTemplate = struct('Grammar', '', 'Required', false, 'RootName', '');

            % Layout
            section = sectionTemplate;
            section.Grammar = 'app:layout';
            section.Required = true;
            section.RootName = 'Components';

            sectionDict('Layout') = section;

            % Groups
            section = sectionTemplate;
            section.Grammar = 'app:componentGroups';
            section.RootName = 'ComponentGroups';

            sectionDict('Groups') = section;

            % AppDetails
            section = sectionTemplate;
            section.Grammar = 'app:appDetails';
            section.RootName = 'AppDetails';

            sectionDict('AppDetails') = section;

            % RunConfiguration
            section = sectionTemplate;
            section.Grammar = 'app:runConfiguration';
            section.RootName = 'RunConfiguration';

            sectionDict('RunConfiguration') = section;

            % InternalData
            section = sectionTemplate;
            section.Grammar = 'app:internalData';
            section.RootName = 'InternalData';

            sectionDict('InternalData') = section;

        end

    end
end
