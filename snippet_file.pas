unit snippet_file;
{$Mode objfpc}
{$PACKRECORDS 1} 

interface

uses classes;

type
  tswagheader = record
    sign:array[1..7] of char;
    title:string[80];
    desc :string[255];
    date :tdatetime;
    author:string[30];
    link:string[255];
    email:string[255];
    tags:string[255];
    lang:string[20];
    master:boolean;
    locked:boolean;
    totalrec:integer;
    
    lastupdate:tdatetime;
    crc:string[10];
    reserved:array[1..50] of byte;
  end;
  
  tswagrec = record
    id:integer;
    title:string[80];
    desc :string[255];
    date :tdatetime;
    author:string[30];
    link:string[255];
    email:string[255];
    tags:string[255];
    filename:string[255];
    textpos:longint;
    textsize:longint;
    crc:string[10];
    deleted:boolean;
    compress:boolean;
  end;

  tswagfile = class
    f : tfilestream;
    header:tswagheader;
    rec:tswagrec;
    constructor create(fn:string; mode:word);
    destructor destroy; Override;
    function open:boolean;
    function first:boolean;
    function next:boolean;
    function last:boolean;
    function gotorec(i:integer):boolean;
    function appendrec(r:tswagrec; fl:string):boolean;
    function updaterec(r:tswagrec; i:integer):boolean;
    function copyrecfrom(var w:tswagfile; var arec:tswagrec):boolean;
    function delete(i:integer):boolean;
    function delete(crc:string):boolean; overload;
    function extracttext(r:tswagrec; fn:string):boolean;
    function iscrc(crc:string):boolean;
    function importfrom(s:string):boolean;
    procedure initnext;
    procedure writeheader;
  end;

procedure createswagfile(fn:string; var header:tswagheader);
function isswagfile(fn:string):boolean;

implementation

uses dos,sysutils,snippet_compress,crt;

Function FileExist (Str: String) : Boolean;
Var
  DF   : File;
  Attr : Word;
Begin
  Assign   (DF, Str);
  GetFattr (DF, Attr);

  Result := (DosError = 0) and (Attr And Directory = 0);
End;

constructor tswagfile.create(fn:string; mode:word);
begin
  Inherited Create;
  f:=tfilestream.create(fn,mode);
  f.read(header,sizeof(header));
end;

destructor tswagfile.destroy;
begin
  Inherited Destroy;
  f.free;
end;

function tswagfile.open:boolean;
begin
  if header.sign='SWGEX01' then result:=true else result:=false;
end;

function tswagfile.first:boolean;
begin
  result:=true;
  try
    f.seek(sizeof(header),soFromBeginning);
    f.read(rec,sizeof(rec));
  except
    result:=false;
  end;
end;

function tswagfile.next:boolean;
begin
  result:=true;
  try
    repeat
      f.seek(rec.textpos+rec.textsize,soFromBeginning);
      f.read(rec,sizeof(rec));
    until rec.deleted=false;
  except
    result:=false;
  end;
end;

function tswagfile.last:boolean;
begin
  result:=true;
  try
    first;
    While F.Position < f.size Do Begin
      next;
    end;
  except
    result:=false;
  end;
end;

{function tswagfile.gotorec(i:integer):boolean;
var
  r:tswagrec;
  d:integer;
begin 
  result:=false;
  if i>header.totalrec then exit;
  
  f.seek(sizeof(header),0);
  try
    for d:=1 to i do begin
      f.read(r,sizeof(r));
      f.seek(r.textpos+r.textsize,0);
    end;
  except
    exit;
  end;
  rec:=r;
  result:=true;
end;}

function tswagfile.gotorec(i:integer):boolean;
var
  r:tswagrec;
  d:integer;
begin 
  result:=false;
  if i>header.totalrec then exit;
  
  f.seek(sizeof(header),0);
  d:=0;
  try
    while f.position < f.size do begin
      f.read(r,sizeof(r));
      if r.deleted=false then d:=d+1;
      f.seek(r.textpos+r.textsize,0);
      if d=i then break;
    end;
  except
    exit;
  end;
  rec:=r;
  result:=true;
end;

function tswagfile.delete(i:integer):boolean;
begin
  result:=false;
  if i>header.totalrec then exit;
  
  if gotorec(i)=false then exit;
  rec.deleted:=true;
  f.seek(rec.textpos-sizeof(rec),0);
  f.write(rec,sizeof(rec));
  
  dec(header.totalrec);
  writeheader;
  result:=true;
end;

