/////////////////////////////////////////////////////////////////////////
// project   : bbs_fcgi
// author    : Ralph Berger
// created   : 07.03.14
//             handle footer events
//             redirect to call page
// sample href="/cgi-bin/bbs/event?ev=3&sesn=xxx
// modified  : 24.04.2014 BF 2.6.4 -> BF 3.0.0

unit fevent;

{$mode objfpc}{$H+}

interface

uses
  BrookAction, BrookFCLFCGIBroker, BrookConsts, Classes, SysUtils, Variants,
  FmtBCD, sqldb, blowcryp, mapping, menu;

type
  Tfevent = class(TBrookAction)
  public
    procedure Get; override;
  end;

implementation

procedure Tfevent.Get;
Var
  i : integer;
  sRedirect : String;
  sesnRec: sessInfType;
  myPara : ParaType;


begin
  // build redirect string & read paras
  for I := 0 to Pred(Params.Count) do
   begin
      if sRedirect <> '' then sRedirect += '&';
      sRedirect += Params.Names[i] + '=' + Params.Values[Params.Names[i]]; // Params.Items[I].AsString;
      case Params.Names[i] of
        'ev'   : myPara.sPst     := Params.Values['ev'];
        'sesn' : myPara.VSession := Params.Values['sesn'];
      end
   end;

  mypara.sip:= TheRequest.RemoteAddress;
  if NOT isSessionValid( mypara ) then
    begin
      Render(err_page, [myPara.LastError]);
      exit;
    end;

 // read session info
  sesnRec.id := myPara.VSession;
  sesn_Read( BrookFCLFCGIBroker.conn, sesnRec);

  case myPara.sPst of
    '1' : sesnRec.v_order := '1';                        // sort order
    '2' : sesnRec.v_order := '2';
    '3' : sesnRec.v_order := '3';
    '4' : if sesnRec.v_page <> '0' then sesnRec.v_page  := sMinus( sesnRec.v_page );   // prev page
    '5' : if sesnRec.v_eof = '0'   then sesnRec.v_page  := sPlus ( sesnRec.v_page );   // next page
  end;

  myPara.LastError := sesn_update ( BrookFCLFCGIBroker.conn, sesnRec);
  if myPara.LastError <> '' then
     begin
      Render(err_page, [myPara.LastError]);
      exit;
    end;

  // return to caller
  redirect (sesnRec.forwarded_for + '&sesn=' + myPara.VSession, 302);

end;

initialization
  Tfevent.Register('event');

end.

