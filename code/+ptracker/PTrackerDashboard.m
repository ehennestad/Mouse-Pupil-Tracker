classdef PTrackerDashboard < applify.DashBoard & applify.mixin.UserSettings
    
    
    % Todo: 
    %   [ ] Why does the imviewer panel resize 3-4 times whenever
    %       showing/hiding the signal viewer panel
    %   [ ] Bug when creating rois and modifying them before the
    %       roisignalarray is initalized.
    %
    
    properties
        ApplicationName = 'Pupil Tracker'
        Tracker
        PupilData = [];
    end
    
    properties(Constant, Hidden = true)
        USE_DEFAULT_SETTINGS = false % Ignore settings file
        DEFAULT_SETTINGS = ptracker.getDefaultSettings() % Struct with default settings
    end
    
    properties (Hidden)
        FigureSize = [1100, 832]
    end
    
    properties (Constant, Hidden)
        PanelTitles = {'Controls', 'Image Display', 'Advanced', 'Signal Viewer', ''}
       %PanelModules = {'structeditor.App', 'imviewer.App', 'roimanager.RoiTable', 'RoiSignalViewer', []}
    end
    
    properties (Access = private)
       %TabButtonGroup = struct() 
       ShowBottomPanel = true;
       
       TempControlPanel
       TempControlPanelDestroyedListener
    end
    
    properties (Access = private)
        hEyeCornerMarkers = gobjects(0)
        hEyeballDiagonal = gobjects(0)
        gobjectTransporter
        
        hCropBox = gobjects(0)
        
        hPupilCircle = gobjects(0)
        hPupilCenter = gobjects(0)
        hPupilTrajectory = gobjects(0)
        
        pupilPositionViewer
        pupilMovementViewer
        
        TabButtonGroup
        
        waitForMousePress = false
        
        hBinaryImage
        frameChangedListener
        
        PreviewTimer
        
    end
    
    methods % Structor
        
        function obj = PTrackerDashboard(varargin)
            
            % Explicit call to superclass constructors.
            obj@applify.DashBoard()
           
            % Todo: Get figure position from properties.
            obj.hFigure.Position = [100, 50, obj.FigureSize];
            obj.Theme = nansen.theme.getThemeColors('dark-purple');
            
            % Initialize modules
            
            % 1) Imviewer
            h = imviewer(obj.hPanels(2), varargin{:});
            h.resizePanelContents()
            obj.AppModules = h;
            obj.configurePanelResizeButton(obj.hPanels(2).Children(1), h)

            if h.ImageStack.NumChannels > 1
                h.ImageStack.CurrentChannel = 1;
            end

            % Call method for activating the roimanager plugin on imviewer
            %obj.activatePlugin(h)
            
            
            % 2) Signal viewer
            obj.openSignalViewer()
            obj.addPanelResizeButton(obj.hPanels(4).Children(1))
            
            %obj.AppModules(end+1) = obj.SignalViewer;
       
            
            % 3) For advanced viewer (roitable as placeholder for now)
