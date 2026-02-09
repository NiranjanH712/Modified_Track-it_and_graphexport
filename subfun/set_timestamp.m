function set_timestamp(hMainUIAxes, hMainUITimestamp, hFrameSlider)


%Small ui where the user can set the timestamp options.
% TrackIt GUI. Called when user clicks on "Tools" -> "Timestamp"


%Make timestamp visible
hMainUITimestamp.Visible = 'on';

%Create UI
tsUI = CreateTimestampUI();

%Get settings of the current timestamp
GetCurrentSettings();

%Create dragable crosshair
crossHairHandle = drawcrosshair(hMainUIAxes,'Position', [str2double(tsUI.editTsPosX.String) str2double(tsUI.editTsPosY.String)]);

%Create a listener, that executes when user interacts with the dragable crosshair
addlistener(crossHairHandle,'MovingROI',@TsMovedCB);

%Check if a timestamp has been shown ebefore
if isempty(hMainUITimestamp.String)
    %Timestamp tool is opened for the first time

    %Place the scalebar into the bottom right, so select corresponding
    %button in the 'set location' button group
    tsUI.btnGroupLocation.SelectedObject = tsUI.btnLR;

    %Update timestamp
    UpdateTimestampCB([])
end


%Create time stamp settings UI
    function tsUI = CreateTimestampUI()

        textPosHor = 0.05;
        textHeight = 0.05;
        textWidth = 0.5;
        editWidth = 0.15;
        editPosHor = 0.6;
        editHeight = textHeight;
        vertDist = 0.08;
        buttonWidth = 0.3;

        tsUI.f = figure('Units','normalized',...
            'Position',[0.8 0.2 .2 .35],...
            'MenuBar','None',...
            'Name','Scalebar settings',...
            'NumberTitle','off',...
            'DefaultUicontrolFontSize', 8,...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);

        tsUI.tbFrameTime = uitable('Units','normalized',...
            'Position',[textPosHor  1-vertDist*3 .9  .2],...
            'ColumnName',{'#frames in sequence';'Frame cycle time'},...
            'Data',[{0,0}; repmat({'',''},20,1)],...
            'ColumnEditable',[true,true],...
            'CellEditCallback',@UpdateTimestampCB);


        %% Number of digits after decimal point
        uicontrol('String','Number of digits after decimal point',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*4 textWidth  textHeight]);

        tsUI.editTsDigits = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateTimestampCB,...
            'Position',[editPosHor 1-vertDist*4 editWidth editHeight]);

        %% Font size
        uicontrol('String','Timestamp font size: ',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*5  textWidth  textHeight]);

        tsUI.editTsTextSize = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateTimestampCB,...
            'Position',[editPosHor 1-vertDist*5 editWidth editHeight]);


        %% Popup menu for text color
        uicontrol('String','Text color: ',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*6  textWidth  textHeight]);

        tsUI.popColor = uicontrol('String',{'White', 'Black', 'Light Gray', 'Gray', 'Dark Gray', 'Red', 'Green', 'Blue', 'Yellow'},...
            'Style','popupmenu',...
            'Units','normalized',...
            'Callback',@UpdateTimestampCB,...
            'Position',[editPosHor 1-vertDist*6 editWidth*2 editHeight]);

        %Write RGB values corresponding to the given colors into the
        %userdata property
        tsUI.popColor.UserData = [1 1 1; 0 0 0; 0.8 0.8 0.8; 0.5 0.5 0.5; 0.3 0.3 0.3; 1 0 0; 0 1 0; 0 0 1; 1 1 0];


        %% Popup menu for Location



        tsUI.btnGroupLocation = uibuttongroup('Units','normalized',...
            'Position', [textPosHor 1-vertDist*8 .9 editHeight*2],...
            'Title','Set Location',...
            'SelectionChangedFcn',@UpdateTimestampCB);


        tsUI.btnLR = uicontrol(tsUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.01  .1  .5 .8],...
            'Style','radiobutton',...
            'String','Lower Right',...
            'HorizontalAlignment','Left');

        tsUI.btnLL = uicontrol(tsUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.25  .1  .6 .8],...
            'Style','radiobutton',...
            'String','Lower Left',...
            'HorizontalAlignment','Left');

        tsUI.UR = uicontrol(tsUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.5  .1  .6 .8],...
            'Style','radiobutton',...
            'String','Upper Right',...
            'HorizontalAlignment','Left');

        tsUI.UL = uicontrol(tsUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.75  .1  .6 .8],...
            'Style','radiobutton',...
            'String','Upper Left',...
            'HorizontalAlignment','Left');


        tsUI.btnGroupLocation.SelectedObject = [];


        %% Bold Checkbox
        tsUI.cboxBold = uicontrol('String','Bold font',...
            'Style','checkbox',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*9  textWidth  textHeight],...
            'Callback',@UpdateTimestampCB);



        %% Additional text
        uicontrol('String','Additional text (linebreak with \n)',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*10 textWidth  textHeight]);

        tsUI.editTsText = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateTimestampCB,...
            'Position',[editPosHor 1-vertDist*10 editWidth*2 editHeight]);

        %% Scalebar position
        uicontrol('String','Scalebar position: hor(x), vert(y)',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor,  1-vertDist*11, textWidth,  textHeight]);

        tsUI.editTsPosX = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Tag','tsPosition',...
            'Callback',@UpdateTimestampCB,...
            'Position',[editPosHor 1-vertDist*11 editWidth editHeight]);

        tsUI.editTsPosY = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Tag','tsPosition',...
            'Callback',@UpdateTimestampCB,...
            'Position',[editPosHor+.2 1-vertDist*11 editWidth editHeight]);


        %% Buttons

        uicontrol('String','Delete',...
            'Units','normalized',...
            'Position',[.35 0.02 buttonWidth textHeight*1.5],...
            'Callback',@CloseRequestCB);


        uicontrol('String','OK',...
            'Units','normalized',...
            'Position',[.68 0.02 buttonWidth textHeight*1.5],...
            'Callback',@OkCB);







    end

