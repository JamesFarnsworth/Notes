program Notes;

{$mode objfpc}{$H+}
//{$APPTYPE GUI}//So the console window doesn't show
uses
  Windows,
  Wingraph in 'wingraph.pas',
  WinCrt in 'wincrt.pas',
  Winmouse in 'winmouse.pas',            //CHECK THAT CREATING NOTES.TXT IN LOAD IF IT DOES NOT EXIST WORKS
  Classes,
  SysUtils,
  StrUtils,                              //add tutorial if there is no notes.txt or it is blank, error detection for loading file (invalid syntax etc.)
  Math;

type                                    //finish validation messages in load
  tText = record
    X, Y: longint;                       //add use of mouseevents procedure REMEMBER: MOUSEEVENTS DOES NOT REQUIRE A SLEEP AFTER IT
    Text, LastLine: string;
    Font: word;
    FontSize: integer;
    NoOfLines: integer;
  end;

var
  Gd, Gm, FontPanelTab, LastPanelCalled: smallint;
  MouseX, MouseY, MouseXAsOfLastTextEntry, MouseYAsOfLastTextEntry: integer;
  NumOfTexts, CurrentStringPos, CharsToDisplay, CursorCountdown, MouseEvent: integer;
  Count, Count2, UserFontSize, DefaultFontSize, MaxX, MaxY, TextToEditGlobal: integer;
  InputKey: char;
  UserFont, DefaultFont: word;
  SpecialKeyPressed: boolean;
  NotesFile: TextFile;
  Str, Str2, FileAddress: string;
  Texts: array of tText;