%             h = roimanager.RoiTable(obj.hPanels(3), obj.roiGroup);
%             obj.addPanelResizeButton(obj.hPanels(3).Children(1))
%             obj.AppModules(end+1) = h;

            % Button bar on bottom switching between different panels.
            obj.createToolbar()

            obj.IsConstructed = true; % triggers onConstructed which will
            % make figure visible, apply theme etc.
            
            drawnow
            
            %obj.TabButtonGroup.Group.Visible = 'on';
            
            
            % Load settings.... Needs to be done after figure is visible
            % due to the way controls are drawn.
            obj.initializeSettingsPanel()
                        
            obj.keepFigureOnScreen()
                       
            obj.TabButtonGroup.Group.Visible = 'on';

        end
        
        function quit(obj)
            
            % Reset this
            obj.saveSettings()
        end
        
    end

    methods (Access = protected) % Create/configure layout
        
        function createPanels(obj)
            
            % Todo: Incorporate colors into theme
            S = obj.Theme;
                            
            bgColor2 = [0.15,0.15,0.15];
            hlColor = [0.3000 0.3000 0.3000];
            shColor = [0.3000 0.3000 0.3000];
            fgColor = [0.75,0.75,0.75];
            
            panelParameters = {'Parent', obj.hMainPanel, ...
                'BorderType', 'line', 'BorderWidth', 1, ...
                'Background', bgColor2, 'ShadowColor', shColor, ...
                'Foreground', fgColor, 'HighlightColor', hlColor };
            
            for i = 1:numel(obj.PanelTitles)
                iTitle = obj.PanelTitles{i};
                obj.hPanels(i) = uipanel( panelParameters{:}, 'Title', iTitle);
            end

            set(obj.hPanels, 'Units', 'pixel')

            obj.addPanelResizeButton(obj.hPanels(1))
            %obj.addPanelResizeButton(obj.hPanels(3))
            
        end

        function resizePanels(obj)
            
            if ~obj.IsConstructed; return; end
            
            set(obj.hPanels(1:3), 'BorderType', 'none');
            set(obj.hPanels(3), 'Visible', 'off');
            
            mainPanelVisibility = obj.hMainPanel.Visible;
            %drawnow limitrate
            
            obj.hMainPanel.Visible = 'off';
            %obj.hFigure.Visible = 'off';
            
            [xPosA, Wa] = obj.computePanelPositions([200, 0.7, 0.3], 'x');
            [xPosB, Wb] = obj.computePanelPositions(1, 'x');


            if obj.ShowBottomPanel
                panelHeights = [25, 0.3, 0.7];
                iA = 3;
                iB = 2;
            else
                panelHeights = [25, 1];
                iA = 2;
            end
            
            [yPos, H] = obj.computePanelPositions(panelHeights, 'y');
            
            panelNumsA = [1, 2, 3];
            numPanelsA = numel(panelNumsA);
            
            newPos = cell(numPanelsA, 1);
            
            for i = [1,3,2] % Resize imviewer latest...
                newPos{i} = [xPosA(i), yPos(iA), Wa(i), H(iA)];
                setpixelposition(obj.hPanels(panelNumsA(i)), newPos{i})
            end
            
            if obj.ShowBottomPanel
                setpixelposition(obj.hPanels(4), [xPosB, yPos(iB), Wb, H(iB)])
            end
            
            setpixelposition(obj.hPanels(5), [xPosB, yPos(1), Wb, H(1)])

            
            %set( obj.hPanels, {'Position'},  newPos );
            
            set(obj.hPanels(1:3), 'BorderType', 'line');
            set(obj.hPanels(3), 'Visible', 'on');
            
            obj.hMainPanel.Visible = mainPanelVisibility;
            
            %obj.hFigure.Visible = 'on';
            
            %drawnow

        end
        
    end
    
    methods (Access = protected) % Create/configure modules
        
        function initializeSettingsPanel(obj)

            % Reset some "transient" settings
            obj.settings.Configuration.rotateImages = false;
            obj.settings.TrackerOptions.showBinarizedImage = false;
            
            % Create filepath for saving results.
            savePath = obj.createResultSavePath();
            obj.settings.RunTracker.SavePath = savePath;
            
            i = 0;
            [structs, names, callbacks] = deal( {} );
            
            i = i+1;
            structs{i} = obj.settings.Configuration;
            names{i} = '(1) Initialization';
            callbacks{i} = @obj.onConfigurationChanged;
                       
            i = i+1;
            structs{i} = obj.settings.TrackerOptions;
            names{i} = '(2) Tracker Options';
            callbacks{i} = @obj.onTrackerOptionsChanged;
            
            i = i+1;
            structs{i} = obj.settings.RunTracker;
            names{i} = '(3) Run Tracker';
            callbacks{i} = @obj.onRunTrackerSettingsChanged;
            
            i = i+1;
            structs{i} = obj.settings.ProcessResults;
            names{i} = '(4) Post Processing';
            callbacks{i} = @obj.onDataProcessingSettingsChanged;
            
            h = structeditor.App(obj.hPanels(1), structs, 'FontSize', 10, ...
                'FontName', 'helvetica', 'LabelPosition', 'Over', ...
                'TabMode', 'dropdown', ...
                'Name', names, ...
                'Callback', callbacks );
            
            obj.AppModules(end+1) = h;
            
            % Reset some "transient" settings
            obj.settings.Configuration.thetaEye = 0;
            obj.settings.Configuration.centerPos = [nan, nan];
            obj.settings.Configuration.eyeCoordinates = [];
            %obj.settings.Configuration.cropCoordinates = [];

            
            hImStack = obj.AppModules(1).ImageStack;
            imageSizeXY = [hImStack.ImageWidth, hImStack.ImageHeight];
            obj.settings.Configuration.imageSizeXY = imageSizeXY;
            
        end
        
