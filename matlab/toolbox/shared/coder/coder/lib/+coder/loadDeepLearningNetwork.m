function net = loadDeepLearningNetwork(matfile, varargin)
%
%   CODER.LOADDEEPLEARNINGNETWORK Loads a trained deep learning network or
%   an object detector for code generation. See documentation link below for
%   the list of supported classes.
%
%   NET = CODER.LOADDEEPLEARNINGNETWORK(FILENAME) loads a trained deep learning
%   network or an object detector saved in a MAT-file. FILENAME must be a 
%   valid MAT-file existing in MATLAB path containing a single deep learning
%   network or an object detector object.
%
%   NET = CODER.LOADDEEPLEARNINGNETWORK(FUNCTIONNAME) calls a function that
%   returns a trained deep learning network or an object detector object.
%   FUNCTIONNAME must be a name of a function existing in MATLAB path that 
%   returns a deep learning network or an object detector object.
%
%   This function should be used when code is generated from a network
%   object for inference. This function generates a C++ class from this
%   network. The class name is derived from the MAT-file name, or the
%   function name.
%
%   NET = CODER.LOADDEEPLEARNINGNETWORK(FILENAME,NETWORK_NAME) is the same
%   as NET = CODER.LOADDEEPLEARNINGNETWORK(FILENAME) with the option to
%   name the C++ class generated from the network. NETWORK_NAME is a
%   descriptive name for the network object saved in the MAT-file, or the
%   function. It must be a char type that is a valid identifier in C++.
%
%   Example : Code generation from SeriesNetwork inference loaded from a
%   MAT-file
%
%   function out = alexnet_codegen(in)
%     %#codegen
%     persistent mynet;
%
%     if isempty(mynet)
%         mynet = coder.loadDeepLearningNetwork('imagenet-cnn.mat','alexnet');
%     end
%     out = mynet.predict(in);
%
%   Example : Code generation from SeriesNetwork inference loaded from a
%   function name. 'alexnet' is a Deep Learning Toolbox function that
%   returns a pretrained AlexNet model.
%
%   function out = alexnet_codegen(in)
%     %#codegen
%     persistent mynet;
%
%     if isempty(mynet)
%         mynet = coder.loadDeepLearningNetwork('alexnet','myAlexnet');
%     end
%     out = mynet.predict(in);
%
%   See also CODEGEN

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen
narginchk(1, 4);
if coder.target('MATLAB')
    try
        netName = iGetNetworkName(varargin{:});
        net = coder.internal.loadDeepLearningNetwork(matfile, 'NetworkName', netName);
        
    catch err
        throwAsCaller(err);
    end
    
else
    netName = coder.const(iGetNetworkName(varargin{:}));
    net = coder.internal.loadDeepLearningNetwork(matfile, 'NetworkName', netName);   
end

end

function netName = iGetNetworkName(varargin)
coder.inline('always');
if coder.const(nargin == 0)
    netName = '';
else
    netName = coder.const(varargin{1});
end
end
