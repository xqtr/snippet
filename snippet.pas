program snippet;
{$Mode objfpc}
{$PACKRECORDS 1} 

{
* var
  BlobStream : TStream;
begin
    Screen.Cursor:= crSQLWait;
    BlobStream := CreateBlobStream(SQLQuery1.FieldByName('Contents'),bmRead);
    BlobStream.Position:= 0;
    Image1.Picture.LoadFromStream(BlobStream);
    Screen.Cursor:= crDefault;
    BlobStream.Free;
  end}

Uses
  {$IFDEF DEBUG}
    LineInfo,
    HeapTrc,
  {$ENDIF}
  {$IFDEF UNIX}
    Unix,
  {$ENDIF}
  xcrt,
  xfileio,
  inifiles,
  xdoor,
  crc,
  sysutils,
  xmenubox,
  xstrings,
  xMenuForm,
  classes,
  xbar,
  snippet_ansiviewer,
  snippet_file,
  snippet_dialogs;
  
Type
  CharSet = Set Of Char;
  
Const
  AppName     = 'Snippet ';
  AppVer      = '1.0';  
  FmtChars : CharSet = ['!', '.', ',', ' ',')',';','-'];
  Appbold     = 30;
  Appfield    =15+7*16;
  Apptext     = 7*16;
  
Var
  output      : toutput;
  input       : tinput;
  db          : tswagfile;
  bar         : tbar;
  abar        : tbar;
  database    : String;
  StartDir    : String;
  i           : Integer;
  Res         : Integer;
  AppAscii    : Boolean = False;
  AppDoor     : Boolean = False;
  Done        : Boolean = False;
  sel         : integer;
  arts        : integer;
  IsLocked    : Boolean = False;
  stmp        : string;
  
  acs         : byte = 255;
  downloadcmd : string = '';
  
  
procedure listdir(dir:string; ext:String); forward;
procedure drawlibbg; forward;
procedure getarticles; forward;
procedure drawreadlib; forward;
procedure readlib(f:string); forward;

Procedure GetFile(F:String);
Var
  Img : Tconsoleimagerec;
Begin
  If Not FileExist(F) Then Begin
    WriteXY(1,25,8,'File not found... '+F);
    Exit;
  End;
  SaveScreen(Img);
  if trim(downloadcmd)<>'' then
    fpsystem(downloadcmd+' "'+f+'"');
  RestoreScreen(Img);
End;

function CrcFile(filename: string): string;
var
  crcvalue: longword;
  fin: File;
  NumRead: Word;
  buf: Array[1..2048] of byte;
begin
  crcvalue := crc32(0,nil,0);
  ///AssignFile (fin, Paramstr(1)); <- change this
  AssignFile (fin, filename); //<- to this
  Reset (Fin,1);
  repeat
    BlockRead(fin, buf, Sizeof(buf), NumRead);   // here show error
    crcvalue := crc32(crcvalue, @buf[1], NumRead);
  until (NumRead=0);
  CloseFile(fin);
  //result := crcvalue;
  result:=IntToHex(crcvalue, 8);
end;

procedure writefield(x,y:byte; s:string; const w:byte=0);
var
  ww:byte;
begin
  if w=0 then ww:=length(s) else ww:=w;
  writexy(x,y,8+7*16,strrep(' ',ww));
  if isnumber(s) then
    writexy(x+ww-length(s),y,7*16,s)
  else
    writexy(x,y,7*16,copy(strstripb(s,' '),1,ww));
end;


Procedure HelpLine(S:String);
Var
  d : Byte;
Begin
  d:= 40 - (strMCILen(S) Div 2);
  GotoXY(1,25);
  Settextattr(AppBold);
  Write(StrRep(' ',79));
  GotoXY(d,25);
  Writepipe(S);
End;

procedure readarticle;
var
  done:boolean = false;
  c:char;
begin
  repeat
    settextattr(7);
    clrscr;
    AppTBox(1,1,79,6,'');
    
    writexy(40-length(' '+db.rec.title+' ') div 2,1,Appbold,' '+db.rec.title+' ');
    
    writexy(2,2,AppField,'Descr.:'); writexy(10,2,AppText,strpadr(db.rec.desc,30,' '));
    writexy(2,3,AppField,'From  :'); writexy(10,3,AppText,strpadr(db.rec.author,30,' '));
    writexy(2,4,AppField,'Email :'); writexy(10,4,AppText,strpadr(db.rec.email,30,' '));
    writexy(2,5,AppField,'CRC   :'); writexy(10,5,AppText,strpadr(db.rec.CRC,10,' '));
    
    writexy(45,2,AppField,'Date :'); writexy(52,2,AppText,Formatdatetime('DD/MM/YYYY',db.rec.date));
    writexy(45,3,AppField,'Tags :'); writexy(52,3,AppText,strpadr(db.rec.tags,26,' '));
    writexy(45,4,AppField,'Link :'); writexy(52,4,AppText,strpadr(db.rec.link,26,' '));
    writexy(45,5,AppField,'File :'); writexy(52,5,AppText,strpadr(db.rec.filename,26,' '));
    
    db.extracttext(db.rec,startdir+'snippet.tmp');
    c:=AnsiViewer(startdir+'snippet.tmp',Appbold);
    case c of
      #0 : done:=true;
      keycursorright : db.next;
      keycursorleft : done:=true;
    end;
  until done;
  
  fileerase(startdir+'snippet.tmp');