% %         function createMenu(obj)
% %             
% %             % Create menu category
% %             try
% %                 m = uimenu(obj.hFigure, 'Text', 'File');
% %                 textKey = 'Text';
% %                 callbackKey = 'MenuSelectedFcn';
% %             catch
% %                 m = uimenu(obj.hFigure, 'Label', 'File');
% %                 textKey = 'Label';
% %                 callbackKey = 'Callback';
% %             end
% %             
% %             
% %             % File menu category
% %             mitem = uimenu(m, textKey,'Load Video');
% %             mitem.(callbackKey) = @obj.loadVideo;
% %             
% %             mitem = uimenu(m, textKey,'Load Pupil Data');
% %             mitem.(callbackKey) = @(s,e) obj.loadPupilData;
% %             
% %             mitem = uimenu(m, textKey,'Save Pupil Data');
% %             mitem.(callbackKey) = @(s,e) obj.savePupilData;
% %         
% %         end

        
        function createToolbar(obj)
            
            buttonSize = [100, 22];
    
            obj.hPanels(5).BorderType = 'none';

           % Create toolbar
            hToolbar = uim.widget.toolbar_(obj.hPanels(5), 'Margin', [10,0,0,0], ...
                'ComponentAlignment', 'left', 'BackgroundAlpha', 0, ...
                'Spacing', 20, 'Padding', [0,1,0,1], 'NewButtonSize', buttonSize, ...
                'Visible', 'off');
            hToolbar.Location = 'southwest';
            
            buttonProps = { 'Mode', 'togglebutton', 'CornerRadius', 4, ...
                'Padding', [0,0,0,0], 'Style', uim.style.buttonDarkMode3, ...
                'Callback', @obj.onTabButtonPressed, 'HorizontalTextAlignment', 'center' };


            hBtn = uim.control.Button_.empty;
    
            buttonNames = {'Pupil Position', 'Pupil Movement'};
            
            for i = 1:numel(buttonNames)
                hBtn(i) = hToolbar.addButton('Text', buttonNames{i}, buttonProps{:});
            end
            
            hBtn(1).Value = true;
            
            obj.TabButtonGroup.Group = hToolbar;
            obj.TabButtonGroup.Buttons = hBtn;
            
        end


        function configurePanelResizeButton(obj, hPanel, hImviewer)
            
            hAppbar = hImviewer.uiwidgets.Appbar;

            hButton = hAppbar.Children(3);
            hButton.ButtonDownFcn = @(s, e) obj.toggleMaximizePanel(hButton, hPanel);
            
        end
        
    end

    methods (Access = protected)% Settings changed callbacks

        function onSettingsChanged(obj, name, value)
        end
        
        function onConfigurationChanged(obj, name, value)
        
            switch name
                
                case 'loadVideo'
                    obj.loadVideo()
                    
                case 'pupilPolarity'
                    obj.settings.Configuration.(name)=value;
                    if obj.settings.TrackerOptions.showBinarizedImage
                        obj.updateBinarizedImage()
                    end
                case 'markCornersOfEye'
                    if value
                        obj.markEyeCorners()
                    else
                        set([obj.hEyeballDiagonal, obj.hEyeCornerMarkers], 'Visible', 'off')
                    end
                    
                case 'hideCornerMarkers'
                    set([obj.hEyeballDiagonal, obj.hEyeCornerMarkers], 'Visible', ~value)

                case 'rotateImages'
                    obj.settings.Configuration.(name)=value;
                    if value
                        obj.AppModules(1).ImageProcessingFcn = @obj.rotateImage;
                    else
                        obj.AppModules(1).ImageProcessingFcn = [];
                    end
                    obj.AppModules(1).refreshImageDisplay()
                    
                    obj.toggleEyeMarkerEnabled(~value)
                    obj.updateEyeCornerMarkers()
                    obj.plotPupilTrajectory()
                    obj.updateBinarizedImage()
                    
                case 'cropImage'
                   obj.cropImage() 
                    
                    
                case 'selectPupil'
                    obj.waitForMousePress = true;
                    % Todo: Implement a crosshair pointer tool
                    obj.hFigure.Pointer = 'hand';
            end

            
        end
        
        function onTrackerOptionsChanged(obj, name, value)
                    
            obj.settings.TrackerOptions.(name)=value;
            
            switch name
                case 'method'
                    switch value
                        case 'thresholding'
                       
                        case 'edgedetection'
                            obj.AppModules(1).displayMessage('Edge detection is not implemented yet', [], 2)
                    end
                        
                
                case 'editOptions'
                    
                %case 'threshold'
                    
                case 'showBinarizedImage'
                    if value && isempty(obj.hBinaryImage)
                        obj.initializeBinarizedImage()
                    else
                        set(obj.hBinaryImage, 'Visible', value)
                    end
                case {'threshold', 'imclose', 'removeObjectsSmallerThan'}
                    if obj.settings.TrackerOptions.showBinarizedImage
                        obj.updateBinarizedImage()
                    end
                    
                case 'outlineMethod'
                    BW = obj.hBinaryImage.CData(:, :, 1);
                    obj.updatePupilOutline(BW)
                    
                case 'showPupilOutline'
                    set([obj.hPupilCircle, obj.hPupilCenter], 'Visible', value)
                    
            end


        end
        
        function onRunTrackerSettingsChanged(obj, name, value)
            
            obj.settings.RunTracker.(name) = value;

            switch name
                case 'preview'
                    
                    obj.configurePreviewTimer(value)
                    obj.onTrackerOptionsChanged('showBinarizedImage', true);
                    obj.onTrackerOptionsChanged('showPupilOutline', true);
                
                case 'run'
                    obj.runTracker()
                    
                    
                case 'plotPupilCenterOnImage'
                    
                    if value
                        obj.plotPupilTrajectory()
                        set(obj.hPupilTrajectory, 'Visible', 'on')

                    else
                        set(obj.hPupilTrajectory, 'Visible', 'off')
                    end
                    
                    
                case 'savePath'

                case 'savePupilData'
                    obj.savePupilData()
                    
                case 'loadPupilData'
                    obj.loadPupilData()
                    
            end
        end
        
        function onDataProcessingSettingsChanged(obj, name, value)
            
            obj.settings.ProcessResults.(name) = value;
            
            switch name
                case 'showRotatedCoordinates'
                    obj.updatePupilDataPlot()
                case 'applyOkadaFilter'
                    obj.updatePupilDataPlot()
                case {'movementDetectionStdValue','removeConsecutive','maxFrequency'}
                    obj.updatePupilMovementDetection()
                case 'updatePupilPlot' % This should not be necessary anymore. Update should happen on data changes.. Keep for manual updates just in case...
                    obj.updatePupilDataPlot()
            end
            
            
        end
        
        function onMousePressed(obj, src, evt)
            
            if obj.waitForMousePress
                obj.hFigure.Pointer = 'arrow';
                point = obj.AppModules(1).Axes.CurrentPoint;
                x = point(1,1); y = point(1,2);
                obj.settings.Configuration.centerPos = [x, y];
                msg = sprintf('Center @ x=%d, y=%d', round(x), round(y));
                
                % Todo: Autodetect pupil and plot...
                obj.AppModules(1).displayMessage(msg, [], 2)
                
                obj.waitForMousePress = false;
            end
            
            
        end
        
        function onControlPanelOpened(obj, h, targetName, h2)
            obj.TempControlPanel = obj.AppModules(4);
            obj.AppModules(4) = h;
            obj.TempControlPanelDestroyedListener = addlistener(h, ...
                'AppDestroyed',  @(s,e,nm,hp) obj.onControlPanelClosed(targetName, h2) );
                        
        end
        
        function onControlPanelClosed(obj, targetName, h2)
            
            % Get changes
            if obj.AppModules(4).wasCanceled
                S = obj.AppModules(4).dataOrig;
                %obj.AppModules(1).displayMessage('Optio', [], 1.5)
            else
                S = obj.AppModules(4).dataEdit; 
                obj.AppModules(1).displayMessage('Options updated!', [], 1.5)
            end
            
            subs = struct('type', {'.'}, 'subs', strsplit(targetName, '.'));
            obj.settings = subsasgn(obj.settings, subs, S);
            
            delete(obj.AppModules(4))
            delete(h2) % delete plugin...
            obj.AppModules(4) = obj.TempControlPanel;
            obj.hPanels(1).Title = 'Controls';
            
            delete(obj.TempControlPanelDestroyedListener)
            obj.TempControlPanelDestroyedListener=[];
        end
        
        function S = getDatasetOptions(obj)
            S = ptracker.getDatasetParameters(obj.settings);
        end
        
        function applyDatasetOptions(obj)
            
            
        end
        
    end
    
    methods % Imviewer plugin functions...
        
        function markEyeCorners(obj)
            
            if isempty(obj.hEyeCornerMarkers)
                obj.plotEyeCornerMarkers()
            else
                obj.updateEyeCornerMarkers()
                set([obj.hEyeballDiagonal, obj.hEyeCornerMarkers], 'Visible', 'on')
            end
            
        end
        
        function toggleEyeMarkerEnabled(obj, value)
            
            if isempty(obj.hEyeCornerMarkers)
                return
            else
                h = obj.hEyeCornerMarkers;
            end
            
            
            for i = 1:2
                if value
                    h(i).ButtonDownFcn = @(s,e) obj.gobjectTransporter.startDrag(h(i),e);
                else
                    hImviewer = obj.AppModules(1);
                    msg = 'Markers can not move when image is rotated';
                    h(i).ButtonDownFcn = @(s,e,m,~,t) hImviewer.displayMessage(msg, [], 2);
                end
            
            end
            
            
            
        end
        
        function plotEyeCornerMarkers(obj)
            hImviewer = obj.AppModules(1);

            if isempty(obj.gobjectTransporter)
                obj.gobjectTransporter = applify.gobjectTransporter(hImviewer.Axes);
                obj.gobjectTransporter.TransportFcn = @obj.onEyeCornersDragged;
                hImviewer = obj.AppModules(1);
                obj.gobjectTransporter.StopDragFcn = @hImviewer.refreshImageDisplay;
            end
            
            rad = 8;
            [X, Y] = uim.shape.circle(rad);
            X = X-rad; Y=Y-rad;
            
            imSize = [hImviewer.imHeight, hImviewer.imWidth];
            
            initPoints = repmat(imSize/2, 2, 1) + [-imSize/4; imSize/4];

            obj.hEyeCornerMarkers = gobjects(0);
            obj.hEyeballDiagonal = gobjects(0);
            
                
            for i = 1:size(initPoints, 2)
                x0 = initPoints(i,1);
                y0 = initPoints(i,2);

                h = patch(hImviewer.Axes, x0+X, y0+Y, 'w', 'FaceAlpha', 0.4);
                h.EdgeColor = ones(1,3)*0.2;
                h.LineWidth = 1;
                h.ButtonDownFcn = @(s,e) obj.gobjectTransporter.startDrag(h,e);
                obj.gobjectTransporter.setPointerBehavior(h)
                obj.hEyeCornerMarkers(i) = h;
            end
            
            obj.hEyeballDiagonal = plot(hImviewer.Axes, initPoints(:,1), initPoints(:,2), '-');
            obj.hEyeballDiagonal.Marker = '.';
            %obj.hEyeballDiagonal.MarkerColor = 'k';
            obj.hEyeballDiagonal.PickableParts = 'none';
            obj.hEyeballDiagonal.HitTest = 'off';
            obj.hEyeballDiagonal.Color = [0.7, 0.7, 0.6, 0.4];
            obj.hEyeballDiagonal.LineWidth = 3;
            
            obj.settings.Configuration.eyeCoordinates = initPoints;
            
        end
        
        function updateEyeCornerMarkers(obj)
            
            h1 = obj.hEyeCornerMarkers;
            h2 = obj.hEyeballDiagonal;
            
            if isempty(h1); return; end
            
            coords = obj.settings.Configuration.eyeCoordinates;
            if obj.settings.Configuration.rotateImages
                coords = ptracker.rotateCoordinates(coords, obj.settings, -1);
            end
            
            for i = 1:2
                h1(i).XData = h1(i).XData - mean([h1(i).XData]) + coords(i,1);
                h1(i).YData = h1(i).YData - mean([h1(i).YData]) + coords(i,2);
            end
            
            h2.XData = coords(:,1);
            h2.YData = coords(:,2);
            
        end
        
        function onEyeCornersDragged(obj, h, shift)
            
            ind = ismember(obj.hEyeCornerMarkers, h);
            
            h.XData = h.XData + shift(1);
            h.YData = h.YData + shift(2);
            
            obj.hEyeballDiagonal.XData(ind) = obj.hEyeballDiagonal.XData(ind)+shift(1);
            obj.hEyeballDiagonal.YData(ind) = obj.hEyeballDiagonal.YData(ind)+shift(2);
            
            % Sort from left to right
            X = obj.hEyeballDiagonal.XData;
            Y = obj.hEyeballDiagonal.YData;
            
            [~, sortIdx] = sort(X);
            X = X(sortIdx); Y = Y(sortIdx);
            
            coords = [X',Y'];
            
            % Derotate coordinates before placing them in options.
