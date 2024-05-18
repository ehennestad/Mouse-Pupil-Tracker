classdef PupilTracker < handle
    
    
    properties
        
       StartFrame = 1
       CurrentFrame = 1
       NumFrames = 1
       
       ShowPreview = false
       IsFinished = false
       
       PupilData = struct()
       Verbose = true
    end
    
    
    properties (Access = protected)
        hImageStack
        options
        IsCanceled = false;
    end
    
    
    
    methods
        function obj = PupilTracker(hImageStack, options)
            obj.hImageStack = hImageStack;
            obj.options = options;
            
            obj.NumFrames = obj.hImageStack.NumFrames;
            
            obj.initializePupilData()
            
        end

    end
    
    
    methods (Access = protected) % Setup
        
        function initializePupilData(obj)
            
            nFrames = obj.NumFrames;
            
            trackData = struct();
%             trackData.CenterX = nan(nFrames, 1);
%             trackData.CenterY = nan(nFrames, 1);
            trackData.Center = nan(nFrames, 2);
            trackData.Radius = nan(nFrames, 1);
            trackData.Width = nan(nFrames, 1);
            trackData.Height = nan(nFrames, 1);
            trackData.Orientation = nan(nFrames, 1);
            
            obj.PupilData = trackData;
            
        end
        
    end
    
    
    methods % Control tracking
        
        function run(obj)
            
            % Use highjacked fprintf if available
            global fprintf 
            if isempty(fprintf); fprintf = str2func('fprintf'); end
            
            tic
            prevstr = [];
            
            frameIndices = obj.hImageStack.getChunkedFrameIndices(1000);
            numParts = numel(frameIndices);
            
            for iPart = 1:numParts

                iIndices = frameIndices{iPart};
                %imChunk = obj.hImageStack.Data(:, :, iIndices);
                   
                imChunk = obj.hImageStack.getFrameSet(iIndices);
                imChunk = squeeze(imChunk);
                c=0;
                for j = iIndices
                    c = c+1;
                    
                    IM = imChunk(:, :, c);
                    BW = ptracker.getBinarizedImage(IM, obj.options);

                    [~, position] = ptracker.getPupilOutline(BW, obj.options);

                    %obj.PupilData.CenterX(j, :) = position(1);
                    %obj.PupilData.CenterY(j, :) = position(2);
                    obj.PupilData.Center(j, :) = position(1:2);
                    obj.PupilData.Radius(j, :) = position(3);

                    obj.CurrentFrame = j;

                    if obj.IsCanceled
                        break
                    end

                    if obj.ShowPreview
                        drawnow limitrate
                    end

                    if mod(j,10) == 0 && obj.Verbose
                        str = sprintf('Finished frame %d out of %d', j , obj.NumFrames);
                        refreshdisp(str, prevstr, j);
                        prevstr=str;
                        
                        %if ~exist('fprintf', 'builtin') == 5
                            if ~isequal(fprintf, str2func('fprintf') )
                                fprintf(str)
                            end
                        %end
                    end
                    
                end
            end
            
            fprintf('\n')
            toc
            
            if j == obj.NumFrames
                obj.IsFinished = true;
            end

        end
        
        
        function stop(obj)
            obj.IsCanceled = true;
        end
        
    end
    
end

function refreshdisp(str,prevstr,iteration)

    if ~exist('iteration','var')
        iteration=2;
    end
    
    if iteration==1
        fprintf(str)
    else
        fprintf(char(8*ones(1,length(prevstr))));
        fprintf(str);
    end
end