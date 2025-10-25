function out = dlEntryPointTest(in, ntwkfile)
%

%   Copyright 2018 The MathWorks, Inc.

    net = coder.loadDeepLearningNetwork(ntwkfile);
    out = net.predict(in);

end