% %             if obj.settings.Configuration.rotateImages
% %                 coords2 = ptracker.rotateCoordinates(coords, obj.settings, -1);
% %             end
            
            obj.settings.Configuration.eyeCoordinates = coords;

            % Calculate angle between points
            ds = abs( diff(obj.settings.Configuration.eyeCoordinates) );
            obj.settings.Configuration.thetaEye = rad2deg( atan(ds(2)/ds(1)) );

            if ~isempty(obj.PupilData)
                obj.PupilData = ptracker.rotateResults(obj.PupilData, obj.settings, -1);
                obj.updatePupilDataPlot();
            end
            
        end

        function cropImage(obj)
            
            hImviewer = obj.AppModules(1);
            
            if obj.settings.Configuration.rotateImages
                hImviewer.displayMessage('Image can not be cropped while it is rotated', [], 2)
                return
            end
            
            % Create a rectangle for cropping the image.
            hImviewer.uiwidgets.msgBox.displayMessage('Crop Image, Press Enter to Finish', 2);
            
            rccInit = obj.settings.Configuration.cropCoordinates;
            rcc = hImviewer.selectRectangularRoi(rccInit);

            % rcc = [ min([xCoords, yCoords]), range([xCoords, yCoords]) ];
            obj.settings.Configuration.cropCoordinates = rcc;

            % Create an alphamask for image, where cropped part is in focus
            vertexX = rcc(1) + [0, rcc(3), rcc(3), 0];
            vertexY = rcc(2) + [0, 0, rcc(4), rcc(4)];
            
            hImage = findobj(hImviewer.Axes, 'Type', 'Image');
            
            if numel(hImage)>1
                hImage = hImage(end); % Pick the first one that was added.
            end
            
            imSize = size(hImage.CData);
            imSize = imSize(1:2);
            imSizeXY = fliplr(imSize);
            