function tswagfile.delete(crc:string):boolean; overload;
begin
  result:=iscrc(crc);
  if result then begin
    rec.deleted:=true;
    f.seek(rec.textpos-sizeof(rec),0);
    f.write(rec,sizeof(rec));
    dec(header.totalrec);
    writeheader;
  end;
end;

function tswagfile.appendrec(r:tswagrec; fl:string):boolean;
var
  rf  : tfilestream;
  buf : byte;
  rd  : tswagrec;
  zf  : string;
begin
  result:=false;
  try
    rd:=r;
    zf:=fl+'.zz';
    
    result:=rawzipstream(fl,zf);
    
    rf:=tfilestream.create(zf,fmopenread+fmShareDenyNone);
    rf.seek(0,0);
    rd.textsize:=rf.size;
    rd.filename:=extractfilename(fl);
    
    f.seek(f.size,0);
    rd.textpos:=f.position+sizeof(rd);
    f.write(rd,sizeof(rd));
    
    while rf.position<rf.size do begin
      rf.read(buf,1);
      f.write(buf,1);
    end;
    rf.free;
    header.totalrec:=header.totalrec+1;
    writeheader;
  except
    result:=false;
    exit;
  end;
  deletefile(zf);
end;

procedure createswagfile(fn:string; var header:tswagheader);
var
  f:tfilestream;  
begin 
  f:=tfilestream.create(fn, fmcreate);
  header.sign:='SWGEX01';
  f.write(header,sizeof(header));
  f.free;
end;

procedure tswagfile.writeheader;
begin
  f.seek(0,0);
  f.write(header,sizeof(header));
end;

procedure tswagfile.initnext;
begin
  f.seek(sizeof(header),0);
end;

function tswagfile.updaterec(r:tswagrec; i:integer):boolean;
begin
  result:=false;
  if not gotorec(i) then exit;
  f.seek(rec.textpos-sizeof(rec),0);
  f.write(r,sizeof(r));
  result:=true;
end;

function tswagfile.extracttext(r:tswagrec; fn:string):boolean;
var
  ft:tfilestream;  
  buf:byte;
  d:integer;
begin 
  result:=true;
  try
    ft:=tfilestream.create(fn+'.z', fmCreate);
    
    f.seek(rec.textpos,0);
    for d:=1 to rec.textsize do begin
      f.read(buf,1);
      ft.write(buf,1);
    end;
    
    ft.free;
    
    result:=rawunzipStream(fn+'.z',fn);
    deletefile(fn+'.z');
    
  except
    result:=false;
  end;
end;

function tswagfile.iscrc(crc:string):boolean;
begin
  result:=false;
  f.seek(sizeof(header),0);
  while f.position < f.size do begin
    f.read(rec,sizeof(rec));
    if rec.deleted=false then 
      if rec.crc=crc then begin
        result:=true;
        break;
      end;  
    f.seek(rec.textpos+rec.textsize,0);
  end;
end;

function tswagfile.copyrecfrom(var w:tswagfile; var arec:tswagrec):boolean;
begin
  try
    result:=false;
    f.seek(f.size,0);
    f.write(arec,sizeof(arec));
    w.f.seek(arec.textpos,0);
    f.copyfrom(w.f,arec.textsize); 
  except
   result:=false;
  end;
  result:=true;
end;

function tswagfile.importfrom(s:string):boolean;
var
  w:tfilestream;
  buf:byte;
  wh:tswagheader;
  wr:tswagrec;
  i:longint;
begin
  result:=false;
  
  if not fileexist(s) then exit;
  if not isswagfile(s) then exit;
  
  w:=tfilestream.create(s,fmopenread+fmShareDenyNone);
  w.read(wh,sizeof(wh));
  f.seek(f.size,0);
  while w.position < w.size do begin
    w.read(wr,sizeof(wr));
    if wr.deleted=false then begin
      wr.textpos:=f.position+sizeof(wr);
      f.write(wr,sizeof(wr));
      for i:=1 to wr.textsize do begin
        w.read(buf,1);
        f.write(buf,1);
      end;
      inc(header.totalrec);
    end else 
      w.seek(wr.textpos+wr.textsize,0);
  end;
  f.seek(0,0);
  f.write(header,sizeof(header));
  w.free;
  result:=true;
end;

function isswagfile(fn:string):boolean;
var
  g:tswagfile;
begin
  result:=false;
  if not fileexist(fn) then exit;
  g:=tswagfile.create(fn,fmopenread+fmShareDenyNone);
  result:=g.open;
  g.destroy;
end;

end.
