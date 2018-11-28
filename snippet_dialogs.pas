unit snippet_dialogs;
{$Mode objfpc}
{$PACKRECORDS 1} 

interface

uses
  xmenubox,
  xstrings,
  xmenuinput,
  xquicksort,
  dos,
  xfileio,
  xMenuForm,
  xcrt;
  
Const
    AppBold  = 30;
    AppTitle = 14+7*16;
    AppDisabled = 8+7*16;

Procedure AppBox(x1,y1,x2,y2:byte; title:string);
Procedure AppDBox(x1,y1,x2,y2:byte; title:string);
Function ShowMsgBox (BoxType: Byte; Str: String) : Boolean;
Function GetSaveFileName(Header,def,xferpath,mask: String): String;
Function GetOpenFileName(Header,xFerPath,mask: String) : String;
Function StrBox(title,prompt:string; sizeb,sizes:byte;default:string):string;
Procedure AppTBox(x1,y1,x2,y2:byte; title:string);
procedure ArticleHelp(sys:boolean);
procedure MainHelp(sys:boolean);
  
implementation

procedure ArticleHelp(sys:boolean);
var
  img:tconsoleimagerec;
  y:byte = 5;
  x:byte = 5;
begin
  savescreen(img);
  appbox(1,1,79,24,'Help');
  writexy(1,25,appbold,strpadc('Press a key to continue...',79,' '));
  
  writexy(5,5,8+7*16,'Writing text on the list searches through the titles.');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-A');writexy(x+10,y,7*16,'Repeat Search');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-Y');writexy(x+10,y,7*16,'Reset Search');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-T');writexy(x+10,y,7*16,'Tag Item');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-U');writexy(x+10,y,7*16,'Untag All Items');y:=y+1;
 
  writexy(x,y,15+7*16,'F10');writexy(x+10,y, 7*16,'User Info');y:=y+1;
  if not sys then begin
    writexy(x,y,15+7*16,'CTRL-Z');writexy(x+10,y,7*16,'Download Text');y:=y+1;
  end else begin
    writexy(x,y,15+7*16,'CTRL-Z');writexy(x+10,y,7*16,'Extract Text');y:=y+1;
  end;
  
  writexy(x,y,15+7*16,'ENTER');writexy(x+10,y,7*16,'Read Article');y:=y+1;
  writexy(x,y,15+7*16,'ESC');writexy(x+10,y,7*16,'Go Back');y:=y+1;
  
  if sys then begin
    writexy(x,y,15+7*16,'CTRL-E');writexy(x+10,y,7*16,'Edit Article');y:=y+1;
    writexy(x,y,15+7*16,'CTRL-I');writexy(x+10,y,7*16,'Insert New Article');y:=y+1;
    writexy(x,y,15+7*16,'CTRL-D');writexy(x+10,y,7*16,'Remove Article');y:=y+1;
  end;
  
  readkey;
  restorescreen(img);
end;

procedure MainHelp(sys:boolean);
var
  img:tconsoleimagerec;
  y:byte = 5;
  x:byte = 5;
begin
  savescreen(img);
  appbox(1,1,79,24,'Help');
  writexy(1,25,appbold,strpadc('Press a key to continue...',79,' '));
  
  writexy(5,5,8+7*16,'Writing text on the list searches through the titles.');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-A');writexy(x+10,y,7*16,'Repeat Search');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-Y');writexy(x+10,y,7*16,'Reset Search');y:=y+1;
  writexy(x,y,15+7*16,'CTRL-S');writexy(x+10,y, 7*16,'Find text in all files');y:=y+1;
  writexy(x,y,15+7*16,'F10');writexy(x+10,y, 7*16,'User Info');y:=y+1;
  
    
  writexy(x,y,15+7*16,'CTRL-L');writexy(x+10,y,7*16,'Refresh List');y:=y+1;
  
  writexy(x,y,15+7*16,'ENTER');writexy(x+10,y,7*16,'Read Article');y:=y+1;
  writexy(x,y,15+7*16,'ESC');writexy(x+10,y,7*16,'Go Back');y:=y+1;
  
  if sys then begin
    writexy(x,y,15+7*16,'CTRL-R');writexy(x+10,y,7*16,'Rename Library');y:=y+1;
    writexy(x,y,15+7*16,'CTRL-E');writexy(x+10,y,7*16,'Edit Library');y:=y+1;
    writexy(x,y,15+7*16,'CTRL-I');writexy(x+10,y,7*16,'Create New Library');y:=y+1;
    writexy(x,y,15+7*16,'CTRL-D');writexy(x+10,y,7*16,'Remove Library');y:=y+1;
  end;
  
  readkey;
  restorescreen(img);
