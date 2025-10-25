function requiresCVT()
%   Helper function that validates if Computer Vision Toolbox has been
%   installed.

%   Copyright 2021 The MathWorks Inc.

    isCVT = license('checkout', 'Video_and_Image_Blockset');
    if isCVT == 0
        error(message('images:externalImageContainer:RequiresCVT'));
    end