%Retrieve the settings of the current scale bar
    function GetCurrentSettings()

        %Retrieve frame cycle times array from main ui timestamp handle
        %user data
        frameCycleTimesArray = hMainUITimestamp.UserData.frameCycleTimes;

        %Count number of different frame cycle time sequences
        nSequences = size(frameCycleTimesArray,1);

        %Convert array into character array
        charArray = cellfun(@num2str, num2cell(frameCycleTimesArray), 'UniformOutput', false);

        %Fill sequences table in the scalebar settings ui with sequences
        %from the timestamp handle user data
        tsUI.tbFrameTime.Data(1:nSequences,:) = charArray;

        %Get suffix from the main ui timestamp handle userdata and write it
        %into the 'additional text' edit field
        tsUI.editTsText.String = hMainUITimestamp.UserData.suffix;

        %Get number of digits after decimal point from the main ui timestamp handle userdata and write it
        %into the 'Nuimber of digits after decimal point' edit field
        tsUI.editTsDigits.String = hMainUITimestamp.UserData.nDigitsAfDecPoint;

        %Get font size of existing time stamp and write it into the
        %corresponding edit field
        tsUI.editTsTextSize.String = hMainUITimestamp.FontSize;

        %Get Color of existing timestamp and compare it with the colormap of
        %the userdata of the color popup menu
        [~,idx] = ismember(hMainUITimestamp.Color, tsUI.popColor.UserData, 'rows');

        %Select the corresponding color
        if ~isempty(idx)
            tsUI.popColor.Value = idx;
        else
            tsUI.popColor.Value = 1;
        end


        %Check if text is bold
        if strcmp(hMainUITimestamp.FontWeight,'bold')
            tsUI.cboxBold.Value = 1;
        end


        %Get position from existing scalebar and write it into the
        %corresponing edit field
        tsUI.editTsPosX.String = hMainUITimestamp.Position(1);
        tsUI.editTsPosY.String = hMainUITimestamp.Position(2);

    end

