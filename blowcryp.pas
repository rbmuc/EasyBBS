//////////////////////////////////////////////////////////////////////////////////
//   funktion  : Hilfsunit mit oft gebrauchten komponenten
//   Datum     : 03.08.2013
//   modified  : 01.03.2014
//               23.04.2014 BF 2.6.4 -> BF 3.0.0

unit BlowCryp;

{$mode objfpc}{$H+}

interface

uses
  BrookHTTPConsts, BrookConsts, HTTPDefs, BrookHTTPClient, BrookFCLHTTPClientBroker,
  Classes, SysUtils, Variants, FmtBCD, blowfish;

type
  paraType = record                    // lokal vars for get/post handlers
   VSession : string ;
   sError: string ;
   sTopic : string ;
   sID : string ;
   sPst : string ;
   text1 : string ;
   text2 : string ;
   sCmd : string;
   lastError : string;
   userID : integer;
   sip : string;                        // client ip
   v_order : String;
   v_page : String;
   v_rec : String;
   v_eof : String;
  end;

  sessInfType = record                 // session record
   rid : string;
   id : string;
   user_id: string;
   forum_id: string;
   is_active: string;
   last_forum: string;
   browser: string;                     // client browser
   sip : string;                        // client ip
   sLat : string;
   sLong : string;
   latitude: string;
   longitude: string;
   accuracy : string;
   forwarded_for : string;              // footer infos start
   v_order : String;
   v_page : String;
   v_rec : String;
   v_eof : String;
   viewonline : string;
   autologin : string;
   admin : string;
   lastsearch : string;
   lastlogin : String;
   last_post_cnt : String;              // footer infos end
   login : string;
   logout : string;
  end;


  function ip_ntoa(nip: integer):string;
  function ip_aton(sip: string):integer;
  procedure GetIPLatLon( CONST sURL_sip:String; VAR sLat, sLong:STRING );
  function sUpdate(const s1,s2,s3:String):String;
  function encrypt(inStrg: string): string;
  function decrypt(inStrg: string): string;
  procedure codeSessionID( VAR sesnRec: sessInfType );
  function decodeSessionID(VAR myPara: ParaType ):integer;
  function isSessionValid( VAR myPara: ParaType):boolean;
  FUNCTION SecuredStr(CONST S : STRING) : STRING;
  Function sPlus( sIn: String ) : String;
  Function sMinus( sIn: String ) : String;
  function StrToHex(const value:string):string;
  function StripHTML(S: string): string;
  function iif( bPara: Boolean; sTrue, sFalse:String):String;

implementation


function StripHTML(S: string): string;
var
  TagBegin, TagEnd, TagLength: integer;
begin
  TagBegin := Pos( '<', S);             // search position of first <

  while (TagBegin > 0) do begin         // while there is a < in S
    TagEnd := Pos('>', S);              // find the matching >
    TagLength := TagEnd - TagBegin + 1;
    Delete(S, TagBegin, TagLength);     // delete the tag
    TagBegin:= Pos( '<', S);            // search for next <
  end;

  Result := S;                          // give the result
end;


Function sPlus( sIn: String ) : String;
var
  i: integer;
begin
  try
    i := StrToInt( sIn );
  except
    on e: Exception do i := 0;
  end;

  sPlus := IntToStr( i+1 );
end;

Function sMinus( sIn: String ) : String;
var
  i: integer;
begin
  try
    i := StrToInt( sIn );
  except
    on e: Exception do i := 0;
  end;

  if i > 1 then
     sMinus := IntToStr( i-1 )
  else
     sMinus := '0';

end;

function iif( bPara: Boolean; sTrue, sFalse:String):String;
begin
  if bPara then
     iif := sTrue
   else
     iif := sFalse;
end;

function ip_ntoa(nip: integer):string;
var
  o1,o2,o3,o4 : integer;
begin
  o1 := ( nip DIV 16777216 ) MOD 256;
  o2 := ( nip DIV 65536    ) MOD 256;
  o3 := ( nip DIV 256      ) MOD 256;
  o4 := ( nip              ) MOD 256;
  ip_ntoa := IntToStr(o1) + '.' +
             IntToStr(o2) + '.' +
             IntToStr(o3) + '.' +
             IntToStr(o4) ;
