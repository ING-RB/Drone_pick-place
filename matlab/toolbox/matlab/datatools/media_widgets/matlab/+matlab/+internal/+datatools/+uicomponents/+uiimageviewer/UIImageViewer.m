classdef UIImageViewer < matlab.ui.componentcontainer.ComponentContainer
    % UIImageViewer a Component Container with an axes to show a preview of
    % an image.
    %
    % matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
    %     "ImageSource", filename)
    % Shows the image specified as filename in the image preview
    %
    % matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
    %     "ImageSource", filename, "Parent", parentComponent)
    % Shows the image specified as filename in the image preview, which is
    % parented to the parentComponent.
    %
    % matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
    %     "ImageSource", cdata)
    % Shows the image specified by the cdata in the image preview
    %
    % matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
    %     "ImageSource", cdata, "Colormap", colormap, "Alpha", alpha)
    % Shows the image specified by the cdata in the image preview, using the
    % specified colormap and alpha values.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Dependent = true)
        ImageSource;
        Colormap;
        Alpha;
    end

    properties (Access = {?UIImageViewer, ?matlab.unittest.TestCase}, Transient, NonCopyable, Hidden)
        Axes matlab.ui.control.UIAxes
        GridLayout matlab.ui.container.GridLayout
        Panel matlab.ui.container.Panel
    end

    properties (Access = protected, Transient, NonCopyable)
        ImageSourceI;
        ColormapI;
        AlphaI;
    end

    properties(Hidden, Constant)
        DOWNSAMPLE_PREVIEW_NUMEL = 100000;
        PREVIEW_SIZE = 120;
        WIDTH_OFFSET = 80;
        HEIGHT_OFFSET = 350;
    end

    methods
        function val = get.ImageSource(this)
            % Get the ImageSource property
            val = this.ImageSourceI;
        end

        function set.ImageSource(this, val)
            % Set the ImageSource property, which can be a numeric value, or a
            % filename.
            if isnumeric(val) || islogical(val)
                this.ImageSourceI = val;
            elseif strlength(val) > 0
                [v, map, a] = imread(val);
                this.ImageSourceI = v;
                this.Colormap = map;
                this.Alpha = a;
            end
        end

        function val = get.Colormap(this)
            % Get the Colormap property
            val = this.ColormapI;
        end

        function set.Colormap(this, val)
            % Set the Colormap property
            this.ColormapI = val;
        end

        function val = get.Alpha(this)
            % Get the Alpha property
            val = this.AlphaI;
        end

        function set.Alpha(this, val)
            % Set the Alpha property
            this.AlphaI = val;
        end
    end

    methods
        function this = UIImageViewer(NameValueArgs)
            % Construct a UIImageViewer
            arguments
                NameValueArgs.?matlab.ui.componentcontainer.ComponentContainer
                NameValueArgs.Parent = uifigure
                NameValueArgs.BackgroundColor = [1, 1, 1]
                NameValueArgs.ImageSource = ""
                NameValueArgs.Colormap = []
                NameValueArgs.Alpha = []
            end
            this@matlab.ui.componentcontainer.ComponentContainer(NameValueArgs);
            this.ImageSource = NameValueArgs.ImageSource;
        end
    end

    methods (Access = protected)
        function setup(~)
            % Do actual setup when we know the size of the image, as this will
            % determine the components used
        end

        function update(this)
            this.setupImagePreview();
        end

        function setupUIForImage(this, imageSrc)
            % Do the setup now that we know the image size.

            smallImage = true;
            sz = size(imageSrc);
            if sz(1) > this.PREVIEW_SIZE || sz(2) > this.PREVIEW_SIZE
                smallImage = false;
            end
            this.SetupComplete = false;

            if smallImage
                % Create a panel with the axes set to a fixed size, centered in
                % the panel.
                this.Panel = uipanel(this, "BorderType", "none");
                bkObj = this.Panel;

                this.Axes = uiaxes("Parent", this.Panel);

                % Set the axes width/height to the image size (plus a buffer)
                this.Axes.Position(3) = max(size(imageSrc, 1) + 50, 50);
                this.Axes.Position(4) = max(size(imageSrc, 2) + 50, 50);

                % Set the figure itself to not be resizable for small images
                f = ancestor(this, 'figure');
                f.Resize = false;

                % Size/position the panel and axes based on the figure size
                figWidth = f.Position(3);
                figHeight = f.Position(4);
                this.Panel.Position(3) = figWidth - this.WIDTH_OFFSET;
                this.Panel.Position(4) = figHeight - this.HEIGHT_OFFSET;
                this.Axes.Position(1) = (figWidth - this.WIDTH_OFFSET)/2 - this.Axes.Position(3)/2;
                this.Axes.Position(2) = (figHeight- this.HEIGHT_OFFSET)/2 - this.Axes.Position(4)/2;
            else
                this.GridLayout = uigridlayout(this, [1, 1], "Padding", [0, 0, 0, 0]);
                bkObj = this.GridLayout;
                this.Axes = uiaxes("Parent", this.GridLayout);
            end

            matlab.graphics.internal.themes.specifyThemePropertyMappings(bkObj, ...
                "BackgroundColor", "--mw-graphics-backgroundColor-axes-primary");

            this.SetupComplete = true;

            this.Axes.XAxis.Visible = "off";
            this.Axes.YAxis.Visible = "off";
        end

        function setupImagePreview(this)
            imageSrc = this.getImageSourceForPreview();
            if isempty(this.Axes)
                this.setupUIForImage(imageSrc)
            end

            if ~isempty(this.Colormap)
                % If there is a colormap, call image with the ImageSource data,
                % and set the colormap and alpha value, if set
                image(imageSrc, "Parent", this.Axes);
                this.Axes.Colormap = this.Colormap;
                if ~isempty(this.Alpha)
                    alpha(this.Axes, double(~this.Alpha));
                end
            else
                % Use imagesc for the ImageSource
                imagesc(imageSrc, "Parent", this.Axes);
                if size(imageSrc, 3) == 1
                    this.Axes.Colormap = gray;
                end
            end

            % The following code is similar to 'axes image'
            this.Axes.Toolbar.Visible = "off";
            disableDefaultInteractivity(this.Axes);
            set(this.Axes, ...
                "DataAspectRatio", [1 1 1], ...
                "PlotBoxAspectRatioMode", "auto")
            pbarlimit = 0.1;

            pbar = get(this.Axes, "PlotBoxAspectRatio");
            pbar = max(pbarlimit, pbar / max(pbar));
            if any(pbar(1:2) == pbarlimit)
                set(this.Axes, "PlotBoxAspectRatio", pbar)
            end

            names = get(this.Axes, "DimensionNames");
            set(this.Axes, names{1} + "LimSpec", "tight", names{2} + "LimSpec", "tight");
            set(this.Axes, names{1} + "LimMode", "auto", names{2} + "LimMode", "auto")
        end
    end

    methods(Hidden = true)
        function imageSrc = getImageSourceForPreview(this)
            import matlab.internal.capability.Capability;

            imageSrc = this.ImageSource;
            if ~Capability.isSupported(Capability.LocalClient)
                % Downsample the image (manually) for MOL, to improve
                % preview performance.  (Done manually because we want to
                % maintain the 3rd array value for images)
                while numel(imageSrc) > this.DOWNSAMPLE_PREVIEW_NUMEL
                    imageSrc = imageSrc(1:2:end, 1:2:end, :);
                end
            end
        end
    end
end