const
  FontSizeTab = 1;
  FontTab = 0;
  ControlBar = 0;
  FontPanel = 1;
  BMP_Panel = 2;
  None = 3;
  MouseLeft = 1;
  MouseRight = 2;
  MouseDoubleLeft = 3;
  MouseDoubleRight = 4;
  //Settings
  SHOW_INFO = False;       //set as true to show general info about record items
  WINDOW_SIZE_MESSAGE = 'Pick a window size:';
  SMALL_WINDOW_SIZE_X = 400;
  SMALL_WINDOW_SIZE_Y = 400;
  MEDIUM_WINDOW_SIZE_X = 800;
  MEDIUM_WINDOW_SIZE_Y = 400;
  LARGE_WINDOW_SIZE_X = 1000;
  LARGE_WINDOW_SIZE_Y = 600;
  FONT_SIZE_1 = 10;
  FONT_SIZE_2 = 15;
  FONT_SIZE_3 = 20;
  FONT_SIZE_4 = 25;
  LOAD_ERROR_MESSAGE = 'An error occurred opening Notes.txt. Check the file exists.';
  LOAD_BUTTON1_TEXT = 'Create Notes.txt';
  LOAD_BUTTON2_TEXT = 'Exit';
  CREATE_NOTES_ERROR_MESSAGE = 'There has been a problem creating the new notes file. You''re on your own!';

  function MouseEvents : integer;
  var
    ButtonReleased : boolean;
    time : integer;
  begin
    time := 0;
    ButtonReleased := False;
    result := 0;
    if (getMouseButtons = MouseLeftButton) then
    begin
      repeat
        if not (getMouseButtons = MouseLeftButton) then ButtonReleased:=True;
        sleep(10);
        time := time + 10;
      until (time=100) or (ButtonReleased);

      if ButtonReleased then
      begin
        repeat
          if (getMouseButtons = MouseLeftButton) then result := MouseDoubleLeft;
          sleep(10);
          time := time + 10;
        until (time=200) or (result = MouseDoubleLeft)
      end;
      if not (result = MouseDoubleLeft) then result := MouseLeft;
    end
    else if (getMouseButtons = MouseRightButton) then
    begin
      repeat
        if not (getMouseButtons = MouseRightButton) then ButtonReleased:=True;
        sleep(10);
        time := time + 10;
      until (time=100) or (ButtonReleased);

      if ButtonReleased then
      begin
        repeat
          if (getMouseButtons = MouseRightButton) then result := MouseDoubleRight;
          sleep(10);
          time := time + 10;
        until (time=200) or (result = MouseDoubleRight)
      end;
      if not (result = MouseDoubleRight) then result := MouseRight;
    end;
  end;

  function ErrorMessage(Message, Button1Text : String): Boolean; Overload;
  begin    //Result variable is not used - it is just there to allow overloading
    setbkcolor(White);
    setfillstyle(slashfill,Gray);
    bar(0,0,MaxX,MaxY);
    setfillstyle(solidfill,Gray);
    settextstyle(ArialFont, Horizdir, 10);
    bar((MaxX div 2) - ((textwidth(Button1Text) div 2) + 5), (MaxY div 2) + 20, (MaxX div 2) + ((textwidth(Button1Text) div 2) + 5), (MaxY div 2) + 40);
    outtextXY((MaxX + textwidth(Button1Text)) div 2, (MaxY div 2) + 25, Button1Text);
    settextstyle(ArialFont, Horizdir, 15);
    outtextXY(MaxX div 2 - (textwidth(Message) div 2), MaxY div 2 - 5, Message);
    updategraph(updatenow);
    repeat
      MouseEvent := MouseEvents;
      MouseX := GetMouseX;
      MouseY := GetMouseY;
      sleep(20);
    until (MouseEvent = MouseLeft) and (MouseY >= (MaxY div 2) + 20) and (MouseY <= (MaxY div 2) + 40) and (MouseX >= (MaxX div 2) - ((textwidth(Button1Text) div 2) + 5)) and (MouseX <= (MaxX div 2) + ((textwidth(Button1Text) div 2) + 5));
  end;

  function ErrorMessage(Message, Button1Text, Button2Text : String): Integer; Overload;
  begin
    setbkcolor(White);
    setfillstyle(slashfill,Gray);
    bar(0,0,MaxX,MaxY);
    setfillstyle(solidfill,Gray);
    settextstyle(ArialFont, Horizdir, 10);
    bar((MaxX div 2) - (textwidth(Button1Text) + 20), (MaxY div 2) + 20, (MaxX div 2) - 10, (MaxY div 2) + 40);
    outtextXY((MaxX div 2) - (textwidth(Button1Text) + 15), (MaxY div 2) + 25, Button1Text);
    bar((MaxX div 2) + 10, (MaxY div 2) + 20, (MaxX div 2) + (textwidth(Button2Text) + 20), (MaxY div 2) + 40);
    outtextXY((MaxX div 2) + 15, (MaxY div 2) + 25, Button2Text);
    settextstyle(ArialFont, Horizdir, 15);
    outtextXY(MaxX div 2 - (textwidth(Message) div 2), MaxY div 2 - 5, Message);
    updategraph(updatenow);
    repeat
      MouseEvent := MouseEvents;
      MouseX := GetMouseX;
      MouseY := GetMouseY;
      if (MouseEvent = MouseLeft) and (MouseY >= (MaxY div 2) + 20) and (MouseY <= (MaxY div 2) + 40) then
      begin
        if (MouseX >= (MaxX div 2) - (textwidth(Button1Text) + 20)) and (MouseX <= (MaxX div 2) - 10) then
          result := 1;
        if (MouseX <= (MaxX div 2) + (textwidth(Button2Text) + 20)) and (MouseX >= (MaxX div 2) + 10) then
          result := 2;
      end;
      sleep(20);
    until (Result = 1) or (Result = 2);
  end;

  procedure Save;
  begin
    assignfile(NotesFile, 'Notes.txt');
    rewrite(NotesFile);
    case DefaultFont of
      ArialFont: Str := 'ArialFont';
      CourierNewFont: Str := 'CourierNewFont';
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
      writeln(NotesFile, IntToStr(Texts[Count].X) + ',' +
        IntToStr(Texts[Count].Y) + ',' + IntToStr(Texts[Count].FontSize) +
        ',' + Str + ',' + Texts[Count].Text);
    end;
    closefile(NotesFile);
    settextstyle(ArialFont, Horizdir, 10);
    for Count := -10 to 0 do
    begin
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
  var
    buttonPressed : Integer;
    F : LongInt;
  begin
    if fileexists('Notes.txt') then
    begin
      {$I-}
        assignfile(NotesFile, 'Notes.txt');
        reset(NotesFile);
      {$I+}
    end;
    if (IOResult <> 0) or (not fileexists('Notes.txt')) then
    begin
      {{$I-}
        closeFile(NotesFile);//try to close, but don't show error if not able to
      {$I+}}
      if IOResult = 0 then; //reset IOResult by reading from it
      ButtonPressed := ErrorMessage(LOAD_ERROR_MESSAGE, LOAD_BUTTON1_TEXT, LOAD_BUTTON2_TEXT);
      if (ButtonPressed = 1) then
      begin
        {$I-}
          writeln(IOResult);
          F := FileCreate('Notes.txt');
          FileClose(F);
          repeat sleep(5) until fileexists('Notes.txt');
          assignfile(NotesFile, 'Notes.txt');
          rewrite(NotesFile);
          writeln(NotesFile, 'ArialFont');
          writeln(NotesFile, FONT_SIZE_2);
          closeFile(NotesFile);
          assignfile(NotesFile, 'Notes.txt');
          reset(NotesFile);
        {$I+}
        if (IOResult <> 0) then
        begin
          ErrorMessage(CREATE_NOTES_ERROR_MESSAGE, 'Exit');
          Halt;
        end;
      end
      else if (ButtonPressed = 2) then Halt;
    end;
    readln(NotesFile, Str);
    case str of
      'ArialFont': DefaultFont := ArialFont;
      'CourierNewFont': DefaultFont := CourierNewFont;
      'MSSansSerifFont': DefaultFont := MSSansSerifFont;
      'TimesNewRomanFont': DefaultFont := TimesNewRomanFont;
    end;
    readln(NotesFile, Str);
    DefaultFontSize := StrToInt(Str);
    UserFont := DefaultFont;
    UserFontSize := DefaultFontSize;
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
        until (Str[CurrentStringPos] = ',');
        X := StrToInt(leftstr(Str, CurrentStringPos - 1));
        Inc(CurrentStringPos);
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
        until (str[CurrentStringPos] = ',');
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

  procedure SelectWindowSize;
  begin
    //Initiate graph
    MaxX := 200;
    MaxY := 100;
    setwindowsize(MaxX, MaxY);
    gd := 9;
    gm := 13;
    InitGraph(gd, gm, 'Notes');
    updateGraph(updateOff);
    setfillstyle(SolidFill, White);
    bar(0,0,MaxX,MaxY);
    settextstyle(ArialFont, HorizDir, 10);
    setcolor(Black);
    outtextXY((MaxX - textwidth(WINDOW_SIZE_MESSAGE)) div 2, 10, WINDOW_SIZE_MESSAGE);
    setfillstyle(SolidFill, Gray);
    bar((MaxX div 2) - 50, MaxY div 2, (MaxX div 2) - 20, (MaxY div 2) + 20);
    outtextXY((MaxX div 2) - 50, MaxY div 2, inttostr(SMALL_WINDOW_SIZE_X) + 'x' + inttostr(SMALL_WINDOW_SIZE_Y));
    bar((MaxX div 2) - 15, MaxY div 2, (MaxX div 2) + 15, (MaxY div 2) + 20);
    outtextXY((MaxX div 2) - 15, MaxY div 2, inttostr(MEDIUM_WINDOW_SIZE_X) + 'x' + inttostr(MEDIUM_WINDOW_SIZE_Y));
    bar((MaxX div 2) + 20, MaxY div 2, (MaxX div 2) + 50, (MaxY div 2) + 20);
    outtextXY((MaxX div 2) + 20, MaxY div 2, inttostr(LARGE_WINDOW_SIZE_X) + 'x' + inttostr(LARGE_WINDOW_SIZE_Y));
    updateGraph(updateNow);
    repeat
      MouseX := GetMouseX;
      MouseY := GetMouseY;
      if CloseGraphRequest then
      begin
        CloseGraph;
        Halt;
      end;
      sleep(20);
    until (GetMouseButtons = MouseLeftButton) and ((((MouseX >= (MaxX div 2) - 50) and (MouseX <= (MaxX div 2) - 20)) or ((MouseX >= (MaxX div 2) - 15) and (MouseX <= (MaxX div 2) + 15))) or ((MouseX >= (MaxX div 2) + 20) and (MouseX <= (MaxX div 2) + 50))) and ((MouseY >= MaxY div 2) and (MouseY <= (MaxY div 2) + 20));
    CloseGraph;
    if (MouseX >= (MaxX div 2) - 50) and (MouseX <= (MaxX div 2) - 20) then
    begin
      MaxX := SMALL_WINDOW_SIZE_X;
      MaxY := SMALL_WINDOW_SIZE_Y;
    end;
    if (MouseX >= (MaxX div 2) - 15) and (MouseX <= (MaxX div 2) + 15) then
    begin
      MaxX := MEDIUM_WINDOW_SIZE_X;
      MaxY := MEDIUM_WINDOW_SIZE_Y;
    end;
    if (MouseX >= (MaxX div 2) + 20) and (MouseX <= (MaxX div 2) + 50) then
    begin
      MaxX := LARGE_WINDOW_SIZE_X;
      MaxY := LARGE_WINDOW_SIZE_Y;
    end;
  end;

  procedure InitGraphAndProgram;
  begin
    //Initiate graph
    setwindowsize(MaxX, MaxY);
    gd := 9;
    gm := 13;
    InitGraph(gd, gm, 'Notes');
    setcolor(Black);
    updategraph(updateoff);
    MouseXAsOfLastTextEntry := -1;
    //These are to force the program to create a new text the first time the user
    MouseYAsOfLastTextEntry := -1;
    //types something in, as it is impossible for the mouse to have these coordinates
    UserFont := DefaultFont;
    UserFontSize := DefaultFontSize;
    FontPanelTab := FontTab;
    LastPanelCalled := None;
    CursorCountdown := 9;
    Inputkey := #1;   //unused value - 0 could indicate a special character
    FileAddress := '';
    CharsToDisplay := 0;
  end;

  procedure ReportStatus;
  begin
    settextstyle(ArialFont, HorizDir, 10);
    outtextxy(0, 40, 'NumOfTexts=' + IntToStr(NumOfTexts));
    outtextxy(0, 60, 'Text items in ascending order, from 0 to numoftexts-1:');
    for Count := 0 to numoftexts - 1 do
      outtextxy(0, 70 + (Count * 10), Texts[Count].Text + ', X=' +
        IntToStr(Texts[Count].X) + ', Y=' + IntToStr(Texts[Count].Y) +
        ', Font Size=' + IntToStr(Texts[Count].FontSize));

    outtextxy(0, (numoftexts * 10) + 70, 'Current mouse position: X=' +
      IntToStr(mousex) + ' Y=' + IntToStr(mousey));
  end;

  procedure DrawTexts;
  var
    SpaceFound: boolean;
    NoOfLinesDrawn: integer;
  begin
    if (numoftexts >= 1) then
    begin
      for Count := 0 to numoftexts - 1 do
      begin
        settextstyle(Texts[Count].Font, HorizDir, Texts[Count].FontSize);
        NoOfLinesDrawn := 0;
        Currentstringpos := 0;
        repeat
          str := '';                     //str is going to be the next line
          SpaceFound := False;
          //draw each word checking if it'll go off the window, and then when it does, it increments
          //NoOfLinesDrawn. Uses Str, Str2, and CurrentStringpos to remember what it's got so far

          while not ((Textwidth(Str) + Texts[Count].X > MaxX) or
              (CurrentStringPos >= length(Texts[Count].Text))) do
          begin
            //going round infinite loop if no space
            Inc(CurrentStringPos);
            Str := Str + Texts[Count].Text[CurrentStringPos];
            if Texts[Count].Text[CurrentStringPos] = ' ' then
              Spacefound := True;
          end;
          if spacefound then
          begin
            while not ((Texts[Count].Text[CurrentStringPos] = ' ') or
                (CurrentStringPos >= length(Texts[Count].Text))) do
            begin
              Dec(CurrentStringPos);
              Str := leftstr(Str, length(Str) - 1);
              //take 1 character off the end of str
            end;
          end
          else
          begin
            if (Textwidth(Str) + Texts[Count].X > MaxX) then
            begin
              //decrement CurrentStringpos so that the program knows that the character about to be replaced hasn't been drawn
              Dec(CurrentStringPos);
              //replace last character of str with a dash
              Str := leftstr(Str, length(Str) - 1) + '-';
            end;
          end;
          OuttextXY(Texts[Count].X, Texts[Count].Y +
            (NoOfLinesDrawn * Texts[Count].FontSize), Str);
          Inc(NoOfLinesDrawn);
        until (Currentstringpos >= length(Texts[Count].Text));
        Texts[Count].NoOfLines := NoOfLinesDrawn;
        //so the section that selects text items knows
        Texts[Count].LastLine := Str;
        //where the boundaries of the text items are
        {if CursorCountdown = 0 then CursorCountdown:=40;
        dec(CursorCountdown);}
      end;
    end;
  end;

  procedure DrawFontPanel(texttoedit : integer);
  var
    MouseEvent : integer;
  begin
    MouseEvent := MouseEvents;
    if (FontPanelTab = FontTab) then
    begin
      setfillstyle(solidfill, Gray);
      bar((MaxX div 2) - 50, 100, (MaxX div 2) + 50, 250);
      setfillstyle(solidfill, LightGray);
      case UserFont of
        ArialFont: bar((MaxX div 2) - 50, 130, (MaxX div 2) + 50, 160);
        CourierNewFont: bar((MaxX div 2) - 50, 161, (MaxX div 2) + 50, 190);
        MSSansSerifFont: bar((MaxX div 2) - 50, 191, (MaxX div 2) + 50, 220);
        TimesNewRomanFont: bar((MaxX div 2) - 50, 221, (MaxX div 2) + 50, 250);
      end;
      setfillstyle(solidfill, Black);
      if (MouseX > (MaxX div 2) - 50) and (MouseX < (MaxX div 2) + 50) then
      begin
        case MouseY of
          130..160: bar((MaxX div 2) - 50, 130, (MaxX div 2) - 47, 160);
          161..190: bar((MaxX div 2) - 50, 161, (MaxX div 2) - 47, 190);
          191..220: bar((MaxX div 2) - 50, 191, (MaxX div 2) - 47, 220);
          221..250: bar((MaxX div 2) - 50, 221, (MaxX div 2) - 47, 250);
        end;
      end;
      settextstyle(ArialFont, HorizDir, 10);
      setfillstyle(solidfill, LightGray);
      bar((MaxX div 2) - 50, 100, MaxX div 2, 116);
      setfillstyle(solidfill, LightSlateGray);
      bar((MaxX div 2) + 1, 100, (MaxX div 2) + 50, 115);
      outtextxy((MaxX div 2) - 48, 103, 'Font');
      outtextxy((MaxX div 2) + 3, 103, 'Font Size');
      setfillstyle(solidfill, White);

      settextstyle(ArialFont, HorizDir, 15);
      outtextxy((MaxX div 2) - 45, 140, 'Arial');

      settextstyle(CourierNewFont, HorizDir, 15);
      outtextxy((MaxX div 2) - 45, 170, 'Courier New');

      settextstyle(MSSansSerifFont, HorizDir, 15);
      outtextxy((MaxX div 2) - 45, 200, 'MS Sans Serif');

      settextstyle(TimesNewRomanFont, HorizDir, 15);
      outtextxy((MaxX div 2) - 45, 230, 'Times New Roman');

      updategraph(updatenow);

      if (MouseEvent = MouseLeft) or (MouseEvent = MouseRight) then
      begin
        LastPanelCalled := None;
        if (MouseX > (MaxX div 2) - 50) and (MouseX < (MaxX div 2) + 50) then
        begin
          if (MouseY >= 100) and (MouseY <= 115) then
          begin
            if MouseX > MaxX div 2 then
              FontPanelTab := FontSizeTab;
            LastPanelCalled := FontPanel;
          end; //since the last text is at position NoOfTexts - 1, I use position NoOfTexts to mean it is undefined
          if (MouseEvent = MouseLeft) and (TextToEdit = NumOfTexts) then
          begin
            case MouseY of
              130..160: UserFont := ArialFont;
              161..190: UserFont := CourierNewFont;
              191..220: UserFont := MSSansSerifFont;
              221..250: UserFont := TimesNewRomanFont;
            end;
          end
          else if (MouseEvent = MouseRight) and (TextToEdit = NumOfTexts) then
          begin
            case MouseY of
              130..160: DefaultFont := ArialFont;
              161..190: DefaultFont := CourierNewFont;
              191..220: DefaultFont := MSSansSerifFont;
              221..250: DefaultFont := TimesNewRomanFont;
            end;
          end
          else if (not (TextToEdit = NumOfTexts)) and (MouseEvent = MouseLeft) then
          begin
            case MouseY of
              130..160: Texts[TextToEdit].Font := ArialFont;
              161..190: Texts[TextToEdit].Font := CourierNewFont;
              191..220: Texts[TextToEdit].Font := MSSansSerifFont;
              221..250: Texts[TextToEdit].Font := TimesNewRomanFont;
            end;
          end;
        end;
      end;
    end
    else
    begin
      setfillstyle(solidfill, Gray);
      bar((MaxX div 2) - 50, 100, (MaxX div 2) + 50, 250);
      setfillstyle(solidfill, LightGray);
      case UserFontSize of
        FONT_SIZE_1: bar((MaxX div 2) - 50, 130, (MaxX div 2) + 50, 160);
        FONT_SIZE_2: bar((MaxX div 2) - 50, 161, (MaxX div 2) + 50, 190);
        FONT_SIZE_3: bar((MaxX div 2) - 50, 191, (MaxX div 2) + 50, 220);
        FONT_SIZE_4: bar((MaxX div 2) - 50, 221, (MaxX div 2) + 50, 250);
      end;
      setfillstyle(solidfill, Black);
      if (MouseX > (MaxX div 2) - 50) and (MouseX < (MaxX div 2) + 50) then
      begin
        case MouseY of
          130..160: bar((MaxX div 2) - 50, 130, (MaxX div 2) - 47, 160);
          161..190: bar((MaxX div 2) - 50, 161, (MaxX div 2) - 47, 190);
          191..220: bar((MaxX div 2) - 50, 191, (MaxX div 2) - 47, 220);
          221..250: bar((MaxX div 2) - 50, 221, (MaxX div 2) - 47, 250);
        end;
      end;
      settextstyle(Arialfont, HorizDir, 15);
      outtextxy((MaxX div 2) - 45, 140, inttostr(FONT_SIZE_1));
      outtextxy((MaxX div 2) - 45, 170, inttostr(FONT_SIZE_2));
      outtextxy((MaxX div 2) - 45, 200, inttostr(FONT_SIZE_3));
      outtextxy((MaxX div 2) - 45, 230, inttostr(FONT_SIZE_4));
      settextstyle(ArialFont, HorizDir, 10);
      setfillstyle(solidfill, LightSlateGray);
      bar((MaxX div 2) - 50, 100, (MaxX div 2) - 1, 115);
      setfillstyle(solidfill, LightGray);
      bar(MaxX div 2, 100, (MaxX div 2) + 50, 116);
      outtextxy((MaxX div 2) - 48, 103, 'Font');
      outtextxy((MaxX div 2) + 3, 103, 'Font Size');
      setfillstyle(solidfill, white);
      if (MouseEvent = MouseLeft) or (MouseEvent = MouseRight) then
      begin
        LastPanelCalled := None;
        if (MouseX > (MaxX div 2) - 50) and (MouseX < (MaxX div 2) + 50) then
        begin
          if (MouseY >= 100) and (MouseY <= 115) then
          begin
            if MouseX < MaxX div 2 then
              FontPanelTab := FontTab;
            LastPanelCalled := FontPanel;
          end; //since the last text is at position NoOfTexts - 1, I use position NoOfTexts to mean it is undefined
          if (MouseEvent = MouseLeft) and (TextToEdit = NumOfTexts) then
          begin
            case MouseY of
              130..160: UserFontSize := FONT_SIZE_1;
              161..190: UserFontSize := FONT_SIZE_2;
              191..220: UserFontSize := FONT_SIZE_3;
              221..250: UserFontSize := FONT_SIZE_4;
            end;
          end
          else if (MouseEvent = MouseRight) and (TextToEdit = NumOfTexts) then
          begin
            case MouseY of
              130..160: DefaultFontSize := FONT_SIZE_1;
              161..190: DefaultFontSize := FONT_SIZE_2;
              191..220: DefaultFontSize := FONT_SIZE_3;
              221..250: DefaultFontSize := FONT_SIZE_4;
            end;
          end
          else if (not (TextToEdit = NumOfTexts)) and (MouseEvent = MouseLeft) then
          begin
            case MouseY of
              130..160: Texts[TextToEdit].FontSize := FONT_SIZE_1;
              161..190: Texts[TextToEdit].FontSize := FONT_SIZE_2;
              191..220: Texts[TextToEdit].FontSize := FONT_SIZE_3;
              221..250: Texts[TextToEdit].FontSize := FONT_SIZE_4;
            end;
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
      bar((MaxX div 2) - 200, 0, (MaxX div 2) + 200, Count);
      setfillstyle(solidfill, Gray);
      bar((MaxX div 2) - 200, 0, (MaxX div 2) + 200, Count);
      //DrawTexts;
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
    begin
      bar((MaxX div 2) - 200, Count, (MaxX div 2) + 200, 50);
      updategraph(updatenow);
      sleep(5);
    end;
    if LastPanelCalled = ControlBar then
      LastPanelCalled := None;
    //so the bar that makes the background in the main loop doesn't turn grey
    setfillstyle(solidfill, white);
  end;

  procedure DrawSaveIcon(x: longint);     //All the Draw[...]Icon procedures take an x
  begin                                //coordinate that will form the centre of the icon
    line(x - 15, 10, x + 15, 10);
    line(x - 15, 40, x + 15, 40);
    line(x - 15, 10, x - 15, 40);
    line(x + 15, 10, x + 15, 40);
    line(x - 10, 10, x - 10, 20);
    line(x + 10, 10, x + 10, 20);
    line(x - 10, 20, x + 10, 20);
    line(x - 4, 10, x - 4, 20);
    line(x - 5, 10, x - 5, 20);
    line(x - 6, 10, x - 6, 20);
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
    bar((MaxX div 2) - 200, 0, (MaxX div 2) + 200, 50);
    setfillstyle(solidfill, white);
    //icon=30px X 30px with a 20 px margin between each
    setcolor(White);
    //procedures to draw icons
    DrawSaveIcon((MaxX div 2) - 150);
    DrawDeleteAllIcon((MaxX div 2) - 50);
    DrawFontSizeIcon((MaxX div 2) + 50);
    DrawBMPicon((MaxX div 2) + 150);
    setcolor(Black);
    setfillstyle(solidfill, Black);
    if (MouseY <= 50) and (MouseY >= 0) then
    begin
      if (MouseX >= (MaxX div 2) - 170) and (MouseX <= (MaxX div 2) - 130) then
        bar((MaxX div 2) - 170, 47, (MaxX div 2) - 130, 50); //save icon
      if (MouseX >= (MaxX div 2) - 70) and (MouseX <= (MaxX div 2) - 30) then
        bar((MaxX div 2) - 70, 47, (MaxX div 2) - 30, 50); //delete all icon
      if (MouseX <= (MaxX div 2) + 70) and (MouseX >= (MaxX div 2) + 30) then
        bar((MaxX div 2) + 30, 47, (MaxX div 2) + 70, 50); //font panel icon
      if (MouseX <= (MaxX div 2) + 170) and (MouseX >= (MaxX div 2) + 130) then
        bar((MaxX div 2) + 130, 47, (MaxX div 2) + 170, 50); //bmp icon
    end;
    setfillstyle(solidfill, white);
    LastPanelCalled := ControlBar;
    if (GetMouseButtons = MouseLeftButton) then
    begin
      sleep(200);
      //so that when the program moves on, the mouse button will have been released
      DrawControlBarHideAnimation;
      if (MouseY <= 50) and (MouseY >= 0) then
      begin
        if (MouseX >= (MaxX div 2) - 170) and (MouseX <= (MaxX div 2) - 130) then //save icon
          Save;
        if (MouseX >= (MaxX div 2) - 70) and (MouseX <= (MaxX div 2) - 30) then //delete all icon
        begin
          numoftexts := 0;
          setlength(texts, numoftexts);
        end;
        if (MouseX <= (MaxX div 2) + 70) and (MouseX >= (MaxX div 2) + 30) then //font panel icon
        begin
          FontPanelTab := FontTab;
          LastPanelCalled := FontPanel;
          TextToEditGlobal := NumOfTexts;
        end;
        if (MouseX <= (MaxX div 2) + 170) and (MouseX >= (MaxX div 2) + 130) then //bmp icon
          LastPanelCalled := BMP_Panel;
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
      BMP_File_Address := BMP_File_Address + '.bmp';

    if FileExists(BMP_File_Address) then
    begin
      SetTextStyle(ArialFont, HorizDir, 15);
      repeat
        if not CloseGraphRequest then
          SetFillStyle(SolidFill, Gray)
        else
          SetfillStyle(SolidFill, DarkRed);
        MouseX := GetMouseX;
        MouseY := GetMouseY;
        Bar((MaxX div 2) - 100, 250, (MaxX div 2) + 100, 300);
        OutTextXY((MaxX div 2) - 98, 252, 'File already exists. Overwrite?');
        SetFillStyle(SolidFill, LightGray);
        Bar((MaxX div 2) - 60, 280, (MaxX div 2) - 10, 295);
        Bar((MaxX div 2) + 10, 280, (MaxX div 2) + 60, 295);
        OutTextXY((MaxX div 2) - 55, 280, 'Yes');
        OutTextXY((MaxX div 2) + 15, 280, 'No');
        UpdateGraph(UpdateNow);
        sleep(20);
      until (GetMouseButtons = MouseLeftButton) and
        ((((MouseX >= (MaxX div 2) - 60) and (MouseX <= (MaxX div 2) - 10) or
          ((MouseX >= (MaxX div 2) + 10) and (MouseX <= (MaxX div 2) + 60)))) and
          (MouseY <= 295) and (MouseY >= 280));

      sleep(100);//to stop the mouse click being detected by later parts of the code
      SetFillStyle(SolidFill, White);

      if (MouseX >= (MaxX div 2) + 10) and (MouseX <= (MaxX div 2) + 60) then
        Exit;
    end;
    bar(0, 0, MaxX, MaxY);
    DrawTexts;
    {$I-}
    AssignFile(BMP_File, BMP_File_Address);
    Rewrite(BMP_File, 1);
    {$I+}
    if (IOResult <> 0) then
    begin
      SetTextStyle(ArialFont, HorizDir, 15);
      repeat
        if not CloseGraphRequest then
          SetFillStyle(SolidFill, Gray)
        else
          SetfillStyle(SolidFill, DarkRed);
        MouseX := GetMouseX;
        MouseY := GetMouseY;
        Bar((MaxX div 2) - 100, 250, (MaxX div 2) + 100, 325);
        OutTextXY((MaxX div 2) - 98, 252, 'An unknown error ocurred. Maybe');
        OutTextXY((MaxX div 2) - 98, 267, 'you have typed an invalid file');
        OutTextXY((MaxX div 2) - 98, 282, 'address');
        SetFillStyle(SolidFill, LightGray);
        Bar((MaxX div 2) - 25, 305, (MaxX div 2) + 25, 320);
        OutTextXY((MaxX div 2) - 23, 305, 'OK');
        UpdateGraph(UpdateNow);
        sleep(20);
      until (GetMouseButtons = MouseLeftButton) and
        ((MouseX >= (MaxX div 2) - 25) and (MouseX <= (MaxX div 2) + 25) and
          (MouseY <= 320) and (MouseY >= 305));
    end
    else
    begin
      BMP_Size := ImageSize(0, 0, MaxX, MaxY);
      GetMem(BMP_Memory_Location, BMP_Size);
      GetImage(0, 0, MaxX, MaxY, BMP_Memory_Location^);
      BlockWrite(BMP_File, BMP_Memory_Location^, BMP_Size);
      CloseFile(BMP_File);
      FreeMem(BMP_Memory_Location);
      settextstyle(ArialFont, Horizdir, 10);
      for Count := -10 to 0 do
      begin
        bar(0, 0, textwidth('Saved ' + BMP_File_Address), Count + 10);
        outtextxy(0, Count, 'Saved ' + BMP_File_Address);
        updategraph(updatenow);
        sleep(5);
      end;
      sleep(1000);
      for Count := 0 downto -10 do
      begin
        bar(0, 0, textwidth('Saved ' + BMP_File_Address), Count + 10);
        outtextxy(0, Count, 'Saved ' + BMP_File_Address);
        updategraph(updatenow);
        sleep(5);
      end;
    end;
  end;

  procedure Draw_BMP_Panel;
  begin
    if (SpecialKeyPressed = False) then
    begin
      case inputkey of
        #32..#255:
        begin
          FileAddress := FileAddress + inputkey;
          if not (textwidth(rightstr(FileAddress, CharsToDisplay)) > 345) then
            Inc(CharsToDisplay);
        end;
      end;
    end;
    if textwidth(rightstr(FileAddress, CharsToDisplay)) > 345 then
      Dec(CharsToDisplay);
    if (inputkey = #8) and (SpecialKeyPressed = False) then
      FileAddress := leftstr(FileAddress, length(FileAddress) - 1);
    if (inputkey = #13) and (SpecialKeyPressed = False) then
    begin
      SaveBMP(FileAddress);
      FileAddress := '';
      LastPanelCalled := None;
    end;
    setfillstyle(SolidFill, Gray);
    bar((MaxX div 2) - 200, 200, (MaxX div 2) + 200, 350);
    settextstyle(ArialFont, HorizDir, 15);
    outtextxy((MaxX div 2) - 195, 200,
      'Type in a file address for the BMP image. The ''.bmp'' extension will be');
    outtextxy((MaxX div 2) - 195, 215,
      'added if you do not include it. If no file address is specified, but there');
    outtextxy((MaxX div 2) - 195, 230,
      'is a file name, the file will be saved in the same directory as the program');
    outtextxy((MaxX div 2) - 195, 245, 'is installed in');
    setfillstyle(SolidFill, DarkGray);
    bar((MaxX div 2) - 195, 275, (MaxX div 2) + 150, 292);
    outtextxy(((MaxX div 2) + 150) - textwidth(rightstr(FileAddress, CharsToDisplay)),
      276, rightstr(FileAddress, CharsToDisplay));
    setfillstyle(SolidFill, LightGray);
    bar((MaxX div 2) - 195, 310, (MaxX div 2) - 135, 330);
    outtextxy((MaxX div 2) - 193, 312, 'Save BMP');
    setfillstyle(SolidFill, White);
    updategraph(updatenow);
    if getmousebuttons = MouseLeftButton then
    begin        //the sleep is so that when the program next checks for if the
      sleep(200);//mouse button is pressed, the mouse button will have been released
      if (MouseX < (MaxX div 2) - 200) or (MouseX > (MaxX div 2) + 200) or
        (MouseY < 200) or (MouseY > 350) then
        LastPanelCalled := None;
      if (MouseX < (MaxX div 2) - 135) and (MouseX > (MaxX div 2) - 195) and
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
  SelectWindowSize;
  InitGraphAndProgram;
  Load;
  repeat //main program loop
    bar(0, 0, MaxX, MaxY);
    MouseX := GetMouseX;
    MouseY := GetMouseY;
    if SHOW_INFO then
      ReportStatus;
    DrawTexts;
    SpecialKeyPressed := False;

    if (KeyPressed) then
    begin
      InputKey := ReadKey;
    end
    else
    begin
      InputKey := #1;  //an unused value
    end;

    if inputkey = #0 then
    begin
      inputkey := ReadKey;
      SpecialKeyPressed := True;
    end;

    if (LastPanelCalled = None) and (SpecialKeyPressed = False) then
    begin
      case InputKey of
        #32..#255:
        begin
          if ((MouseXAsOfLastTextEntry <> MouseX) or
            (MouseYAsOfLastTextEntry <> MouseY)) then
          begin
            Inc(numoftexts);
            setlength(Texts, numoftexts);
            MouseXAsOfLastTextEntry := MouseX;
            MouseYAsOfLastTextEntry := MouseY;
            Texts[numoftexts - 1].X := MouseX;
            Texts[numoftexts - 1].Y := MouseY;
            Texts[numoftexts - 1].Font := UserFont;
            Texts[numoftexts - 1].FontSize := UserFontSize;
          end;

          Texts[numoftexts - 1].Text := Texts[numoftexts - 1].Text + inputkey;

        end;
      end;
    end;

    if (inputkey = #8) and (numoftexts > 0) and (LastPanelCalled = None) and (SpecialKeyPressed = False) then
      //code for backspacing. #8 is backspace or Ctrl+H
    begin
      Texts[numoftexts - 1].Text :=
        leftstr(Texts[numoftexts - 1].Text, length(Texts[numoftexts - 1].Text) - 1);
      if length(texts[numoftexts - 1].Text) = 0 then
      begin
        Dec(numoftexts);
        setlength(Texts, numoftexts);
      end;
    end;

    if (inputkey = #19) and (SpecialKeyPressed = False) then  //#19 is Ctrl+S. This is the code for saving
    begin
      Save;
    end;

    //reordering items to make the text clicked on the latest one, so that the rest of the program will edit it,
    //and adding right click to change font of any text
    if (MouseEvent = MouseLeft) or (MouseEvent = MouseRight) and (LastPanelCalled = None) and
      (NumOfTexts > 0) then
    begin
      Count := 0;
      repeat
        if ((MouseY <= ((Texts[Count].NoOfLines - 1) * Texts[Count].FontSize) +
          Texts[Count].Y) and (MouseY >= Texts[Count].Y) and
          (MouseX >= Texts[Count].X) and (MouseX <= MaxX)) or
          ((MouseY <= (Texts[Count].NoOfLines * Texts[Count].FontSize) +
          Texts[Count].Y) and (MouseY >= Texts[Count].Y) and
          (MouseX >= Texts[Count].X) and (MouseX <= Texts[Count].X +
          textwidth(Texts[Count].LastLine))) then
        begin
          if (MouseEvent = MouseRight) then
          begin
            if LastPanelCalled = ControlBar then
              DrawControlBarHideAnimation;
            LastPanelCalled := FontPanel;
            TextToEditGlobal := Count;
          end
          else
          begin
            MouseXAsOfLastTextEntry := MouseX;
            MouseYAsOfLastTextEntry := MouseY;
            if not (Count = NumOfTexts - 1) then //reordering texts
            begin
              Inc(numoftexts);
              setlength(Texts, numoftexts);
              Texts[NumOfTexts - 1] := Texts[Count];
              for Count2 := Count to numoftexts - 2 do
              begin
                Texts[Count2] := Texts[Count2 + 1];
              end;
              Dec(numoftexts);
              setlength(Texts, numoftexts);
            end;
          end;
        end;
        Inc(Count);
      until (((MouseY <= ((Texts[Count - 1].NoOfLines - 1) * Texts[Count - 1].FontSize) +
          Texts[Count - 1].Y) and (MouseY >= Texts[Count - 1].Y) and
          (MouseX >= Texts[Count - 1].X) and (MouseX <= MaxX)) or
          ((MouseY <= (Texts[Count - 1].NoOfLines * Texts[Count - 1].FontSize) +
          Texts[Count - 1].Y) and (MouseY >= Texts[Count - 1].Y) and
          (MouseX >= Texts[Count - 1].X) and (MouseX <= Texts[Count - 1].X +
          textwidth(Texts[Count - 1].LastLine)))) or (Count >= numoftexts);
      updategraph(updatenow);
    end;

    //code to decide what menu to show

    if ((InputKey = #20) and (not (LastPanelCalled = ControlBar))) or
      (((MouseY < 5) and (MouseX <> 0)) and (not (LastPanelCalled = ControlBar))) and (SpecialKeyPressed = False) then
      //#20 is Ctrl+T
    begin
      DrawControlBarAnimation;
    end;

    if (inputkey = #6) and (SpecialKeyPressed = False) then     //#6 is Ctrl+F
    begin
      if LastPanelCalled = ControlBar then
        DrawControlBarHideAnimation;
      LastPanelCalled := FontPanel;
      TextToEditGlobal := NumOfTexts;
    end;

    if (inputkey = #2) and (SpecialKeyPressed = False) then   //#2 is Ctrl+B
    begin
      if LastPanelCalled = ControlBar then
        DrawControlBarHideAnimation;
      LastPanelCalled := BMP_Panel;
    end;

    //drawing menus
    if LastPanelCalled = ControlBar then
      DrawControls;
    if LastPanelCalled = FontPanel then
      DrawFontPanel(TextToEditGlobal);
    if LastPanelCalled = BMP_Panel then
      Draw_BMP_Panel;

    updategraph(updatenow);
    sleep(25);

  until (CloseGraphRequest) or ((inputkey = #107) and SpecialKeyPressed);
  //#0 then #107 is Alt+F4
  CloseGraph;
  Save;
end.
