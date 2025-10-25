function classDiagramViewer
% classDiagramViewer Launch class diagram viewer with no classes in it

% Copyright 2021 The MathWorks, Inc.
appsGalleryViewerTag = "CDV_AppsGallery";
% Make sure that ClassDiagramViewer is only open once, when launched from
% apps gallery
classdiagram.app.core.ClassDiagramLaunchManager.launchClassViewer(appsGalleryViewerTag);
end