%             mask = double(poly2mask(vertexX, vertexY, imSizeXY(2), imSizeXY(1)));
%             mask(~mask) = 0.4;
%             hImage.AlphaData = mask;
            
            outerBoxX = [0, imSizeXY(1)+1, imSizeXY(1)+1, 0, 0];
            innerBoxX = [vertexX, vertexX(1)];
            outerBoxY = [imSizeXY(2)+1, imSizeXY(2)+1, 0, 0, imSizeXY(2)+1];
            innerBoxY = [vertexY, vertexY(1)];
            
            h = findobj(hImviewer.Axes, 'Tag', 'Crop Outline');
            
            if isempty(h)
                h = patch(hImviewer.Axes, [outerBoxX, innerBoxX], [outerBoxY, innerBoxY], 'k');
                h.FaceAlpha = 0.3;
                h.EdgeColor = 'none';
                h.Tag = 'Crop Outline';
            else
                set(h, 'XData', [outerBoxX, innerBoxX], 'YData',  [outerBoxY, innerBoxY] )
            end
            
            obj.hCropBox = h;
                
        end
        
        function plotPupilTrajectory(obj)
            
            
            hImviewer = obj.AppModules(1);

            % Return if pupildata is not initialized
            if isempty(obj.PupilData); return; end
            
            % Rotate if theta ~= 0
            if obj.settings.Configuration.rotateImages
                pupilCenterCoords = obj.PupilData.CenterRotated;
            else
                pupilCenterCoords = obj.PupilData.Center;
            end
            
            % Update plot if it already exists
            if ~isempty(obj.hPupilTrajectory)
                set(obj.hPupilTrajectory, 'XData', pupilCenterCoords(:,1), ...
                    'YData', pupilCenterCoords(:,2) );
            else
                obj.hPupilTrajectory = plot(hImviewer.Axes, ...
                    pupilCenterCoords(:,1), pupilCenterCoords(:,2));
                obj.hPupilTrajectory.HitTest = 'off';
                obj.hPupilTrajectory.PickableParts = 'none'; 
                obj.hPupilTrajectory.Color = ones(1,3)*0.7;
            end
            
        end
        
% % %   Function for rotating images
        
        function im = rotateImage(obj, im)
            theta = obj.settings.Configuration.thetaEye;
            im = imrotate(im, theta, 'bilinear', 'crop');
        end
        