end;

Procedure DeleteArticle;
Begin
  if abar.totalitems<=0 then exit;
  if not showmsgbox(1,'Delete record? Are you sure?') then exit;
  if not db.delete(trim(abar.items[abar.position].field1)) then showmsgbox(0,'Could not delete record');
end;

Procedure insertarticle;
label rewrite;
Var
  img    : tconsoleimagerec;
  MyForm : TMenuForm;
  Data   : Array[1..12] of String[255];
  i      : Byte;
  sd,s:string;
  td     : tdatetime;
  d9:byte;
  fn:string;
  encode:boolean = false;
  sl:tstringlist;
  rec:tswagrec;
  goback:boolean=false;
Begin
  savescreen(img);
 
  fn:=GetOpenFileName('Select File to Insert',startdir,'*.*');
  if fn='' then begin
    restorescreen(img);
    exit;
  end;
  
  FillByte (Data, SizeOf(Data), 0);
  MyForm := TMenuForm.Create;
  
  With MyForm Do Begin
    HelpSize := 0;
    HelpColor   :=7;
    cLo         :=15+7*16;
    cHi         :=15+2*16;
    cData       :=7*16;
    cLoKey      :=14+7*16;
    cHiKey      :=14+2*16;
    cField1     :=15+2*16;
    cField2     :=2*16;
  End;
  
  AppBox(11, 5, 70, 18,'Insert New Article');
  writexy(31,16,8+7*16,'Press ESC when ready.');
  fillchar(rec,sizeof(rec),#0);
  rec.crc:=CrcFile(fn);
  if db.iscrc(rec.crc) then 
    if not showmsgbox(1,'It seems that the text file all ready exists. Continue?') then begin
      MyForm.Free;
      exit;
    end;
  MyForm.AddStr ('T',' Title ',     13,  8, 24,  8, 10, 45, 60, @rec.title, rec.title);
  MyForm.AddStr ('D',' Descr.  ',  13,  9, 24,  9, 10, 45, 60, @rec.desc, rec.desc);
  
  MyForm.AddStr ('A',' Author  ',  13, 11, 24, 11, 10, 45, 60, @rec.author, rec.author);
  MyForm.AddStr ('E',' Email   ',  13, 12, 24, 12, 10, 45, 60, @rec.email, rec.email);
  MyForm.AddStr ('L',' Link    ',  13, 13, 24, 13, 10, 45, 60, @rec.link, rec.link);
  MyForm.AddStr ('G',' Tags    ',  13, 14, 24, 14, 10, 45, 60, @rec.tags, rec.tags);
rewrite:  
  MyForm.Execute;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      if rec.title='' then begin
        showmsgbox(0,'You have to at least enter a title!');
        goto rewrite;
      end;
      
      rec.date:=now;
      rec.deleted:=false;
      if not db.appendrec(rec, fn) then showmsgbox(0,'Could not add record,');
    End;
  MyForm.Free;
  
  restorescreen(img);
End;

Procedure editarticle;
Var
  img    : tconsoleimagerec;
  MyForm : TMenuForm;
  Data   : Array[1..12] of String[255];
  i      : Byte;
  sd,s:string;
  td     : tdatetime;
  d9:byte;
  fn:string;
  encode:boolean = false;
  sl:tstringlist;
  rec:tswagrec;
Begin
  savescreen(img);
  
  FillByte (Data, SizeOf(Data), 0);
  MyForm := TMenuForm.Create;
  
  With MyForm Do Begin
    HelpSize := 0;
    HelpColor   :=7;
    cLo         :=15+7*16;
    cHi         :=15+2*16;
    cData       :=7*16;
    cLoKey      :=14+7*16;
    cHiKey      :=14+2*16;
    cField1     :=15+2*16;
    cField2     :=2*16;
  End;
  
  AppBox(11, 5, 70, 18,'Edit Article');
  writexy(31,16,8+7*16,'Press ESC when ready.');
  fillchar(rec,sizeof(rec),#0);
  rec:=db.rec;
  
  MyForm.AddStr ('T',' Title ',     13,  8, 24,  8, 10, 45, 60, @rec.title, rec.title);
  MyForm.AddStr ('D',' Descr.  ',  13,  9, 24,  9, 10, 45, 60, @rec.desc, rec.desc);
  
  MyForm.AddStr ('A',' Author  ',  13, 11, 24, 11, 10, 45, 60, @rec.author, rec.author);
  MyForm.AddStr ('E',' Email   ',  13, 12, 24, 12, 10, 45, 60, @rec.email, rec.email);
  MyForm.AddStr ('L',' Link    ',  13, 13, 24, 13, 10, 45, 60, @rec.link, rec.link);
  MyForm.AddStr ('G',' Tags    ',  13, 14, 24, 14, 10, 45, 60, @rec.tags, rec.tags);
    
  MyForm.Execute;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      
      rec.date:=now;
      //rec.deleted:=false;
      db.updaterec(rec,abar.position+1);
      
    End;
  MyForm.Free;
  
  restorescreen(img);
End;


Procedure editbase(fn:string);
Var
  img    : tconsoleimagerec;
  MyForm : TMenuForm;
  Data   : Array[1..12] of String[255];
  i      : Byte;
  sf     : tswagfile;
  sd,s:string;
  td     : tdatetime;
  
Begin
  if not fileexist(fn) then exit;
  
  sf:=tswagfile.create(fn,fmopenreadwrite+fmShareDenyNone);
  sf.open;
  
  if sf.header.locked then begin
    showmsgbox(0,'Libray is locked. Can''t edit.');
    sf.destroy;
    exit;
  end;
  
  FillByte (Data, SizeOf(Data), 0);
  MyForm := TMenuForm.Create;
  
  With MyForm Do Begin
    HelpSize := 0;
    HelpColor   :=7;
    cLo         :=15+7*16;
    cHi         :=15+2*16;
    cData       :=7*16;
    cLoKey      :=14+7*16;
    cHiKey      :=14+2*16;
    cField1     :=15+2*16;
    cField2     :=2*16;
  End;
   
  data[1]:=sf.header.title;
  data[2]:=FormatDateTime('DD/MM/YY',sf.header.date);
  data[3]:=sf.header.author;
  data[4]:=sf.header.email;
  data[5]:=sf.header.desc;
  data[7]:=sf.header.lang;
  data[8]:=sf.header.crc;
  if sf.header.master then data[9]:='Yes' else data[9]:='No';
  if sf.header.locked then data[6]:='Yes' else data[6]:='No';
  data[10]:=sf.header.tags;
  
  data[12]:=int2str(sf.header.totalrec);
  
  
  savescreen(img);
  AppBox(11, 5, 70, 19,'Edit Library');
  writexy(31,17,8+7*16,'Press ESC when ready.');

  MyForm.AddStr ('N',' Title ',    13,  8, 24,  8, 10, 45, 60, @Data[1], Data[1]);
  MyForm.AddStr ('D',' Descr.  ',  13,  9, 24,  9, 10, 45, 60, @Data[5], Data[5]);
  MyForm.AddDate('T',' Date    ',  13, 10, 24, 10, 10, @Data[2], Data[2]);
  MyForm.AddStr ('A',' Author  ',  13, 11, 24, 11, 10, 45, 60, @Data[3], Data[3]);
  MyForm.AddStr ('E',' Email   ',  13, 12, 24, 12, 10, 45, 60, @Data[4], Data[4]);
  MyForm.AddStr ('L',' Language',  13, 13, 24, 13, 10, 45, 60, @Data[7], Data[7]);
  MyForm.AddStr ('G',' Tags    ',  13, 14, 24, 14, 10, 45, 60, @Data[10], Data[10]);
  MyForm.Addbol ('P',' Master  ', 13, 15, 24, 15, 10, 3,@sf.header.master, Data[9]);
  MyForm.Addbol ('O',' Locked  ', 13, 16, 24, 16, 10, 3,@sf.header.locked, Data[6]);
  
  writexy(35,10,8+7*16,'dd/mm/yy');
  
  MyForm.Execute;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      sf.header.title:=data[1];
      sf.header.desc:=data[5];
      sf.header.author:=data[3];
      sf.header.email:=data[4];
      sf.header.lang:=data[7];
      sf.header.tags:=data[10];
      //If Data[9]='Yes' then sf.header.master:=true else sf.header.master:=false;
      //If Data[6]='Yes' then sf.header.locked:=true else sf.header.locked:=false;
     
      try
        DefaultFormatSettings.ShortDateFormat:='d/m/y';
        DefaultFormatSettings.DateSeparator := '/';
        sf.header.date:=StrToDate(Data[2]);
      except
        sf.header.date:=now;
      end;
      sf.writeheader;
    end;
  
  MyForm.Free;
  sf.destroy;
  restorescreen(img);
End;

procedure createbase(fn:string);
var
  fs  : tfilestream;
  r   : tswagheader;
  d   : word;
Begin
  fs := tfilestream.create(fn,fmcreate);
  fillbyte(r,sizeof(r),0);
  with r do begin
    sign:='SWGEX01';
    title:='';
    desc :='';
    date :=now;
    author:='';
    link:='';
    email:='';
    tags:='';
    lang:='';
    master:=false;
    locked:=false;
    totalrec:=0;
    lastupdate:=now;
    crc:='';    
  end;
  fs.write(r,sizeof(r));
  fs.free;
end;

procedure newbase;
var
  fn:string;
begin
  fn:=GetSaveFileName('Save Filename As...','newlib.dbs',startdir,'*.dbs');
  if fn='' then exit;
  createbase(fn);
  sel:=0;
end;

procedure renamelib(fn:string);
var
 nf:string;
begin
  if bar.totalitems=0 then exit;
  //startdir+bar.items[bar.position].text
  if not fileexist(startdir+fn) then begin
    showmsgbox(0,'File doesn''t exist. Aborting...');
    exit;
  end;
  
  nf:=StrBox(' Rename ','New filename', 20,20,fn);
  if nf='' then exit;
  if fileexist(startdir+nf) then begin
    showmsgbox(0,'File all ready exists. Aborting...');
    exit;
  end;
  
  if upper(justfileext(nf))<>'DBS' then begin
    showmsgbox(0,'File extension doesn''t match. Aborting...');
    exit;
  end;
  renamefile(startdir+fn,startdir+nf);
  listdir(startdir,'dbs');
end;


procedure extractmultiples;
var
  s:string;
  img:tconsoleimagerec;
  d:integer;
  v:string;
begin
  savescreen(img);
  s:=strbox(' Extract Selected Records ','Destination:',60,255,startdir);
  if showmsgbox(1,'Proceed with extracting records?') then begin
    for d:=0 to abar.totalitems-1 do begin
      if abar.items[d].selected then begin
        db.gotorec(d+1);
        v:=uniquefilename(addslash(s)+db.rec.filename);
        db.extracttext(db.rec, v);
      end;
    end;
    showmsgbox(0,'Extraction Complete!');
  end;
  restorescreen(img);
end;

procedure ListFiles(dir:string; mask:String; var files:tstringlist);
var
  Info : TSearchRec;
begin
  If FindFirst (AddSlash(dir)+mask,faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      With Info do
        begin
          if (Attr and faDirectory) = 0 then
            //if Pos(Upper(mask),Upper(Name))>0 Then Files.Add(Name);
            Files.Add(Name);
        end;
    Until FindNext(info)<>0;
    end;
  FindClose(Info);
end;

function FindInMemStream(Stream: TMemoryStream; What: String; ins:boolean):Integer;
var
  bufBuffer, bufBuffer2: array[0..254] of Char;
  i: Integer;
begin
  Result := 0;
  i := 0;
  FillChar(bufBuffer, 255, #0);
  FillChar(bufBuffer2, 255, #0);
  if ins then
    StrPCopy(@bufBuffer2, upper(What))
  else
    StrPCopy(@bufBuffer2, What);
  Stream.Position:=0;
  while Stream.Position <> Stream.Size do begin
    Stream.Read(bufBuffer[0],Length(What));
    if ins then bufBuffer:=upper(bufBuffer);
    if CompareMem(@bufBuffer,@bufBuffer2,Length(What)) then begin
      Result := Stream.Position-Length(What);
      Exit;
    end;
    i := i + 1;
    Stream.Seek(i,0)
  end;
end; 

procedure grep(m:string);
var
  img:tconsoleimagerec;
  d:integer;
  sl:tstringlist;
  finds:integer = 0;
  sw:tswagfile;
  res:tswagfile;
  rescount:integer =0;
  swi:integer;
  s:string;
  pat:string;
  mem:tmemorystream;
  myform:tmenuform;
  rheader:tswagheader;
  
  sstr:string;
  v:string;
  scase:boolean = false;
  stags:boolean = true;
  stitle:boolean = true;
  stext:boolean = true;
  sdesc:boolean = true;
  
  dosearch:boolean = false;
  recfind:boolean = false;
  
  procedure drawbar;
  begin
    writexypipe(38,11,15+7*16,'|23|00'+int2str(d+1)+'|15 of |00'+int2str(sl.count));
    writexy(59,11,7*16,int2str(finds));
    writexy(12,12,15,strrep(#178,((d+1)*57) div sl.count));
  end;
  
  procedure drawbar2(l1,l2:integer);
  begin
    writexy(12,13,7*16,int2str(l1)+'/'+int2str(l2));
    writexy(12,14,15,strrep(#178,((l1)*57) div l2));
  end;
begin
  savescreen(img);
  
  MyForm := TMenuForm.Create;
  With MyForm Do Begin
    HelpSize := 0;
    HelpColor   :=7;
    cLo         :=15+7*16;
    cHi         :=15+2*16;
    cData       :=7*16;
    cLoKey      :=14+7*16;
    cHiKey      :=14+2*16;
    cField1     :=15+2*16;
    cField2     :=2*16;
  End;
  
  AppBox(11, 5, 70, 18,' Search Files ');
  writexy(31,16,8+7*16,'Press ESC when ready.');
  
  MyForm.AddStr ('S',' Search '          ,  13,  8, 24,  8, 10, 45, 60, @sstr, '');
  MyForm.AddBol ('C',' Case Sensitive.  ',  13,  9, 29,  9, 15, 3,  @scase, 'No');
  MyForm.AddBol ('T',' Inc. Titles  '    ,  13, 11, 29, 11, 15, 3, @stitle, 'Yes');
  MyForm.AddBol ('A',' Inc. Tags   '     ,  13, 12, 29, 12, 15, 3, @stags, 'Yes');
  MyForm.AddBol ('B',' Inc. Text   '     ,  13, 13, 29, 13, 15, 3, @stext, 'Yes');
  MyForm.AddBol ('D',' Inc. Descr. '     ,  13, 14, 29, 14, 15, 3, @sdesc, 'Yes');
  
  MyForm.Execute;
  
  If MyForm.Changed Then
    if fileexist(startdir+'result.dbs') then fileerase( startdir+'result.dbs');
    If ShowMsgBox(1, 'Proceed Search?') Then Begin
      if sstr='' then begin
        restorescreen(img);
        exit;
      end;
      sl:=tstringlist.create;
      listfiles(startdir,m,sl);
      fillbyte(rheader,sizeof(rheader),0);
      rheader.title:='Search Results - '+datetimetostr(now);
      rheader.desc:='Pattern: '+sstr;
      rheader.date:=now;
      rheader.lastupdate:=now;
      rheader.master:=false;
      rheader.locked:=false;
      
      createswagfile(startdir+'result.dbs',rheader);
      res:=tswagfile.create(startdir+'result.dbs',fmopenreadwrite+fmShareDenyNone);
      res.open;
      
      dosearch:=true;
    End else begin
      restorescreen(img);
      exit;
    end;
  MyForm.Free;
    
  if not dosearch then begin
    restorescreen(img);
    exit;
  end;
  
  if sl.count=0 then begin
    sl.free;
    restorescreen(img);
    exit;
  end;
  appdbox(10,10,70,15,' Searching...');
  writexy(12,12,15,strrep(#176,57));
  writexy(12,14,15,strrep(#176,57));
  writexy(12,11,15+7*16,'File: ');
  writexy(52,11,15+7*16,'Finds: ');
  for d:=0 to sl.count-1 do begin
    writexy(18,11,7*16,strpadr(justfile(sl[d]),20,' '));
    sw:=tswagfile.create(startdir+sl[d],fmopenreadwrite+fmShareDenyNone);
    sw.open;
    drawbar;

    textcolor(7);
    sw.f.seek(sizeof(sw.header),0);
    while sw.f.position < sw.f.size do begin
      sw.f.read(sw.rec,sizeof(sw.rec));
      recfind:=false;
      if sw.rec.deleted=false then 
        begin
          
          if stags then begin
            s:=sw.rec.tags;
            if scase=false then begin
              s:=upper(s);
              pat:=upper(sstr);
            end else pat:=sstr;
            if pos(pat,s)>0 then begin
              recfind:=true;
              inc(finds);
            end;
          end;
          
          if stitle and (not recfind) then begin
            s:=sw.rec.title;
            if scase=false then begin
              s:=upper(s);
              pat:=upper(sstr);
            end else pat:=sstr;
            if pos(pat,s)>0 then begin
              recfind:=true;
              inc(finds);
            end;
          end;
          
          if sdesc and (not recfind) then begin
            s:=sw.rec.desc;
            if scase=false then begin
              s:=upper(s);
              pat:=upper(sstr);
            end else pat:=sstr;
            if pos(pat,s)>0 then begin
              recfind:=true;
              inc(finds);
            end;
          end;
          
          if stext and (not recfind) then begin
            sw.f.seek(sw.rec.textpos,0);
            mem:=tmemorystream.create;
            
            v:=uniquefilename(startdir+'grepex.tmp');
            sw.extracttext(sw.rec,v);
            
            //mem.copyfrom(sw.f,sw.rec.textsize);
            mem.loadfromfile(v);
            
            fileerase(v);
            
            if FindInMemStream(mem,sstr,scase)>0 then begin
              inc(finds);
              recfind:=true;
            end;
            mem.free;
          end;
          
          if recfind then begin
            sw.extracttext(sw.rec,startdir+'snippet_txt.tmp');
            res.appendrec(sw.rec,startdir+'snippet_txt.tmp');
            fileerase(startdir+'snippet_txt.tmp');
            //res.copyrecfrom(sw,sw.rec);
            rescount:=rescount+1;
          end;
          
        end else
          sw.f.seek(sw.rec.textpos+sw.rec.textsize,0);
      drawbar2(sw.f.position,sw.f.size);
    end;
    sw.destroy;
    writexy(12,14,15,strrep(#176,57));
  end;
  res.header.totalrec:=rescount;
  res.writeheader;
  res.destroy;
  restorescreen(img);
  if finds>0 then readlib(startdir+'result.dbs') else begin
    showmsgbox(0,'No results!');
    fileerase(startdir+'result.dbs');
  end;
end;

procedure extractarticle(i:integer);
var
  s:string;
  v:string;
  img:tconsoleimagerec;
  
  procedure extract;
  begin
    if not db.gotorec(i) then begin
      showmsgbox(0,'Error [004]');
      exit;
    end;
    s:=getsavefilename('Save As...',db.rec.filename,startdir,'*.txt');
    if trim(s)='' then exit;
    s:=uniquefilename(s);
    if db.extracttext(db.rec,s) then
      showmsgbox(0,'Extraction Complete!')
    else
      showmsgbox(0,'Couldn''t extract data.')
  end;
  
begin
  if not appdoor then begin
    if abar.hasselected then extractmultiples else begin
      db.gotorec(i);
      extract;
    end;
  end else begin // is DOOR!
    //if isacs(acs) then
    db.gotorec(i);
    v:=uniquefilename(startdir+db.rec.filename);
    db.extracttext(db.rec,v);
    savescreen(img);
    fpsystem(downloadcmd+' "'+v+'"');
    restorescreen(img);
    
  end;
end;


procedure appinfo;
var
  img:tconsoleimagerec;
begin
  savescreen(img);
  appbox(5,5,40,12,'App. Info');
  if local then 
    writexy(7,8,7*16,'Local Mode')
  else
    writexy(7,8,7*16,'DOOR Mode');
  writexy(7,9,7*16,'ACS:'+int2str(acs));
  writexy(7,10,7*16,'User:'+dropinfo.alias);
  
  readkey;
  restorescreen(img);
end;

Procedure article_OtherKey(C:Char; i:integer);
var
  d:integer;
begin
  if local Or ((local=false) and (acs>=200)) then begin
    case c of
      
      keyctrlz : begin
                extractarticle(i+1);
              end;
      keyctrle : begin
                db.gotorec(i+1);
                editarticle;
                getarticles;
              end;
      keyctrli : begin
                insertarticle;
                drawreadlib;
                getarticles;
              end;
      keyctrld : begin
                deletearticle;
                getarticles;
              end;
    end;
  end;
  case c of
    keyf10 : appinfo;
    keyctrlt : abar.items[i].selected:=not abar.items[i].selected;
    keyctrlu: begin
              for d:=0 to abar.totalitems do abar.items[d].selected:=false;
             end;
    keyctrlh : if local Or ((not local) and isacs(acs)) then articlehelp(true) else articlehelp(false)
  end;
end;

Procedure otherkey(C:Char; i:integer);
  begin
    case c of
      keyctrlh : if local Or ((local=false) and (acs>=200)) then mainhelp(true) else mainhelp(false);
      keyctrll : begin
                listdir(startdir,'dbs');
                bar.sort;
              end;
      keyf10 : appinfo;
      keyctrls : begin
                  grep('*.dbs');
                  drawlibbg;
                  if fileexist(startdir+'result.dbs') then
                    if showmsgbox(1,'Delete Results?') then fileerase(startdir+'result.dbs')
                      else if showmsgbox(1,'Rename file to avoid overwriting it?') then
                        begin
                          renamelib('result.dbs');
                        end;
                  listdir(startdir,'dbs');
                end;
    end;
    if local Or ((local=false) and (acs>=200)) then begin
      case c of
        keyctrlr : renamelib(bar.items[bar.position].text);
        keyctrli : begin
                  newbase;
                  listdir(startdir,'dbs');
                  bar.sort;
                end;
        keyctrle : if bar.totalitems>0 then begin
                  editbase(startdir+bar.items[i].text);
                  drawlibbg;
                end;
        keyctrld : begin
                   if bar.totalitems>0 then begin
                   if showmsgbox(1,'Are you sure?') then begin
                    if fileexist (startdir+bar.items[i].text) then
                      fileerase(startdir+bar.items[i].text);
                    listdir(startdir,'dbs');
                    bar.sort;
                    end;
                  end;
                 end;
      end;
    end;
  sel:=i;
end;

procedure article_select(i:integer);
begin
 arts:=i;
 db.gotorec(i);
 //writexy(1,24,15,strpadr(int2str(db.rec.textpos)+'/'+int2str(db.rec.textsize)+'/'+int2str(sizeof(db.header))+'/'+int2str(sizeof(db.rec)),79,' '));
end;

procedure select(i:integer);
const
  tx = 28;
  fx = 38;
var
  sw  : tswagfile;
Begin
  sw := tswagfile.create(startdir+bar.items[i].text,fmreadwrite+fmShareDenyNone);
  if not sw.open then exit;
  
        
  writexy(tx,5,AppField,'Title:');       writefield(tx,6,strpadr(sw.header.title,40,' '),49);
  writexy(tx,7,AppField,'Description:'); writefield(tx,8,strpadr(sw.header.desc,40,' '),49);
  writexy(tx,9,AppField,'Date    :');    writefield(fx,9,FormatDateTime('DD MMMM YYYY',sw.header.date),25);
  
  
  writexy(tx,11,AppField,'Language:');    writefield(fx,11,sw.header.lang,39);
  writexy(tx,13,AppField,'Tags:');        writefield(tx,14,sw.header.tags,49);
  writexy(tx,15,AppField,'Type    :');       
  
  if sw.header.master=true then
    writefield(fx,15,'Master Lib.',11)
  Else writefield(fx,15,'Update Pack',11);
  
  if sw.header.locked then writefield(fx+12,15,'[Locked]',8) 
    else writefield(fx+12,15,'',8);
    
  
  writexy(tx,21,AppField,'Author  :');     writefield(fx,21,sw.header.author,39);
  writexy(tx,22,AppField,'Email   :');      writefield(fx,22,sw.header.email,39);
  
  
  writexy(tx,17,AppField,'Articles:');      writefield(fx,17,int2str( sw.header.totalrec),6);
  
  
  sw.destroy;
end;
   
procedure listdir(dir:string; ext:String);
var
  Info : TSearchRec;
begin
  bar.clear;
  If FindFirst (AddSlash(dir)+'*',faAnyFile and faDirectory,Info)=0 then
    begin
    Repeat
      With Info do
        begin
          if (Attr and faDirectory) = 0 then begin
            if Pos(Upper(ext),Upper(Name))>0 Then begin
              Bar.Add(Name);
            end;
          end;
        end;
    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  if bar.totalitems>0 then bar.sort;
end;

procedure getarticles;
var
  p:integer;
  n:boolean;
  
  procedure addbar(sr:tswagrec);
  begin
    abar.add(strpadr(int2str(p),5,' ')+' '+
    strpadr(sr.author,20,' ')+' '+
    strpadr(FormatDatetime('DD/MM/YY',sr.date),10,' ')+' '+
    strpadr(sr.title,30,' '));
    abar.items[high(abar.items)].field1:=sr.crc;
  end;
  
begin
  abar.clear;
  if db.header.totalrec<=0 then exit;
  
  for p:=1 to db.header.totalrec do begin
   db.gotorec(p);
   if db.rec.deleted=false then addbar(db.rec);
  end;
  
end;

procedure drawreadlib;
begin
  settextattr(7*16);
  cleararea(1,1,80,25,' ');
  writexy(1,1,AppBold,StrPadR(' '+AppName+' '+AppVer,80,' '));
  helpline('|17|14CTRL-H |08: |15Help Screen');
  AppBox(1,2,79,24,db.header.title);
  writexy(3,5,7*16,strpadr('ID',5,' ')+' '+strpadr('From',20,' ')+' '+strpadr('Date',10,' ')+' '+strpadr('Title',30,' '));
  writexy(3,6,8+7*16,strrep(#196,75));
end;

procedure readlib(f:string);
var
  r    : integer;
begin
  db := tswagfile.create(f,fmopenreadwrite+fmShareDenyNone);
  if not db.open then begin
    showmsgbox(0,'Couldn''t read file.');
    db.destroy;
    exit;
  end;
  drawreadlib;
  abar := tbar.create;
  with abar do begin
    if TotalItems>0 then abar.sort;
    BarOnCl:='|15|18';
    BarOffCl:='|08|23';
    bg:=7*16;
    searchx:=4;
    searchy:=23;
    searcha:=8+7*16;
    dobar:=true;
    barbgcl:=8+7*16;
    barfgcl:=15+7*16;
    selon:='|14|18';
    seloff:='|15|19';
  end;
  abar.OnOtherKey:=@Article_otherkey;
  abar.OnSelect:=@Article_select;
  getarticles;
  r:=0;
  arts:=0;
  repeat
    R:=abar.drawmenu(3,7,75,16,arts);
    if (r=RENTER) and (abar.totalitems>0) then begin
      db.gotorec(abar.position+1);
      readarticle;
      drawreadlib;
    end;
    
  until r=RESC;
  db.free;
  abar.free;

end;

procedure drawlibbg;
begin
  settextattr(7*16);
  cleararea(1,1,80,25,' ');
  writexy(1,1,AppBold,StrPadR(' '+AppName+' '+AppVer,80,' '));
  AppBox(1,2,23,24,' Library');
  AppBox(25,2,79,24,'Details');
  helpline('|17|14CTRL-H |08: |15Help Screen');
end;

procedure initbg;
begin
  drawlibbg;
  listdir(startdir,'dbs');
  with bar do begin
    if bar.totalitems>0 then sort;
    BarOnCl:='|15|18';
    BarOffCl:='|08|23';
    bg:=7*16;
    searchx:=4;
    searchy:=23;
    searcha:=8+7*16;
    dobar:=true;
    barbgcl:=8+7*16;
    barfgcl:=15+7*16;
    
  end;
  bar.OnOtherKey:=@otherkey;
  bar.OnSelect:=@select;
  Res := 0;
  sel := 0;
  
  repeat
    
    Res:=bar.drawmenu(3,5,19,18,sel);
    if res=RENTER then 
      if bar.totalitems>0 then begin readlib(startdir+bar.items[bar.position].text);
        drawlibbg;
      end;
  until res=RESC;
  
end;  

procedure WriteHelp;
begin
  WriteLn('');
  setTextAttr(14);
  WriteLn(' ____  _____ _____ ____   ___   ____    _    __  __ _____ ____  ');
  WriteLn('|  _ \| ____|_   _|  _ \ / _ \ / ___|  / \  |  \/  | ____/ ___| ');
  WriteLn('| |_) |  _|   | | | |_) | | | | |  _  / _ \ | |\/| |  _| \___ \ ');
  WriteLn('|  _ <| |___  | | |  _ <| |_| | |_| |/ ___ \| |  | | |___ ___) |');
  WriteLn('|_| \_\_____| |_| |_| \_\\___/ \____/_/   \_\_|  |_|_____|____/ ');
  WriteLn('                                        Version '+Appver);
  WriteLn('');
  SetTextAttr(7);
  WriteLn(' Thousands of retro games inside your BBS');
  WriteLn(' Usage:');
  WriteLn('    retrogames <door/32 filename>');
  WriteLn('');
  WriteLn(' Example:');
  WriteLn('    retrogames /bbs/node1/door.sys');
  WriteLn('');
end;

Procedure ExitApp(cl:boolean);
Begin
  settextattr(7);
  if cl then clrscr;
  bar.free;
  Output.free;
  input.free;
End;

procedure loadsettings;
var
  ini:tinifile;
begin
  if not fileexist(addslash(justpath(paramstr(0)))+'snippet.ini') then begin
    acs:=255;
    startdir:=AppPath;
    exit;
  end;
  ini:=tinifile.create(Apppath+'snippet.ini');
  downloadcmd:=ini.readstring('door','download_command','');
  acs:=0;
  if appdoor then begin
    acs:=ini.readinteger('users',dropinfo.alias,0);
  end;
  ini.free;
end;

procedure showhelp;
begin
  system.writeln('');
  system.writeln(' [] '+Appname + ' '+Appver);
  system.writeln('    Create libraries with snippets of code or useful info about everything.');
  system.writeln('');
  system.writeln(' Usage:');
  system.writeln('');
  stmp:=justfilename(justfile(paramstr(0)));
  system.writeln(' Normal mode');
  system.writeln('   '+stmp+' [--help|-h|/h|-h] [door_dropfile]');
  system.writeln(' Import mode');
  system.writeln('   '+stmp+' <dest_lib> <source_lib>');
  system.writeln(' ');
  system.writeln(' In Normal Mode you can use the program as a DOOR app also.');
  system.writeln(' Just point the dropfile to read. ex DOOR32.SYS');
  system.writeln('');
  system.writeln(' In Import Mode the source_lib will be imported to the dest_lib file.');
  system.writeln('');
  system.writeln('   _            _   _              ___          _    _       ');
  system.writeln('  /_\  _ _  ___| |_| |_  ___ _ _  |   \ _ _ ___(_)__| |               8888');
  system.writeln(' / _ \| '' \/ _ \  _| '' \/ -_) ''_| | |) | ''_/ _ \ / _` |            8 888888 8');
  system.writeln('/_/ \_\_||_\___/\__|_||_\___|_|   |___/|_| \___/_\__,_|            8888888888');
  system.writeln('                                                                   8888888888');
  system.writeln('         DoNt Be aNoTHeR DrOiD fOR tHe SySteM                      88 8888 88');
  system.writeln('                                                                   8888888888');
  system.writeln('    .o HaM RaDiO    .o ANSi ARt!       .o MySTiC MoDS              "88||||88"');
  system.writeln('    .o NeWS         .o WeATheR         .o FiLEs                     ""8888""');
  system.writeln('    .o GaMeS        .o TeXtFiLeS       .o PrEPardNeSS                  88');
  system.writeln('    .o TuTors       .o bOOkS/PdFs      .o SuRVaViLiSM          8 8 88888888888');
  system.writeln('    .o FsxNet       .o SurvNet         .o More...            888 8888][][][888');
  system.writeln('                                                               8 888888##88888');
  system.writeln('   TeLNeT : andr01d.zapto.org:9999 [UTC 11:00 - 20:00]         8 8888.####.888');
  system.writeln('   SySoP  : xqtr                   eMAiL: xqtr@gmx.com         8 8888##88##888');
  system.writeln('   DoNaTE : http://paypal.me/xqtr');
  system.writeln(' ');

end;

procedure import(s1,s2:string);
var
  sw:tswagfile;
  c:char;
begin
  system.writeln;
  if not isswagfile(paramstr(1)) then begin
    system.writeln(' File: '+justfile(justfilename(s1))+' is not a library file. Aborting...');
    halt;
  end;
  if not isswagfile(paramstr(2)) then begin
    system.writeln(' File: '+justfile(justfilename(s2))+' is not a library file. Aborting...');
    halt;
  end;
  system.writeln('This procedure will import records from: '+justfile(justfilename(s2))+' to library: '+justfile(justfilename(s1))+'.');
  repeat
    system.writeln('Are you sure you want to proceed? (Y/N)');
    input:=tinput.create;
    xcrt.keyboard:=input;
    c:=readkey;
    c:=LoCase(c);
    input.destroy;
  until (c='y') or (c='n');
  if c='n' then halt;

  sw:=tswagfile.create(s1,fmopenreadwrite+fmShareDenyNone);
  sw.open;
  
  if not sw.importfrom(s2) then system.writeln('Error while importing data. Check for corrupt files')
    else system.writeln('Import procedure complete!');
  system.writeln;
  sw.destroy;
end;

Begin
  StartDir := AppPath;
  
  If ParamCount < 1 Then Begin
    local:=true;
    appdoor:=false;
  End 
  else if paramcount=1 then begin
    stmp:=upper(paramstr(1));
    if (stmp='/?') or (stmp='-?') or (stmp='-H') or (stmp='--HELP') or (stmp='/H') then begin
      showhelp;
      halt;
    end;
    
    ReadDoor(ParamStr(1));
    appdoor:=not local;
    LoadSettings;
  end else if paramcount=2 then begin
    import(paramstr(1),paramstr(2));
    halt; 
  end;
  
  output:=toutput.create(true);
  input:=tinput.create;
  xcrt.screen:=output;
  xcrt.keyboard:=input;
  bar:=tbar.create;
  enable_ansi_unix;
  
  SetTextAttr(7);
  ClrScr;
  InitBG;
  ExitApp(true);
  
End.