%Adjust timestamp to new settings
    function UpdateTimestampCB(src,~)


        %% Timestamp position


        if ~isempty(src) && strcmp(src.Tag,'tsPosition')
            %User manually changed timestamp position in the "timestamp position" edit field

            %Uncheck the "Set Location" button group
            tsUI.btnGroupLocation.SelectedObject = [];

            %Get new scalebar position
            xPos = str2double(tsUI.editTsPosX.String);
            yPos = str2double(tsUI.editTsPosY.String);

            %Adjust the dragable crosshair
            crossHairHandle.Position = [xPos yPos];

            %Set new text position
            hMainUITimestamp.Position = [xPos yPos];

        elseif ~isempty(tsUI.btnGroupLocation.SelectedObject)
            %One of the buttons in the "Set location" button group is
            %active, so we automatically set the location with respect to
            %the field of view in the main TrackIt UI


            %Get the axis limits from the main TrackIt UI
            ylim = hMainUIAxes.YLim;
            xlim = hMainUIAxes.XLim;

            %Calculate the window size
            xWindowSize = xlim(2) - xlim(1);
            yWindowSize = ylim(2) - ylim(1);


            %Set the vertical position with respect to the window size and
            %field of view
            switch tsUI.btnGroupLocation.SelectedObject.String
                case {'Lower Right','Lower Left'}
                    yPos = ylim(2) - yWindowSize/100;
                    hMainUITimestamp.VerticalAlignment = 'bottom';
                case {'Upper Right','Upper Left'}
                    yPos = ylim(1) + yWindowSize/100;
                    hMainUITimestamp.VerticalAlignment = 'top';
            end

            %Set the horizontal position with respect to the window size and
            %field of view
            switch tsUI.btnGroupLocation.SelectedObject.String
                case {'Lower Right','Upper Right'}
                    xPos = xlim(2) - xWindowSize/100;
                    hMainUITimestamp.HorizontalAlignment = 'right';
                case {'Lower Left','Upper Left'}
                    xPos = xlim(1) + xWindowSize/100;
                    hMainUITimestamp.HorizontalAlignment = 'left';
            end

            %Write new position into the "timestamp position" edit fields
            tsUI.editTsPosX.String = num2str(xPos);
            tsUI.editTsPosY.String = num2str(yPos);

            %Adjust the dragable crosshair
            crossHairHandle.Position = [xPos yPos];

            %Set new text position
            hMainUITimestamp.Position = [xPos yPos];
        end


        %% Scalebar text settings

        %Get the value of the "Bold Font" checkbox
        if tsUI.cboxBold.Value
            %Set font weight to bold
            hMainUITimestamp.FontWeight = 'bold';
        else
            %Set font weight to normal
            hMainUITimestamp.FontWeight = 'normal';
        end


        %Set the timestamp text size
        hMainUITimestamp.FontSize = str2double(tsUI.editTsTextSize.String);


        %Get the rgb color from the user data field of the color popup menu
        %and set the timestamp color
        hMainUITimestamp.Color = tsUI.popColor.UserData(tsUI.popColor.Value,:);


        %% Calculate time of current frame

        %Get cell array from frame cycle time table
        cellArray = tsUI.tbFrameTime.Data;

        %Check non-empty rows
        nonEmptyRows = sum(~cellfun('isempty', cellArray),2) == 2;

        %Keep only non-empty rows
        cellArray = cellArray(nonEmptyRows, :);

        %Convert to numbers
        frameCycleTimes = cellfun(@str2double, cellArray);

        %Get current frame from frame slider handle
        curFrame = round(hFrameSlider.Value)-1;

        %Get total number of frames in the frame cycle times table
        framesInSeqSum = sum(frameCycleTimes(:,1));


        %Calculate total time needed for one iteration through all
        %sequences in the frame cycle time table and create a vector
        %containing the frame times of each frame

        nSequences = size(frameCycleTimes,1);
        timeForCompleteSequenceIteration = 0;
        timeVector = [];

        nFramesInLoop = 0;

        for idx = 1:nSequences
            timeForCompleteSequenceIteration = timeForCompleteSequenceIteration + frameCycleTimes(idx,1)*frameCycleTimes(idx,2);
            nFramesInCurSequence = frameCycleTimes(idx,1);
            timeVector(nFramesInLoop+1:nFramesInLoop+nFramesInCurSequence) = frameCycleTimes(idx,2);
            nFramesInLoop = nFramesInLoop + frameCycleTimes(idx,1);
        end

        %Get number of fully completed sequences
        nCompleteSeq = floor(curFrame/framesInSeqSum);

        %Get amount of frames that do not complete a full sequence
        remainder = mod(curFrame,framesInSeqSum);

        %Total time of current frame is: number of completed sequences
        %times time for a complete sequence + the time for the partially
        %completed sequence
        curTime = timeForCompleteSequenceIteration * nCompleteSeq + sum(timeVector(1:remainder));


        %Get number of digits after decimal point from the edit field
        nDigitsAfDecPoint = tsUI.editTsDigits.String; 

        %Get additional text from the edit field
        suffix = tsUI.editTsText.String; 

        %Write frame cycle time array, number of digits after decimal point
        %and additional text (suffix) into a structure variable to save it
        %in the timestamp handle user data property.

        ts = struct(...
            'frameCycleTimes',frameCycleTimes,...
            'nDigitsAfDecPoint',nDigitsAfDecPoint,...
            'suffix', suffix);

        hMainUITimestamp.UserData = ts;

        %Create a pattern where the number of digits after the decimal
        %point is considered, and the additional text (eg. seconds) is
        %added.
        formatspec = ['%0.',ts.nDigitsAfDecPoint,'f ', ts.suffix];

        %Write text into timestamp handle
        hMainUITimestamp.String = sprintf(formatspec,curTime);

    end

%User moved the dragable crosshair
    function TsMovedCB(~,evt)


        hMainUITimestamp.Position = evt.CurrentPosition;

        tsUI.editTsPosX.String = evt.CurrentPosition(1);
        tsUI.editTsPosY.String = evt.CurrentPosition(2);


        tsUI.btnGroupLocation.SelectedObject = [];
    end

%User pressed "OK"
    function OkCB(~,~)

        %User pressed "OK"

        %Delete dragable crosshair
        if exist('crossHairHandle', 'var') == 1
            delete(crossHairHandle)
        end

        %Delete figure
        delete(gcf)
    end

%User pressed "delete" button
    function CloseRequestCB(~,~)

        %User pressed "delete" button

        %Hide timestamp
        hMainUITimestamp.Visible = 'off';

        %Delete dragable crosshair
        if exist('crossHairHandle', 'var') == 1
            delete(crossHairHandle)
        end

        %Delete figure
        delete(gcf)
    end


%User pressed esc key
    function KeyPressFcnCB(~,event)
        %User pressed esc key

        if strcmp(event.Key, 'escape')
            CloseRequestCB()
        end
    end




end