% % %   Function for showing binarized image

        function initializeBinarizedImage(obj, src, evt)
            
            if isempty(obj.frameChangedListener)
                obj.frameChangedListener = addlistener(obj.AppModules(1), ...
                    'currentFrameNo', 'PostSet', @obj.onFrameChanged);
            end
            
            BW = obj.getBinarizedImage();
            BW_ = false(size(BW));
            BW = cat(3, BW, BW_, BW_);
            
            hAxes = obj.AppModules(1).Axes;
            
            obj.hBinaryImage = image(hAxes, BW);
            obj.hBinaryImage.AlphaData = BW(:, :, 1).*0.4;
            obj.hBinaryImage.PickableParts = 'none';
            obj.hBinaryImage.HitTest = 'off';
            obj.hBinaryImage.Tag = 'Binary Overlay';
            
            % Place it in the uistack just above the imviewer image.
            % Imviewer image should be image lowest in the stack.
            isimagehandle = @(x) isa(x, 'matlab.graphics.primitive.Image');
            isImage = arrayfun(@(h) isimagehandle(h), hAxes.Children);
            steps = find(isImage, 1, 'last') - 2;
            uistack(obj.hBinaryImage, 'down', steps)
            
        end
        
        function updateBinarizedImage(obj)
            
            if isempty(obj.hBinaryImage); return; end
            
            BW = obj.getBinarizedImage();
            
            pupilCenter = round( obj.settings.Configuration.centerPos );
            if all(~isnan(pupilCenter))
                obj.updatePupilOutline(BW)
            end
            
            if obj.settings.Configuration.rotateImages
                theta = obj.settings.Configuration.thetaEye;
                BW = imrotate(BW, theta, 'bilinear', 'crop');
            end
            
            obj.hBinaryImage.CData(:, :, 1) = BW;
            obj.hBinaryImage.AlphaData = BW(:, :, 1).*0.4;
            
        end

        function updatePupilOutline(obj, BW)
            
            if ~obj.settings.TrackerOptions.showPupilOutline
                return
            end
            
            [outline, position] = ptracker.getPupilOutline(BW, obj.settings);
            
            xCoords = outline(:,1);
            yCoords = outline(:,2);
            x0 = position(1);
            y0 = position(2);
            
            if obj.settings.Configuration.rotateImages
                [xCoords, yCoords] = ptracker.rotateCoordinates([xCoords, yCoords], obj.settings, -1);
                [x0, y0] = ptracker.rotateCoordinates([x0, y0], obj.settings, -1);
            end
            
            
            if isempty(obj.hPupilCircle)
                obj.hPupilCircle = plot(obj.AppModules(1).Axes, xCoords, yCoords, 'w');
                obj.hPupilCircle.LineWidth = 2;
                obj.hPupilCenter = plot(obj.AppModules(1).Axes, x0, y0, '+w');
                obj.hPupilCenter.LineWidth = 1;
                obj.hPupilCenter.MarkerSize = 10;
            else
                obj.hPupilCircle.XData = xCoords;
                obj.hPupilCircle.YData = yCoords;
                obj.hPupilCenter.XData = x0;
                obj.hPupilCenter.YData = y0;
            end
        end
        
        function BW = getBinarizedImage(obj)
            
            % Get displayed image.
            %im = obj.AppModules(1).image;
            im = obj.AppModules(1).ImageStack.getFrameSet(obj.AppModules(1).currentFrameNo);
            BW = ptracker.getBinarizedImage(im, obj.settings);
            
        end
        
        function signal = getSignal(obj, signalName)
           
            if isempty(obj.PupilData)
                return
            end
            
            if obj.settings.ProcessResults.showRotatedCoordinates
                pupilCenterCoords = obj.PupilData.CenterRotated;
            else
                pupilCenterCoords = obj.PupilData.Center;             
            end
            
            switch signalName
                case 'Radius'
                    signal = obj.PupilData.Radius;
                case 'MovX'
                    signal = diff(pupilCenterCoords(:, 1));
                case 'MovY'
                    signal = diff(pupilCenterCoords(:, 2));
                case 'PosX'
                    signal = pupilCenterCoords(:, 1);
                case 'PosY'
                    signal = pupilCenterCoords(:, 2);
            end
            
            if obj.settings.ProcessResults.applyOkadaFilter
                signal = ptracker.okada(signal, 1);
            end
            
        end
        
        function updatePupilMovementDetection(obj)
            
            if isempty(obj.pupilMovementViewer); return; end
            
            pupilPosition = obj.getSignal('PosX');
            
            stdThresh = obj.settings.ProcessResults.movementDetectionStdValue;
            
            [peaks, locs] = ptracker.findPupilMovements(pupilPosition, obj.settings.ProcessResults);
            
            yData = nan(size(pupilPosition));
            
            movX = cat(1, 0, obj.getSignal('MovX'));
            yData(locs) = movX(locs);
           
            h = obj.pupilMovementViewer.getHandle('PupilMovementEvents');
            
            if isempty(h)
                pMovEvt = timeseries(yData, 'Name', 'PupilMovementEvents');
                h = obj.pupilMovementViewer.plot(pMovEvt);
                h=h{1};
                h.Marker = '*';
            else
                obj.pupilMovementViewer.updateLineData('PupilMovementEvents', yData );
            end
            
            
        end
        
        function updatePupilDataPlot(obj)
            
            if isempty(obj.PupilData)
                obj.AppModules(1).displayMessage('There is no data to plot, run tracker and try again', [], 2.5)
                return
            end
            
            isSignalViewer = arrayfun(@(h) isa(h, 'signalviewer.timeseriesPlot'), obj.AppModules);

            if any( isSignalViewer )
                hSignalViewer = obj.pupilPositionViewer;

                hSignalViewer.updateLineData('PupilRadius', obj.getSignal('Radius') );
                hSignalViewer.updateLineData('PupilPositionX', obj.getSignal('PosX') );
                hSignalViewer.updateLineData('PupilPositionY', obj.getSignal('PosY') );
            end
            
            if ~isempty(obj.pupilMovementViewer)
                obj.pupilMovementViewer.updateLineData('PupilMovementX', obj.getSignal('MovX') );
                obj.pupilMovementViewer.updateLineData('PupilMovementY', obj.getSignal('MovY') );
            end
            
        end
        
        function openSignalViewer(obj)
            
            if isempty(obj.PupilData)
                obj.PupilData.Radius = nan(obj.AppModules(1).nFrames, 1);
                obj.PupilData.Center = nan(obj.AppModules(1).nFrames, 2);
                obj.PupilData.CenterRotated = nan(obj.AppModules(1).nFrames, 2);
            end


            pupilR = timeseries(obj.PupilData.Radius, 'Name', 'PupilRadius');
            pupilX = timeseries(obj.PupilData.Center(:, 1), 'Name', 'PupilPositionX');
            pupilY = timeseries(obj.PupilData.Center(:, 2), 'Name', 'PupilPositionY');



            hSignalViewer = signalviewer.App(obj.hPanels(4), pupilR);
            %hSignalViewer.Theme = signalviewer.theme.Dark;

            hSignalViewer.YLabelName = 'Pupil Radius';

            hSignalViewer.yyaxis('right')
            hSignalViewer.YLabelName = 'Pupil Position';

            hSignalViewer.plot([pupilX,pupilY])


            colors = flipud( viridis(12) );

            names = {'PupilRadius', 'PupilPositionX', 'PupilPositionY'};

            for i = 1:numel(names)
                % Color lines
                hTmp = hSignalViewer.getHandle(names{i});
                hTmp.Color = colors(i*2,:);
            end

            hSignalViewer.showLegend()

            obj.pupilPositionViewer = hSignalViewer;
            
            obj.AppModules(end+1) = hSignalViewer;
            obj.AppModules(1).linkprop(hSignalViewer)
                
        end

        function openPupilMovementViewer(obj)
            
            pupilMovX = timeseries(obj.getSignal('MovX'), 'Name', 'PupilMovementX');
            pupilMovY = timeseries(obj.getSignal('MovY'), 'Name', 'PupilMovementY');
            
            hSignalViewer = signalviewer.timeseriesPlot(obj.hPanels(4), [pupilMovX, pupilMovY]);
            hSignalViewer.Theme = signalviewer.theme.Dark;

            hSignalViewer.YLabelName = 'Pupil Movement';
            
            colors = flipud( viridis(12) );

            names = {'PupilMovementX', 'PupilMovementY'};

            for i = 1:numel(names)
                % Color lines
                hTmp = hSignalViewer.getHandle(names{i});
                hTmp.Color = colors(i*2,:);
            end
            
            hSignalViewer.showLegend()

            obj.pupilMovementViewer = hSignalViewer;
            obj.AppModules(end+1) = hSignalViewer;
            obj.AppModules(1).linkprop(hSignalViewer)
            
            obj.addPanelResizeButton(obj.hPanels(4).Children(2))

            obj.Theme = obj.Theme;
        end
        
        
        function loadVideo(obj)
            % Todo
        end
        
        function resultPath = createResultSavePath(obj)
            
            hImviewer = obj.AppModules(1);
            dataFilePath = hImviewer.ImageStack.FileName;
            
            [folder, fileName] = fileparts(dataFilePath);
            
            fileName = strcat(fileName, '_pupildata.mat');
            resultPath = fullfile(folder, fileName);
        end
        
        function loadPupilData(obj)
            
            initPath = fileparts(obj.settings.RunTracker.SavePath);
            
            if isempty(initPath)
                initPath = fileparts( obj.AppModules(1).filePath );
            end
            
            [filename, folderPath] = uigetfile('*.mat','',initPath);
            
            if filename == 0; return; end
            
            S = load(fullfile(folderPath, filename));
            
            if isfield(S, 'Radius')
                obj.PupilData = S;
                obj.updatePupilDataPlot()
            else
                obj.AppModules(1).displayMessage('File does not contain pupildata', [], 2)
            end

        end
        
        function savePupilData(obj)
            
            savePath = obj.settings.RunTracker.SavePath;

            if isempty( savePath )
                obj.AppModules(1).displayMessage('Please enter a path above before saving', [], 2.5)
                return
            end
            
            if isempty(obj.Tracker) && isempty(obj.PupilData)
                obj.AppModules(1).displayMessage('There is no data to save, run tracker and try again', [], 2.5)
                return
            end
            
            
            pupilData = obj.PupilData;
            
            % Make sure rotated coordinates are included if eye is rotated
            if obj.settings.Configuration.thetaEye ~= 0 && ...
                ~isfield(obj.PupilData, 'CenterRotated')
                obj.PupilData = ptracker.rotateResults(obj.PupilData, obj.settings);
            end
            
            % Add options to pupildata
            pupilData.options = obj.getDatasetOptions(); 
            
            save(savePath, '-struct', 'pupilData')
            
            obj.AppModules(1).displayMessage('Pupil data was saved to the specified path', [], 2.5)
            
            fprintf('Pupildata saved to %s\n', savePath)

        end
        
    end
    
    methods
        
        function tf = assertPupilIsSelected(obj)
            tf = true;
            if all(isnan(obj.settings.Configuration.centerPos))
                obj.AppModules(1).displayMessage('You need to go to initialization and click to select pupil before starting the tracker', [], 3)
                tf = false;
            end
            
        end
        
        function runTracker(obj)
            
            if ~obj.assertPupilIsSelected
                return
            end

            hImviewer = obj.AppModules(1);
            
           
            if obj.settings.RunTracker.runOnSeparateWorker

                % Create message
                tic
                msg = sprintf('Creating a job to run the pupil tracker on a separate worker...');
                hImviewer.displayMessage(msg);
                
                filePath = hImviewer.filePath;
                [~, name] = fileparts( filePath );
                
                options = obj.settings;
                
                currentPath = mfilename('fullpath');
                nansenCodePath = utility.path.getAncestorDir(currentPath, 2);
                nansenCodePath = {nansenCodePath, fullfile(nansenCodePath, 'apps'), ...
                     fullfile(nansenCodePath, 'dependencies')};
                
                % nansenCodePath = strsplit( genpath(nansenCodePath), ':' );
                % Todo:
                jobDescription = sprintf('Track Pupil (%s)', name);
                job = batch(@ptracker.run, 0, {filePath, options}, ...
                    'AutoAddClientPath',false, 'AutoAttachFiles', false, ...
                    'AdditionalPaths', nansenCodePath);
                job.Tag = jobDescription;
                t2 = toc;
                
                switch job.State
                    case 'running'
                        msg1 = sprintf('Pupil tracker job is running.\n');

                    case 'queued'
                        msg1 = sprintf('Pupil tracker job is queued.\n');
                end
                
                savePath = obj.settings.RunTracker.SavePath;
                msg2 = sprintf('Results will be saved to:\n %s', savePath);
                
                hImviewer.displayMessage([msg1, newline, msg2], [], 2)

                return
            
            end
            
            hImviewer.activateGlobalMessageDisplay()
            C = onCleanup(@hImviewer.clearMessage);
            
            % Get framenumber of first frame
            if strcmp(obj.settings.RunTracker.startAt, 'Beginning')
                startFrame = 1;
            elseif strcmp(obj.settings.RunTracker.startAt, 'Current Image')
                startFrame = obj.AppModules(1).currentFrameNo;
            end
           
            if isempty(obj.Tracker)
                imageStack = obj.AppModules(1).ImageStack;
                obj.Tracker = ptracker.PupilTracker(imageStack, obj.settings);
            end

            obj.Tracker.StartFrame = startFrame;
            
            % This can be removed...
