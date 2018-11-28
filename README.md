# snippet
<code>

                 ____  _      _  ____  ____  _____ _____ 
                / ___\/ \  /|/ \/  __\/  __\/  __//__ __\
                |    \| |\ ||| ||  \/||  \/||  \    / \  
                \___ || | \||| ||  __/|  __/|  /_   | |  
                \____/\_/  \|\_/\_/   \_/   \____\  \_/  v1.0

=---------------------------------------------------------------------------=

  ] DISCLAIMER [

   The author has taken every precaution to insure that no harm or damage
will occur on computer systems operating this util.  Never the less, the
author will NOT be held liable for whatever may happen on your computer
system or to any computer systems which connects to your own as a result of
operating this util.  The user assumes full responsibility for the correct
operation of this software package, whether harm or damage results from
software error, hardware malfunction, or operator error.  NO warranties are
offered, expressly stated or implied, including without limitation or
restriction any warranties of operation for a particular purpose and/or
merchant ability.  If you do not agree with this then do NOT use this
program.


  ] WHAT IT IS [

  Do you remember the SWAG project? Make a search for it in internet as "swag
pascal" and you will find some version of it online. At best, you could
locate the files at a BBS and download the original DOS version of it.

  The SWAG project was a very cool collection of source code for the old good
Turbo Pascal. The group collected useful code and packed it inside a
compressed binary file. The package also included a nice reader to view the
files. This way, someone in the 80's - 90's could find code for pascal, by
downloading update packages from BBSes or get the files  from Disks included
in Magazines related to computers and home computing in general.

  At that time the Internet was hard to get and users had to find a way to
exchange code. So the SWAG project was a very cool idea to implement and
cover that need.

  So Snippet, is a rewrite of the old SWAG Reader program. It does the same
thing with a similar look, but unfortunately can't read the old library
files, as the format wasn't open source and used some type of compression,
which the code/format of it, never released. You can read the old .SWG files
only with the original reader.

  Snippet uses its own format of files/libraries and also compressed the
text, with a gzip compression. Snippet is Open Source and the code can be
found at: https://github.com/xqtr/snippet



  ] FEATURES [

  * Import any type of text file, even ANSI graphics
  * Export the articles/records text
  * Create as many libraries you want
  * Compress of data to reduce size
  * Search TEXT in all files/libraries
  * Use it as a DOOR program under Linux machines for use in BBSes
    - Sysops can edit/alter libraries and/or articles online
    - Users can download the text of an article they want


  ] DOOR [

  As mentioned, you can use Snippet as a DOOR program under Linux Machines.
To do that use it like this:

  ./snippet <dropfile_filename>

  <dropfile_filename> is the full filename (with path) to one of these
dropfile formats:
                  DOOR.SYS
                  DOOR32.SYS

  To allow users to download files, edit the snippet.ini file and complete
the dowload_command key, with the appropriate program to use, for initiating
downloads in a BBS. I suggest SEXYZ, which is one of the best tools for the
job.

  Sysops must edit the snippet.ini file and include their userid, at the
[USERS] stanza of the .ini file. The format is:
  <username> = <ACS Level>

  For example in my BBS, which i am a sysop, i add this key:
  xqtr = 255

  At this time, only one ACS Level is used and its 255, which means that the
user is a sysop and has full access. In the future, other levels will be
added, to allow users with restricted access ex: only insert records, but not
delete.
</code>
<code>

   _            _   _              ___          _    _       
  /_\  _ _  ___| |_| |_  ___ _ _  |   \ _ _ ___(_)__| |               8888
 / _ \| ' \/ _ \  _| ' \/ -_) '_| | |) | '_/ _ \ / _` |            8 888888 8
/_/ \_\_||_\___/\__|_||_\___|_|   |___/|_| \___/_\__,_|            8888888888
                                                                   8888888888
         DoNt Be aNoTHeR DrOiD fOR tHe SySteM                      88 8888 88
                                                                   8888888888
    .o HaM RaDiO    .o ANSi ARt!       .o MySTiC MoDS              "88||||88"
    .o NeWS         .o WeATheR         .o FiLEs                     ""8888""
    .o GaMeS        .o TeXtFiLeS       .o PrEPardNeSS                  88
    .o TuTors       .o bOOkS/PdFs      .o SuRVaViLiSM          8 8 88888888888
    .o FsxNet       .o SurvNet         .o More...            888 8888][][][888
                                                               8 888888##88888
   TeLNeT : andr01d.zapto.org:9999 [UTC 11:00 - 20:00]         8 8888.####.888
   SySoP  : xqtr                   eMAiL: xqtr@gmx.com         8 8888##88##888
   PaYPaL : paypal.me/xqtr

</code>
