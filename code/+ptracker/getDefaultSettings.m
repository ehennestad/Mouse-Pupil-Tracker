function P = getDefaultSettings()


    % Default values and uicontrol specifications for the configuration page. 
    
    P.Configuration = struct;
%     % Todo.
%     P.Configuration.loadVideo = false;
%     P.Configuration.loadVideo_  = struct('type', 'button', 'args', {{'String', 'Load Pupil Video...', 'FontWeight', 'bold'}});

    P.Configuration.pupilPolarity = 'dark';
    P.Configuration.pupilPolarity_ = {'bright', 'dark'};
    
    P.Configuration.selectPupil = false;
    P.Configuration.selectPupil_ = struct('type', 'button', 'args', {{'String', 'Click to Select Pupil'}});

    P.Configuration.markCornersOfEye = false;
    P.Configuration.markCornersOfEye_ = struct('type', 'togglebutton', 'args', {{'String', 'Mark Corners of Eye'}});

    P.Configuration.cropImage = false;
    P.Configuration.cropImage_ = struct('type', 'button', 'args', {{'String', 'Crop Image'}});

    P.Configuration.rotateImages = false;
    
    % Internal settings
    P.Configuration.thetaEye = 0; % Todo: rename to thetaEyeDeg
    P.Configuration.thetaEye_ = 'internal';    
    P.Configuration.centerPos = [nan, nan];
    P.Configuration.centerPos_ = 'internal';
    P.Configuration.eyeCoordinates = [nan, nan];
    P.Configuration.eyeCoordinates_ = 'internal';
    P.Configuration.imageSizeXY = [];
    P.Configuration.imageSizeXY_ = 'internal';
    P.Configuration.cropCoordinates = [];
    P.Configuration.cropCoordinates_ = 'internal';
    
    
    % Default values and uicontrol specifications for the tracker options page. 

    P.TrackerOptions.method = 'thresholding';
    P.TrackerOptions.method_ = {'thresholding', 'edgedetection'};
    
    P.TrackerOptions.editOptions  = false;
    P.TrackerOptions.editOptions_  = struct('type', 'button', 'args', {{'String', 'Edit Method Options', 'FontWeight', 'bold'}});
    
    P.TrackerOptions.threshold = 10;
    P.TrackerOptions.threshold_ = struct('type', 'slider', 'args', {{'Min', 1, 'Max', 100, 'nTicks', 100, 'TooltipPrecision', 0, 'TooltipUnits', 'percentile'}});
    
    P.TrackerOptions.removeObjectsSmallerThan = 500;
    P.TrackerOptions.removeObjectsSmallerThan_ = struct('type', 'slider', 'args', {{'Min', 0, 'Max', 2000, 'nTicks', 100, 'TooltipPrecision', 0, 'TooltipUnits', 'pixels'}});

    P.TrackerOptions.imclose = 5;
    P.TrackerOptions.imclose_ = struct('type', 'slider', 'args', {{'Min', 1, 'Max', 10, 'nTicks', 10, 'TooltipPrecision', 0}});

    P.TrackerOptions.showBinarizedImage = false;
    
    P.TrackerOptions.outlineMethod = 'Detect Boundary';
    P.TrackerOptions.outlineMethod_ = {'Detect Boundary', 'Fit Circle', 'Fit Ellipsis'};
    
    P.TrackerOptions.showPupilOutline = false;
    
    
    % Default values and uicontrol specifications for the run tracker page. 
    
    P.RunTracker.run  = false;
    P.RunTracker.run_  = struct('type', 'button', 'args', {{'String', 'Run Tracking', 'FontWeight', 'bold'}});
    
    P.RunTracker.runOnSeparateWorker = false;
    
    P.RunTracker.startAt = 'Beginning';
    P.RunTracker.startAt_ = {'Beginning', 'Current Image'};
    
    %P.RunTracker.preview = false; % Todo: remove...
    
    P.RunTracker.SavePath = '';
    P.RunTracker.SavePath_ = 'uiputfile';
    
    P.RunTracker.savePupilData = false;
    P.RunTracker.savePupilData_  = struct('type', 'button', 'args', {{'String', 'Save PupilData', 'FontWeight', 'bold'}});

    P.RunTracker.loadPupilData = false;
    P.RunTracker.loadPupilData_  = struct('type', 'button', 'args', {{'String', 'Load PupilData...', 'FontWeight', 'bold'}});
    
    P.RunTracker.plotPupilCenterOnImage = false;
    P.RunTracker.plotPupilCenterOnImage_ = struct('type', 'togglebutton', 'args', {{'String', 'Show Pupil Trajectory'}});
    

    
    % Default values and uicontrol specifications for postprocessing. 

    P.ProcessResults.showRotatedCoordinates = false;
    
    P.ProcessResults.applyOkadaFilter = false;
    P.ProcessResults.movementDetectionStdValue = 1;
    P.ProcessResults.movementDetectionStdValue_ = struct('type', 'slider', 'args', {{'Min', 0, 'Max', 10, 'nTicks', 101, 'TooltipPrecision', 1}});
    
    P.ProcessResults.removeConsecutive = true;
    P.ProcessResults.maxFrequency = 5;
    P.ProcessResults.maxFrequency_ = struct('type', 'slider', 'args', {{'Min', 0, 'Max', 10, 'nTicks', 101, 'TooltipPrecision', 1}});
    
    P.ProcessResults.updatePupilPlot = false;
    P.ProcessResults.updatePupilPlot_  = struct('type', 'togglebutton', 'args', {{'String', 'Update PupilData Plot', 'FontWeight', 'bold'}});

end