%             if isempty( obj.PreviewTimer ) && obj.settings.RunTracker.preview
%                 obj.configurePreviewTimer(true)
%                 obj.Tracker.ShowPreview = true;
%             end
%             
%             if ~isempty( obj.PreviewTimer )
%                 if strcmp(obj.PreviewTimer.Running, 'off')
%                     start( obj.PreviewTimer )
%                 end
%             end

            obj.Tracker.run()
            
            obj.AppModules(1).clearMessage()
            
            obj.PupilData = obj.Tracker.PupilData;
            
            if obj.settings.Configuration.rotateImages || ~isnan( obj.settings.Configuration.thetaEye )
                obj.PupilData = ptracker.rotateResults(obj.PupilData, obj.settings);
            end
            
            obj.updatePupilDataPlot()
            
        end

        function configurePreviewTimer(obj, showPreview)
            
            if isempty(obj.PreviewTimer) && showPreview
                
                obj.PreviewTimer = timer('ExecutionMode', 'fixedRate', ...
                                         'Period', 0.03);
            
                obj.PreviewTimer.TimerFcn = @obj.updateView;
                obj.PreviewTimer.ErrorFcn = @obj.onTimerError;
            elseif ~isempty(obj.PreviewTimer) && ~showPreview
                obj.stopPreviewTimer()
            end

        end

        function stopPreviewTimer(obj)
            if ~isempty(obj.PreviewTimer)
                stop(obj.PreviewTimer)
                delete(obj.PreviewTimer)
                obj.PreviewTimer = [];
            end
        end
        
        function updateView(obj, src, evt) % Timer Callback
            
            %if ~obj.settings.RunTracker.run || obj.Tracker.IsFinished
            if obj.Tracker.IsFinished || ~obj.settings.RunTracker.preview
                obj.stopPreviewTimer();
                return
            end
                        
            frameNum = obj.Tracker.CurrentFrame;
            obj.AppModules(1).currentFrameNo = frameNum;
            
        end
        
        function onTimerError(obj, src, evt)

            disp(evt)
            
        end
        
        function onFrameChanged(obj, src, evt)
            obj.updateBinarizedImage()
        end
        
    end
    
    
    methods 
        
        function onTabButtonPressed(obj, src, evt)
            
            for iBtn = 1:numel(obj.TabButtonGroup.Buttons)
                
                buttonName = obj.TabButtonGroup.Buttons(iBtn).Text;
                
                if ~isequal(src, obj.TabButtonGroup.Buttons(iBtn))
                    obj.TabButtonGroup.Buttons(iBtn).Value = 0;
                    obj.hideModule(buttonName)
                else
                    obj.TabButtonGroup.Buttons(iBtn).Value = src.Value;
                    
                    if obj.TabButtonGroup.Buttons(iBtn).Value
                        obj.showModule(buttonName)
                    else
                        obj.hideModule(buttonName)
                    end
                end
            end
            
        end
        
        function showModule(obj, moduleName)
            
            switch moduleName
                case 'Pupil Position'
                    obj.pupilPositionViewer.show()
                    
                case 'Pupil Movement'
                    if isempty(obj.pupilMovementViewer)
                        obj.openPupilMovementViewer()
                    else
                        obj.pupilMovementViewer.show()
                    end
            end
        end
        
        function hideModule(obj, moduleName)
                      
            switch moduleName
                case 'Pupil Position'
                    obj.pupilPositionViewer.hide()
                case 'Pupil Movement'
                    obj.pupilMovementViewer.hide()
            end
            
            
        end

    end
    
    
end