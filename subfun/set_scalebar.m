function pixelSize = set_scalebar(mainUIAxes, mainUIScalebarHandle, mainUITextHandle, pixelSize)


%Small ui where the user can set the scale bar options.
% Called when user clicks on "Tools" -> "Scale bar"


%Set visibilty of the scale bar and scale bar text to 'on'
mainUIScalebarHandle.Visible = 'on';
mainUITextHandle.Visible = 'on';

%Create UI
sbUI = CreateScaleBarUI();

%Get settings of the current scalebar
GetCurrentSettings();

%Create dragable rectangle that surrounds the current scalebar
hDragableRectangle = drawrectangle(mainUIAxes,'Position', mainUIScalebarHandle.Position);

%Create a listener, that executes when user interacts with the dragable rectangle
addlistener(hDragableRectangle,'MovingROI',@SbMovedCB);

%Check if a scale bar has been drawn before
if isempty(mainUIScalebarHandle.UserData)
    %Scale bar tool is opened for the first time

    %Place the scalebar into the bottom right, so select corresponding
    %button in the 'set location' button group
    sbUI.btnGroupLocation.SelectedObject = sbUI.btnLR;

    %Set UserData to a non-empty value to mark for the following calls that
    %the scale bar has been drawn once already
    mainUIScalebarHandle.UserData = 1;

    %Update scale bar
    UpdateScaleBar([])
end

%Wait until user closes the scalebar settings ui to return the pixelSize
uiwait(sbUI.f);

%Create scale bar settings UI
    function newSbUI = CreateScaleBarUI()

        textPosHor = 0.05;
        textHeight = 0.05;
        textWidth = 0.5;
        editWidth = 0.15;
        editPosHor = 0.6;
        editHeight = textHeight;
        vertDist = 0.08;
        buttonWidth = 0.3;

        newSbUI.f = figure('Units','normalized',...
            'Position',[0.8 0.2 .2 .35],...
            'MenuBar','None',...
            'Name','Scalebar settings',...
            'NumberTitle','off',...
            'DefaultUicontrolFontSize', 8,...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);

        %% Pixelsize
        uicontrol('String','Pixelsize in microns per px',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*1 textWidth  textHeight]);

        newSbUI.editPixelSize = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*1 editWidth editHeight]);

        %% Scale bar width
        uicontrol('String','Scale bar width in microns',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*2 textWidth  textHeight]);

        newSbUI.editSbWidth = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*2 editWidth editHeight]);

        %% Scale bar height
        uicontrol('String','Scale bar height in pixels',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*3 textWidth  textHeight]);

        newSbUI.editSbHeight = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*3 editWidth editHeight]);


        %% Buttongroup for Location

        newSbUI.btnGroupLocation = uibuttongroup('Units','normalized',...
            'Position', [textPosHor 1-vertDist*4.5 .9 editHeight*2],...
            'Title','Set Location',...
            'SelectionChangedFcn',@UpdateScaleBar);


        newSbUI.btnLR = uicontrol(newSbUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.01  .1  .5 .8],...
            'Style','radiobutton',...
            'String','Lower Right',...
            'HorizontalAlignment','Left');

        newSbUI.btnLL = uicontrol(newSbUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.25  .1  .6 .8],...
            'Style','radiobutton',...
            'String','Lower Left',...
            'HorizontalAlignment','Left');

        newSbUI.UR = uicontrol(newSbUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.5  .1  .6 .8],...
            'Style','radiobutton',...
            'String','Upper Right',...
            'HorizontalAlignment','Left');

        newSbUI.UL = uicontrol(newSbUI.btnGroupLocation,...
            'Units','normalized',...
            'Position', [.75  .1  .6 .8],...
            'Style','radiobutton',...
            'String','Upper Left',...
            'HorizontalAlignment','Left');


        newSbUI.btnGroupLocation.SelectedObject = [];


        %% Scale bar position
        uicontrol('String','Scale bar position: hor(x), vert(y)',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor,  1-vertDist*6, textWidth,  textHeight]);

        newSbUI.editSbPosX = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Tag','sbPosition',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*6 editWidth editHeight]);

        newSbUI.editSbPosY = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Tag','sbPosition',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor+.2 1-vertDist*6 editWidth editHeight]);



        %% Scale bar text
        uicontrol('String','Scale bar text: ',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*8 textWidth  textHeight]);


        newSbUI.popSbTextSetting = uicontrol('String',{'Auto', 'Manual', 'None'},...
            'Style','popupmenu',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*8 editWidth editHeight]);


        newSbUI.editSbText = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor+.2 1-vertDist*8 editWidth editHeight]);



        %% Scale bar font size and font weigth
        uicontrol('String','Scale bar font size: ',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*9  textWidth  textHeight]);

        newSbUI.editSbTextSize = uicontrol('Style','Edit',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*9 editWidth editHeight]);


        newSbUI.cboxBold = uicontrol('String','Bold font',...
            'Style','checkbox',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[editPosHor+.2  1-vertDist*9  textWidth  textHeight],...
            'Callback',@UpdateScaleBar);


        %% Popup menu for text color
        uicontrol('String','Text color: ',...
            'Style','Text',...
            'Units','normalized',...
            'HorizontalAlignment','Left',...
            'Position',[textPosHor  1-vertDist*10  textWidth  textHeight]);

        newSbUI.popColor = uicontrol('String',{'White', 'Black', 'Light Gray', 'Gray', 'Dark Gray', 'Red', 'Green', 'Blue', 'Yellow'},...
            'Style','popupmenu',...
            'Units','normalized',...
            'Callback',@UpdateScaleBar,...
            'Position',[editPosHor 1-vertDist*10 editWidth*1.5 editHeight]);

        %Write RGB values corresponding to the given colors into the
        %userdata property
        newSbUI.popColor.UserData = [1 1 1; 0 0 0; 0.8 0.8 0.8; 0.5 0.5 0.5; 0.3 0.3 0.3; 1 0 0; 0 1 0; 0 0 1; 1 1 0];

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

        %Write pixel size into edit field
        sbUI.editPixelSize.String = pixelSize;

        %Get values from existing scalebar
        sbUI.editSbPosX.String = mainUIScalebarHandle.Position(1);
        sbUI.editSbPosY.String = mainUIScalebarHandle.Position(2);
        sbUI.editSbWidth.String =  mainUIScalebarHandle.Position(3) * pixelSize;
        sbUI.editSbHeight.String =  mainUIScalebarHandle.Position(4);


        %Get Color of existing scalebar and compare it with the colormap of
        %the userdata of the color popup menu
        [~,idx] = ismember(mainUIScalebarHandle.FaceColor, sbUI.popColor.UserData, 'rows');

        %Select the corresponding color
        if ~isempty(idx)
            sbUI.popColor.Value = idx;
        else
            sbUI.popColor.Value = 1;
        end


        %Get values from existing scalebar text
        sbUI.editSbTextSize.String = mainUITextHandle.FontSize;
        sbUI.editSbText.String = mainUITextHandle.String;

        % Define regular expression pattern to check if current width is
        % displayed as scale bar text
        pattern = [sbUI.editSbWidth.String,'\s*µm$'];

        %Compare regular expression with scale bar text
        match = regexp(mainUITextHandle.String, pattern, 'once');

        if match
            %Current width is also displayed as scale bar text, so set the
            %text popup menu to "Auto"
            sbUI.popSbTextSetting.Value = 1;
            %Disable edit field for scale bar text
            sbUI.editSbText.Enable = 'off';
        elseif isempty(mainUITextHandle.String)
            %Scale bar text is empty, so set the text popup menu to "None"
            sbUI.popSbTextSetting.Value = 3;
            %Disable edit field for scale bar text
            sbUI.editSbText.Enable = 'off';
        else
            %Scale bar text is not empty and does not have the actual width
            %in it, so set the text popup menu to "Manual"
            sbUI.popSbTextSetting.Value = 2;
            %Enable edit field for scale bar text
            sbUI.editSbText.Enable = 'on';
        end

        %Check if text is bold
        if strcmp(mainUITextHandle.FontWeight,'bold')
            sbUI.cboxBold.Value = 1;
        end
    end

