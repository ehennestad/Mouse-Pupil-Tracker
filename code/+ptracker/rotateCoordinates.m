function varargout = rotateCoordinates(coords, options, direction)

    if nargin < 3 || isempty(direction)
        direction = 1;
    else
        assert(direction == 1 || direction == -1, 'Direction must be +1 or -1')
    end

    X = coords(:,1);
    Y = coords(:,2);
    
    imSizeXY = options.Configuration.imageSizeXY;
    
    thetaOffsetDeg = options.Configuration.thetaEye; % Note: This is in degrees
    thetaOffsetDeg = direction .* thetaOffsetDeg;
    
    thetaOffset = deg2rad(thetaOffsetDeg);
    
    
    % Todo: Consider the cropping coords?
    % Todo: make rotational transformation...
    
    X = X - imSizeXY(1)/2;
    Y = Y - imSizeXY(2)/2;
        
    [theta, rho] = cart2pol(X, Y);
    theta = theta + thetaOffset;
    
    [X, Y] = pol2cart(theta, rho);
    X = X + imSizeXY(1)/2;
    Y = Y + imSizeXY(2)/2;
       
    
    if nargout == 1
        varargout = {[X, Y]};
    elseif nargout == 2
        varargout = {X, Y};
    end
    
end