end;


function ip_aton(sip: string):integer;
var
  o1,o2,o3,o4 : integer;
  integer_ip  : integer;
  Oktett      : TStringList;

begin
  Oktett := TStringList.Create;
  Oktett.Delimiter := '.';
  Oktett.DelimitedText := sip;

  try
    o1 := StrToInt( Oktett[0] );
    o2 := StrToInt( Oktett[1] );
    o3 := StrToInt( Oktett[2] );
    o4 := StrToInt( Oktett[3] );
    if ( o1 < 0 ) or ( o1 > 255 ) or
       ( o2 < 0 ) or ( o2 > 255 ) or
       ( o3 < 0 ) or ( o3 > 255 ) or
       ( o4 < 0 ) or ( o4 > 255 ) then raise Exception.Create('Oktett Fehler: Eingabe < 0 oder > 255');
    integer_ip := 16777216 * o1
               +     65536 * o2
               +       256 * o3
               +             o4 ;
  except
    on e: Exception do
    begin
     integer_ip := 0;
     // ShowMessage('Falsches IP Format: ' + e.Message );
    end;
  end;
  Oktett.Free;
  ip_aton := integer_ip;
end;


function iTime():integer;
var
  Hour, Min, Sec, MSec, Y, M, D : Word;
begin
  DecodeTime(now(), Hour, Min, Sec, MSec);
  DecodeDate(now(), Y, M, D);
  iTime := Min + 60 * Hour + 1440 * D;
end;


// build session id based on
// user IP & user.iduser + now()
procedure codeSessionID( VAR sesnRec: sessInfType );
begin
  sesnRec.id := encrypt(
                inttostr(ip_aton( sesnRec.sip ))+
                '|' + sesnRec.user_id +
                '|' + inttostr( iTime ) ) ;
end;



function decodeSessionID( VAR myPara: ParaType ):integer;
var
  i : integer;
  sInfo : TStringList;


begin
  // exit on empty sesion string
  if myPara.VSession = '' then
    begin
     myPara.userID   := 0;
     decodeSessionID := 0;
     exit;
    end;

  // parse session string
  sInfo := TStringList.Create;
  sInfo.Delimiter := '|';
  sInfo.DelimitedText := decrypt(myPara.VSession);

  // handle special ip '0.0.0.1' ( used in register mail )
  if sInfo[0] = '1' then sInfo[0] := inttostr(ip_aton( myPara.sIP ));

  // check ip
  if sInfo[0] <> inttostr(ip_aton( myPara.sIP )) then
    begin
     // error on ip diff
     myPara.userID := 0;
     decodeSessionID := -1;
     sInfo.Free;
     exit;
    end;

  // nothing is granted !
  try
    myPara.userID := strtoint( sInfo[1] );
    i := strtoint( sInfo[2] );
  except
    myPara.userID := 0;
    i := 0;
  end;

  decodeSessionID := itime() - i;                          // calc sesn age( mins)
  sInfo.Free;
end;

// check session
// function isSessionValid( VSession: string; VAR sError:String; VAR userID:integer ):boolean;
function isSessionValid( VAR myPara: ParaType):boolean;
VAR
 ttl:integer ;                                             // time to life
begin
 isSessionValid := FALSE;
 IF myPara.VSession <> '' then                             // exit on empty vSession
   begin
     ttl := decodeSessionID(myPara );
     if ttl > 60 then                                      // timeout in minutes
       begin
        myPara.LastError := 'Session abgelaufen.';
        exit;
       end;
     if ttl < 0 then                                       // different ip
       begin
        myPara.LastError := 'Session ungültig.';
        exit;
       end;
     isSessionValid := true;                               // set session flag
   end;

end;


/// replaceString wrapper
function sUpdate (const s1,s2,s3:String):String;
begin
  result:= StringReplace(s1, s2, s3, [rfReplaceAll]);
end;


// procedure GetIPLatLon( CONST sip:String; VAR sLat, sLong:STRING );
// procedure GetIPLatLon( CONST conn: TMySQL55Connection; sip:String; VAR sLat, sLong:STRING );
procedure GetIPLatLon( CONST sURL_sip:String; VAR sLat, sLong:STRING );

