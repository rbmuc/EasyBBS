////////////////////////////////////////////////////
// project   : bbs_fcgi
// file      : geoinfo.pas
// created   : 07.05.14
// function  : show active bbs users on google maps
// called via: bbs/geoinfo
// paras     : s1 = latlon positions, s2 = marker, s3 = boundary elements
//             s4 = header, s5 = footer

unit geoinfo;
{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;

CONST

  sPos = 'var <<name>>  = new google.maps.LatLng(<<Lat>>, <<Lon>>);' + #13;
  sMark = 'var <<vm>> = new google.maps.Marker({ position: <<name>>, map: map, title: ''<<info>>'' });' + #13;
  sBound = 'Bounds.extend(<<name>>);' + #13 ;


type
  Tgeoinfo = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure Tgeoinfo.Get;
var
  i : integer;
  poscalc : extended;

  myPos, myMark, myBound,
  tPos, tMark, tBound,
  myLat, myLon : String;

  mypara : paraType;
  usrFrm1: usrInfType;
  mySessn: sessInfType;
  query  : TSQLQuery;

begin

// check session
  mypara.VSession := Params.Values['sesn'];
  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.lastError]);
      exit;
    end;

// preset myPara
  paraTypeInit('geoinfo?', myPara );     // callback target for footer
  mypara.sCmd := '1';                    // '1' full menus
  mySessn.id  := mypara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, mySessn );
  sesn_copy_para( mySessn, myPara );

// query
  query := TSQLQuery.Create(nil);
  query.DataBase := BrookFCLFCGIBroker.conn;
  query.SQL.Text := 'select * from sessions where is_active = 1;';
  query.Open;

  if query.EOF then
    begin
       query.active := false;
       query.free;
       Render(err_page, ['No Users online.']);
       exit;
    end;

// loop throug open sessions
  i := 1;
  while not query.EOF do
   begin
     cpySessInfo ( query, mySessn );
     // read session user
     ReadUsr( conn, 'where iduser=' + mySessn.user_id , usrFrm1 );

     // get best lat/lon
     /// lat
     if (Length(mySessn.longitude) > Length(mySessn.sLong)) then
         poscalc := StrToFloat(mySessn.longitude)
       else
         poscalc := StrToFloat(mySessn.sLong);
     poscalc := poscalc + i * 0.000007;                               // avoid stacks on map
     myLon   := FloatToStr( poscalc );
     /// lat
     if (Length(mySessn.latitude) > Length(mySessn.sLat)) then
         poscalc := StrToFloat(mySessn.latitude)
       else
         poscalc := StrToFloat(mySessn.sLat);
     poscalc := poscalc + i * 0.000007;                               // avoid stacks on map
     myLat   := FloatToStr( poscalc );

     // build java script inserts
     myPos  := sUpdate( sPos, '<<name>>', 'pos' + IntToStr(i) );      // set var name
     myPos  := sUpdate( myPos, '<<Lat>>', sUpdate(myLat, ',','.'));   // set vars lat
     myPos  := sUpdate( myPos, '<<Lon>>', sUpdate(myLon, ',', '.'));  // set vars lon
     tPos   += myPos;

     myMark := sUpdate( sMark, '<<vm>>', 'mark' + IntToStr(i) );      // set marker name
     myMark := sUpdate( myMark, '<<name>>', 'pos' + IntToStr(i) );    // set var name
     myMark := sUpdate( myMark, '<<info>>', usrFrm1.Name );           // set marker info
     tMark  += myMark;

     myBound:= sUpdate( sBound, '<<name>>', 'pos' + IntToStr(i) );    // set boundary
     tBound += myBound;
     i += 1;
     query.Next;
   end;


  // display geo_pos
  Render('bbs_geopos.html', [tPos, tMark, tBound,
                             make_Header( mypara ),
                             make_Footer( BrookFCLFCGIBroker.conn, mypara ) ]);

  // release mem
  query.active := false;
  query.free;


end;


initialization
  Tgeoinfo.Register('geoinfo');

end.

