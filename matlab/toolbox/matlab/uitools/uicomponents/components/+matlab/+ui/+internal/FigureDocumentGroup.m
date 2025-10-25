classdef FigureDocumentGroup < matlab.ui.container.internal.appcontainer.DocumentGroup
    %FigureDocumentGroup Represents an AppContainer Figure Document Group
    %   The base class provides the ability to set and get Document Group properties
    %   as well as listen for changes to the same.

    % Copyright 2018-2024 The MathWorks, Inc.

    methods

        function this = FigureDocumentGroup(varargin)
            % instantiate the base class
            this = this@matlab.ui.container.internal.appcontainer.DocumentGroup(varargin{:});
            
            documentFactory.Modules(1) = matlab.ui.internal.FigureModuleInfo;

            % set the DocumentFactory used for all Figure-based documents
            this.DocumentFactory = documentFactory;
            
            % Set the Tag for the FigureDocumentGroup if one was not supplied.
            % The Tag will become typeId in UIContainer, to match the ChildProperties.documentType
            % set in UIContainerDivFigureFactory.createProperties() for the Figure widgets created in
            % UIContainerDivFigureFactory.createWidget().
            if this.Tag == ""
                this.Tag = "defaultfigure";
            end
            
            % Set the Title for the FigureDocumentGroup if one was not supplied.
            % This string should eventually be pulled from a message catalog so it can
            % be localized, perhaps as part of the default FigureDocumentGroup change.
            if this.Title == ""
                this.Title = "Figures";
            end

        end % constructor
        
    end % methods
end