%Adjust scale bar to new settings
    function UpdateScaleBar(src,~)


        %% Scalebar size and position

        %Get the pixel size from the edit field
        pixelSize = str2double(sbUI.editPixelSize.String);

        %Get the width from the edit field and convert it to pixels
        widthInPixels = str2double(sbUI.editSbWidth.String)/pixelSize;

        %Get the hight from the edit field
        heightInPixels = str2double(sbUI.editSbHeight.String);

        %Check if position needs to be updated
        if ~isempty(src) && strcmp(src.Tag,'sbPosition')
            %User manually changed scalebar position in the "Scale bar position" edit field

            %Uncheck the "Set Location" button group
            sbUI.btnGroupLocation.SelectedObject = [];

            %Get the scale bar position entered by the user
            xPos = str2double(sbUI.editSbPosX.String);
            yPos = str2double(sbUI.editSbPosY.String);

            %Update the scale bar position
            mainUIScalebarHandle.Position = [xPos, yPos, widthInPixels, heightInPixels];

            %Adjust the dragable rectangle
            hDragableRectangle.Position = mainUIScalebarHandle.Position;
        elseif ~isempty(sbUI.btnGroupLocation.SelectedObject)
            %One of the buttons in the "Set location" button group is
            %active, so we automatically set the location with respect to
            %the field of view in the main TrackIt UI

            %Get the axis limits from the main TrackIt UI
            ylim = mainUIAxes.YLim;
            xlim = mainUIAxes.XLim;

            %Calculate the window size
            xWindowSize = xlim(2) - xlim(1);
            yWindowSize = ylim(2) - ylim(1);


            %Set the vertical position with respect to the window size and field of view
            switch sbUI.btnGroupLocation.SelectedObject.String
                case {'Lower Right','Lower Left'}
                    if sbUI.popSbTextSetting.Value == 3
                        %No scalebar text is displayed so move the scalebar further down
                        yPos = ylim(2) - yWindowSize/100 - heightInPixels;
                    else
                        %Leave space for the scalebar text
                        yPos = ylim(2) - yWindowSize/20 - heightInPixels - 0.5;
                    end
                case {'Upper Right','Upper Left'}
                    yPos = ylim(1) + yWindowSize/100;
            end

            %Set the horizontal position with respect to the window size and field of view
            switch sbUI.btnGroupLocation.SelectedObject.String
                case {'Lower Right','Upper Right'}
                    xPos = xlim(2) - xWindowSize/100 - widthInPixels;
                case {'Lower Left','Upper Left'}
                    xPos = xlim(1) + xWindowSize/100;
            end

            %Update the scale bar position
            mainUIScalebarHandle.Position = [xPos, yPos, widthInPixels, heightInPixels];

            %Adjust the dragable rectangle
            hDragableRectangle.Position = mainUIScalebarHandle.Position;

            %Write new position into the "Scale bar position" edit fields
            sbUI.editSbPosX.String = xPos;
            sbUI.editSbPosY.String = yPos;
        else
            %User did not change position so get the old position and update width and height
            xPos = mainUIScalebarHandle.Position(1);
            yPos = mainUIScalebarHandle.Position(2);

            %Update the scale bar position
            mainUIScalebarHandle.Position = [xPos, yPos, widthInPixels, heightInPixels];


            %Adjust the dragable rectangle
            hDragableRectangle.Position = mainUIScalebarHandle.Position;
        end


        %Get the rgb color from the user data field of the color popup menu
        color = sbUI.popColor.UserData(sbUI.popColor.Value,:);

        %Set scale bar color
        mainUIScalebarHandle.FaceColor = color;

        %% Scalebar text settings

        %Get the setting from the text popup menu
        switch sbUI.popSbTextSetting.Value
            case 1
                %Auto
                sbUI.editSbText.Enable = 'off';
                mainUITextHandle.String = [sbUI.editSbWidth.String, ' µm'];
                sbUI.editSbText.String = [sbUI.editSbWidth.String, ' µm'];
            case 2
                %Manual
                sbUI.editSbText.Enable = 'on';
                mainUITextHandle.String = sbUI.editSbText.String;
            case 3
                %Hide
                sbUI.editSbText.Enable = 'off';
                sbUI.editSbText.String = '';
                mainUITextHandle.String = '';
        end


        %Get the value of the "Bold Font" checkbox
        if sbUI.cboxBold.Value
            %Set font weight to bold
            mainUITextHandle.FontWeight = 'bold';
        else
            %Set font weight to normal
            mainUITextHandle.FontWeight = 'normal';
        end

        %Set the scalebar text size
        mainUITextHandle.FontSize = str2double(sbUI.editSbTextSize.String);

        %Set new text position
        mainUITextHandle.Position(1) = xPos + widthInPixels/2;
        mainUITextHandle.Position(2) = yPos+heightInPixels;

        %Set text color
        mainUITextHandle.Color = color;
    end

