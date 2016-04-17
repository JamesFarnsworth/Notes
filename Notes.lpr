program Notes;

{$mode objfpc}{$H+}
{$APPTYPE GUI} //So the console window doesn't show
uses
  Windows, Wingraph in 'wingraph.pas;', WinCrt in 'wincrt.pas', Winmouse in 'winmouse.pas',
  Classes, SysUtils, StrUtils, Math;

type
  tText = record
    X, Y: longint;
    Text: string;
    Font: word;
    FontSize: integer;
    LinkedBack: boolean;
  end;

var
  Gd, Gm, FontPanelTab, LastPanelCalled: smallint;
  MouseX, MouseY, MouseXAsOfLastTextEntry, MouseYAsOfLastTextEntry: integer;
  numoftexts, CurrentStringPos, NoOfTextsLinkedTogether, CharsToDisplay: integer;
  WhereCollectionOfTextItemsStarts, CursorCountdown, Count, UserSizeOfFont, DefaultFontSize: integer;
  inputkey, keyfound: char;
  User_Font, DefaultFont: word;
  FoundText, SpecialKeyPressed,BackspacingEnabled: boolean;
  NotesFile: TextFile;
  Str, Str2, FileAddress: string;
  Texts: array of tText;

const
  MAX_X = 420;
  MAX_Y = 594;
  FontSizeTab = 1;
  FontTab = 0;
  ControlBar = 0;
  FontPanel = 1;
  BMP_Panel = 2;
  None = 3;
  //Settings
  SHOW_INFO = False; //Set to true to show general info about record items.

  procedure Save;
  begin
    assignfile(NotesFile, 'Notes.txt');
    rewrite(NotesFile);
    case DefaultFont of                          //DefaultFont is not implemented yet,
      ArialFont: Str := 'ArialFont';             //but it is loaded and saved inside the program
      CourierNewFont: Str := 'CourierNewFont';   //so changes to it during runtime will be saved.
      MSSansSerifFont: Str := 'MSSansSerifFont';
      TimesNewRomanFont: Str := 'TimesNewRomanFont';
    end;
    writeln(NotesFile, Str);
    writeln(NotesFile, IntToStr(DefaultFontSize));
    for Count := 0 to numoftexts - 1 do
    begin
      case Texts[Count].Font of
        ArialFont: Str := 'ArialFont';
        CourierNewFont: Str := 'CourierNewFont';
        MSSansSerifFont: Str := 'MSSansSerifFont';
        TimesNewRomanFont: Str := 'TimesNewRomanFont';
      end;
      //Write necessary info to the file in a way that is readable by the program.
      writeln(NotesFile, IntToStr(Texts[Count].X) + ',' + IntToStr(Texts[Count].Y) +
              ',' + IntToStr(Texts[Count].FontSize) +  ',' + Str + ',' + Texts[Count].Text);
    end;
    settextstyle(ArialFont, Horizdir, 10);
    for Count := -10 to 0 do
    begin  //Draw 'Saved Notes.txt' that drops down from the top.
      bar(0, 0, textwidth('Saved Notes.txt'), Count + 10);
      outtextxy(0, Count, 'Saved Notes.txt');
      updategraph(updatenow);
      sleep(5);
    end;
    sleep(1000);
    for Count := 0 downto -10 do
    begin
      bar(0, 0, textwidth('Saved Notes.txt'), Count + 10);
      outtextxy(0, Count, 'Saved Notes.txt');
      updategraph(updatenow);
      sleep(5);
    end;
  end;

  procedure Load;
  begin
    assignfile(NotesFile, 'Notes.txt');
    reset(NotesFile);
    readln(NotesFile, Str);
    case str of
      'ArialFont': DefaultFont := ArialFont;
      'CourierNewFont': DefaultFont := CourierNewFont;
      'MSSansSerifFont': DefaultFont := MSSansSerifFont;    //for conversion between word and string. Wingraph needs a word variable for fonts,
      'TimesNewRomanFont': DefaultFont := TimesNewRomanFont;//but the default font information is stored in a text file in string form
    end;
    readln(NotesFile, Str);
    DefaultFontSize := StrToInt(Str); //Read and set the default font size.
    while not EOF(NotesFile) do
    begin
      CurrentStringPos := 1;
      Inc(numoftexts);
      setlength(Texts, numoftexts);
      readln(NotesFile, Str);
      with Texts[numoftexts - 1] do
      begin
        repeat
          Inc(CurrentStringPos);
        until (str[CurrentStringPos] = ',');
        X := StrToInt(leftstr(Str, CurrentStringPos - 1)); //going through the file, using commas to find
        Inc(CurrentStringPos);                             //where a specific piece of information starts or ends
        Str := midstr(Str, CurrentStringPos, length(Str) - CurrentStringPos + 1);
        CurrentStringPos := 1;
        repeat
          Inc(CurrentStringPos);
        until (str[CurrentStringPos] = ',');
        Y := StrToInt(leftstr(Str, CurrentStringPos - 1));
        Inc(CurrentStringPos);
        Str := midstr(Str, CurrentStringPos, length(Str) - CurrentStringPos + 1);
        CurrentStringPos := 1;
        repeat
          Inc(CurrentStringPos);
        until str[CurrentStringPos] = ',';
        FontSize := StrToInt(leftstr(Str, CurrentStringPos - 1));
        Inc(CurrentStringPos);
        Str := midstr(Str, CurrentStringPos, length(Str) - CurrentStringPos + 1);
        CurrentStringPos := 1;
        repeat
          Inc(CurrentStringPos);
        until (str[CurrentStringPos] = ',');
        str2 := leftstr(Str, CurrentStringPos - 1);
        case str2 of
          'ArialFont': Font := ArialFont;
          'CourierNewFont': Font := CourierNewFont;
          'MSSansSerifFont': Font := MSSansSerifFont;
          'TimesNewRomanFont': Font := TimesNewRomanFont;
        end;
        Text := rightstr(str, length(str) - CurrentStringPos);
      end;
    end;
    closefile(NotesFile);
  end;

  procedure InitGraphAndProgram;
  begin
    //Initiate graph
    setwindowsize(420, 594);
    gd := 9;
    gm := 13;
    InitGraph(Gd, Gm, 'Notes');
    setcolor(Black);
    updategraph(updateoff);
    User_Font := DefaultFont;
    UserSizeOfFont := DefaultFontSize;
    FontPanelTab := FontTab;
    LastPanelCalled := None;
    CursorCountdown := 9;
    Inputkey := #1;
    FileAddress := '';
    CharsToDisplay := 0;
  end;

  procedure ReportStatus;
  begin
    settextstyle(ArialFont, HorizDir, 10);
    outtextxy(0, 40, 'NumOfTexts=' + IntToStr(NumOfTexts));
    outtextxy(0, 60, 'Text items in ascending order, from 0 to numoftexts-1:');
    for Count := 0 to numoftexts - 1 do  //Draw information about text items.
      outtextxy(0, 70 + (Count * 10), Texts[Count].Text + ', X=' +
                IntToStr(Texts[Count].X) + ', Y=' + IntToStr(Texts[Count].Y) +
                ', Font Size=' + IntToStr(Texts[Count].FontSize));

    outtextxy(0, (numoftexts * 10) + 70, 'Current mouse position: X=' +
              IntToStr(mousex) + ' Y=' + IntToStr(mousey));
  end;

  procedure DrawTexts;
  begin
    if numoftexts >= 1 then
    begin
      for Count := 0 to numoftexts - 1 do
      begin
        settextstyle(Texts[Count].Font, HorizDir, Texts[Count].FontSize);
        outtextxy(Texts[Count].x, Texts[Count].y, Texts[Count].Text); //going through and drawing the text
        if (CursorCountdown < 20) and (Count = NumOfTexts - 1) and    //and then, if the cursor countdown is
          (MouseX = MouseXAsOfLastTextEntry) then                     //within a certain range, drawing a cursor
          outtextxy(Texts[Count].x + textwidth(Texts[Count].Text) - 1, Texts[Count].y, '|');
        if CursorCountdown = 0 then
          CursorCountdown := 40;
        Dec(CursorCountdown);
      end;
    end;
  end;

  procedure DrawFontPanel;
  begin
    if (FontPanelTab = FontTab) then  //This is the code for the font section of the font panel.
    begin
      setfillstyle(solidfill, Gray);
      bar((MAX_X div 2) - 50, 100, (MAX_X div 2) + 50, 250); //drawing the background of the font panel
      setfillstyle(solidfill, LightGray);
      case User_Font of   //Draw the bar to show the selected font.
        ArialFont: bar((MAX_X div 2) - 50, 130, (MAX_X div 2) + 50, 160);
        CourierNewFont: bar((MAX_X div 2) - 50, 161, (MAX_X div 2) + 50, 190);
        MSSansSerifFont: bar((MAX_X div 2) - 50, 191, (MAX_X div 2) + 50, 220);
        TimesNewRomanFont: bar((MAX_X div 2) - 50, 221, (MAX_X div 2) + 50, 250);
      end;
      setfillstyle(solidfill, Black);
      if (MouseX > (MAX_X div 2) - 50) and (MouseX < (MAX_X div 2) + 50) then
      begin
        case MouseY of  //Draw the bar to show what the mouse is hovering over.
          130..160: bar((MAX_X div 2) - 50, 130, (MAX_X div 2) - 47, 160);
          161..190: bar((MAX_X div 2) - 50, 161, (MAX_X div 2) - 47, 190);
          191..220: bar((MAX_X div 2) - 50, 191, (MAX_X div 2) - 47, 220);
          221..250: bar((MAX_X div 2) - 50, 221, (MAX_X div 2) - 47, 250);
        end;
      end;
      settextstyle(ArialFont, HorizDir, 10);
      setfillstyle(solidfill, LightGray);
      bar((MAX_X div 2) - 50, 100, MAX_X div 2, 116);
      setfillstyle(solidfill, LightSlateGray); //drawing the labels to switch between font and font size
      bar((MAX_X div 2) + 1, 100, (MAX_X div 2) + 50, 115);
      outtextxy((MAX_X div 2) - 48, 103, 'Font');
      outtextxy((MAX_X div 2) + 3, 103, 'Font Size');
      setfillstyle(solidfill, White);

      settextstyle(ArialFont, HorizDir, 15);
      outtextxy((MAX_X div 2) - 45, 140, 'Arial');
      settextstyle(CourierNewFont, HorizDir, 15);
      outtextxy((MAX_X div 2) - 45, 170, 'Courier New');
      settextstyle(MSSansSerifFont, HorizDir, 15);
      outtextxy((MAX_X div 2) - 45, 200, 'MS Sans Serif');
      settextstyle(TimesNewRomanFont, HorizDir, 15);
      outtextxy((MAX_X div 2) - 45, 230, 'Times New Roman');
      updategraph(updatenow);

      if GetMouseButtons = MouseLeftButton then
      begin
        LastPanelCalled := None; //makes sure the program will not leave the font panel running
        if (MouseX > (MAX_X div 2) - 50) and (MouseX < (MAX_X div 2) + 50) then
        begin
          case MouseY of
            100..115: begin
                        if MouseX > MAX_X div 2 then
                          FontPanelTab := FontSizeTab;
                         LastPanelCalled := FontPanel;
                      end;
            130..160: User_Font := ArialFont;
            161..190: User_Font := CourierNewFont;  //If the user has clicked on a font,
            191..220: User_Font := MSSansSerifFont; //set the font to that font.
            221..250: User_Font := TimesNewRomanFont;
          end;
        end;
      end;
    end
    else
    begin      //This is the code for the font size section of the font panel.
      setfillstyle(solidfill, Gray);
      bar((MAX_X div 2) - 50, 100, (MAX_X div 2) + 50, 250);
      setfillstyle(solidfill, LightGray);
      case UserSizeOfFont of
        7: bar((MAX_X div 2) - 50, 130, (MAX_X div 2) + 50, 160);
        10: bar((MAX_X div 2) - 50, 161, (MAX_X div 2) + 50, 190);
        15: bar((MAX_X div 2) - 50, 191, (MAX_X div 2) + 50, 220); //drawing the background
        20: bar((MAX_X div 2) - 50, 221, (MAX_X div 2) + 50, 250);
      end;
      setfillstyle(solidfill, Black);
      if (MouseX > (MAX_X div 2) - 50) and (MouseX < (MAX_X div 2) + 50) then
      begin
        case MouseY of //Draw bars to show what the mouse is hovering over.
          130..160: bar((MAX_X div 2) - 50, 130, (MAX_X div 2) - 47, 160);
          161..190: bar((MAX_X div 2) - 50, 161, (MAX_X div 2) - 47, 190);
          191..220: bar((MAX_X div 2) - 50, 191, (MAX_X div 2) - 47, 220);
          221..250: bar((MAX_X div 2) - 50, 221, (MAX_X div 2) - 47, 250);
        end;
      end;
      settextstyle(Arialfont, HorizDir, 15);
      outtextxy((MAX_X div 2) - 45, 140, '7');
      outtextxy((MAX_X div 2) - 45, 170, '10'); //drawing the labels for the different font sizes
      outtextxy((MAX_X div 2) - 45, 200, '15');
      outtextxy((MAX_X div 2) - 45, 230, '20');
      settextstyle(ArialFont, HorizDir, 10);
      setfillstyle(solidfill, LightSlateGray);
      bar((MAX_X div 2) - 50, 100, (MAX_X div 2) - 1, 115);
      setfillstyle(solidfill, LightGray);
      bar(MAX_X div 2, 100, (MAX_X div 2) + 50, 116);
      outtextxy((MAX_X div 2) - 48, 103, 'Font');
      outtextxy((MAX_X div 2) + 3, 103, 'Font Size');
      setfillstyle(solidfill, white);
      if (GetMouseButtons = MouseLeftButton) then
      begin
        LastPanelCalled := None; //Make sure the program will exit the panel.
        if (MouseX > (MAX_X div 2) - 50) and (MouseX < (MAX_X div 2) + 50) then
        begin
          case MouseY of
            100..115:
            begin
              if MouseX < MAX_X div 2 then
                FontPanelTab := FontTab;    //If the user clicks on the button to change the
              LastPanelCalled := FontPanel; //section of the font panel, change the section and
            end;                            //keep the panel running after all.
            130..160: UserSizeOfFont := 7;
            161..190: UserSizeOfFont := 10;
            191..220: UserSizeOfFont := 15;
            221..250: UserSizeOfFont := 20;
          end;
        end;
      end;
      updategraph(updatenow);
    end;
  end;

  procedure DrawControlBarAnimation;
  begin
    for Count := 1 to 50 do
    begin
      setfillstyle(solidfill, White);
      bar((MAX_X div 2) - 200, 0, (MAX_X div 2) + 200, Count);
      setfillstyle(solidfill, Gray);        //Draw the control bar coming down.
      bar((MAX_X div 2) - 200, 0, (MAX_X div 2) + 200, Count);
      sleep(5);
      updategraph(updatenow);
    end;
    setfillstyle(solidfill, white);
    //so the bar that makes the background in the main loop doesn't turn grey
    LastPanelCalled := ControlBar;
  end;

  procedure DrawControlBarHideAnimation;
  begin
    for Count := 50 downto 0 do
    begin  //Draw the control bar going up by drawing a growing white bar below it.
      bar((MAX_X div 2) - 200, Count, (MAX_X div 2) + 200, 50);
      updategraph(updatenow);
      sleep(5);
    end;
    if LastPanelCalled = ControlBar then
      LastPanelCalled := None;
  end;

  procedure DrawSaveIcon(x: longint); //All the Draw[...]Icon procedures take an x
  begin                               //coordinate that will form the centre of the icon
    line(x - 15, 10, x + 15, 10);
    line(x - 15, 40, x + 15, 40);
    line(x - 15, 10, x - 15, 40);
    line(x + 15, 10, x + 15, 40);
    line(x - 10, 10, x - 10, 20);
    line(x + 10, 10, x + 10, 20);
    line(x - 10, 20, x + 10, 20);
    bar(x - 6, 10, x - 4, 20);
  end;

  procedure DrawBMPIcon(x: longint);
  begin
    settextstyle(ArialFont, HorizDir, 16);
    outtextxy(x - 14, 17, '.bmp');
  end;

  procedure DrawFontSizeIcon(x: longint);
  begin
    settextstyle(ArialFont, HorizDir, 20);
    outtextxy(x - 9, 15, 'A');
    settextstyle(ArialFont, HorizDir, 15);
    outtextxy(x + 2, 18, 'A');
  end;

  procedure DrawDeleteAllIcon(x: longint);
  begin
    line(x - 8, 40, x + 8, 40);
    line(x - 8, 40, x - 10, 20);
    line(x + 8, 40, x + 10, 20);
    line(x - 15, 19, x + 15, 19);
    line(x - 15, 16, x - 15, 19);
    line(x + 15, 16, x + 15, 19);
    line(x + 15, 16, x - 15, 16);
    line(x - 8, 16, x - 8, 10);
    line(x + 8, 16, x + 8, 10);
    line(x - 8, 10, x + 8, 10);
    line(x, 20, x, 40);
    line(x - 5, 19, x - 4, 40);
    line(x + 5, 19, x + 4, 40);
  end;

  procedure DrawControls;
  begin
    setfillstyle(solidfill, Gray);
    bar((MAX_X div 2) - 200, 0, (MAX_X div 2) + 200, 50);//draw background
    setfillstyle(solidfill, white);
    //icon=30px X 30px with a 20 px margin between each
    setcolor(White);
    //procedures to draw icons
    DrawSaveIcon((MAX_X div 2) - 150);
    DrawBMPicon((MAX_X div 2) + 150);
    DrawDeleteAllIcon((MAX_X div 2) - 50);
    DrawFontSizeIcon((MAX_X div 2) + 50);
    setcolor(Black);
    setfillstyle(solidfill, Black);
    if (MouseY <= 50) and (MouseY >= 0) then
    begin
      case MouseX of //Draw bars to show what the mouse is hovering over.
        35..85: bar(35, 47, 85, 50);
        136..185: bar(136, 47, 185, 50);
        236..285: bar(236, 47, 285, 50);
        336..385: bar(336, 47, 385, 50);
      end;
    end;
    setfillstyle(solidfill, white);
    LastPanelCalled := ControlBar;
    if GetMouseButtons = MouseLeftButton then
    begin
      sleep(100);
      DrawControlBarHideAnimation;
      if (MouseY <= 50) and (MouseY >= 0) then
      begin
        case MouseX of
          35..85:
          begin
            Save;
            CloseFile(NotesFile);
          end;
          136..185:
          begin               //Do actions according to which icon is clicked on.
            numoftexts := 0;
            setlength(texts, numoftexts);
          end;
          236..285:
          begin
            FontPanelTab := FontTab;
            LastPanelCalled := FontPanel;
          end;
          336..385:
          begin
            LastPanelCalled := BMP_Panel;
          end;
        end;
      end;
    end;
  end;

  procedure SaveBMP(BMP_File_Address: string);
  var
    BMP_File: file;
    BMP_Memory_Location: pointer;
    BMP_Size: longint;
  begin
    if not (uppercase(rightstr(BMP_File_Address, 4)) = '.BMP') then
      BMP_File_Address := BMP_File_Address + '.bmp'; //add .bmp extension if not included
    if FileExists(BMP_File_Address) then
    begin
      SetTextStyle(ArialFont, HorizDir, 15);
      repeat
        if not CloseGraphRequest then //Turn the dialog red if the user tries to close the window.
          SetFillStyle(SolidFill, Gray)
        else
          SetfillStyle(SolidFill, DarkRed);
        MouseX := GetMouseX;              //Check if the user wants to overwrite.
        MouseY := GetMouseY;
        Bar((Max_X div 2) - 100, 250, (Max_X div 2) + 100, 300);
        OutTextXY((Max_X div 2) - 98, 252, 'File already exists. Overwrite?');
        SetFillStyle(SolidFill, LightGray);
        Bar((Max_X div 2) - 60, 280, (Max_X div 2) - 10, 295);
        Bar((Max_X div 2) + 10, 280, (Max_X div 2) + 60, 295);
        OutTextXY((Max_X div 2) - 55, 280, 'Yes');
        OutTextXY((Max_X div 2) + 15, 280, 'No');
        UpdateGraph(UpdateNow);
        sleep(20);
      until (GetMouseButtons = MouseLeftButton) and
        ((((MouseX >= (Max_X div 2) - 60) and (MouseX <= (Max_X div 2) - 10) or
          ((MouseX >= (Max_X div 2) + 10) and (MouseX <= (Max_X div 2) + 60)))) and
          (MouseY <= 295) and (MouseY >= 280));
      sleep(100);//to stop the mouse click being detected by later parts of the code
      SetFillStyle(SolidFill, White);
      if (MouseX >= (Max_X div 2) + 10) and (MouseX <= (Max_X div 2) + 60) then
        Exit;
    end;
    bar(0, 0, Max_X, Max_Y);
    DrawTexts;
    {$I-}
    AssignFile(BMP_File, BMP_File_Address); //Error checking is disabled here because
    Rewrite(BMP_File, 1);                   //it is dealt with later on in the code.
    {$I+}
    if IOResult <> 0 then //If IOResult isn't equal to 0 then it means an error has occurred.
    begin
      SetTextStyle(ArialFont, HorizDir, 15);
      repeat
        if not CloseGraphRequest then
          SetFillStyle(SolidFill, Gray)
        else
          SetfillStyle(SolidFill, DarkRed);
        MouseX := GetMouseX;
        MouseY := GetMouseY;
        Bar((Max_X div 2) - 100, 250, (Max_X div 2) + 100, 325);
        OutTextXY((Max_X div 2) - 98, 252, 'An unknown error occurred. Maybe');
        OutTextXY((Max_X div 2) - 98, 267, 'you have typed an invalid file');
        OutTextXY((Max_X div 2) - 98, 282, 'address.');
        SetFillStyle(SolidFill, LightGray);
        Bar((Max_X div 2) - 25, 305, (Max_X div 2) + 25, 320);
        OutTextXY((Max_X div 2) - 23, 305, 'OK');
        UpdateGraph(UpdateNow);
        sleep(20);
      until (GetMouseButtons = MouseLeftButton) and
        ((MouseX >= (Max_X div 2) - 25) and (MouseX <= (Max_X div 2) + 25) and
          (MouseY <= 320) and (MouseY >= 305));
      Exit;    //Exit the procedure after the user clicks ok.
    end;
    BMP_Size := ImageSize(0, 0, Max_X, Max_Y); //Because the procedure is still running, all is ok so
    GetMem(BMP_Memory_Location, BMP_Size);     //the program saves the bitmap.
    GetImage(0, 0, Max_X, Max_Y, BMP_Memory_Location^);
    BlockWrite(BMP_File, BMP_Memory_Location^, BMP_Size);
    CloseFile(BMP_File);
    FreeMem(BMP_Memory_Location);
  end;

  procedure Draw_BMP_Panel;
  begin
    case inputkey of
      #32..#255: //#32 to #255 are the acceptable keyboard input characters (ie. excluding arrow keys and key combinations)
      begin
        FileAddress := FileAddress + inputkey;
        if not (textwidth(rightstr(FileAddress, CharsToDisplay)) > 345) then //If the text entered for the file address is not longer
          Inc(CharsToDisplay);                                               //than the input box and a valid key has been pressed then
      end;                                                                   //increment the number of characters to be displayed.
    end;
    if textwidth(rightstr(FileAddress, CharsToDisplay)) > 345 then //If the file address outgrows the input box then
      Dec(CharsToDisplay);                                         //decrement the number of characters to display.

    if inputkey = #8 then                                          //If backspace is pressed, delete one
      FileAddress := leftstr(FileAddress, length(FileAddress) - 1);//character off the end of the file address.

    if inputkey = #13 then      //#13 is the enter key
    begin
      SaveBMP(FileAddress);
      FileAddress := '';
      LastPanelCalled := None;
    end;
    setfillstyle(SolidFill, Gray);
    bar((Max_X div 2) - 200, 200, (Max_X div 2) + 200, 350);
    settextstyle(ArialFont, HorizDir, 15);
    outtextxy((Max_X div 2) - 195, 200,
      'Type in a file address for the BMP image. The ''.bmp'' extension will be');
    outtextxy((Max_X div 2) - 195, 215,
      'added if you do not include it. If no file address is specified, but there');
    outtextxy((Max_X div 2) - 195, 230,
      'is a file name, the file will be saved in the same directory as the program');
    outtextxy((Max_X div 2) - 195, 245, 'is installed in.');
    setfillstyle(SolidFill, DarkGray);
    bar((Max_X div 2) - 195, 275, (Max_X div 2) + 150, 292);
    outtextxy(((Max_X div 2) + 150) - textwidth(rightstr(FileAddress, CharsToDisplay)), //Draw the relevant amount of characters
      276, rightstr(FileAddress, CharsToDisplay));
    setfillstyle(SolidFill, LightGray);
    bar((Max_X div 2) - 195, 310, (Max_X div 2) - 135, 330);
    outtextxy((Max_X div 2) - 193, 312, 'Save BMP');
    setfillstyle(SolidFill, White);
    updategraph(updatenow);
    if getmousebuttons = MouseLeftButton then
    begin         //The sleep is so that when the program next checks for if the
      sleep(100); //mouse button is pressed, the mouse button will have been released.
      if (MouseX < (Max_X div 2) - 200) or (MouseX > (Max_X div 2) + 200) or
        (MouseY < 200) or (MouseY > 350) then
        LastPanelCalled := None;
      if (MouseX < (Max_X div 2) - 135) and (MouseX > (Max_X div 2) - 195) and
        (MouseY < 330) and (MouseY > 310) then
      begin
        SaveBMP(FileAddress);
        FileAddress := '';
        LastPanelCalled := None;
      end;
    end;
  end;

  //------------MAIN PROGRAM BEGINS HERE------------\\
