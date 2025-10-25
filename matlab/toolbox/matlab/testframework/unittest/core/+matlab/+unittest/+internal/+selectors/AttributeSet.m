classdef AttributeSet
%AttributeSet represents a set of attributes of a test suite
%   The AttributeSet class is a data structure that represents a set of
%   zero or more attributes for zero or more test suite elements. Attribute
%   sets are used by test selectors to evaluate which suite elements to
%   select.

%   Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = private)
        Attributes
        AttributeDataLength
    end
    methods
        function attrSet = AttributeSet(attributes, dataLength)
            arguments
                attributes (1, :) matlab.unittest.internal.selectors.SelectionAttribute
                dataLength (1, 1) double {mustBeNonnegative}
            end

            attrSet.Attributes = attributes;
            attrSet.AttributeDataLength = dataLength;
        end
        function attrSubset = dataSubset(attrSet, subsetIndices)
            %dataSubset returns a reduced AttributeSet
            %   The returned AttributeSet contains the same attributes, but
            %   the attributes contain data for only the elements indicated
            %   by the logical array subsetIndices.
            newAttributes = attrSet.Attributes; 
            newAttributeDataLength = nnz(subsetIndices);

            for attrIdx = 1:numel(newAttributes)
                newAttributes(attrIdx).Data = newAttributes(attrIdx).Data(subsetIndices);
            end

            attrSubset = attrSet;
            attrSubset.Attributes = newAttributes;
            attrSubset.AttributeDataLength = newAttributeDataLength;
        end
    end

    methods (Static)
        function attributeSet = fromTestSuite(suite, attributeUsage)
            %fromTestSuite creates an attribute set representing a test suite
            %   The method takes a test suite and a struct defining what
            %   attributes to include in the attribute set. The method
            %   returns an attribute set representing the suite that can be
            %   used with selector objects to filter the suite.

            import matlab.unittest.internal.selectors.SelectionAttribute;
            import matlab.unittest.internal.selectors.ParameterAttribute;
            import matlab.unittest.internal.selectors.SharedTestFixtureAttribute;
            import matlab.unittest.internal.selectors.NameAttribute;
            import matlab.unittest.internal.selectors.BaseFolderAttribute;
            import matlab.unittest.internal.selectors.TagAttribute;
            import matlab.unittest.internal.selectors.ProcedureNameAttribute;
            import matlab.unittest.internal.selectors.SuperclassAttribute;
            import matlab.unittest.internal.selectors.FilenameAttribute;

            % Optimize creation of class level attributes by duplicating
            % data for all elements of the same class. This saves time
            % querying expensive attribute data like BaseFolder.

            classBoundaries = [suite.ClassBoundaryMarker];
            uniqueClassBoundaries = unique(classBoundaries);

            baseFolders = cell(1, numel(suite));
            superclasses = cell(1, numel(suite));
            filenames = strings(1, numel(suite));

            for classIdx = 1:numel(uniqueClassBoundaries)

                boundaryMask = uniqueClassBoundaries(classIdx) == classBoundaries;
                classSuite = suite(boundaryMask);

                % Base folder
                if attributeUsage.UsesBaseFolder
                    classBaseFolder = {classSuite(1).BaseFolder};
                    baseFolders(boundaryMask) = repmat(classBaseFolder, size(classSuite));
                end

                % Superclass
                if attributeUsage.UsesSuperclass
                    classSuperclasses = {classSuite(1).Superclasses};
                    superclasses(boundaryMask) = repmat(classSuperclasses, size(classSuite));
                end

                % Filename
                if attributeUsage.UsesFilename
                    classFilenames = classSuite(1).Filename;
                    filenames(boundaryMask) = repmat(classFilenames, size(classSuite));
                end
            end

            % Create selection attributes based on selector usage
            emptySelectionAttribute = SelectionAttribute.empty;

            baseFolder = emptySelectionAttribute;
            if attributeUsage.UsesBaseFolder
                baseFolder = BaseFolderAttribute(baseFolders);
            end

            superclass = emptySelectionAttribute;
            if attributeUsage.UsesSuperclass
                superclass = SuperclassAttribute(superclasses);
            end

            filename = emptySelectionAttribute;
            if attributeUsage.UsesFilename
                filename = FilenameAttribute(filenames);
            end

            name = emptySelectionAttribute;
            if attributeUsage.UsesName
                name = NameAttribute({suite.Name});
            end

            parameter = emptySelectionAttribute;
            if attributeUsage.UsesParameter
                parameter = ParameterAttribute({suite.Parameterization});
            end

            sharedTestFixture = emptySelectionAttribute;
            if attributeUsage.UsesSharedTestFixture
                sharedTestFixture = SharedTestFixtureAttribute({suite.SharedTestFixtures});
            end

            tag = emptySelectionAttribute;
            if attributeUsage.UsesTag
                tag = TagAttribute({suite.Tags});
            end

            procedureName = emptySelectionAttribute;
            if attributeUsage.UsesProcedureName
                procedureName = ProcedureNameAttribute({suite.ProcedureName});
            end

            attributes = [baseFolder, name, parameter, sharedTestFixture, tag, procedureName, superclass, filename];
            dataLength = numel(suite);
            attributeSet = matlab.unittest.internal.selectors.AttributeSet(attributes, dataLength);
        end
    end
end