end;

Function ShowMsgBox (BoxType: Byte; Str: String) : Boolean;
Var
  Len    : Byte;
  Len2   : Byte;
  Pos    : Byte;
  Offset : Byte;
  SavedX : Byte;
  SavedY : Byte;
  SavedA : Byte;
  img    : tconsoleimagerec;
Begin
  ShowMsgBox := True;
  SavedX     := WhereX;
  SavedY     := WhereY;
  SavedA     := GetTextAttr;
  savescreen(img);
  Len := (80 - (Length(Str) + 2)) DIV 2;
  Pos := 1;
  offset:=0;

  If BoxType < 2 Then
    appdbox (Len, 10 + Offset, Len + Length(Str) + 3, 15 + Offset,' Info ')
  Else
    appdbox (Len, 10 + Offset, Len + Length(Str) + 3, 14 + Offset,' Info ');

  WriteXY (Len + 2, 12 + Offset, 15+7*16, Str);

  Case BoxType of
    0 : Begin
          Len2 := (Length(Str) - 4) DIV 2;

          WriteXY (Len + Len2 + 2, 14 + Offset, 7*16, ' OK ');

          Repeat
            Keyboard.ReadKey;
          Until Not Keyboard.KeyPressed;
        End;
    1 : Repeat
          Len2 := (Length(Str) - 9) DIV 2;

          WriteXY (Len + Len2 + 2, 14 + Offset, 8+7*16, ' YES ');
          WriteXY (Len + Len2 + 7, 14 + Offset, 8+7*16, ' NO ');

          If Pos = 1 Then
            WriteXY (Len + Len2 + 2, 14 + Offset, 15+2*16, ' YES ')
          Else
            WriteXY (Len + Len2 + 7, 14 + Offset, 15+2*16, ' NO ');

          Case UpCase(Keyboard.ReadKey) of
            #00 : Case Keyboard.ReadKey of
                    #75 : Pos := 1;
                    #77 : Pos := 0;
                  End;
            #13 : Begin
                    ShowMsgBox := Boolean(Pos);
                    Break;
                  End;
            #32 : If Pos = 0 Then Inc(Pos) Else Pos := 0;
            'N' : Begin
                    ShowMsgBox := False;
                    Break;
                  End;
            'Y' : Begin
                    ShowMsgBox := True;
                    Break;
                  End;
          End;
        Until False;
  End;

  //If BoxType <> 2 Then MsgBox.Close;
  restorescreen(img);
  GotoXY (SavedX, SavedY);
  SetTextAttr(SavedA);
End;

Function GetSaveFileName(Header,def,xferpath,mask: String): String;
Const
  ColorBox = 3*16;
  ColorBar = 15+2*16;
