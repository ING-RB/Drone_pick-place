classdef MATLABGraphicsContainer< mlreportgen.report.mixin.SnapshotMaker
% mlreportgen.report.MATLABGraphicsContainer is a base class for graphics
% container classes like Figure, Axes and ScopeSnapshot.

     
    % Copyright 2021-2024 The MathWorks, Inc.

    methods
        function out=MATLABGraphicsContainer
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=getImageFormat(~) %#ok<STOUT>
        end

        function out=getSnapshotDimensions(~) %#ok<STOUT>
            % Returns the height and width that the snapshot image should
            % be, based on the Scaling property. Return values are in
            % inches. If Scaling is set to 'none', returned width and
            % height are -1
        end

        function out=getSnapshotImage(~) %#ok<STOUT>
            % imgpath = getSnapshotImage(reporter,rpt) creates an
            % image of the figure window specified by reporter and
            % returns a path to a file containing the image. You can use
            % this method to customize the layout of figures in your
            % report.
            %
            % See also mlreportgen.report.Figure, mlreportgen.report.Axes
        end

        function out=getSnapshotImageImpl(~) %#ok<STOUT>
        end

    end
    methods (Abstract)
        % Get figure file for creating figure snapshot
        getClonedFigureFile;

    end
    properties
        Height;

        % Derived class should implement this method for setting the
        % caption numbered template name
        HierNumberedCaptionTemplateName;

        % Derived class should implement this property for setting the image
        % template name
        ImageTemplateName;

        % Derived class should implement this method for setting the
        % caption hierarchical numbered template name
        NumberedCaptionTemplateName;

        PreserveBackgroundColor;

        Scaling;

        Snapshot;

        SnapshotFormat;

        Source;

        Theme;

        Width;

    end
end
