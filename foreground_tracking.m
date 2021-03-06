function foreground_tracking(obj, event,vid,demoParameters)
    persistent imgIn;
    persistent bgModel;
    persistent nFrames;
    persistent handlesInput;
    persistent handlesFg;
    persistent handlesTracking;
    persistent handles2D;
    persistent trackingData;
    persistent H;
    persistent img2Dplane;
    trigger(vid);
    imgIn= imresize(getdata(vid,1,'uint8'),demoParameters.resizeScale);
    
    thresh = 80;
    fileName = demoParameters.fileName;
    imgSize = size(imgIn);
    
    if isempty(handlesInput)
        % if first execution, we create the figure objects
        subplot(2,2,1);
        handlesInput=imshow(imgIn);
        title(['Current image, resolution = ' num2str(imgSize(2)) 'x' num2str(imgSize(1))]);

        %initialise the frame number
        nFrames = 1;
        %load background model and homography
        bgModel = load(['models/' fileName '_background_model.mat'],'bgModelOut');
        bgModel = bgModel.bgModelOut;
        H = load(['models/' fileName '_homography.mat'],'H');
        H = H.H;
        img2Dplane = create_2D_plane(H,bgModel,demoParameters.xDistance+1,demoParameters.yDistance+1);

        % show foreground detection
        subplot(2,2,2);
        fgImg = double(max(abs(double(imgIn)-double(bgModel))>thresh,[],3));
        fgImg = filter_foreground(fgImg);
        handlesFg=imshow(fgImg,[]);
        title('Estimated foreground');

        % show tracking
        subplot(2,2,3);
        handlesTracking=imshow(fgImg,[]);
        title('Tracked objects');
        %initialise tracking data
        trackingData.trackingObj = setupSystemObjects();
        trackingData.tracks = initializeTracks();
        trackingData.nextId = 1;

        % show tracking
        subplot(2,2,4);
        handles2D=imshow(imgIn);
        title('2D projection');
    else
        nFrames = nFrames+1;
        set(handlesInput,'CData',imgIn);
        
        fgImg = double(max(abs(double(imgIn)-double(bgModel))>thresh,[],3));
        fgImg = filter_foreground(fgImg);
 
        set(handlesFg,'CData',fgImg);
        
        %show tracking
        fgImg = zeros(size(fgImg));
        [trackedFrame,trackingData] = track_objects(imgIn,logical(fgImg),trackingData);
        set(handlesTracking,'CData',trackedFrame);
        
        % show 2D projection
        tracksTemp = trackingData.tracks;
        for ii=1:length(tracksTemp)
            tracksBboxes(ii,:) = double(tracksTemp(ii).bbox);
        end
        
        %if there are tracks to show, display them
        if (exist('tracksBboxes','var'))
            [~,maxAreaTrack] = min(tracksBboxes(:,3).*tracksBboxes(:,4));
            posY = round(tracksBboxes(maxAreaTrack,2)+tracksBboxes(maxAreaTrack,4));
            posX = round(tracksBboxes(maxAreaTrack,1)+floor(tracksBboxes(maxAreaTrack,4))/2);
            imgProjected = imresize(project_2D_point(H,img2Dplane,posY,posX),[size(imgIn,1) size(imgIn,2)]);
            set(handles2D,'CData',imgProjected);
        end
    end
end