Var
  DirList  : TMenuList;
  FileList : TMenuList;
  Str      : String;
  Path     : String;
  //Mask     : String;
  OrigDIR  : String;
  SaveFile : String;
  img      : tconsoleimagerec;

  Procedure UpdateInfo;
  Begin
    WriteXY (8,  7, 3 * 16, strPadR(Path, 65, ' '));
    WriteXY (8, 21, 3 * 16, strPadR(SaveFile, 65, ' '));
  End;

  Procedure CreateLists;
  Var
    Dir      : SearchRec;
    DirSort  : TQuickSort;
    FileSort : TQuickSort;
    Count    : LongInt;
  Begin
    DirList.Clear;
    FileList.Clear;

    While Path[Length(Path)] = PathSep Do Dec(Path[0]);

    ChDir(Path);

    Path := Path + PathSep;

    If IoResult <> 0 Then Exit;

    DirList.Picked  := 1;
    FileList.Picked := 1;

    UpdateInfo;

    DirSort  := TQuickSort.Create;
    FileSort := TQuickSort.Create;

    FindFirst (Path + '*', AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If (Dir.Attr And Directory = 0) or ((Dir.Attr And Directory <> 0) And (Dir.Name = '.')) Then Begin
        FindNext(Dir);
        Continue;
      End;

      DirSort.Add (Dir.Name, 0);
      FindNext    (Dir);
    End;

    FindClose(Dir);

    FindFirst (Path + Mask, AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If Dir.Attr And Directory <> 0 Then Begin
        FindNext(Dir);

        Continue;
      End;

      FileSort.Add(Dir.Name, 0);
      FindNext(Dir);
    End;

    FindClose(Dir);

    DirSort.Sort  (1, DirSort.Total,  qAscending);
    FileSort.Sort (1, FileSort.Total, qAscending);

    For Count := 1 to DirSort.Total Do
      DirList.Add(DirSort.Data[Count]^.Name, 0);

    For Count := 1 to FileSort.Total Do
      FileList.Add(FileSort.Data[Count]^.Name, 0);

    DirSort.Free;
    FileSort.Free;

    WriteXY (14, 9, AppDisabled, strPadR('(' + strComma(FileList.ListMax) + ')', 7, ' '));
    WriteXY (53, 9, AppDisabled, strPadR('(' + strComma(DirList.ListMax) + ')', 7, ' '));
  End;

Var
  Done : Boolean;
  Mode : Byte;
Begin
  Result   := '';
  Path     := XferPath;
  //Mask     := '*.*';
  SaveFile := def;
  savescreen(img);
  
  DirList  := TMenuList.Create;
  FileList := TMenuList.Create;

  GetDIR (0, OrigDIR);

  FileList.NoWindow   := True;
  FileList.LoChars    := #9#13#27;
  FileList.HiChars    := #77;
  FileList.HiAttr     := ColorBar;
  FileList.LoAttr     := ColorBox;

  DirList.NoWindow    := True;
  DirList.NoInput     := True;
  DirList.HiAttr      := ColorBox;
  DirList.LoAttr      := ColorBox;

  AppBox(6,3,74,23,Header);

  WriteXY ( 8,  6, Apptitle, 'Directory');
  WriteXY ( 8,  9, Apptitle, 'Files');
  WriteXY (41,  9, Apptitle, 'Directories');
  WriteXY ( 8, 20, Apptitle, 'File Name');
  WriteXY ( 8, 21, 15+7*16, strRep(' ', 65));

  CreateLists;

  DirList.Open (40, 9, 72, 19);
  DirList.Update;

  Done := False;

  Repeat
    FileList.Open (7, 9, 39, 19);

    Case FileList.ExitCode of
      #09,
      #77 : Begin
              FileList.HiAttr := ColorBox;
              DirList.NoInput := False;
              DirList.LoChars := #09#13#27;
              DirList.HiChars := #75;
              DirList.HiAttr  := ColorBar;

              FileList.Update;

              Repeat
                DirList.Open(40, 9, 72, 19);

                Case DirList.ExitCode of
                  #09 : Begin
                          DirList.HiAttr := ColorBox;
                          DirList.Update;

                          Mode  := 1;
                          xMenuInput.FillAttr := 2;
                          xMenuInput.Attr := 15+2*16;
                          xMenuInput.LoChars := #09#13#27;

                          Repeat
                            Case Mode of
                              1 : Begin
                                    Str := GetStr(8, 21, 65, 255, 1, SaveFile);

                                    Case xMenuInput.ExitCode of
                                      #09 : Mode := 2;
                                      #13 : Begin
                                              SaveFile := Str;
                                              if SaveFile <> '' then 
                                                if fileexist(Path + Savefile) then Begin
                                                  if ShowMsgBox(1, 'File Exists. Overwrite?') then Result := Path + Savefile
                                                  End else Result := Path + Savefile;
                                              if result = Path + Savefile then begin
                                                ChDIR(OrigDIR);
                                                FileList.Free;
                                                DirList.Free;
                                                restorescreen(img);
                                                exit;
                                              end;
                                              (*CreateLists;
                                              FileList.Update;
                                              DirList.Update;*)
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                              2 : Begin
                                    UpdateInfo;

                                    Str := GetStr(8, 7, 65, 255, 1, Path);

                                    Case xMenuInput.ExitCode of
                                      #09 : Break;
                                      #13 : Begin
                                              ChDir(Str);

                                              If IoResult = 0 Then Begin
                                                Path := Str;
                                                CreateLists;
                                                FileList.Update;
                                                DirList.Update;
                                              End;
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                            End;
                          Until False;

                          UpdateInfo;

                          Break;
                        End;
                  #13 : If DirList.ListMax > 0 Then Begin
                          ChDir  (DirList.List[DirList.Picked]^.Name);
                          GetDir (0, Path);

                          Path := Path + PathSep;

                          CreateLists;
                          FileList.Update;
                        End;
                  #27 : Done := True;
                  #75 : Break;
                End;
              Until Done;

              DirList.NoInput := True;
              DirList.HiAttr  := ColorBox;
              FileList.HiAttr := ColorBar;
              DirList.Update;
            End;
      #13 : If FileList.ListMax > 0 Then Begin
              //Result := Path + FileList.List[FileList.Picked]^.Name;
              if fileexist(Path + FileList.List[FileList.Picked]^.Name) then Begin
                if ShowMsgBox(1, 'File Exists. Overwrite?') then Result := Path + FileList.List[FileList.Picked]^.Name;
              End else Result := Path + FileList.List[FileList.Picked]^.Name;
              if Result = Path + FileList.List[FileList.Picked]^.Name then Break;
            End;
      #27 : Begin
              Result:='';
              Break;
            End;
    End;
  Until Done;

  ChDIR(OrigDIR);
  restorescreen(img);
  FileList.Free;
  DirList.Free;
End;

Function GetOpenFileName(Header,xFerPath,mask: String) : String;
Const
  ColorBox = 3*16;
  ColorBar = 15+2*16;
Var
  DirList  : TMenuList;
  FileList : TMenuList;
  
  Str      : String;
  Path     : String;
  //Mask     : String;
  OrigDIR  : String;

  Procedure UpdateInfo;
  Begin
    WriteXY (8,  7, 3 * 16, strPadR(Path, 65, ' '));
    WriteXY (8, 21, 3 * 16, strPadR(Mask, 65, ' '));
  End;

  Procedure CreateLists;
  Var
    Dir      : SearchRec;
    DirSort  : TQuickSort;
    FileSort : TQuickSort;
    Count    : LongInt;
  Begin
    DirList.Clear;
    FileList.Clear;

    While Path[Length(Path)] = PathSep Do Dec(Path[0]);

    ChDir(Path);

    Path := Path + PathSep;

    If IoResult <> 0 Then Exit;

    DirList.Picked  := 1;
    FileList.Picked := 1;

    UpdateInfo;

    DirSort  := TQuickSort.Create;
    FileSort := TQuickSort.Create;

    FindFirst (Path + '*', AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If (Dir.Attr And Directory = 0) or ((Dir.Attr And Directory <> 0) And (Dir.Name = '.')) Then Begin
        FindNext(Dir);
        Continue;
      End;

      DirSort.Add (Dir.Name, 0);
      FindNext    (Dir);
    End;

    FindClose(Dir);

    FindFirst (Path + Mask, AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If Dir.Attr And Directory <> 0 Then Begin
        FindNext(Dir);

        Continue;
      End;

      FileSort.Add(Dir.Name, 0);
      FindNext(Dir);
    End;

    FindClose(Dir);

    DirSort.Sort  (1, DirSort.Total,  qAscending);
    FileSort.Sort (1, FileSort.Total, qAscending);

    For Count := 1 to DirSort.Total Do
      DirList.Add(DirSort.Data[Count]^.Name, 0);

    For Count := 1 to FileSort.Total Do
      FileList.Add(FileSort.Data[Count]^.Name, 0);

    DirSort.Free;
    FileSort.Free;

    WriteXY (14, 9, AppDisabled, strPadR('(' + strComma(FileList.ListMax) + ')', 7, ' '));
    WriteXY (53, 9, AppDisabled, strPadR('(' + strComma(DirList.ListMax) + ')', 7, ' '));
  End;

Var
  Box  : TMenuBox;
  Done : Boolean;
  Mode : Byte;
Begin
  Result   := '';
  Path     := XferPath;
  //Mask     := '*.*';
  Box      := TMenuBox.Create;
  DirList  := TMenuList.Create;
  FileList := TMenuList.Create;

  GetDIR (0, OrigDIR);

  FileList.NoWindow   := True;
  FileList.LoChars    := #9#13#27;
  FileList.HiChars    := #77;
  FileList.HiAttr     := ColorBar;
  FileList.LoAttr     := ColorBox;

  DirList.NoWindow    := True;
  DirList.NoInput     := True;
  DirList.HiAttr      := ColorBox;
  DirList.LoAttr      := ColorBox;

  AppBox(6,3,74,23,Header);

  WriteXY ( 8,  6, Apptitle, 'Directory');
  WriteXY ( 8,  9, Apptitle, 'Files');
  WriteXY (41,  9, Apptitle, 'Directories');
  WriteXY ( 8, 20, Apptitle, 'File Mask');
  WriteXY ( 8, 21,  15+7*16, strRep(' ', 65));

  CreateLists;

  DirList.Open (40, 9, 72, 19);
  DirList.Update;

  Done := False;

  Repeat
    FileList.Open (7, 9, 39, 19);

    Case FileList.ExitCode of
      #09,
      #77 : Begin
              FileList.HiAttr := ColorBox;
              DirList.NoInput := False;
              DirList.LoChars := #09#13#27;
              DirList.HiChars := #75;
              DirList.HiAttr  := ColorBar;

              FileList.Update;

              Repeat
                DirList.Open(40, 9, 72, 19);

                Case DirList.ExitCode of
                  #09 : Begin
                          DirList.HiAttr := ColorBox;
                          DirList.Update;

                          Mode  := 1;
                          xMenuInput.LoChars := #09#13#27;
                          xMenuInput.FillAttr := 2;
                          xMenuInput.Attr := 15+7*16;
                          Repeat
                            Case Mode of
                              1 : Begin
                                    //xMenuInput.Attr := 7*16;
                                    xMenuInput.Attr := 15+2*16;
                                    Str := GetStr(8, 21, 65, 255, 1, Mask);

                                    Case xMenuInput.ExitCode of
                                      #09 : Mode := 2;
                                      #13 : Begin
                                              Mask := Str;
                                              CreateLists;
                                              FileList.Update;
                                              DirList.Update;
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                              2 : Begin
                                    UpdateInfo;
                                    //xMenuInput.Attr := 7*16;
                                    xMenuInput.Attr := 15+2*16;
                                    Str := GetStr(8, 7, 65, 255, 1, Path);

                                    Case xMenuInput.ExitCode of
                                      #09 : Break;
                                      #13 : Begin
                                              ChDir(Str);

                                              If IoResult = 0 Then Begin
                                                Path := Str;
                                                CreateLists;
                                                FileList.Update;
                                                DirList.Update;
                                              End;
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                            End;
                          Until False;

                          UpdateInfo;

                          Break;
                        End;
                  #13 : If DirList.ListMax > 0 Then Begin
                          ChDir  (DirList.List[DirList.Picked]^.Name);
                          GetDir (0, Path);

                          Path := Path + PathSep;

                          CreateLists;
                          FileList.Update;
                        End;
                  #27 : Done := True;
                  #75 : Break;
                End;
              Until Done;

              DirList.NoInput := True;
              DirList.HiAttr  := ColorBox;
              FileList.HiAttr := ColorBar;
              DirList.Update;
            End;
      #13 : If FileList.ListMax > 0 Then Begin
              Result := Path + FileList.List[FileList.Picked]^.Name;
              Break;
            End;
      #27 : Break;
    End;
  Until Done;

  ChDIR(OrigDIR);

  FileList.Free;
  DirList.Free;
  Box.Close;
  Box.Free;
End;

Procedure AppDBox(x1,y1,x2,y2:byte; title:string);
var
  box:tmenubox;
begin
  box:=tmenubox.create;
  with box do begin
    frametype:=2;
    shadow:=true;
    shadowattr:=8;
    headtype:=0;
    header:=title;
    emboss:=false;
  end;
  box.open(x1,y1,x2,y2);
  box.free;
end;

Procedure AppTBox(x1,y1,x2,y2:byte; title:string);
var
  box:tmenubox;
begin
  box:=tmenubox.create;
  with box do begin
    frametype:=1;
    shadow:=false;
    shadowattr:=8;
    headtype:=3;
    header:=title;
    emboss:=true;
  end;
  box.open(x1,y1,x2,y2);
  box.free;
end;

Procedure AppBox(x1,y1,x2,y2:byte; title:string);
var
  d:byte;
begin
  WinBoxBorder(x1,y1,x2,y2,7);
  d:=((x2-x1) div 2) - (length(title) div 2);
  writexy(x1+d,y1+1,AppBold,title);
end;

Function StrBox(title,prompt:string; sizeb,sizes:byte;default:string):string;
Var 
  MsgBox : TMenuBox;
  Len    : Byte;
  SavedX : Byte;
  SavedY : Byte;
  SavedA : Byte;
Begin
  SavedX     := WhereX;
  SavedY     := WhereY;
  SavedA     := GetTextAttr;
  MsgBox := TMenuBox.Create;
  MsgBox.Header     := Title;
  with msgbox do begin
    frametype:=2;
    shadow:=true;
    shadowattr:=8;
    headtype:=0;
    header:=title;
    emboss:=false;
  end;
  Len := (80 - (sizeb + 2)) DIV 2;
  MsgBox.Open (Len, 10 , Len + sizeb + 3, 13 );
  writexy(len+2,11,8+7*16,prompt);
  result:=getstr(len+2,12,sizeb,sizes,1,15+2*16,15,#176,default);
  msgbox.close;
  MsgBox.Free;
  GotoXY (SavedX, SavedY);
  SetTextAttr(SavedA);
End;

End.