begin
  Load;
  InitGraphAndProgram;
  repeat //main program loop
    bar(0, 0, MAX_X, MAX_Y);
    mousex := GetMouseX;
    mousey := GetMouseY;
    if SHOW_INFO then
      ReportStatus;
    DrawTexts;
    if keypressed then
    begin
      inputkey := readkey;
    end
    else
    begin
      inputkey := #1;  //an unused value
    end;

    if LastPanelCalled = None then
    begin
      case inputkey of                                 //If there are no panels running and a valid key is
        #32..#255:                                     //pressed, add a text if one is not being edited
        begin                                          //or add the character to the text being edited,
          if ((MouseXAsOfLastTextEntry <> mousex) or   //breaking it onto a new line if necessary.
            (MouseYAsOfLastTextEntry <> mousey) or (numoftexts = 0)) then
          begin
            Inc(numoftexts);                     //Create a new text item if one is not being edited.
            setlength(Texts, numoftexts);
            Texts[numoftexts - 1].X := MouseX;
            Texts[numoftexts - 1].Y := MouseY;
            Texts[numoftexts - 1].LinkedBack := False;
          end;

          with Texts[numoftexts - 1] do
          begin
            Text := Text + inputkey; //Add the character to the text item being edited.
            Font := User_Font;
            FontSize := UserSizeOfFont;
            if textwidth(Text) + x > MAX_X then
            begin                                //If the text goes off the window, find the last space
              CurrentStringPos := length(Text);  //in the text, and break what is after it on to a new line.
              repeat
                keyfound := Text[CurrentStringPos];
                Dec(CurrentStringPos);
              until (keyfound = ' ');
              Inc(numoftexts);
              setlength(Texts, numoftexts);
              with Texts[numoftexts - 1] do
              begin
                x := Texts[numoftexts - 2].x;
                y := Texts[numoftexts - 2].Y + Texts[numoftexts - 2].FontSize;
                //The font size is the height of the text in pixels.
                Text := rightstr(Texts[numoftexts - 2].Text,
                  (length(Texts[numoftexts - 2].Text) - CurrentStringPos) - 1);
                font := Texts[numoftexts - 2].Font;
                fontsize := Texts[numoftexts - 2].FontSize;
                LinkedBack := True;
              end;
              Texts[numoftexts - 2].Text := leftstr(Text, CurrentStringPos);
            end;
          end;
          MouseXAsOfLastTextEntry := MouseX;
          MouseYAsOfLastTextEntry := MouseY;
        end;
      end;
    end;

    if (inputkey = #8) and (numoftexts > 0) and (LastPanelCalled = None) and BackspacingEnabled then
      //code for backspacing. #8 is backspace or Ctrl+H
    begin
      //If length is 1 before the character is deleted then delete character and text item and then
      //only backspace if mousexasoflasttextentry= mouse x and same for y.
      Texts[numoftexts - 1].Text := leftstr(Texts[numoftexts - 1].Text, length(Texts[numoftexts - 1].Text) - 1);
      if length(texts[numoftexts - 1].Text) = 0 then
      begin
        if Texts[numoftexts-1].linkedback then
          BackspacingEnabled:=true
        else
          BackspacingEnabled:=false;
        Dec(numoftexts);
        setlength(Texts, numoftexts);
        MouseXAsOfLastTextEntry := MouseX + 1; //to stop editing
      end;
    end;

    if inputkey = #19 then //#19 is Ctrl+S. This is the code for saving.
    begin
      Save;
      CloseFile(NotesFile);
    end;

    //Reorder items to make the text clicked on the latest one, so that the rest of the program will edit it.
    //A linked text is one that is created as the result of the program breaking text on to a new line.
    if (getmousebuttons = MouseLeftButton) and (LastPanelCalled = None) then
    begin
      WhereCollectionOfTextItemsStarts := 0;
      NoOfTextsLinkedTogether := 0;
      foundtext := False;

      if numoftexts <> 0 then
      begin
        while (not ((foundtext) or (WhereCollectionOfTextItemsStarts = numoftexts - 1))) do
        begin
          settextstyle(Texts[WhereCollectionOfTextItemsStarts].Font,
                       Horizdir, Texts[WhereCollectionOfTextItemsStarts].FontSize);
          if ((texts[WhereCollectionOfTextItemsStarts].X <= MouseX) and
              (texts[WhereCollectionOfTextItemsStarts].x +
               textwidth(texts[WhereCollectionOfTextItemsStarts].Text) >= MouseX)) and //searching for text that
             ((texts[WhereCollectionOfTextItemsStarts].Y <= MouseY) and              //matches the mouse position
             ((Texts[WhereCollectionOfTextItemsStarts].Y +
               Texts[WhereCollectionOfTextItemsStarts].Fontsize) >= MouseY)) then
          begin
            foundtext := True;
          end;
          Inc(WhereCollectionOfTextItemsStarts);
        end;

        if ((texts[numoftexts - 1].X <= MouseX) and
            (texts[numoftexts - 1].x + textwidth(texts[numoftexts - 1].Text) >= MouseX)) and
           ((texts[numoftexts - 1].Y <= MouseY) and                                      //If the last text item is the one found then
           ((Texts[numoftexts - 1].Y + Texts[numoftexts - 1].Fontsize) >= MouseY)) then //it cannot be linked to any, so make the program edit it.
        begin
          MouseXasoflasttextentry := MouseX;
          MouseYasoflasttextentry := MouseY;
          BackspacingEnabled:=True;
        end;
        Dec(WhereCollectionOfTextItemsStarts);
        if foundtext = True then
        begin
          if SHOW_INFO then
          begin
            settextstyle(ArialFont, HorizDir, 15);
            outtextxy(Max_X - textwidth('Moved on to reordering items'), //giving debugging info
              185, 'Moved on to reordering items');
            UpdateGraph(UpdateNow);
          end;
          while Texts[WhereCollectionOfTextItemsStarts].LinkedBack do //set wherecollectionoftextitemsstarts to the beginning text
            Dec(WhereCollectionOfTextItemsStarts);                    //of collection of linked texts

          NoOfTextsLinkedTogether := 1;
          //Keep incrementing NoOfTextsLinkedTogether until it represents the
          //number of texts that are in the 'chain' of related texts.
          while Texts[WhereCollectionOfTextItemsStarts + NoOfTextsLinkedTogether].LinkedBack do
            Inc(NoOfTextsLinkedTogether);

          for Count := WhereCollectionOfTextItemsStarts to
            WhereCollectionOfTextItemsStarts + NoOfTextsLinkedTogether - 1 do
          begin
            Inc(numoftexts);                          //Increment the number of texts
            setlength(Texts, numoftexts);             //then move the related texts
            Texts[NumOfTexts - 1] := Texts[Count];    //to the new free space.
            if SHOW_INFO then
            begin
              bar(Max_X - textwidth('Moving text item: ' + IntToStr(Count)), 200, Max_X, 315);
              outtextxy(Max_X - textwidth('Moving text item: ' + IntToStr(Count)),
                200, 'Moving text item: ' + IntToStr(Count)); //giving debugging info
              updategraph(updatenow);
              sleep(1000);
            end;
          end;

          Count := 0;
          repeat  //Move all the texts numbered higher than the original position of the texts backwards into the available spaces.
            Texts[WhereCollectionOfTextItemsStarts + Count] := Texts[WhereCollectionOfTextItemsStarts + Count + NoOfTextsLinkedTogether];
            Inc(Count);
          until WhereCollectionOfTextItemsStarts + Count + NoOfTextsLinkedTogether = numoftexts;
          NumOfTexts := NumOfTexts - NoOfTextsLinkedTogether;
          setlength(Texts, NumOfTexts);
          MouseXAsOfLastTextEntry := MouseX;
          MouseYAsOfLastTextEntry := MouseY;//Delete the available spaces at the end that were created by the previous step.
          if SHOW_INFO then
          begin
            outtextxy(Max_X - textwidth('Done reordering'), 215, 'Done reordering');
            UpdateGraph(UpdateNow);    //Give debugging info.
            sleep(1000);
          end;
        end;
      end;
    end;

    //Decide what menu to show.  #20 is Ctrl+T
    if ((inputkey = #20) and (not (LastPanelCalled = ControlBar))) or
      (((mousey < 5) and (mouseX <> 0)) and (not (LastPanelCalled = ControlBar))) then
    begin
      DrawControlBarAnimation;
    end;

    if inputkey = #6 then  //#6 is Ctrl+F
    begin
      if LastPanelCalled = ControlBar then
        DrawControlBarHideAnimation;
      LastPanelCalled := FontPanel;
    end;

    if inputkey = #2 then   //#2 is Ctrl+B
    begin
      if LastPanelCalled = ControlBar then
        DrawControlBarHideAnimation;
      LastPanelCalled := BMP_Panel;
    end;

    //Draw menus.
    if LastPanelCalled = ControlBar then
      DrawControls;
    if LastPanelCalled = FontPanel then
      DrawFontPanel;
    if LastPanelCalled = BMP_Panel then
      Draw_BMP_Panel;

    updategraph(updatenow);
    sleep(25);
    if inputkey = #0 then  //If inputkey is #0 then a special key must have been pressed
    begin                  //because no key pressed is #1 in this program.
      inputkey := ReadKey;
      SpecialKeyPressed := True;
    end;
  until (CloseGraphRequest) or ((inputkey = #107) and SpecialKeyPressed); //#0 then #107 is Alt+F4

  CloseGraph;
  Save;
  closeFile(NotesFile);
end.