var
  VClient: TBrookHTTPClient;
  VHttp  : TBrookHTTPDef = nil;
  sInfo  : TStringList;

begin
  VClient := TBrookHTTPClient.Create('fclweb');
  sInfo   := TStringList.Create;
  sInfo.Delimiter := ',';

  try
    VClient.Prepare(VHttp);
    VHttp.Method := 'GET';
    VHttp.Url    := sURL_sip ;
    VClient.Request(VHttp);
    VHttp.Document.Position := 0;
    sInfo.LoadFromStream(VHttp.Document);

    // cut down JSON string
    // sTest := '{"ip":"109.128.12.96","country_code":"BE","region_code":"11","city":"Brussels","zipcode":"",
    // "latitude":50.8333 ,"longitude":4.3333 ,"region_name":"Brussels Hoofdstedelijk Gewest","country_name":"Belgium"}';
    sInfo.DelimitedText := sUpdate( sUpdate( sUpdate(sInfo.Text , '{', '' ), '}', '' ), '"', '' );
    sLat  := sUpdate( sInfo[5], 'latitude:', '' );
    sLong := sUpdate( sInfo[6], 'longitude:', '' );

  except
    // no answer from service
    on e: Exception do
    begin
     sLat    := '0';
     sLong   := '0';
    end;
  end;

  VHttp.Free;
  VClient.Free;
  sInfo.Free;



end;

FUNCTION SecuredStr(CONST S : STRING) : STRING;
var
  sTemp : string;
  flag  : boolean;

BEGIN
  // silent correction
  sTemp     := s;
  sTemp     := sUpdate(sTemp, '''', '');    // remove quotes
  sTemp     := sUpdate(sTemp, '"','');      // remove DQ
  SecuredStr:= sUpdate(sTemp, ';','');      // remove Semicolon

  // punisher action: return empty string
  sTemp :=  UpperCase(sTemp);
  flag  := Pos('AND', sTemp) > 0  ;
  flag  := flag OR ( Pos('DROP', sTemp) > 0 );
  flag  := flag OR ( Pos('OR 1', sTemp) > 0 );
  flag  := flag OR ( Pos('LIKE', sTemp) > 0 );
  flag  := flag OR ( Pos('WHERE', sTemp)> 0 );
  flag  := flag OR ( Pos('CREATE', sTemp)> 0 );
  if flag then SecuredStr:= '';

END;



{**************************************************************************
* NAME:    StringToHexStr
* DESC:    Konvertiert einen String in eine hexadezimale Darstellung
*************************************************************************}
function StrToHex(const value:string):string;
begin
   SetLength(Result, Length(value)*2); // es wird doppelter Platz benötigt
   if Length(value) > 0 then
      BinToHex(PChar(value), PChar(Result), Length(value));
end;


{**************************************************************************
* NAME:    HexStrToString
* DESC:    Dekodiert einen hexadezimalen String
*************************************************************************}
function HexToStr(const value:string):string;
begin
   SetLength(Result, Length(value) div 2); // es wird halber Platz benötigt
   if Length(value) > 0 then
      HexToBin(PChar(value), PChar(Result), Length(value));
end;



/// blowfish crypt functions
function encrypt(inStrg: string): string;
var
  s1: TStringStream;
  bf: TBlowfishEncryptStream;

begin
  if inStrg ='' then exit;
  s1:=TStringStream.Create('');                          //  make sure destination stream is blank
  bf:=TBlowfishEncryptStream.Create('Mona#1lisa', s1);   //  writes to destination stream
  bf.writeAnsiString( inStrg );
  bf.free;
  result:= StrToHex ( s1.datastring ) ;
  s1.free;

end;

function decrypt(inStrg: string): string;
var
  s2: TStringStream;
  bf: TBlowfishDecryptStream;

begin
  if inStrg ='' then exit;
  s2:=TStringStream.Create( HexToStr(inStrg) );          // fill stream
  bf:=TBlowfishDecryptStream.Create('Mona#1lisa', s2);   // create blowfish stream
  result:= bf.readAnsiString ;                           // copy stream contents to destination
  bf.free;
  s2.free;

end;


end.



