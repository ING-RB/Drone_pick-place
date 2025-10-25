classdef ReferenceTopicBuilder
    properties
        SortByProduct (1,1) logical = true;
        Topic         (1,1) string;
        IsVariable    (1,1) logical;
        IsPrimitive   (1,1) logical = false;
        WhichTopic    (1,1) string;
        ClassInfo;
        RefBook       (1,1) string;
    end

    methods
        function obj = ReferenceTopicBuilder(topic, isVariable, whichTopic, classInfo, toolbox)
            arguments
                topic (1,1) string;
                isVariable (1,1) logical;
                whichTopic (1,1) string = "";
                classInfo = [];
                toolbox (1,1) string = "";
            end
            obj.Topic = topic;
            obj.IsVariable = isVariable;
            if obj.IsVariable
                [~, comment] = which(obj.Topic);
                obj.IsPrimitive = isempty(comment);
            end
            obj.WhichTopic = whichTopic;
            obj.ClassInfo = classInfo;
            obj.RefBook = matlab.internal.doc.reference.getDocProductName(toolbox);
        end

        function [refTopics, topicName] = buildRefTopics(obj)
            import matlab.internal.reference.property.RefEntityType;

            [~, topicName] = fileparts(obj.WhichTopic);
            addSimpleTopic = false;
            addParentClassTopic = false;
            if ~isempty(obj.ClassInfo)
                topicName = obj.ClassInfo.fullTopic;
                [refTopics, addParentClassTopic, obj.Topic] = createClassInfoTopic(obj.ClassInfo, obj.Topic);
                addSimpleTopic = true;
            elseif obj.IsVariable
                refTopics = matlab.internal.doc.reference.ReferenceTopic(obj.Topic);
            elseif topicName ~= ""
                refTopics = matlab.internal.doc.reference.ReferenceTopic(topicName);
            else
                refTopics = createSimpleTopics(obj);
                return;
            end

            if addSimpleTopic
                refTopics = [refTopics, matlab.internal.doc.reference.ReferenceTopic(obj.Topic)];
            end

            % For methods and properties, look for the class reference page if we
            % can't find a reference page for the method/property.
            if addParentClassTopic
                classTopic = createParentTopic(refTopics(1), obj.ClassInfo);
                refTopics(end+1) = classTopic;
            end

            altTopic = createAltTopic(obj);
            if isempty(refTopics) || ~strcmp(obj.Topic, altTopic)
                altTopicObj = matlab.internal.doc.reference.ReferenceTopic(altTopic);
                if ~isequal(altTopicObj,refTopics(end))
                    refTopics(end+1) = altTopicObj;
                end
            end

            refTopics = obj.addTopicDetails(refTopics);
        end
    end

    methods (Access = private)
        function simpleTopics = createSimpleTopics(obj)
            if obj.RefBook == ""
                simpleTopics = createTopicsIfToolboxQualified(obj.Topic);
            else
                simpleTopics = matlab.internal.doc.reference.ReferenceTopic.empty;
            end
            simpleTopic = matlab.internal.doc.reference.ReferenceTopic(obj.Topic);
            simpleTopic = obj.addTopicDetails(simpleTopic);
            simpleTopics(end+1) = simpleTopic;
        end

        function refTopics = addTopicDetails(obj, refTopics)
            for i = 1:numel(refTopics)
                refTopics(i).IsPrimitive = obj.IsPrimitive;

                if obj.RefBook ~= ""
                    refTopics(i).EntityProduct = obj.RefBook;
                    if obj.SortByProduct
                        refTopics(i).ProductPrecision = matlab.internal.doc.reference.ProductPrecision.Sort;
                    end
                end
            end
        end

        function altTopic = createAltTopic(obj)
            altTopic = regexprep(obj.Topic,'\.m(lx)?$','');
            altTopic = regexprep(altTopic,'[\s-\(\)]','');
        end
    end
end

function [classTopic, addParentClassTopic, topic] = createClassInfoTopic(classInfo, topic)
    if ~classInfo.isInherited
        topic = classInfo.fullTopic;
    end
    topic = replace(topic, '/', '.');
    classTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
    classTopic.EntityPrecision = matlab.internal.reference.api.EntityPrecision.Exact_Match;
    [classTopic.EntityTypes, addParentClassTopic] = getClassInfoTypes(classInfo);
end

function [types, addParentTopic] = getClassInfoTypes(classInfo)
    import matlab.internal.reference.property.RefEntityType;
    if classInfo.isMethod
        types = [RefEntityType.Method, RefEntityType.Function];
    elseif classInfo.isConstructor
        types = [RefEntityType.Constructor, RefEntityType.Function];
    elseif classInfo.isSimpleElement
        types = RefEntityType.Property;
    elseif classInfo.isClass
        types = matlab.internal.doc.reference.getClassEntityTypes;
    else
        types = RefEntityType.empty;
    end
    addParentTopic = ~isempty(types) && ~classInfo.isClass;
end

function toolboxTopics = createTopicsIfToolboxQualified(topic)
    % see if the topic is in the form: product/topic
    toolboxTopics = matlab.internal.doc.reference.ReferenceTopic.empty;
    splitTopic = regexp(topic,'[/.]','split','once');
    if ~isscalar(splitTopic)
        toolbox = matlab.internal.doc.reference.getDocProductName(splitTopic{1});
        if toolbox ~= ""
            toolboxTopics = createToolboxTopics(toolbox, splitTopic{2});
        end
    end
end

function toolboxTopics = createToolboxTopics(toolbox, topic)
    nameResolver = matlab.lang.internal.introspective.MCOSMetaResolver(topic);
    nameResolver.executeResolve;
    if nameResolver.isResolved
        [simpleToolboxTopic, addParentClassTopic] = createClassInfoTopic(nameResolver, topic);
    else
        simpleToolboxTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
        addParentClassTopic = false;
    end
    simpleToolboxTopic.EntityProduct = toolbox;
    simpleToolboxTopic.ProductPrecision = matlab.internal.doc.reference.ProductPrecision.Filter;
    toolboxTopics = simpleToolboxTopic;
    if addParentClassTopic
        parentClassTopic = createParentTopic(simpleToolboxTopic, nameResolver);
        parentClassTopic.EntityProduct = toolbox;
        toolboxTopics(end+1) = parentClassTopic;
    end
end

function classTopic = createParentTopic(classTopic, classInfo)
    classTopic.EntityName = classInfo.fullClassName;
    classTopic.EntityTypes = matlab.internal.doc.reference.getClassEntityTypes;
    classTopic.IsParentSearch = true;
end

% Copyright 2020-2024 The MathWorks, Inc.
