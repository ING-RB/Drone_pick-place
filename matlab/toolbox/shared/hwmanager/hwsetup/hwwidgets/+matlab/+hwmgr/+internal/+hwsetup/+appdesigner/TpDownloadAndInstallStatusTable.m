classdef TpDownloadAndInstallStatusTable < matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable
    % TPDOWNLOADANDINSTALLSTATUSTABLE is a class that implements a
    % TpDownloadAndInstallStatusTable widget.
    % It renders a table with three text columns for display.
    % The first column has a StatusIcon, the second column has a string, and
    % the third column has a license link.
    % It exposes all of the settable and gettable properties defined by the
    % interface specification.
    %
    %See also matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable

    % Copyright 2021-2022 The MathWorks, Inc.

    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for table

            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});

            aPeer = matlab.hwmgr.internal.hwsetup.appdesigner.TpDownloadAndInstallStatusTableWrapper(aParent);
            aPeer.formatTextForDisplay();
        end
    end

    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = TpDownloadAndInstallStatusTable(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable(varargin{:});

            addlistener(obj.Parent, 'ObjectBeingDestroyed', @obj.parentDeleteCallback);
        end
    end
    %----------------------------------------------------------------------
    % setter methods - set properties on peer
    %----------------------------------------------------------------------
    methods (Access = protected)
        function setEnable(obj, value)
            obj.Peer.Enable = value;
        end

        function setStatus(obj, value)
            obj.Peer.Status = value;
        end

        function setName(obj, value)
            obj.Peer.Name = value;
        end

        function setLicenseURL(obj, value)
            obj.Peer.LicenseURL = value;
        end

        function setColumnHeader(obj, value)
            obj.Peer.ColumnHeader = value;
        end
    end

    %----------------------------------------------------------------------
    % getter methods - get properties from peer
    %----------------------------------------------------------------------
    methods(Access = protected)
        function value = getEnable(obj)
            value = obj.Peer.Enable;
        end

        function value = getStatus(obj)
            value = obj.Peer.Status;
        end

        function value = getName(obj)
            value = obj.Peer.Name;
        end

        function value = getLicenseURL(obj)
            value = obj.Peer.LicenseURL;
        end

        function value = getColumnHeader(obj)
            value = obj.Peer.ColumnHeader;
        end
    end

    %----------------------------------------------------------------------
    % helper methods
    %----------------------------------------------------------------------
    methods
        function parentDeleteCallback(obj, varargin)
            delete(obj)
        end
    end
end