function [ Occ ] = fillOccupancyGrid( A, Occ, motion )
%FILLOCCUPANCYGRID update an occupancy OCC with a scan A using different
%types of models. For probabilistic sonar, A must be in polar coordinates
% locally referenced from the robot position. The shift will be calculated
% using the motion.



L = Occ.PARAM.L;
xmin = Occ.PARAM.xmin;
xmax = Occ.PARAM.xmax;
ymin = Occ.PARAM.ymin;
ymax = Occ.PARAM.ymax;

sscan = size(A,1);
xwide = abs(xmax - xmin);
ywide = abs(ymax - ymin);

xrob = motion(1);
yrob = motion(2);
throb = motion(3);


% We need these coordinates to reference the cell in global coordinates
[rx ry] = getCoordinates( [xrob yrob] , Occ.PARAM);

NX = floor(xwide / L)+1;
NY = floor(ywide / L)+1;

%%Occ.grid = zeros(NX,NY);

for i = 1:sscan
    x = A(i,1);
    y = A(i,2);
    
    switch(Occ.PARAM.type)
        
        % In the binary model, only the cell believed to be hit is filled
        case 'binary'
            
            %Calculate the cell where the point (x,y) should fall in.
            [ix1 iy1] = getCoordinates( [x y], Occ.PARAM);
            
            % global reference the scan shifting of a number of
            % cells equal to the robot's position cell
            Occ.grid(ix1,iy1) = 1;
        case 'binary sonar'    
            
            
        case 'prob sonar'
            
            rangeb = A(i,2);
            angleb = A(i,1) + throb; % global reference the scan
            bwdth = Occ.PARAM.bwidth;
            % calculate the length of the chord by the size of the cell as
            % approximate number of cells to check
            
            rwidth = floor( rangeb / L );
            for j = 1:rwidth
                
                incrr = (rangeb / rwidth) * j;
                if j == rwidth
                    incrr = rangeb;
                end
                nrangeb =  incrr;
                lwidth = floor( ( 2*nrangeb*cos(bwdth/2) ) / L ) +1;
                for k = -lwidth:1:lwidth
                    
                    % calculate an angular shift and its relative occupancy
                    incra =  (bwdth/2)/lwidth * k;
                    nangleb = angleb + incra;
                    [xp yp] = pol2cart(nangleb ,nrangeb);
                    
                    % global reference the scan shifting of a number of
                    % cells equal to the robot's position cell
                    
                    ix1 = min(floor( ( abs(xmin) + xp + xrob) / L)+1,NX);
                    iy1 = min(floor( ( abs(ymin) + yp + yrob) / L)+1,NY);
                    pocc = ( ( (Occ.PARAM.maxr - nrangeb ) / Occ.PARAM.maxr ) + ...
                        ( (bwdth - abs(incra) ) / bwdth ) ) / 2
                    
                    pemp = 1 - pocc;
                    
                    % this area is behind the occupied chord so the
                    % probability is inverse
                    if j < rwidth
                        pocc = 1 - pocc;
                        pemp = pocc;
                    end
                    
                    % The cell was not visited yet
                    if Occ.grid(ix1,iy1) == -2
                        Occ.grid(ix1,iy1) = pocc ;
                    else
                        % Update the cell using the bayes rule
                        Occ.grid(ix1,iy1) = (pocc * Occ.grid(ix1,iy1)) / ...
                            (pocc * Occ.grid(ix1,iy1) +   pemp * ( 1 - Occ.grid(ix1,iy1) ) ) ;
                    end
                    
                end
            end
            
        case 'logodds sonar'
            rangeb = A(i,2);
            angleb = A(i,1) + throb; % global reference the scan
            bwdth = Occ.PARAM.bwidth;
            % calculate the length of the chord by the size of the cell as
            % approximate number of cells to check
            
            rwidth = floor( rangeb / L );
            for j = 1:rwidth
                
                incrr = (rangeb / rwidth) * j;
                if j == rwidth
                    incrr = rangeb;
                end
                nrangeb =  incrr;
                lwidth = floor( ( 2*nrangeb*cos(bwdth/2) ) / L ) +1;
                for k = -lwidth:1:lwidth
                    
                    % calculate an angular shift and its relative occupancy
                    incra =  (bwdth/2)/lwidth * k;
                    nangleb = angleb + incra;
                    [xp yp] = pol2cart(nangleb ,nrangeb);
                    
                    % global reference the scan shifting of a number of
                    % cells equal to the robot's position cell
                    
                    ix1 = min(floor( ( abs(xmin) + xp + xrob) / L)+1,NX);
                    iy1 = min(floor( ( abs(ymin) + yp + yrob) / L)+1,NY);
                    pocc = ( ( (Occ.PARAM.maxr - nrangeb ) / Occ.PARAM.maxr ) + ...
                        ( (bwdth - abs(incra) ) / bwdth ) ) / 2;
                    
                    
                    pemp = 1 - pocc;
                    
                    % this area is behind the occupied chord so the
                    % probability is inverse
                    if j < rwidth
                        pocc = 1 - pocc;
                        pemp = pocc;
                    end
                    
                    % The cell was not visited yet
                    if Occ.grid(ix1,iy1) == -2
                        Occ.grid(ix1,iy1) = pocc ;
                    else
                        % Update the cell using the bayes rule
                        Occ.grid(ix1,iy1) = (pocc * Occ.grid(ix1,iy1)) / ...
                            (pocc * Occ.grid(ix1,iy1) +   pemp * ( 1 - Occ.grid(ix1,iy1) ) ) ;
                    end
                    
                end
            end
    end
    
end

