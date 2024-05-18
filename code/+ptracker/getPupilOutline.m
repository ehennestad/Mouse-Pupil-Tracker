function [outline, position] = getPupilOutline(BW, options)

    % Get boundaries of binary mask
    B = bwboundaries(BW);

    
    if isempty(B)
        outline = [nan, nan];
        position = [nan, nan, nan];
        return
    end
    

    switch options.TrackerOptions.outlineMethod
        
        case 'Detect Boundary'
            stats = regionprops(BW,'centroid', 'convexhull');

            position = stats.Centroid;

            xCoords = stats.ConvexHull(:, 1);
            yCoords = stats.ConvexHull(:, 2);

% %             X = B{1}(:,2);
% %             Y = B{1}(:,1);
% % 
% %                 x0 = mean(X);
% %                 y0 = mean(Y);
% %                 
% %                 k = convhull(X,Y);
% % 
% %                 xCoords = X(k);
% %                 yCoords = Y(k);

            xCoords = circularsmooth(xCoords, 3);
            yCoords = circularsmooth(yCoords, 3);
            xCoords = interp(xCoords, 10);
            yCoords = interp(yCoords, 10);
            xCoords(end)=xCoords(1);
            yCoords(end)=yCoords(1);
            xCoords = circularsmooth(xCoords, 5);
            yCoords = circularsmooth(yCoords, 5);
            xCoords(end)=xCoords(1);
            yCoords(end)=yCoords(1);
            
            outline = [xCoords, yCoords];
            
            position(3) = mean( [range(xCoords), range(yCoords)] ) / 2;
            
        case 'Fit Circle'
            stats = regionprops(BW, 'Centroid', 'ConvexArea');
            position = stats.Centroid;
            position(3) = sqrt(4*stats.ConvexArea/pi) / 2;
            
            outline = uim.shape.circle(position(3));
            outline = position(1:2) + outline - position(3);
            
        case 'Fit Ellipsis'
            stats = regionprops(BW, 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');
            
            a = stats.MajorAxisLength/2; % horizontal radius
            b = stats.MinorAxisLength/2; % vertical radius
            x0 = 0; % x0,y0 ellipse centre coordinates
            y0 = 0;
            t = -pi:0.01:pi;
            x = x0 + a * cos(t);
            y = y0 + b * sin(t);
            
            [theta, rho] = cart2pol(x,y);
            theta = theta - deg2rad(stats.Orientation);
            [x, y] = pol2cart(theta, rho);
            
            x = x + stats.Centroid(1);
            y = y + stats.Centroid(2);
            
            position = [stats.Centroid, mean([a,b])];
            outline = [x',y'];
    end
    
end



function data = circularsmooth(data, N, method)
% Note: Only works for vectors.

    if nargin < 3
        method = 'movmean';
    end

    % Make sure data is a column vector
    if isrow(data)
        data = data';
        isTransposed = true;
    else
        isTransposed = false;
    end

    % Add circular padding
    data = cat(1, data(end-N+1:end), data, data(1:N)); 

    data = smoothdata(data, 1, method, N);
    
    % Remove circular padding
    data = data(N+1:end-N);
    
    % Make sure output has same shape as input
    if isTransposed
        data = data';
    end

end