%Callback: User moved the dragable scalebar rectangle
    function SbMovedCB(~,evt)

        %Get the new position and write it into the "Scale bar position" edit field
        sbUI.editSbPosX.String = evt.CurrentPosition(1);
        sbUI.editSbPosY.String = evt.CurrentPosition(2);

        %Get the new width, convert it to pixels and write it into the "Scale bar width" edit field
        sbUI.editSbWidth.String = evt.CurrentPosition(3)*pixelSize;

        %Get the new height, convert it to pixels and write it into the "Scale bar height" edit field
        sbUI.editSbHeight.String = evt.CurrentPosition(4);

        %Update scale bar position
        mainUIScalebarHandle.Position = evt.CurrentPosition;

        %Deselect the "set location" button group
        sbUI.btnGroupLocation.SelectedObject = [];

        %Set new text position
        mainUITextHandle.Position(1) = mainUIScalebarHandle.Position(1) + mainUIScalebarHandle.Position(3)/2;
        mainUITextHandle.Position(2) = mainUIScalebarHandle.Position(2) + mainUIScalebarHandle.Position(4);


    end

%User pressed "OK"
    function OkCB(~,~)

        %Delete dragable rectangle
        if exist('hDragableRectangle', 'var') == 1
            delete(hDragableRectangle)
        end

        %Delete figure
        delete(gcf)
    end

%User pressed "delete" button
    function CloseRequestCB(~,~)

        %Hide scale bar and text
        mainUIScalebarHandle.Visible = 'off';
        mainUITextHandle.Visible = 'off';

        %Delete pixelSize return value
        pixelSize = [];

        %Delete dragable rectangle
        if exist('hDragableRectangle', 'var') == 1
            delete(hDragableRectangle)
        end

        %Delete figure
        delete(gcf)
    end

%User pressed esc key
    function KeyPressFcnCB(~,event)

        if strcmp(event.Key, 'escape')
            CloseRequestCB()
        end
    end




end
