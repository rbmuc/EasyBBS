/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : by schema mapper V. 2.1 - 28.02.14
// file      : mapping.pas
// created   : 28.02.14
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0
//             04.05.2014 Update Commit for Laz. 1.2.2
//             08.05.2014 blob save as hexstr
// tested    : yes

unit Mapping;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, FmtBCD, mysql55conn, sqldb, blowcryp ;

const
   sqlDate = 'yyyy-mm-dd hh:nn:ss';


type
  ForInfType = record              // forums record
   id: string;
   fName: string;
   fDesc: string;
   fdesc_bitfield: string;
   fdesc_uid: string;
   topics_per_page: string;
   posts: string;
   topics: string;
   topics_real: string;
   last_post_id: string;
   last_poster_id: string;
   last_post_subject: string;
   last_post_time : string;
   last_poster_name: string;
   end;

  TopInfType = record               // topics record
   id : string;
   forum_id : string;
   title : string;
   topic_text : string;
   poster : string;
   poster_name : string;
   ctime : string;
   time_limit : string;
   views : string;
   replies : string;
   replies_real : string;
   first_post_id : string;
   first_poster_name : string;
   last_post_id : string;
   last_poster_id : string;
   last_poster_name  : string;
   last_post_subject : string;
   last_post_time : string;
   last_view_time : string;
   end;


  PstInfType = record                 // posts record
   id : string;
   topic_id : string;
   forum_id : string;
   user_id : string;
   poster_ip : string;
   post_time : string;
   post_subject : string;
   post_text: string;
   post_postcount: string;
   post_alpha : string;
   post_size  : string;
   post_edit_time : string;
   post_edit_reason: string;
   post_edit_user : string;
   post_edit_count : string;
   post_edit_locked : string;
   end;

  usrInfType = record                  // user record
   iduser : string;
   Name : string;
   pwd : string;
   LastTime : string;
   TotalTime : string;
   MailAdress : string;
   CreateIP : string;
   CreateTime : string;
   RegisterIP : string;
   RegisterTime : string;
   isChecked : string;
   isVisible : string;
   picture_png : string;
   end;


  jobType = record                      // job server record
   idjobs : string ;
   inquirer : string ;
   inqIP : string ;
   inqTime : string ;
   idUser : string ;
   Action : string ;
   Intervall : string ;
   Result : string ;
   Status : string ;
   StatusMsg : string ;
   context : String;
   end;


   procedure cpyForumInfo( CONST qry:TSQLQuery; VAR memFrm:ForInfType   );
   procedure cpyTopicInfo( CONST qry:TSQLQuery; VAR memFrm:TopInfType   );
   procedure cpyPostInfo ( CONST qry:TSQLQuery; VAR PstFrm:PstInfType   );
   procedure cpyUsrInfo  ( CONST qry:TSQLQuery; VAR usrFrm:usrInfType   );
   procedure cpySessInfo ( CONST qry:TSQLQuery; VAR SessFrm:sessInfType );
   procedure cpyJobInfo  ( CONST qry:TSQLQuery; VAR myJob:jobType );

   function  job_insert  ( CONST conn: TMySQL55Connection; CONST myJob:JobType ): String;

   procedure ReadUsr     ( CONST conn: TMySQL55Connection; CONST sUsr:string; VAR usrFrm:usrInfType );
   function  User_insert ( CONST conn: TMySQL55Connection; CONST usrFrm:usrInfType ): String;
   function  updUser     ( CONST conn: TMySQL55Connection; CONST usrFrm:usrInfType ): String;
   function count_usr_themes( CONST conn: TMySQL55Connection; CONST usrRec: usrInfType ): String;
   function count_usr_posts( CONST conn: TMySQL55Connection; CONST usrRec: usrInfType ): String;

   Function  Upd_Forum   ( CONST conn: TMySQL55Connection; CONST memFrm:ForInfType ): STRING ;
   procedure ReadForum   ( CONST conn: TMySQL55Connection; CONST idFrm:string; VAR usrFrm:ForInfType );

   procedure sesn_Read   ( CONST conn: TMySQL55Connection; VAR sesnRec: sessInfType );
   function  sesn_count  ( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
   function  sesn_close  ( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
   function  sesn_insert ( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
   function  sesn_update ( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;

   procedure Topic_Read  ( CONST conn: TMySQL55Connection; VAR memFrm: TopInfType );
   Function  Topic_Update( CONST conn: TMySQL55Connection; CONST memTpc: TopInfType ): STRING ;
   function  topic_insert( CONST conn: TMySQL55Connection; CONST memFrm:TopInfType ): String;

   Function  posts_Update( CONST conn: TMySQL55Connection; CONST memFrm: PstInfType ): STRING ;
   function  posts_insert( CONST conn: TMySQL55Connection; CONST memFrm: PstInfType ): String;
   Function  posts_Delete( CONST conn: TMySQL55Connection; CONST id:String ): STRING ;
   procedure posts_read  ( CONST conn: TMySQL55Connection; VAR memFrm:PstInfType );
   Function  posts_Count ( CONST conn: TMySQL55Connection; CONST dStart: String ): STRING ;

   Function  GetContent  (CONST conn: TMySQL55Connection; CONST sSearch:String ): STRING ;
   Function  GetSetting  (CONST conn : TMySQL55Connection; CONST inStrg: string): string;

implementation


Function GetSetting(CONST conn : TMySQL55Connection; CONST inStrg: string): string;
VAR
   query : TSQLQuery;

begin

  // query
  query := TSQLQuery.Create(nil);
  query.DataBase :=  conn;
  query.SQL.Text := 'select * from dbpara where qName="' + TRIM( inStrg ) + '"';
  query.Open;

  if query.EOF then
     begin
        query.active := false;
        query.free;
        exit;
     end;

  if query.Fields[5].AsInteger <> 0 then
    GetSetting := decrypt( query.Fields[4].AsString )
   else
    GetSetting := query.Fields[4].AsString;

  query.active := false;
  query.free;

end;

//////////////////////////////////////////////////////////
// sample calls :  GetContent(conn, 'bad_de' ): string;
//    	           GetContent(conn, 'bad_en' ): string;

Function  GetContent( CONST conn: TMySQL55Connection; CONST sSearch:String ): STRING ;
VAR
   query : TSQLQuery;

begin
  GetContent := 'none';
  // query
  query := TSQLQuery.Create(nil);
  query.DataBase :=  conn;
  query.SQL.Text := 'select * from contval where cName="' + TRIM( sSearch ) + '"';
  query.Open;

  if query.EOF then
     begin
       query.active := false;
       query.Free;
       exit;
     end;

  if query.Fields[5].AsInteger <> 0 then
     GetContent := decrypt( query.FieldByName('cValue').AsString )
   else
     GetContent := query.FieldByName('cValue').AsString ;

  query.active := false;
  query.Free;

end;

procedure cpyJobInfo ( CONST qry:TSQLQuery; VAR myJob:jobType );
begin
  myJob.idjobs    := qry.FieldByName('idjobs').AsString;
  myJob.inquirer  := qry.FieldByName('inquirer').AsString;
  myJob.inqIP     := qry.FieldByName('inqIP').AsString;
  myJob.inqTime   := qry.FieldByName('inqTime').AsString;
  myJob.idUser    := qry.FieldByName('idUser').AsString;
  myJob.Action    := qry.FieldByName('Action').AsString;
  myJob.Intervall := qry.FieldByName('Intervall').AsString;
  myJob.Result    := qry.FieldByName('Result').AsString;
  myJob.Status    := qry.FieldByName('Status').AsString;
  myJob.StatusMsg := qry.FieldByName('StatusMsg').AsString;
  myJob.context   := qry.FieldByName('context').AsString;
end;

procedure cpyUsrInfo ( CONST qry:TSQLQuery; VAR usrFrm:usrInfType );
begin
  usrFrm.iduser           := qry.FieldByName('iduser').AsString;
  usrFrm.Name             := qry.FieldByName('Name').AsString;
  usrFrm.pwd              := decrypt( qry.FieldByName('pwd').AsString );
  usrFrm.LastTime         := qry.FieldByName('LastTime').AsString;
  usrFrm.TotalTime        := qry.FieldByName('TotalTime').AsString;
  usrFrm.MailAdress       := qry.FieldByName('MailAdress').AsString;
  usrFrm.CreateIP         := qry.FieldByName('CreateIP').AsString;
  usrFrm.CreateTime       := qry.FieldByName('CreateTime').AsString;
  usrFrm.RegisterIP       := qry.FieldByName('RegisterIP').AsString;
  usrFrm.RegisterTime     := qry.FieldByName('RegisterTime').AsString;
  usrFrm.isChecked        := qry.FieldByName('isChecked').AsString;
  usrFrm.isVisible        := qry.FieldByName('isVisible').AsString;
  usrFrm.picture_png      := qry.FieldByName('picture_png').AsString;

end;

procedure cpyPostInfo( CONST qry:TSQLQuery; VAR PstFrm:PstInfType );
begin
  PstFrm.id               := qry.FieldByName('id').AsString;
  PstFrm.topic_id         := qry.FieldByName('topic_id').AsString;
  PstFrm.forum_id         := qry.FieldByName('forum_id').AsString;
  PstFrm.user_id          := qry.FieldByName('user_id').AsString;
  PstFrm.poster_ip        := qry.FieldByName('poster_ip').AsString;
  PstFrm.post_time        := qry.FieldByName('post_time').AsString;
  PstFrm.post_subject     := qry.FieldByName('post_subject').AsString;
  PstFrm.post_text        := qry.FieldByName('post_text').AsString;
  PstFrm.post_postcount   := qry.FieldByName('post_postcount').AsString;
  PstFrm.post_alpha       := qry.FieldByName('post_alpha').AsString;
  PstFrm.post_size        := qry.FieldByName('post_size').AsString;
  PstFrm.post_edit_time   := qry.FieldByName('post_edit_time').AsString;
  PstFrm.post_edit_reason := qry.FieldByName('post_edit_reason').AsString;
  PstFrm.post_edit_user   := qry.FieldByName('post_edit_user').AsString;
  PstFrm.post_edit_count  := qry.FieldByName('post_edit_count').AsString;
  PstFrm.post_edit_locked := qry.FieldByName('post_edit_locked').AsString;
end;


procedure cpyTopicInfo( CONST qry:TSQLQuery; VAR memFrm:TopInfType );
begin
  memFrm.id                := qry.FieldByName('id').AsString;
  memFrm.forum_id          := qry.FieldByName('forum_id').AsString;
  memFrm.title             := qry.FieldByName('title').AsString;
  memFrm.topic_text        := qry.FieldByName('topic_text').AsString;
  memFrm.poster            := qry.FieldByName('poster').AsString;
  memFrm.poster_name       := qry.FieldByName('poster_name').AsString;
  memFrm.ctime             := qry.FieldByName('ctime').AsString;
  memFrm.time_limit        := qry.FieldByName('time_limit').AsString;
  memFrm.views             := qry.FieldByName('views').AsString;
  memFrm.replies           := qry.FieldByName('replies').AsString;
  memFrm.replies_real      := qry.FieldByName('replies_real').AsString;
  memFrm.first_post_id     := qry.FieldByName('first_post_id').AsString;
  memFrm.first_poster_name := qry.FieldByName('first_poster_name').AsString;
  memFrm.last_post_id      := qry.FieldByName('last_post_id').AsString;
  memFrm.last_poster_id    := qry.FieldByName('last_poster_id').AsString;
  memFrm.last_poster_name  := qry.FieldByName('last_poster_name').AsString;
  memFrm.last_post_subject := qry.FieldByName('last_post_subject').AsString;
  memFrm.last_post_time    := qry.FieldByName('last_post_time').AsString;
  memFrm.last_view_time    := qry.FieldByName('last_view_time').AsString;
end;


procedure cpyForumInfo( CONST qry:TSQLQuery; VAR memFrm:ForInfType );
begin
  memFrm.id                := qry.FieldByName('id').AsString;
  memFrm.fName             := qry.FieldByName('fname').AsString;
  memFrm.fDesc             := qry.FieldByName('fdesc').AsString;
  memFrm.fdesc_bitfield    := qry.FieldByName('fdesc_bitfield').AsString;
  memFrm.fdesc_uid         := qry.FieldByName('fdesc_uid').AsString;
  memFrm.topics_per_page   := qry.FieldByName('topics_per_page').AsString;
  memFrm.posts             := qry.FieldByName('posts').AsString;
  memFrm.topics            := qry.FieldByName('topics').AsString;
  memFrm.topics_real       := qry.FieldByName('topics_real').AsString;
  memFrm.last_post_id      := qry.FieldByName('last_post_id').AsString;
  memFrm.last_poster_id    := qry.FieldByName('last_poster_id').AsString;
  memFrm.last_post_subject := qry.FieldByName('last_post_subject').AsString;
  memFrm.last_post_time    := qry.FieldByName('last_post_time').AsString;
  memFrm.last_poster_name  := qry.FieldByName('last_poster_name').AsString;
end;


procedure cpySessInfo ( CONST qry:TSQLQuery; VAR SessFrm:sessInfType );
begin
  SessFrm.rid           := qry.FieldByName('rid').AsString;
  SessFrm.id            := qry.FieldByName('id').AsString;
  SessFrm.user_id       := qry.FieldByName('user_id').AsString;
  SessFrm.forum_id      := qry.FieldByName('forum_id').AsString;
  SessFrm.is_active     := qry.FieldByName('is_active').AsString;
  SessFrm.last_forum    := qry.FieldByName('last_forum').AsString;
  SessFrm.browser       := qry.FieldByName('browser').AsString;
  SessFrm.sip           := qry.FieldByName('sip').AsString;
  SessFrm.sLat          := qry.FieldByName('sLat').AsString;
  SessFrm.sLong         := qry.FieldByName('sLong').AsString;
  SessFrm.latitude      := qry.FieldByName('latitude').AsString;
  SessFrm.longitude     := qry.FieldByName('longitude').AsString;
  SessFrm.accuracy      := qry.FieldByName('accuracy').AsString;
  SessFrm.forwarded_for := qry.FieldByName('forwarded_for').AsString;
  SessFrm.v_order       := qry.FieldByName('v_order').AsString;
  SessFrm.v_page        := qry.FieldByName('v_page').AsString;
  SessFrm.v_rec         := qry.FieldByName('v_rec').AsString;
  SessFrm.v_eof         := qry.FieldByName('v_eof').AsString;
  SessFrm.viewonline    := qry.FieldByName('viewonline').AsString;
  SessFrm.autologin     := qry.FieldByName('autologin').AsString;
  SessFrm.admin         := qry.FieldByName('admin').AsString;
  SessFrm.lastsearch    := qry.FieldByName('lastsearch').AsString;
  SessFrm.lastlogin     := qry.FieldByName('lastlogin').AsString;
  SessFrm.last_post_cnt := qry.FieldByName('last_post_cnt').AsString;
  SessFrm.login         := qry.FieldByName('login').AsString;
  SessFrm.logout        := qry.FieldByName('logout').AsString;
end;

procedure ReadForum(CONST conn:TMySQL55Connection; CONST idFrm:string; VAR usrFrm:ForInfType );
VAR
  query2 : TSQLQuery;

begin
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'select * from forums ' + idFrm ;
  query2.Open;

  if not query2.eof then cpyForumInfo( query2, usrFrm );
  query2.active := false;
  query2.Free;


end;

procedure ReadUsr(CONST conn:TMySQL55Connection; CONST sUsr:string; VAR usrFrm:usrInfType );
VAR
  query2 : TSQLQuery;

begin
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'select * from user ' + sUsr ;
  query2.Open;

  if not query2.eof then
     cpyUsrInfo( query2, usrFrm )
    else
     usrFrm.iduser:= '';

  query2.active := false;
  query2.Free;


end;

Function Upd_Forum( CONST conn: TMySQL55Connection; CONST memFrm: ForInfType ): STRING ;
VAR
  query2 : TSQLQuery;
  sQry   : STRING;

begin
  sQry := 'UPDATE forums SET fname = "%%1", fdesc = "%%2", fdesc_bitfield = "%%3", fdesc_uid = %%4, topics_per_page = %%5, posts = %%6, '+
          'topics = %%7, topics_real = %%8, last_post_id = %%9, last_poster_id = %%A, last_post_subject = "%%B", last_post_time = now(), last_poster_name = "%%C" ' +
          'WHERE id = %%D;';

  sQry := sUpdate( sQry, '%%1', memFrm.fName );
  sQry := sUpdate( sQry, '%%2', memFrm.fDesc );
  sQry := sUpdate( sQry, '%%3', memFrm.fdesc_bitfield );
  sQry := sUpdate( sQry, '%%4', memFrm.fdesc_uid );
  sQry := sUpdate( sQry, '%%5', memFrm.topics_per_page );
  sQry := sUpdate( sQry, '%%6', memFrm.posts );
  sQry := sUpdate( sQry, '%%7', memFrm.topics );
  sQry := sUpdate( sQry, '%%8', memFrm.topics_real );
  sQry := sUpdate( sQry, '%%9', memFrm.last_post_id );
  sQry := sUpdate( sQry, '%%A', memFrm.last_poster_id );
  sQry := sUpdate( sQry, '%%B', memFrm.last_post_subject );
  sQry := sUpdate( sQry, '%%C', memFrm.last_poster_name );
  sQry := sUpdate( sQry, '%%D', memFrm.ID);

  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := sQry;
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do Upd_Forum := e.Message +  query2.SQL.Text;
  end;

  query2.active := False;
  query2.Free;

end;


function updUser( CONST conn: TMySQL55Connection; CONST usrFrm:usrInfType ): String;
VAR
  query2 : TSQLQuery;
  sQry, d1, d2, d3 : STRING;

begin

  // normalize datetime
  d1 := usrFrm.LastTime;
  d2 := usrFrm.CreateTime;
  d3 := usrFrm.RegisterTime;
  if d1 = '' then d1 := DateTimeToStr (now) ;
  if d2 = '' then d2 := d1;
  if d3 = '' then d3 := d1;
  d1 := FormatDateTime(sqlDate, StrToDateTime(d1));
  d2 := FormatDateTime(sqlDate, StrToDateTime(d2));
  d3 := FormatDateTime(sqlDate, StrToDateTime(d3));

  // build query
  sQry := 'UPDATE user SET Name = "%%1", pwd = "%%2", LastTime= "%%3", TotalTime=%%4, MailAdress="%%5", CreateIP="%%6", CreateTime="%%7", ' +
          'RegisterIP="%%8", RegisterTime="%%9", isChecked="%%A", isVisible="%%B"';
  if usrFrm.picture_png <> '' then sQry += ', picture_png=x''%%C'' ';
  sQry += ' WHERE iduser= %%D';


  sQry := sUpdate( sQry, '%%1', usrFrm.Name );
  sQry := sUpdate( sQry, '%%2', encrypt(usrFrm.pwd) );
  sQry := sUpdate( sQry, '%%3', d1 );
  sQry := sUpdate( sQry, '%%4', usrFrm.TotalTime );
  sQry := sUpdate( sQry, '%%5', usrFrm.MailAdress );
  sQry := sUpdate( sQry, '%%6', usrFrm.CreateIP );
  sQry := sUpdate( sQry, '%%7', d2 );
  sQry := sUpdate( sQry, '%%8', usrFrm.RegisterIP );
  sQry := sUpdate( sQry, '%%9', d3 );
  sQry := sUpdate( sQry, '%%A', usrFrm.isChecked );
  sQry := sUpdate( sQry, '%%B', usrFrm.isVisible );
  if usrFrm.picture_png <> '' then
     sQry:=sUpdate(sQry, '%%C', usrFrm.picture_png );
  sQry := sUpdate( sQry, '%%D', usrFrm.iduser );

  // write to db
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := sQry;
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do updUser := e.Message + CHR(13) + sQry;
  end;

  query2.active := False;
  query2.Free;

end;



function posts_insert( CONST conn: TMySQL55Connection; CONST memFrm: PstInfType ): String;
VAR
  i: integer;
  sTmp : string;
  query2 : TSQLQuery;

begin
  posts_insert := '';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'INSERT INTO posts ( topic_id, forum_id, user_id, poster_ip, post_subject, post_text, post_alpha, post_size )' +
                     'VALUES ( ' + memFrm.topic_id + ', ' + memFrm.forum_id + ', ' + memFrm.user_id + ', "' +
                     memFrm.poster_ip + '", "' + memFrm.post_subject + '", x' + #39 + StrToHex(memfrm.post_text) + #39 + ', "' +
                     memfrm.post_alpha + '", ' + memfrm.post_size +');';
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do posts_insert := 'posts_insert ' + e.Message + '--' + query2.SQL.Text;
  end;

  query2.active := False;
  query2.Free;
end;

function User_insert( CONST conn: TMySQL55Connection; CONST usrFrm:usrInfType ): String;
VAR
  query2 : TSQLQuery;

begin
  User_insert := '' ;
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  Query2.SQL.Text := 'INSERT INTO user (Name, pwd, LastTime, TotalTime, MailAdress, CreateIP, CreateTime ) VALUES ("' +
                      usrFrm.Name + '", "' + usrFrm.pwd + '", now(), 0, "' + usrFrm.MailAdress + '", "' + usrFrm.RegisterIP + '", now() )';
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do User_insert := 'User_insert ' + e.Message;
  end;

  query2.active := False;
  query2.Free;

end;

function topic_insert( CONST conn: TMySQL55Connection; CONST memFrm: TopInfType ): String;
VAR
  query2 : TSQLQuery;

begin
  topic_insert := '';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'INSERT INTO topics ( forum_id, title, topic_text, poster, poster_name, ctime ) ' +
                     'VALUES ( ' + memFrm.forum_id + ', "' + memFrm.title + '", x' + #39 + StrToHex(memFrm.topic_text) + #39 + ', ' +
                     memFrm.poster + ', "' + memFrm.poster_name + '", now() );';

  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do topic_insert := 'topic_insert ' + e.Message;
  end;

  query2.active := False;
  query2.Free;

end;


/////////////////////////////////////////////////
// called on new session by sesn_insert
// called on expired session by isSessionValid

function sesn_close( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
VAR
  query2 : TSQLQuery;
  sQry   : STRING;

begin

  sQry := 'UPDATE sessions ' +
          'SET is_active="0", logout="' + FormatDateTime(sqlDate, now()) + '" ' +
          'WHERE user_id="' + sesnRec.user_id + '";' ;
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := sQry;
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do sesn_close := 'sesn_close ' +  e.Message;
  end;

  query2.active := False;
  query2.Free;
end;

function count_usr_posts( CONST conn: TMySQL55Connection; CONST usrRec: usrInfType ): String;
VAR
  query2 : TSQLQuery;
  sQry   : STRING;

begin
  count_usr_posts := '0';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'select count(*) from posts where user_id=' + usrRec.iduser ;
  query2.Open;

  if not query2.eof then count_usr_posts := query2.Fields[0].AsString;
  query2.active := False;
  query2.Free;

end;

function count_usr_themes( CONST conn: TMySQL55Connection; CONST usrRec: usrInfType ): String;
VAR
  query2 : TSQLQuery;
  sQry   : STRING;

begin
  count_usr_themes := '0';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'select count(*) from topics where poster=' + usrRec.iduser ;
  query2.Open;

  if not query2.eof then count_usr_themes := query2.Fields[0].AsString;
  query2.active := False;
  query2.Free;

end;


function sesn_count( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
VAR
  query2 : TSQLQuery;
  sQry   : STRING;

begin
  sesn_count := '0';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'select count(*) from sessions where is_active ="1";';
  query2.Open;

  if not query2.eof then sesn_count := query2.Fields[0].AsString;
  query2.active := False;
  query2.Free;

end;




function sesn_insert( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
VAR
  query2 : TSQLQuery;
  s1,s2,s3,s4, s5 : String;

begin
  // normalize paras - avoid blank
  s1 := iif( sesnRec.last_forum ='', '0', sesnRec.last_forum );
  s2 := iif( sesnRec.latitude   ='', '0', sesnRec.latitude);
  s3 := iif( sesnRec.longitude  ='', '0', sesnRec.longitude );
  s4 := iif( sesnRec.accuracy   ='', '0', sesnRec.accuracy );
  s5 := iif( sesnRec.lastlogin  ='',
             FormatDateTime(sqlDate, now()),
             FormatDateTime(sqlDate, StrToDateTime(sesnRec.lastlogin)));

  // close all open sessions for user_id
  sesn_close( conn, sesnRec );

  sesn_insert := '';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'INSERT INTO sessions ( id, user_id, forum_id, is_active, last_forum, browser, sip, sLat, sLong, latitude, longitude, ' +
                     'accuracy, v_order, v_page, v_rec, v_eof, lastlogin, last_post_cnt ) ' +
                     'VALUES ( "' + sesnRec.id + '", ' + sesnRec.user_id + ' ,' + sesnRec.forum_id + ' ,"' + sesnRec.is_active + '", ' +
                     s1 + ', "' + sesnRec.browser + '", "' + sesnRec.sip + '", ' + sesnRec.sLat + ', ' + sesnRec.sLong + ' ,' +
                     s2 + ', ' + s3 + ', ' + s4 + ', ' + sesnRec.v_order + ', ' + sesnRec.v_page + ', ' + sesnRec.v_rec + ', ' +
                     sesnRec.v_eof + ', "' + s5 + '", ' + sesnRec.last_post_cnt + ');';
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do sesn_insert := 'sesn_insert ' + e.Message;
  end;

  query2.active := False;
  query2.Free;

end;


function job_insert( CONST conn: TMySQL55Connection; CONST myJob:JobType ): String;
VAR
  query2 : TSQLQuery;

begin
  job_insert := '';
  query2     := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'INSERT INTO jobs ( inquirer, inqIP, inqTime, idUser, Action, Intervall, context ) VALUES ("' +
                      myJob.inquirer + '", "' + myJob.inqIP + '", now(), ' + myJob.iduser +', "' + myJob.Action +'", ' +
                      myJob.Intervall +  ', "' + myJob.context + '" )';
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do job_insert := 'job_insert ' + e.Message;
  end;

  query2.active := False;
  query2.Free;

end;


function sesn_update ( CONST conn: TMySQL55Connection; CONST sesnRec: sessInfType ): String;
VAR
  query2 : TSQLQuery;
  sQry   : STRING;

begin
  sesn_update := '';
  sQry := 'UPDATE sessions SET is_active=%%1, forum_id=%%2, last_forum=%%3, forwarded_for="%%4", v_order=%%5, v_page=%%6, v_rec=%%7, v_eof=%%8, lastsearch="%%9" WHERE id="' + sesnRec.id + '";' ;
  sQry := sUpdate( sQry, '%%1', sesnRec.is_active );
  sQry := sUpdate( sQry, '%%2', sesnRec.forum_id );
  sQry := sUpdate( sQry, '%%3', sesnRec.last_forum );
  sQry := sUpdate( sQry, '%%4', sesnRec.forwarded_for );
  sQry := sUpdate( sQry, '%%5', sesnRec.v_order);
  sQry := sUpdate( sQry, '%%6', sesnRec.v_page );
  sQry := sUpdate( sQry, '%%7', sesnRec.v_rec );
  sQry := sUpdate( sQry, '%%8', sesnRec.v_eof );
  sQry := sUpdate( sQry, '%%9', sesnRec.lastsearch );
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := sQry;
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do sesn_update := query2.SQL.Text  + ' -- sesn_update --' +  e.Message;
  end;

  query2.active := False;
  query2.Free;

end;


procedure sesn_Read(CONST conn:TMySQL55Connection; VAR sesnRec: sessInfType );
VAR
  query2 : TSQLQuery;

begin
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'SELECT * FROM sessions WHERE id="' + sesnRec.id + '";';
  query2.Open;

  if not query2.eof then  cpySessInfo ( query2, sesnRec );
  query2.active := false;
  query2.Free;

end;

procedure posts_read( CONST conn: TMySQL55Connection; VAR memFrm:PstInfType );
VAR
  query2 : TSQLQuery;

begin
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'SELECT * FROM posts WHERE id="' + memFrm.id + '";';
  query2.Open;

  if not query2.eof then
     cpyPostInfo( Query2, memFrm )
   else
     memFrm.id := '';

  query2.active := false;
  query2.Free;

end;


Function posts_Delete( CONST conn: TMySQL55Connection; CONST id:String ): STRING ;
VAR
  query2 : TSQLQuery;

begin
  posts_Delete := '';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'DELETE FROM posts WHERE id=' + id + ';';
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do posts_Delete := e.Message +  query2.SQL.Text;
  end;

  query2.active := False;
  query2.Free;

end;


Function posts_Count( CONST conn: TMySQL55Connection; CONST dStart: String ): STRING ;
VAR
  query2 : TSQLQuery;

begin
  posts_Count := '0';
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'select count(*) from posts where post_time > "'+
                     FormatDateTime(sqlDate, StrToDateTime(dStart)) + '";';
  query2.Open;

  if not query2.eof then posts_Count := query2.Fields[0].AsString;
  query2.active := False;
  query2.Free;

end;

procedure Topic_Read(CONST conn:TMySQL55Connection; VAR memFrm: TopInfType );
VAR
  query2 : TSQLQuery;

begin

  if memFrm.id = '' then exit;
  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := 'SELECT * FROM topics where id=' +  memFrm.id ;
  query2.Open;

  if not query2.eof then
     cpyTopicInfo( Query2, memFrm )
   else
     memFrm.id := '';

  query2.active := false;
  query2.Free;

end;


Function posts_Update( CONST conn: TMySQL55Connection; CONST memFrm: PstInfType ): STRING ;
VAR
  query2 : TSQLQuery;
  d1, d2, sQry: STRING;

begin

  posts_Update := '';
  // normalize datetime
  d1 := memFrm.post_time;
  d2 := memFrm.post_edit_time;
  if d1 = '' then d1 := DateTimeToStr (now) ;
  if d2 = '' then d2 := d1;
  d1 := FormatDateTime(sqlDate, StrToDateTime(d1));
  d2 := FormatDateTime(sqlDate, StrToDateTime(d2));
  // make query string post_text=''%%7'' changed to post_text=%%7
  sQry := 'UPDATE posts SET topic_id= %%1, forum_id=%%2, user_id=%%3, poster_ip="%%4", post_time="%%5", post_subject="%%6", post_text=%%7, '  +
          'post_postcount= %%8, post_alpha="%%9", post_size=%%A, post_edit_time="%%B", post_edit_reason="", post_edit_user=%%D, post_edit_count=%%E, post_edit_locked="%%F" ' +
          'WHERE id=%%G;';

  sQry := sUpdate( sQry, '%%1', memFrm.topic_id );
  sQry := sUpdate( sQry, '%%2', memFrm.forum_id );
  sQry := sUpdate( sQry, '%%3', memFrm.user_id );
  sQry := sUpdate( sQry, '%%4', memFrm.poster_ip );
  sQry := sUpdate( sQry, '%%5', d1 );
  sQry := sUpdate( sQry, '%%6', memFrm.post_subject );
  // sQry := sUpdate( sQry, '%%7', memFrm.post_text );
  sQry := sUpdate( sQry, '%%7', 'x' + #39 + StrToHex(memFrm.post_text) + #39 );
  sQry := sUpdate( sQry, '%%8', memFrm.post_postcount );

  sQry := sUpdate( sQry, '%%9', memFrm.post_alpha );
  sQry := sUpdate( sQry, '%%A', memFrm.post_size );

  sQry := sUpdate( sQry, '%%B', d2 );
  sQry := sUpdate( sQry, '%%C', memFrm.post_edit_reason );
  sQry := sUpdate( sQry, '%%D', memFrm.post_edit_user );
  sQry := sUpdate( sQry, '%%E', memFrm.post_edit_count );
  sQry := sUpdate( sQry, '%%F', memFrm.post_edit_locked);
  sQry := sUpdate( sQry, '%%G', memFrm.id );

  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := sQry;
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do posts_Update := e.Message +  query2.SQL.Text;
  end;

  query2.active := False;
  query2.Free;

end;

Function Topic_Update( CONST conn: TMySQL55Connection; CONST memTpc: TopInfType ): STRING ;
VAR
  query2 : TSQLQuery;
  d1, d2, d3, d4, sQry   : STRING;

begin

  Topic_Update := '';
  // normalize datetime
  d1 := memTpc.cTime;
  d2 := memTpc.time_limit;
  d3 := memTpc.last_post_time;
  d4 := memTpc.last_view_time;
  if d1 = '' then d1 := DateTimeToStr (now) ;
  if d2 = '' then d2 := '30.12.2099 00:00:00';
  if d3 = '' then d3 := d1;
  if d4 = '' then d4 := d1;
  d1 := FormatDateTime(sqlDate, StrToDateTime(d1));
  d2 := FormatDateTime(sqlDate, StrToDateTime(d2));
  d3 := FormatDateTime(sqlDate, StrToDateTime(d3));
  d4 := FormatDateTime(sqlDate, StrToDateTime(d4));

 // make query string Test: topic_text=%%3 instead of topic_text="%%3",
  sQry := 'UPDATE topics SET forum_id= %%1, title="%%2", topic_text=%%3, poster=%%4, poster_name="%%5", ctime= "%%6", ' +
          'time_limit="%%7", views=%%8, replies=%%9, replies_real=%%A, first_post_id=%%B, first_poster_name="%%C", last_post_id=%%D, ' +
          'last_poster_id=%%E, last_poster_name="%%F", last_post_subject="%%G", last_post_time="%%H", last_view_time="%%I" ' +
          'WHERE id = %%J' ;

  sQry := sUpdate( sQry, '%%1', memTpc.forum_id );
  sQry := sUpdate( sQry, '%%2', memTpc.title );
  // sQry := sUpdate( sQry, '%%3', memTpc.topic_text );
  sQry := sUpdate( sQry, '%%3', 'x' + #39 + StrToHex(memTpc.topic_text) + #39 );
  sQry := sUpdate( sQry, '%%4', memTpc.poster );
  sQry := sUpdate( sQry, '%%5', memTpc.poster_name );
  sQry := sUpdate( sQry, '%%6', d1 );
  sQry := sUpdate( sQry, '%%7', d2 );
  sQry := sUpdate( sQry, '%%8', memTpc.views );
  sQry := sUpdate( sQry, '%%9', memTpc.replies );
  sQry := sUpdate( sQry, '%%A', memTpc.replies_real );
  sQry := sUpdate( sQry, '%%B', memTpc.first_post_id );
  sQry := sUpdate( sQry, '%%C', memTpc.first_poster_name );
  sQry := sUpdate( sQry, '%%D', memTpc.last_post_id);
  sQry := sUpdate( sQry, '%%E', memTpc.last_poster_id );
  sQry := sUpdate( sQry, '%%F', memTpc.last_poster_name );
  sQry := sUpdate( sQry, '%%G', memTpc.last_post_subject );
  sQry := sUpdate( sQry, '%%H', d3 );
  sQry := sUpdate( sQry, '%%I', d4 );
  sQry := sUpdate( sQry, '%%J', memTpc.id );

  query2 := TSQLQuery.Create(nil);
  query2.DataBase := conn;
  query2.SQL.Text := sQry;
  try
    query2.ExecSQL;
    conn.Transaction.Commit;
  except
    on e: Exception do Topic_Update := e.Message +  query2.SQL.Text;
  end;

  query2.active := False;
  query2.Free;

end;

end.

