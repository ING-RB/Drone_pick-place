classdef ViewModelUtilities
    % Class for viewmodel utilities to help fork the code between peermodel
    % and viewmodel.

    % NOTE: This class should be removed when we stop supporting the
    % java swing rendering through the toolstrip api.

    methods (Static)
        function result = isViewModelChannel(channel)
            if contains(channel, '/app/')...
                    || contains(channel, '/ToolstripShowcaseChannel')...
                    || contains(channel, '/DefaultUIBuilderPeerModelChannel')...
                    || contains(channel, '/ToolstripMCOSAPITestChannel')
                result = true;
            else
                result = false;
            end
        end

        function result = isViewModelChannelForAS(channel)
            % This flag determines if ActionDataService should use ViewModel as its store.
            % This should have the same value as the one specified in
            % UIBuilderFactor.js for "UseVMForAS"
            UseVMForAS = true;
            if (contains(channel, '/app/')...
                    || contains(channel, '/ToolstripShowcaseChannel')...
                    || contains(channel, '/DefaultUIBuilderPeerModelChannel')...
                    || contains(channel, '/ToolstripMCOSAPITestChannel')) && UseVMForAS
                result = true;
            else
                result = false;
            end
        end
    end
end